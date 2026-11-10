#!/usr/bin/env python3
"""Validate public 32-circuit atlas before starting a costly Android export."""
import json
import math
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "assets/tracks/atlas.json"
data = json.loads(path.read_text(encoding="utf-8"))
assert data["schema_version"] == 1
assert data["track_count"] == len(data["tracks"]) == 32
EXPECTED_NEW = ["jeddah_gp","portimao_gp","estoril_gp","istanbul_park_gp","paul_ricard_gp","magny_cours_gp","hockenheimring_gp","nurburgring_gp","sochi_autodrom_gp"]
ids = {t["track_id"] for t in data["tracks"]}
assert set(EXPECTED_NEW).issubset(ids)
assert "sepang_gp" in ids, "existing Malaysia circuit must be retained"
assert len(ids) == data["track_count"], "duplicate track IDs"
for track in data["tracks"]:
    if track["track_id"] in EXPECTED_NEW:
        assert track["pit"].get("approximate") is True, track["track_id"]
        assert track["source_id"] and track["centreline_source"].startswith("Tomislav"), track["track_id"]
seen = set()
count_main = count_pit = 0
for item in data["tracks"]:
    tid = item["track_id"]
    assert tid not in seen, tid
    seen.add(tid)
    center = item["track"]
    pit = item["pit"]["points"]
    assert len(center) >= 50 and len(pit) >= 5, tid
    assert item["reference"].startswith("https://"), tid
    factor = float(item["map_unit_to_m"])
    assert math.isfinite(factor) and factor > 0, tid
    for px, py in center + pit:
        assert math.isfinite(px) and math.isfinite(py), tid
    meters = sum(math.dist(center[i], center[(i+1) % len(center)]) for i in range(len(center))) * factor
    assert abs(meters - item["length_m"]) < 0.05, (tid, meters)
    count_main += len(center)
    count_pit += len(pit)
print(f"ATLAS_STATIC_PASS tracks={len(seen)} main_points={count_main} pit_points={count_pit}")
