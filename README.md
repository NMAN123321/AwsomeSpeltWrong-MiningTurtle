# Tekkit Classic Reloaded Spiral Resource Miner

This project is for a CC:Tweaked Mining Turtle in Tekkit Classic Reloaded 1.3.1.

## Mine layout

The turtle starts on the surface beside its home chest. It cuts a descending square spiral in a fixed **5x5 footprint**, with two-block headroom so a player can walk down the same route. At the selected depth it creates a 48-block main tunnel with eight-block branches on both sides every six blocks.

By default, entering the correct surface Y makes it descend to **Y -54**, a useful Minecraft 1.19.2 diamond and redstone level. If the Y prompt is left blank, it descends 80 blocks instead.

This is a compact spiral stairwell, not a completely hollow 5x5 vertical quarry. A fully hollow shaft would produce far more waste, consume much more fuel, and greatly increase lava and falling-block hazards.

## Surface setup

```text
[Home chest] [Mining Turtle] ---> clear working area
```

1. Use a Mining Turtle.
2. Place a chest or barrel in any directly adjacent block. Behind the turtle is easiest.
3. Put plenty of coal or charcoal in the chest. A surface-to-deepslate run and all return trips can require several hundred fuel operations.
4. Put `miner.lua` on the turtle and run `miner`.
5. Enter the turtle's current Minecraft Y coordinate from the F3 screen.
6. Optionally attach a wireless modem and run `monitor.lua` on a wireless computer.

## Resource handling

The turtle keeps and returns:

- Coal and other recognized fuel
- Diamonds, emeralds, lapis, redstone and quartz
- Raw iron, gold and copper
- Common Tekkit metals and rare resources including tin, silver, lead, nickel, platinum, uranium, iridium, ruby, sapphire, certus quartz, osmium, zinc, cinnabar and apatite

Stone, cobblestone, deepslate, dirt, gravel and other unrecognized blocks are dropped underground and eventually despawn. Edit `resourceWords` near the top of `miner.lua` to add a mod-specific resource name.

When a tunnel exposes a recognized resource, the turtle enters the deposit and follows connected resource blocks in all six directions. It then retraces the vein back to the exact tunnel block where it started. A single vein is capped at 64 blocks (`maxVeinBlocks`) to avoid filling the inventory or following an unusually large modded deposit indefinitely.

Coal discovered while mining is consumed when fuel falls below the reserve. If that is still insufficient, the turtle follows its recorded spiral route to the surface chest. A turtle cannot scan distant blocks or know where an undiscovered coal vein is, so it cannot selectively travel to nearby coal that it has not already exposed.

The fuel reserve grows with the length of the saved route and includes enough allowance for a maximum-size vein excursion. At the surface, the turtle requires enough fuel for the trip back to work, another return home, vein mining, and a safety margin. If the chest cannot provide that amount, it remains at the chest and stops with an error instead of departing on an unsafe trip.

## Safety and chunk loading

- The entire route is saved and used for every surface trip.
- On an interrupted run, the program offers a recovery-only return to the chest.
- It stops at protected or unbreakable blocks.
- Lava is not automatically made safe. Supervise the first run and keep the shaft away from known lava where possible.
- A normal CC:Tweaked turtle cannot load chunks. Use the included FTB Chunks map to claim and force-load every chunk containing the 5x5 shaft and horizontal tunnels. Server settings may restrict force-loading.
- Delete `.spiral-miner-state` only when the turtle is physically back at its original surface position and facing its original direction.

Configuration such as target Y, shaft footprint, tunnel length, branch spacing, and fuel reserve is at the top of `miner.lua`.
