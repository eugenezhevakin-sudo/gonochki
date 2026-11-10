# Circuit atlas origin and restrictions

The geometry data in `assets/tracks/atlas.json` include an initial set of 23 circuits extracted from our Formula Manager's `web/circuit-data.js` and nine later geodata-derived tracks from the publicly available MIT-licensed Bacinger GeoJSON in a **standalone test data file**. No private Git history, original private race scripts, signing keys or commercially sensitive physics/AI code have been copied.

- Centreline geodata: [Tomislav Bacinger / f1-circuits](https://github.com/bacinger/f1-circuits) (MIT; copyright 2019–2025 Tomislav Bacinger).
- Pit lane, garage and structure layout: geographical outline sources from [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright) under [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/), together with approximations. Derivative database obligations can apply: do not relicense this geographical source material as proprietary.
- FIA competition notes are **reference URLs only**. No FIA PDF, logo, protected livery artwork or official photo is included.
- Width estimates (13 m main, 6 m pits), ground, buildings, and bridging are visual/prototyping approximations.
- Coordinates were normalized for schematic display and converted to metres using each track's published lap length. This does not establish legally surveyed track coordinates.
- Source timeline follows the Formula Manager atlas, **not** a promise of the current official F1 calendar. Sepang and Madrid reflect that atlas selection.
- Suzuka centreline crosses itself; the 3D viewer introduces a candidate bridge at the source's approximate crossing phase. Ground clearance and gradients are unverified.

The code and the map data have **different rights holders**. See THIRD_PARTY_LICENSES.md and respect all source conditions.
## Nine extra circuits (November 2026)

For Jeddah, Portimão, Estoril, Istanbul Park, Paul Ricard, Magny-Cours,
Hockenheimring, Nürburgring GP and Sochi, the closed source centrelines were
read from `bacinger/f1-circuits` `f1-circuits.geojson` (master, feature IDs
listed in `docs/ADDED_CIRCUITS.md`), projected from WGS84 longitude/latitude
to a local equirectangular 2D plane, and scaled to the source lap length.
These nine routes are based on source coordinates, **not hand-invented loops**.

**Source caveat:** the nine added pit paths are fabricated *test placeholders*
using a smooth ±19.5 m lateral displacement of the main centreline over the
0.915–1.08 lap interval around the recorded start line. These are NOT mapped
from OSM, FIA diagrams or other surveyed pit-lane data. Their apparent merge
positions, orientation, service boxes and grandstands are all provisional and
must be replaced with verified geometry before use in the racing game.

The course named **Nürburgring GP** is the short modern GP circuit, **not the
Nordschleife**. The French / Portuguese alternatives and Sochi are historical
F1 venues; this atlas is not an official contemporary season calendar.
