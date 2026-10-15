# Tekkit Classic Reloaded Spiral Resource Miner

This project is for a CC:Tweaked Mining Turtle in Tekkit Classic Reloaded 1.3.1.

## Mine layout

The turtle starts on the surface beside its home chest. It cuts a descending square spiral in a fixed **5x5 footprint**, with two-block headroom so a player can walk down the same route. At the selected depth it clears a **10x10x4 staging room**, then mines a continuous tunnel grid across the five-by-five chunk square centered on the starting chunk (two chunks outward in every horizontal direction).

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
5. Enter the turtle's current Minecraft Y, X, and Z coordinates from the F3 screen. X and Z let it align the grid exactly to chunk boundaries; leaving either blank produces a centered 80x80 grid instead.
6. Optionally attach a wireless modem and run `monitor.lua` on a wireless computer.

## Resource handling

The turtle keeps and returns:

- Coal and other recognized fuel
- Diamonds, emeralds, lapis, redstone and quartz
- Raw iron, gold and copper
- Common Tekkit metals and rare resources including tin, silver, lead, nickel, platinum, uranium, iridium, ruby, sapphire, certus quartz, osmium, zinc, cinnabar and apatite

Stone, deepslate, dirt, gravel and other unrecognized blocks are dropped underground and eventually despawn. One stack of cobblestone or cobbled deepslate is reserved for construction; excess stacks are dropped. Edit `resourceWords` near the top of `miner.lua` to add a mod-specific resource name.

The turtle keeps its fullest stack of cobblestone or cobbled deepslate as building material. It checks the block beneath every spiral step and tunnel block; when a cave or mined floor ore leaves an opening, it fills the opening before continuing. If there is no solid floor and no reserved building material, it stops rather than leaving a dangerous player drop. These are full-block steps, so players walk down normally and jump while walking back up.

When a tunnel exposes a recognized resource, the turtle enters the deposit and follows connected resource blocks in all six directions. It then retraces the vein back to the exact tunnel block where it started. A single vein is capped at 64 blocks (`maxVeinBlocks`) to avoid filling the inventory or following an unusually large modded deposit indefinitely.

Coal discovered while mining is consumed when fuel falls below the reserve. If that is still insufficient, the turtle follows its recorded spiral route to the surface chest. A turtle cannot scan distant blocks or know where an undiscovered coal vein is, so it cannot selectively travel to nearby coal that it has not already exposed.

At the chest, the turtle fuels itself to `longRunFuelTarget` (5,000 movement operations by default), or a larger dynamically calculated amount when the route requires it. It does not make scheduled unloading trips. It returns only when its resource inventory is full, its calculated safety reserve is threatened, the mining job finishes, or recovery is required. The safety reserve grows with the saved route and includes a maximum-size vein excursion. If the chest cannot provide enough for a safe round trip, it remains at the chest and stops instead of departing unsafely.

## Safety and chunk loading

- The entire route is saved and used for every surface trip.
- On an interrupted run, the program offers a recovery-only return to the chest.
- It stops at protected or unbreakable blocks.
- Lava is not automatically made safe. Supervise the first run and keep the shaft away from known lava where possible.
- A normal CC:Tweaked turtle cannot load chunks. Use the included FTB Chunks map to claim and force-load every chunk containing the 5x5 shaft and horizontal tunnels. Server settings may restrict force-loading.
- Delete `.spiral-miner-state` only when the turtle is physically back at its original surface position and facing its original direction.

Configuration such as target Y, shaft footprint, room size, chunk radius, grid spacing, and fuel reserve is at the top of `miner.lua`.

## Grid coverage

Grid tunnels are one block wide, two blocks high, and spaced three blocks center-to-center. This leaves two block columns between neighboring tunnels: one is scanned from each side, so every block across the horizontal target layer is inspected without quarrying the entire 80x80 area. The rows are connected in a serpentine path, avoiding a separate trip back to the room for every shaft. Connected valuable veins are still mined in all six directions. The grid covers 25 chunks when valid surface X/Z coordinates are supplied; force-load all 25 before leaving the area.
