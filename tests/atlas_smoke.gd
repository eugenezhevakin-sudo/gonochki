extends SceneTree
const Atlas = preload("res://scripts/atlas.gd")
const Geometry = preload("res://scripts/track_geometry.gd")
var failures := 0

func _expect(ok: bool, label: String) -> void:
    if ok:
        print("ATLAS PASS: ", label)
    else:
        failures += 1
        push_error("ATLAS FAIL: " + label)

func _initialize() -> void:
    call_deferred("_execute")

func _execute() -> void:
    var data: Dictionary = Atlas.load_data()
    var list: Array = Atlas.records()
    _expect(int(data.get("schema_version", 0)) == 1, "atlas schema version")
    _expect(list.size() == 23 and int(data.get("track_count", 0)) == 23, "all 23 circuits")
    var seen := {}
    for raw in list:
        var item: Dictionary = raw
        var id: String = str(item.get("track_id", ""))
        _expect(id != "" and not seen.has(id), "unique id " + id)
        seen[id] = true
        var centerline: PackedVector2Array = Atlas.points_m(item)
        var pitline: PackedVector2Array = Atlas.points_m(item, "pit")
        _expect(centerline.size() >= 50, id + " main centerline")
        _expect(pitline.size() >= 5, id + " pit centerline")
        _expect(absf(Atlas.lap_length(centerline) - float(item.get("length_m", 0))) < 0.05,
            id + " length scale within 5 cm")
        _expect(str(item.get("reference", "")).begins_with("https://"),
            id + " retains source reference")
        var stage: Node3D = Geometry.new()
        root.add_child(stage)
        var built: bool = bool(stage.call("generate", id))
        _expect(built, id + " 3D geometry generated")
        var road: StaticBody3D = stage.get_node_or_null("TrackRoad")
        var pits: StaticBody3D = stage.get_node_or_null("PitRoad")
        _expect(road != null and pits != null, id + " road bodies exist")
        if road != null and pits != null:
            var road_shape: CollisionShape3D = road.get_node_or_null("PhysicalSurface")
            var pit_shape: CollisionShape3D = pits.get_node_or_null("PhysicalSurface")
            _expect(road_shape != null and road_shape.shape != null,
                id + " asphalt collision is solid")
            _expect(pit_shape != null and pit_shape.shape != null,
                id + " pit collision is solid")
        _expect(bool(stage.get_meta("unverified_track_geometry", false)),
            id + " remains explicitly marked unverified")
        stage.queue_free()
        await process_frame
    print("ATLAS SUMMARY tracks=", list.size(), " failures=", failures)
    quit(1 if failures else 0)
