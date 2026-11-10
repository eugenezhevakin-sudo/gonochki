extends RefCounted
## Independent lap/sector timing for geometrical Track Lab tests.
## Crossing order is required. It is NOT official racing timing.
var laps := 0
var last_lap_s := -1.0
var best_lap_s := -1.0
var current_lap_s := 0.0
var fraction := 0.0
var lap_valid := true
var sector := 1

var _path := PackedVector2Array()
var _distance_at_vertex := PackedFloat32Array()
var _total_length := 0.0
var _previous_fraction := 0.0
var _sector_gate := 0
var _lap_start_ms := 0

func configure(path: PackedVector2Array) -> void:
    _path = path.duplicate()
    _distance_at_vertex = PackedFloat32Array()
    _total_length = 0.0
    for i in range(_path.size()):
        _distance_at_vertex.append(_total_length)
        _total_length += _path[i].distance_to(_path[(i + 1) % _path.size()])
    reset_run()

func reset_run() -> void:
    laps = 0
    last_lap_s = -1.0
    best_lap_s = -1.0
    current_lap_s = 0.0
    fraction = 0.0
    lap_valid = true
    sector = 1
    _sector_gate = 0
    _previous_fraction = 0.0
    _lap_start_ms = Time.get_ticks_msec()

func _nearest_fraction(point: Vector2) -> float:
    if _path.size() < 3 or _total_length < 1.0:
        return 0.0
    var nearest_d2 := INF
    var best_distance := 0.0
    for i in range(_path.size()):
        var p: Vector2 = _path[i]
        var q: Vector2 = _path[(i + 1) % _path.size()]
        var edge: Vector2 = q - p
        var len_sq: float = edge.length_squared()
        if len_sq < 0.000001:
            continue
        var t: float = clampf((point - p).dot(edge) / len_sq, 0.0, 1.0)
        var projection: Vector2 = p + edge * t
        var d2: float = point.distance_squared_to(projection)
        if d2 < nearest_d2:
            nearest_d2 = d2
            best_distance = _distance_at_vertex[i] + sqrt(len_sq) * t
    return fposmod(best_distance / _total_length, 1.0)

func update_position(world_position: Vector3, on_road: bool) -> void:
    fraction = _nearest_fraction(Vector2(world_position.x, world_position.z))
    current_lap_s = float(Time.get_ticks_msec() - _lap_start_ms) * 0.001
    if not on_road:
        lap_valid = false
    if _sector_gate == 0 and fraction >= 0.20 and fraction < 0.43:
        _sector_gate = 1
    elif _sector_gate == 1 and fraction >= 0.45 and fraction < 0.70:
        _sector_gate = 2
    elif _sector_gate == 2 and fraction >= 0.72 and fraction < 0.94:
        _sector_gate = 3
    sector = 1 if fraction < 0.333 else (2 if fraction < 0.667 else 3)
    var crossing: bool = _previous_fraction > 0.89 and fraction < 0.12
    if crossing:
        if _sector_gate == 3 and lap_valid and current_lap_s >= 25.0:
            laps += 1
            last_lap_s = current_lap_s
            if best_lap_s < 0.0 or last_lap_s < best_lap_s:
                best_lap_s = last_lap_s
        _lap_start_ms = Time.get_ticks_msec()
        current_lap_s = 0.0
        lap_valid = true
        _sector_gate = 0
    _previous_fraction = fraction

static func format_time(seconds: float) -> String:
    if seconds < 0.0:
        return "--:--.---"
    var mins: int = int(floor(seconds / 60.0))
    var secs: float = fposmod(seconds, 60.0)
    return "%02d:%06.3f" % [mins, secs]
