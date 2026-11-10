# Nine newly added circuits · APEX GRID Track Lab 0.2.0

The 23 existing circuits, including **Malaysia (Sepang International
Circuit)**, are preserved. These nine extra F1 venues are **prototype**
centreline-based drafts, NOT approved drivable race environments.

| Area | Circuit in Track Lab | GeoJSON source ID | Source lap length |
| --- | --- | --- | ---: |
| Saudi Arabia | Jeddah Corniche Circuit | `sa-2021` | 6,175 m |
| Portugal | Algarve International Circuit (Portimão) | `pt-2008` | 4,653 m |
| Portugal | Estoril | `pt-1972` | 4,349 m |
| Turkey | Istanbul Park | `tr-2005` | 5,338 m |
| France | Circuit Paul Ricard | `fr-1969` | 5,842 m |
| France | Circuit de Nevers Magny-Cours | `fr-1960` | 4,412 m |
| Germany | Hockenheimring | `de-1932` | 4,574 m |
| Germany | Nürburgring **GP layout**, not Nordschleife | `de-1927` | 5,148 m |
| Russia | Sochi Autodrom | `ru-2014` | 5,848 m |

**Source:** Tomislav Bacinger, [f1-circuits GeoJSON](https://github.com/bacinger/f1-circuits/blob/master/f1-circuits.geojson), MIT licence. The source coordinates are projected to a local plane and rescaled to the published lap length. They are not independently surveyed.

**Unverified geometry:** for all nine additions, pit lane is a **smooth offset placeholder along the lap timing line**; garages/stands are **illustrative boxes**. They are not genuine OSM/FIA pit points or surveyed building footprints. Road banking, elevation, barriers, curbs and runoff are not mapped. The two road meshes have basic static collisions, but safe pit transitions, apex positions, crossings and race physics **are not tested**.

**Testing:** choose any track in the Android dropdown, inspect 2D and 3D, then use the simple car to identify issues and record Android FPS. Do not infer that a headless 3D smoke test proves all 32 tracks playable for full races.

Some of these are historical Grand Prix circuits; inclusion does not imply hosting a Grand Prix in 2026.
