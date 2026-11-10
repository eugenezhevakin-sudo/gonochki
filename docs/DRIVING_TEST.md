# Track Lab v0.3 · driving-test mode

The **32 circuit atlases** from version 0.2 remain intact. A new button
**ЗАЕЗД** activates a low-polygon open-wheel test car on the selected
3D circuit. This is intended for interactive road-surface testing on
Android and desktop, not as a replacement for the private APEX GRID
physics simulation.

## Controls

| Android control | PC equivalent | Function |
|---|---|---|
| ГАЗ | W / Up | Accelerate |
| ТОРМОЗ | S / Down | Brake; slowly reverse when stopped |
| ◀ РУЛЬ | A / Left | Steer left |
| РУЛЬ ▶ | D / Right | Steer right |
| КАМЕРА | On-screen button | Toggle chase / cockpit / overhead |
| СБРОС | On-screen button | Return to start; reset timer |

Touch buttons use button-down and button-up state, rather than
single clicks, so press continuously to drive. Simultaneous multi-touch
must still be validated on a real phone.

## Simplified vehicle physics

- Independent open-wheel, four-wheel mesh with front wheel visual steering;
- Forward acceleration, speed-dependent steering, braking, basic tyre
  traction / inertia, aero-like drag, and reduced grip off the road;
- ~317 km/h theoretical top speed on a clear straight, not FIA-calibrated;
- No private AI, tyre model, engine, gearbox or suspension code copied;
- Camera modes follow the car rather than zooming from the atlas overview.

The drivable 13 m-wide ribbons and prototype pit meshes now stand above
a **non-surveyed collision ground**, so the car can usually recover after
running wide rather than always falling into the void. Red-white
kerb-like decorations mark approximate road edges, not actual FIA kerbs.

## Timing

The experimental lap tracker estimates distance travelled from the closest
centerline segment. It counts a lap only if it passes all three gates in
order, crosses the start-finish line and remains on-road, with a minimum
25 second lap. This is **not** official timing. Self-crossing tracks such
as Suzuka and nearby-parallel lanes can confuse proximity matching.

## What tests cannot prove

CI tests verify that steering controls, camera modes, braking,
respawn and actual movement function in Godot headless on a sample of
tracks. They do **not** prove 32 full clean laps, realistic pit access,
barrier integrity, touch multi-finger behavior, or stable Android
performance. These still require device and full-lap testing before
promoting the track to the private racing game.
