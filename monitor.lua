-- Run on a wireless Pocket Computer or Computer to watch miner.lua.
local PROTOCOL="mining_turtle_status"
local modem
for _,side in ipairs({"left","right","top","bottom","front","back"}) do
  if peripheral.getType(side)=="modem" then modem=side; break end
end
if not modem then error("Attach a wireless modem") end
rednet.open(modem)
term.clear(); term.setCursorPos(1,1)
print("Waiting for mining turtles...")
while true do
  local sender,msg=rednet.receive(PROTOCOL)
  if type(msg)=="table" then
    term.clear(); term.setCursorPos(1,1)
    print("MINER #"..tostring(msg.id or sender))
    if msg.label then print("Name: "..msg.label) end
    print("State: "..tostring(msg.status))
    print(("Relative position: %s, %s, %s"):format(msg.x,msg.y,msg.z))
    print("Fuel: "..tostring(msg.fuel))
    print("Blocks mined: "..tostring(msg.mined))
    print("Updated: "..textutils.formatTime(os.time(),true))
  end
end

