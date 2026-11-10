extends RefCounted
## Read-only source atlas for the independent public geometry laboratory.
const PATH := "res://assets/tracks/atlas.json"
static var _cache: Dictionary = {}

static func load_data() -> Dictionary:
    if not _cache.is_empty():
        return _cache
    if not FileAccess.file_exists(PATH):
        push_error("Circuit atlas missing: " + PATH)
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if not parsed is Dictionary:
        push_error("Circuit atlas invalid JSON")
        return {}
    _cache = parsed
    return _cache

static func records() -> Array:
    var data: Dictionary = load_data()
    return data.get("tracks", [])

static func get_track(track_id: String) -> Dictionary:
    for item in records():
        var record: Dictionary = item
        if str(record.get("track_id", "")) == track_id:
            return record
    return {}

static func points_m(record: Dictionary, kind: String = "track") -> PackedVector2Array:
    var raw: Array = record.get("track", [])
    if kind == "pit":
        var pit: Dictionary = record.get("pit", {})
        raw = pit.get("points", [])
    var factor: float = float(record.get("map_unit_to_m", 0.0))
    var out := PackedVector2Array()
    if factor <= 0.0:
        return out
    for pair in raw:
        if not pair is Array or pair.size() != 2:
            return PackedVector2Array()
        out.append(Vector2(float(pair[0]), float(pair[1])) * factor)
    return out

static func lap_length(points: PackedVector2Array) -> float:
    if points.size() < 3:
        return 0.0
    var total := 0.0
    for i in range(points.size()):
        total += points[i].distance_to(points[(i + 1) % points.size()])
    return total

static func bounds(points: PackedVector2Array) -> Rect2:
    if points.is_empty():
        return Rect2()
    var out := Rect2(points[0], Vector2.ZERO)
    for point in points:
        out = out.expand(point)
    return out
