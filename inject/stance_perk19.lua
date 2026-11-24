[19]={(function()
local N="Frostguard"
local V,R,b=N.."-SV",N.."-SR"
local function f()for _,o in ipairs(getObjectsWithTag("Character"))do if o.getName()==N then return o end end end
local function a()b=nil local o=f()local s=o.getLuaScript()if s:find(V,1,true)then return end
local t=o.UI.getCustomAssets()or{}table.insert(t,{name=V,url="https://i.imgur.com/RJugn5h.png"})table.insert(t,{name=R,url="https://i.imgur.com/RhTKTDc.png"})o.UI.setCustomAssets(t)
o.setLuaScript((s:gsub("info = {",'info={stances={{label="Vanguard",color="#d6efff",textColor="#000000",icon="'..V..'"},{label="Rearguard",color="#8b4141",textColor="#FFFFFF",icon="'..R..'"}},',1)))o.reload()end
local function w()if b then return end b=1 Wait.condition(a,function()local o=f()return o and not o.spawning and not o.loading_custom end)end
function onCharacterLoad(c)if c.class==N then w()end end
function __callExtension(r)return _G[r.event](table.unpack(r.parameters))end
Wait.time(function()w()pcall(Global.call,"__registerExtensions",{__caller=self.getGUID()})end,.5)
end)()},
