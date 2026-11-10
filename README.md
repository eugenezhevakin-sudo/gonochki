# APEX GRID Track Lab

**Public, independently installable Android prototype** for geometry testing in the APEX GRID Formula 1 project. Built in **Godot 4.4.1**, compatible with Android ARM64 and desktop testing. This repository is **NOT** a copy of the private production `F1` game.

## What you can test

- **32 circuit outlines**: the original 23 Formula Manager layouts (including Sepang, Malaysia), plus nine heritage/extra circuits sourced directly from Tomislav Bacinger's MIT-licensed f1-circuits GeoJSON, including Jeddah, Portimão, Estoril, Istanbul Park, Paul Ricard, Magny-Cours, Hockenheimring, Nürburgring GP and Sochi. Each includes a provisional pit path and illustrative garages/stands.
- **2D overview** to compare the centerline, entry/exit and locations.
- **3D prototype** with procedurally generated 13 m asphalt ribbon and 6 m pit ribbon, collisions, indicative buildings, and a simple terrain plane.
- **Driveable low-poly open-wheel car** with continuous Android throttle, braking and steering buttons (W/A/S/D or arrow keys on PC), adjustable steering grip, basic off-road handling, visible wheel steering, 3 switchable cameras, lap progress, lap timer and best-lap HUD.
- Choose any circuit from the dropdown. Tracks load individually; there is no large 32-track race scene to keep in Android memory.

## Important limits

This is a **track laboratory**, not the latest full release of APEX GRID. Production 22-car AI, accurate racing physics, qualifying, timing, saves and championship logic are **not included**. The tracks are **not race certified**: flat terrain, approximate width, unverified pit joints, no complete barriers or runoff, and Suzuka's raised crossing is an unmeasured visual approximation. **All nine newly added pit paths and garage/stand footprints are synthetic placeholders**, offset near the timing line; they do not represent surveyed pit lanes or official track architecture. You can test map rendering and approximate surface continuity, not realistic pit entry. The experimental car is not the production Formula 1 car.

A low-priority collision ground now allows off-track recovery; visual red/white kerbs and the start/finish line make road direction easier to read. Press **СБРОС** to respawn and restart timing if the car gets stuck. Errors are useful here: the purpose is to expose missing road geometry before promotion to the private game.

See [docs/ADDED_CIRCUITS.md](docs/ADDED_CIRCUITS.md) for all nine new circuits, source identifiers, and important limitations. Sepang was already present in the original 23, so it has not been duplicated.

For controls, camera modes, handling assumptions and caveats see **[Driving Test v0.3](docs/DRIVING_TEST.md)**. Three representative tracks are physics-driven in automated tests, but actual multi-touch and FPS still need on-device verification.

## Android APK

Open **Actions → Build Track Lab Android APK → most recent successful run**, then download artifact **APEX-GRID-Track-Lab-Android-APK**. The workflow performs atlas/geometry/UI checks and builds a debug-signed Android ARM64 APK. It also publishes a separate prerelease with a directly downloadable APK when permissions permit.

Each GitHub Actions run creates a new debug signing key. Therefore, the experimental driving build has a **new package ID** to avoid breaking installation of earlier Track Lab releases. Later upgrades to this build might require uninstalling it first. Install it alongside the main game: Android package is `com.apexgrid.tracklab.drive32`, distinct from the private game.

**No passwords, SSH keys, GitHub tokens, production keystores or production assets are required.** CI uses a generated debug signing key and official Godot 4.4.1 export templates.

## Local run

Install [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/). Clone this repo, open `project.godot` in Godot, wait for import, and press **F6/F5**.

Headless tests:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/atlas_smoke.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/driving_smoke.gd
```

## Copyright and provenance

Original APEX GRID Track Lab code: **Copyright © 2026 APEX GRID contributors. All rights reserved**. No license is granted for reuse of that code; GitHub's applicable terms still govern viewing and forking on the platform.

**Map data have different licenses**: outlines derive from [Tomislav Bacinger's f1-circuits](https://github.com/bacinger/f1-circuits) under MIT; pit/building data include [OpenStreetMap](https://www.openstreetmap.org/copyright) material under ODbL and independent approximations. These third-party rights are not changed by the code's all-rights-reserved status. See [docs/SOURCES.md](docs/SOURCES.md) and [docs/THIRD_PARTY_LICENSES.md](docs/THIRD_PARTY_LICENSES.md). Source maps and reference URLs should not be read as exact surveys.

Develop on this public prototype; port **reviewed and validated** changes back to the separate private F1 repository.
