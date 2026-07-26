#!/usr/bin/env node
// Runs the Lua unit specs under fengari (a Lua VM in JS), so the tests
// exercise the REAL engine.lua rather than a re-implementation.
const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");

const root = path.join(__dirname, "..");
const read = (p) => fs.readFileSync(path.join(root, p), "utf8");

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

// Route Lua print()/io.write to Node stdout.
function loadAndRun(source, chunkname, nresults) {
  const status = lauxlib.luaL_loadbuffer(L, to_luastring(source), null, to_luastring(chunkname));
  if (status !== lua.LUA_OK) {
    console.error(`load error in ${chunkname}:\n` + to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
  }
  if (lua.lua_pcall(L, 0, nresults === undefined ? 0 : nresults, 0) !== lua.LUA_OK) {
    console.error(`runtime error in ${chunkname}:\n` + to_jsstring(lua.lua_tostring(L, -1)));
    process.exit(1);
  }
}

function setGlobalFromChunk(source, chunkname, globalName) {
  loadAndRun(source, chunkname, 1); // leaves 1 return value on the stack
  lua.lua_setglobal(L, to_luastring(globalName));
}

// 1. TTS runtime stub (defines globals).
loadAndRun(read("tests/tts_mock.lua"), "tts_mock.lua", 0);
// 2. Engine (returns the Engine table).
setGlobalFromChunk(read("engine.lua"), "engine.lua", "Engine");
// 3. Manifests (each returns a table).
setGlobalFromChunk(read("manifests/dawnbringer.lua"), "dawnbringer.lua", "DAWNBRINGER");
setGlobalFromChunk(read("manifests/zephyr.lua"), "zephyr.lua", "ZEPHYR");
// 3b. The ACTUAL shipped manifests, extracted from the perk-[19] inject
//     snippets, so the spec can prove they haven't drifted from the fixtures.
function injectManifest(injPath, globalName) {
  const src = read(injPath);
  const m = src.match(/\[==\[([\s\S]*?)\]==\]/);
  if (!m) { console.error(`no [==[...]==] manifest block in ${injPath}`); process.exit(1); }
  loadAndRun(m[1] + `\n` + globalName + ` = MANIFEST`, injPath, 0);
}
injectManifest("inject/dawnbringer_perk19.lua", "INJ_DAWN");
injectManifest("inject/zephyr_perk19.lua", "INJ_ZEPH");
// 4. Spec: returns number of failures.
loadAndRun(read("tests/spec.lua"), "spec.lua", 1);
const failures = lua.lua_tointeger(L, -1);
process.exit(failures > 0 ? 1 : 0);
