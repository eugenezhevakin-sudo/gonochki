extends Control
const Atlas = preload("res://scripts/atlas.gd")
var record: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func set_track(track_id: String) -> void:
    record = Atlas.get_track(track_id)
    queue_redraw()

func _as_vector(pair: Array) -> Vector2:
    return Vector2(float(pair[0]), float(pair[1]))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("0b2433"))
    if record.is_empty() or size.x < 160 or size.y < 160:
        return
    var raw: Array = record.get("track", [])
    var pit_info: Dictionary = record.get("pit", {})
    var pit: Array = pit_info.get("points", [])
    if raw.size() < 3:
        return
    var bounds := Rect2(_as_vector(raw[0]), Vector2.ZERO)
    for pair in raw:
        bounds = bounds.expand(_as_vector(pair))
    for pair in pit:
        bounds = bounds.expand(_as_vector(pair))
    for structure in record.get("structures", []):
        for corner in structure.get("corners", []):
            bounds = bounds.expand(_as_vector(corner))
    var factor: float = minf((size.x - 70.0) / maxf(bounds.size.x, 1.0),
        (size.y - 90.0) / maxf(bounds.size.y, 1.0))
    var origin: Vector2 = (size - bounds.size * factor) * 0.5 - bounds.position * factor
    var main := PackedVector2Array()
    var pitline := PackedVector2Array()
    for pair in raw:
        main.append(origin + _as_vector(pair) * factor)
    for pair in pit:
        pitline.append(origin + _as_vector(pair) * factor)
    for x in range(0, int(size.x), 42):
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color("193b4b"), 1.0)
    for y in range(0, int(size.y), 42):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color("193b4b"), 1.0)
    for raw_structure in record.get("structures", []):
        var structure: Dictionary = raw_structure
        var polygon := PackedVector2Array()
        for corner in structure.get("corners", []):
            polygon.append(origin + _as_vector(corner) * factor)
        if polygon.size() >= 3:
            var kind: String = str(structure.get("kind", ""))
            draw_colored_polygon(polygon, Color("ba9a66") if kind == "garage" else Color("638897"))
    var closed: PackedVector2Array = main.duplicate()
    closed.append(main[0])
    draw_polyline(closed, Color("031620"), 16.0, true)
    draw_polyline(closed, Color("e5ecf2"), 9.0, true)
    draw_polyline(closed, Color("4fdbba"), 4.0, true)
    if pitline.size() >= 2:
        draw_polyline(pitline, Color("142a33"), 8.0, true)
        draw_polyline(pitline, Color("ffbd75"), 3.0, true)
    var heading: Vector2 = (main[1] - main[0]).normalized()
    var normal: Vector2 = Vector2(-heading.y, heading.x)
    draw_line(main[0] - normal * 14.0, main[0] + normal * 14.0, Color.WHITE, 4.0, true)
    draw_circle(main[0], 5.0, Color("ff746d"))
    draw_string(ThemeDB.fallback_font, Vector2(18, 32),
        "%s · %.3f км" % [str(record.get("name", "")), float(record.get("length_m", 0)) / 1000.0],
        HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("f1f7fa"))
    draw_string(ThemeDB.fallback_font, Vector2(18, size.y - 17.0),
        "ЗЕЛЁНЫЙ: ТРАССА   ЖЁЛТЫЙ: ПИТ-ЛЕЙН   |   СХЕМА НЕ ПРОВЕРЕНА",
        HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("e5f6f7"))
