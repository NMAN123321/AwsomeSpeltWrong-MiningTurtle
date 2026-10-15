-- Spiral resource miner for CC:Tweaked / Tekkit Classic Reloaded 1.3.1
-- Surface setup: place a chest directly beside a Mining Turtle.

local CFG = {
  targetY = -54,
  fallbackDepth = 80,
  spiralSide = 4,
  roomSize = 10,
  roomHeight = 4,
  gridChunkRadius = 2,
  gridSpacing = 3,
  maxVeinBlocks = 64,
  statusEvery = 12,
  fuelReserve = 320,
  longRunFuelTarget = 5000,
  protocol = "mining_turtle_status",
  stateFile = ".spiral-miner-state",
}

local pos={x=0,y=0,z=0,dir=0}
local home={x=0,y=0,z=0,dir=0}
local chest=nil
local route={{x=0,y=0,z=0,dir=0}}
local status="starting"
local mined=0

local resourceWords={
  "coal", "diamond", "emerald", "lapis", "redstone", "ancient_debris",
  "raw_", "gold", "iron", "copper", "tin", "lead", "silver", "nickel",
  "platinum", "uranium", "iridium", "ruby", "sapphire", "certus",
  "quartz", "osmium", "zinc", "cinnabar", "apatite",
}

local function copyPoint() return {x=pos.x,y=pos.y,z=pos.z,dir=pos.dir} end

local function save()
  local h=fs.open(CFG.stateFile,"w")
  if h then
    h.write(textutils.serialize({pos=pos,home=home,chest=chest,route=route,status=status,mined=mined}))
    h.close()
  end
end

local function loadState()
  if not fs.exists(CFG.stateFile) then return false end
  local h=fs.open(CFG.stateFile,"r")
  local s=textutils.unserialize(h.readAll()); h.close()
  if type(s)~="table" or type(s.pos)~="table" then return false end
  pos=s.pos; home=s.home or home; chest=s.chest; route=s.route or route
  status=s.status or status; mined=s.mined or 0
  return true
end

local function openModem()
  for _,side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.getType(side)=="modem" then rednet.open(side); return true end
  end
  return false
end

local hasModem=openModem()
local function report(message)
  status=message; save(); term.clear(); term.setCursorPos(1,1)
  print("Spiral Miner #"..os.getComputerID()); print(message)
  print(("Relative: %d, %d, %d"):format(pos.x,pos.y,pos.z))
  print("Fuel: "..tostring(turtle.getFuelLevel())); print("Blocks mined: "..mined)
  if hasModem then
    rednet.broadcast({id=os.getComputerID(),label=os.getComputerLabel(),status=message,
      x=pos.x,y=pos.y,z=pos.z,fuel=turtle.getFuelLevel(),mined=mined},CFG.protocol)
  end
end

local function turnRight() turtle.turnRight(); pos.dir=(pos.dir+1)%4; save() end
local function turnLeft() turtle.turnLeft(); pos.dir=(pos.dir+3)%4; save() end
local function face(d)
  local n=(d-pos.dir)%4
  if n==1 then turnRight() elseif n==2 then turnRight();turnRight() elseif n==3 then turnLeft() end
end

local function applyForward()
  if pos.dir==0 then pos.z=pos.z-1 elseif pos.dir==1 then pos.x=pos.x+1
  elseif pos.dir==2 then pos.z=pos.z+1 else pos.x=pos.x-1 end
end

local function forward(dig)
  local tries=0
  while not turtle.forward() do
    if turtle.detect() then
      if not dig or not turtle.dig() then return false end
      mined=mined+1
    else turtle.attack() end
    tries=tries+1; if tries>20 then return false end; sleep(0.15)
  end
  applyForward(); save(); return true
end

local function up(dig)
  while not turtle.up() do
    if not dig or not turtle.detectUp() or not turtle.digUp() then return false end
    mined=mined+1; sleep(0.15)
  end
  pos.y=pos.y+1; save(); return true
end

local function down(dig)
  while not turtle.down() do
    if not dig or not turtle.detectDown() or not turtle.digDown() then return false end
    mined=mined+1; sleep(0.15)
  end
  pos.y=pos.y-1; save(); return true
end

local function recordRoute() route[#route+1]=copyPoint(); save() end

local function moveAdjacent(target,dig)
  local dx,dy,dz=target.x-pos.x,target.y-pos.y,target.z-pos.z
  if dy==1 and dx==0 and dz==0 then return up(dig) end
  if dy==-1 and dx==0 and dz==0 then return down(dig) end
  if dy~=0 then return false end
  if dx==1 and dz==0 then face(1) elseif dx==-1 and dz==0 then face(3)
  elseif dz==1 and dx==0 then face(2) elseif dz==-1 and dx==0 then face(0)
  else return false end
  return forward(dig)
end

local function followRoute(reverse)
  if reverse then
    for i=#route-1,1,-1 do if not moveAdjacent(route[i],false) then return false end end
  else
    for i=2,#route do if not moveAdjacent(route[i],false) then return false end end
  end
  return true
end

local function isChest(data)
  return data and data.name and (data.name:find("chest",1,true) or data.name:find("barrel",1,true))
end

local function findAdjacentChest()
  local original=pos.dir
  for _=1,4 do
    local ok,data=turtle.inspect()
    if ok and isChest(data) then chest={dir=pos.dir,side="front"}; face(original); save(); return true end
    turnRight()
  end
  local okU,dataU=turtle.inspectUp()
  if okU and isChest(dataU) then chest={dir=original,side="up"}; save(); return true end
  local okD,dataD=turtle.inspectDown()
  if okD and isChest(dataD) then chest={dir=original,side="down"}; save(); return true end
  return false
end

local function chestAction(action)
  face(chest.dir)
  if chest.side=="up" then
    if action=="suck" then return turtle.suckUp(64) else return turtle.dropUp() end
  elseif chest.side=="down" then
    if action=="suck" then return turtle.suckDown(64) else return turtle.dropDown() end
  else
    if action=="suck" then return turtle.suck(64) else return turtle.drop() end
  end
end

local function matchesResource(name)
  if not name then return false end
  for _,word in ipairs(resourceWords) do if name:find(word,1,true) then return true end end
  return false
end

local function isFiller(name)
  return name=="minecraft:cobblestone" or name=="minecraft:cobbled_deepslate"
end

local function findFillerSlot()
  local best=nil
  local bestCount=0
  for slot=1,16 do
    local item=turtle.getItemDetail(slot)
    if item and isFiller(item.name) and item.count>bestCount then
      best=slot; bestCount=item.count
    end
  end
  return best
end

local function refuelTo(target)
  if turtle.getFuelLevel()=="unlimited" then return end
  for slot=1,16 do
    turtle.select(slot)
    while turtle.getItemCount(slot)>0 and turtle.getFuelLevel()<target and turtle.refuel(0) do turtle.refuel(1) end
    if turtle.getFuelLevel()>=target then break end
  end
end

local function discardJunk()
  -- Retain the fullest single stack of cobblestone/cobbled deepslate for floors.
  local fillerSlot=findFillerSlot()
  for slot=1,16 do
    local item=turtle.getItemDetail(slot)
    local reservedFiller=item and isFiller(item.name) and slot==fillerSlot
    if item and not reservedFiller and not matchesResource(item.name) and not turtle.refuel(0) then
      turtle.select(slot); turtle.dropDown()
    end
  end
end

local function ensureSafeFloor()
  if turtle.detectDown() then return true end
  local slot=findFillerSlot()
  if not slot then
    error("Unsafe opening below the path and no cobblestone is available")
  end
  turtle.select(slot)
  if not turtle.placeDown() then
    error("Could not place a safety floor below the path")
  end
  return true
end

local function inventoryFull()
  for slot=1,16 do if turtle.getItemCount(slot)==0 then return false end end
  return true
end

local function safeReturnFuel()
  -- Route home, a worst-case vein traversal (out and back), plus a safety margin.
  return math.max(CFG.fuelReserve,(#route-1)+(CFG.maxVeinBlocks*2)+40)
end

local function safeRoundTripFuel()
  -- From the chest back to the work face and home once more, with a margin.
  return math.max(CFG.longRunFuelTarget,CFG.fuelReserve,(#route-1)*2+(CFG.maxVeinBlocks*2)+40)
end

local function returnHome() report("Returning up the spiral"); return followRoute(true) end
local function returnToWork(workDir)
  if not followRoute(false) then return false end
  face(workDir); return true
end

local function serviceChest(returnAfter)
  local workDir=pos.dir
  discardJunk(); refuelTo(CFG.fuelReserve)
  if not returnHome() then error("The spiral route home is blocked") end
  for slot=1,16 do
    local item=turtle.getItemDetail(slot)
    if item and matchesResource(item.name) then turtle.select(slot); chestAction("drop") end
  end
  local wanted=safeRoundTripFuel()
  for slot=1,16 do
    if turtle.getFuelLevel()=="unlimited" or turtle.getFuelLevel()>=wanted then break end
    if turtle.getItemCount(slot)==0 then
      turtle.select(slot)
      if not chestAction("suck") then break end
      refuelTo(wanted)
    end
  end
  for slot=1,16 do
    local item=turtle.getItemDetail(slot)
    if item and not isFiller(item.name) then turtle.select(slot); chestAction("drop") end
  end
  face(home.dir)
  local fuel=turtle.getFuelLevel()
  if returnAfter and fuel~="unlimited" and fuel<wanted then
    error("Not enough fuel for a safe round trip; turtle remained at the chest")
  end
  if returnAfter and not returnToWork(workDir) then error("The spiral route back to work is blocked") end
  turtle.select(1)
end

local function ensureReady()
  local needed=safeReturnFuel()
  discardJunk(); refuelTo(needed)
  local fuel=turtle.getFuelLevel()
  if inventoryFull() or (fuel~="unlimited" and fuel<needed) then serviceChest(true) end
end

local function isResource(inspect)
  local ok,data=inspect(); return ok and data and matchesResource(data.name)
end

local function mineExposedResources()
  local originalDir=pos.dir
  local seen={}
  local veinCount=0
  local function key(x,y,z) return x..":"..y..":"..z end
  seen[key(pos.x,pos.y,pos.z)]=true

  local function canContinue()
    if veinCount>=CFG.maxVeinBlocks then return false end
    -- Stop before all slots are occupied. The normal tunnel routine will unload.
    return not inventoryFull()
  end

  local function explore()
    if not canContinue() then return end
    local entryDir=pos.dir

    for direction=0,3 do
      if not canContinue() then break end
      face(direction)
      local dx,dz=0,0
      if direction==0 then dz=-1 elseif direction==1 then dx=1
      elseif direction==2 then dz=1 else dx=-1 end
      local targetKey=key(pos.x+dx,pos.y,pos.z+dz)
      if not seen[targetKey] and isResource(turtle.inspect) then
        seen[targetKey]=true
        if turtle.dig() then
          mined=mined+1; veinCount=veinCount+1
          if forward(false) then
            explore()
            face((direction+2)%4)
            if not forward(false) then error("Could not leave a mined ore vein") end
          end
        end
      end
    end

    if canContinue() then
      local targetKey=key(pos.x,pos.y+1,pos.z)
      if not seen[targetKey] and isResource(turtle.inspectUp) then
        seen[targetKey]=true
        if turtle.digUp() then
          mined=mined+1; veinCount=veinCount+1
          if up(false) then explore(); if not down(false) then error("Could not descend out of an ore vein") end end
        end
      end
    end

    if canContinue() then
      local targetKey=key(pos.x,pos.y-1,pos.z)
      if not seen[targetKey] and isResource(turtle.inspectDown) then
        seen[targetKey]=true
        if turtle.digDown() then
          mined=mined+1; veinCount=veinCount+1
          if down(false) then explore(); if not up(false) then error("Could not climb out of an ore vein") end end
        end
      end
    end
    face(entryDir)
  end

  explore()
  face(originalDir)
  ensureSafeFloor()
  if veinCount>0 then report("Mined a connected vein of "..veinCount.." blocks") end
end

local function digSpiral(depth)
  report("Building 5x5 spiral stairway"); face(home.dir)
  local onSide=0
  for _=1,depth do
    ensureReady()
    if not forward(true) then error("Unbreakable block in spiral") end
    recordRoute()
    if turtle.detectUp() and not turtle.digUp() then error("Cannot clear staircase headroom") end
    if not down(true) then error("Unbreakable floor in spiral") end
    recordRoute(); ensureSafeFloor(); mineExposedResources()
    onSide=onSide+1
    if onSide==CFG.spiralSide then turnRight(); onSide=0 end
  end
end

local function recordedForward(clearHeadroom,scanResources,checkFloor)
  ensureReady()
  if not forward(true) then error("Unbreakable block in mining area") end
  recordRoute()
  if checkFloor then ensureSafeFloor() end
  if clearHeadroom and turtle.detectUp() then turtle.digUp(); mined=mined+1 end
  if scanResources then mineExposedResources() end
end

local function recordedHorizontalTo(x,z,clearHeadroom,scanResources,checkFloor)
  if pos.x~=x then
    face(pos.x<x and 1 or 3)
    while pos.x~=x do recordedForward(clearHeadroom,scanResources,checkFloor) end
  end
  if pos.z~=z then
    face(pos.z<z and 2 or 0)
    while pos.z~=z do recordedForward(clearHeadroom,scanResources,checkFloor) end
  end
end

local function clearRoom()
  report("Clearing 10x10x4 staging room")
  local routeMark=#route
  local anchor=copyPoint()
  local minX=anchor.x-math.floor((CFG.roomSize-1)/2)
  local maxX=minX+CFG.roomSize-1
  local minZ=anchor.z-math.floor((CFG.roomSize-1)/2)
  local maxZ=minZ+CFG.roomSize-1

  recordedHorizontalTo(minX,minZ,false,false,true)
  for level=0,CFG.roomHeight-1 do
    if level>0 then
      recordedHorizontalTo(minX,minZ,false,false,false)
      ensureReady()
      if not up(true) then error("Could not excavate the staging room ceiling") end
      recordRoute()
    end
    for row=0,CFG.roomSize-1 do
      local targetX=(row%2==0) and maxX or minX
      recordedHorizontalTo(targetX,pos.z,false,false,level==0)
      if row<CFG.roomSize-1 then recordedHorizontalTo(pos.x,pos.z+1,false,false,level==0) end
    end
  end

  -- Return to the spiral anchor without making the permanent home route tour the room.
  while #route>routeMark do
    local target=route[#route-1]
    if not moveAdjacent(target,false) then error("The staging room route became blocked") end
    table.remove(route); save()
  end
  face(anchor.dir)
end

local function gridBounds(startX,startZ)
  if startX and startZ then
    local centerChunkX=math.floor(startX/16)
    local centerChunkZ=math.floor(startZ/16)
    local minWorldX=(centerChunkX-CFG.gridChunkRadius)*16
    local minWorldZ=(centerChunkZ-CFG.gridChunkRadius)*16
    local width=(CFG.gridChunkRadius*2+1)*16
    return minWorldX-startX,minWorldX-startX+width-1,
      minWorldZ-startZ,minWorldZ-startZ+width-1
  end
  local width=(CFG.gridChunkRadius*2+1)*16
  local low=-math.floor(width/2)
  return low,low+width-1,low,low+width-1
end

local function digGrid(startX,startZ)
  local minX,maxX,minZ,maxZ=gridBounds(startX,startZ)
  report("Connecting to the 5x5 chunk mining grid")
  recordedHorizontalTo(minX,minZ,true,true,true)

  local row=0
  local z=minZ
  while z<=maxZ do
    local targetX=(row%2==0) and maxX or minX
    recordedHorizontalTo(targetX,z,true,true,true)
    row=row+1
    local nextZ=minZ+row*CFG.gridSpacing
    if nextZ<=maxZ then recordedHorizontalTo(pos.x,nextZ,true,true,true) end
    z=nextZ
    if row%CFG.statusEvery==0 then report("Mining chunk grid row "..row) end
  end
end

local function run()
  print("Spiral Resource Miner")
  print("Put a chest with coal directly beside the turtle.")
  print("Enter the turtle's current Minecraft Y level")
  print("(shown on F3), or leave blank for "..CFG.fallbackDepth.." blocks:")
  local entered=tonumber(read())
  local depth=entered and math.max(1,math.floor(entered-CFG.targetY)) or CFG.fallbackDepth
  print("Enter current X (blank uses a centered 80x80 grid):")
  local startX=tonumber(read())
  print("Enter current Z (blank uses a centered 80x80 grid):")
  local startZ=tonumber(read())
  if not startX or not startZ then startX=nil; startZ=nil end
  print("Will descend "..depth.." blocks toward Y "..CFG.targetY..".")
  print("Press Enter to begin."); read()
  if not findAdjacentChest() then error("No chest or barrel directly beside the turtle") end
  if chest.side=="front" then home.dir=(chest.dir+2)%4 else home.dir=pos.dir end
  route[1].dir=home.dir; face(home.dir); save()
  serviceChest(false)
  local fuel=turtle.getFuelLevel()
  if fuel~="unlimited" and fuel<CFG.fuelReserve then
    error("The chest does not contain enough turtle fuel (need "..CFG.fuelReserve.." minimum)")
  end
  digSpiral(depth); clearRoom(); digGrid(startX,startZ); serviceChest(false)
  report("Finished safely at the surface chest")
end

local resumed=loadState()
if resumed and status~="Finished safely at the surface chest" then
  print("Interrupted run found at relative "..pos.x..","..pos.y..","..pos.z)
  print("Type YES to follow the saved spiral route home:")
  if read()=="YES" and chest then serviceChest(false); report("Recovered to the surface chest") end
else
  local ok,err=xpcall(run,debug.traceback)
  if not ok then report("STOPPED: "..tostring(err)); print(err) end
end
