-- Minimal Tabletop Simulator runtime stub for off-TTS unit tests.
-- Captures side-effecting calls so specs can assert on the DATA the engine
-- produces (spawn params, object data, API calls) without a running game.

CAPTURE = { spawned = {}, dataSpawned = {}, puts = {}, apiCalls = {}, logs = {} }

function log(msg) table.insert(CAPTURE.logs, tostring(msg)) end
function printToAll(msg) table.insert(CAPTURE.logs, tostring(msg)) end
function broadcastToAll(msg) table.insert(CAPTURE.logs, tostring(msg)) end

local function fakeObject(o)
  o = o or {}
  o._name = o._name or ""
  o._tags = o._tags or {}
  o._buttons = {}
  o.spawning = false
  o.loading_custom = false
  function o.getName() return o._name end
  function o.setName(n) o._name = n end
  function o.getPosition() return o._pos or { x = 0, y = 0, z = 0 } end
  function o.getGUID() return o._guid or "guid0" end
  function o.getTags() return o._tags end
  function o.hasTag(t) for _, x in ipairs(o._tags) do if x == t then return true end end return false end
  function o.addTag(t) table.insert(o._tags, t) end
  function o.setLuaScript(s) o._script = s end
  function o.getLuaScript() return o._script end
  function o.reload() return o end
  function o.setCustomObject(p) o._custom = p end
  function o.getCustomObject() return o._custom end
  function o.createButton(p) table.insert(o._buttons, p) end
  function o.getButtons() return o._buttons end
  function o.clearButtons() o._buttons = {} end
  function o.setPositionSmooth() end
  function o.spread() return {} end
  function o.putObject(x) table.insert(CAPTURE.puts, { bag = o, obj = x }); o._qty = (o._qty or 0) + 1; return o end
  function o.getQuantity() return o._qty or 1 end
  return o
end
FAKE_OBJECT = fakeObject

function spawnObject(p)
  local pos = p.position and { x = p.position[1], y = p.position[2], z = p.position[3] } or { x = 0, y = 0, z = 0 }
  local o = fakeObject({ _pos = pos })
  o._spawnParams = p
  table.insert(CAPTURE.spawned, { params = p, obj = o })
  if p.callback_function then p.callback_function(o) end
  return o
end

function spawnObjectData(p)
  local o = fakeObject({})
  o._data = p.data
  table.insert(CAPTURE.dataSpawned, { params = p, obj = o, data = p.data })
  if p.callback_function then p.callback_function(o) end
  return o
end
spawnObjectJSON = spawnObjectData

function getObjectsWithTag(t) return (_G.OBJECTS_BY_TAG or {})[t] or {} end
function getObjects() return _G.ALL_OBJECTS or {} end
function getObjectFromGUID(g) return (_G.OBJECTS_BY_GUID or {})[g] end

WebRequest = {
  get = function(url, cb)
    local r = _G.WEBRESPONSES and _G.WEBRESPONSES[url]
    if r then cb({ text = r, is_error = false, response_code = 200 }) end
  end,
}

-- Wait.* fire synchronously only when WAIT_RUN is set, so specs control timing.
Wait = {
  time = function(f) if _G.WAIT_RUN then f() end return 1 end,
  frames = function(f) if _G.WAIT_RUN then f() end return 1 end,
  condition = function(f) if _G.WAIT_RUN then f() end return 1 end,
  stop = function() end,
}

Global = { call = function(fn, params) table.insert(CAPTURE.apiCalls, { fn = fn, params = params }); return true end }

-- `self` = the envelope the loader is injected onto.
self = fakeObject({ _name = "Dawnbringer Class Envelope", _guid = "env-guid", _tags = { "Class Envelope" } })

function resetCapture()
  CAPTURE = { spawned = {}, dataSpawned = {}, puts = {}, apiCalls = {}, logs = {} }
end
