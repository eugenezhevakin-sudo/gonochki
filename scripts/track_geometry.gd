extends Node3D
## Physical asphalt/pit ribbon for VISUAL REVIEW and minimal proxy-car tests.
## No real banking, tyre friction, runoff or certified pit/barrier geometry.
const Atlas = preload("res://scripts/atlas.gd")
const ROAD_WIDTH := 13.0
const PIT_WIDTH := 6.0

var camera: Camera3D
var track_path := PackedVector2Array()
var record: Dictionary = {}

func _material(color_hex: String) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color_hex)
    material.roughness = 0.96
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _track_height(fraction: float) -> float:
    var bridge: Array = record.get("bridge", [])
    if bridge.size() != 3:
        return 0.0
    var start_fraction: float = float(bridge[0])
    var end_fraction: float = float(bridge[1])
    if fraction <= start_fraction or fraction >= end_fraction:
        return 0.0
    var t: float = (fraction - start_fraction) / (end_fraction - start_fraction)
    return sin(t * PI) * sin(t * PI) * float(bridge[2]) * float(record.get("map_unit_to_m", 1.0))

func _ribbon(path: PackedVector2Array, width: float,
        closed: bool, height_m: float, asphalt: StandardMaterial3D) -> ArrayMesh:
    var n: int = path.size()
    if n < 2:
        return null
    var left := PackedVector3Array()
    var right := PackedVector3Array()
    var length: float = Atlas.lap_length(path) if closed else 0.0
    if not closed:
        for i in range(n - 1):
            length += path[i].distance_to(path[i + 1])
    var distance_m: float = 0.0
    for i in range(n):
        var before: Vector2 = path[(i - 1 + n) % n] if closed else path[maxi(0, i - 1)]
        var after: Vector2 = path[(i + 1) % n] if closed else path[mini(n - 1, i + 1)]
        var direction: Vector2 = (after - before).normalized()
        if direction.length_squared() < 0.00001:
            direction = Vector2.RIGHT
        var normal := Vector2(-direction.y, direction.x)
        var offset: Vector2 = normal * (width * 0.5)
        var y: float = height_m + (_track_height(distance_m / maxf(length, 1.0)) if closed else 0.0)
        var p: Vector2 = path[i]
        left.append(Vector3(p.x + offset.x, y, p.y + offset.y))
        right.append(Vector3(p.x - offset.x, y, p.y - offset.y))
        if i + 1 < n:
            distance_m += path[i].distance_to(path[i + 1])
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_material(asphalt)
    var segments: int = n if closed else n - 1
    for i in range(segments):
        var j: int = (i + 1) % n
        st.add_vertex(left[i])
        st.add_vertex(left[j])
        st.add_vertex(right[j])
        st.add_vertex(left[i])
        st.add_vertex(right[j])
        st.add_vertex(right[i])
    st.generate_normals()
    return st.commit()

func _road(parent: Node3D, label: String, mesh: ArrayMesh) -> void:
    if mesh == null:
        return
    var body := StaticBody3D.new()
    body.name = label
    body.collision_layer = 1
    body.collision_mask = 2
    parent.add_child(body)
    var appearance := MeshInstance3D.new()
    appearance.name = "Asphalt"
    appearance.mesh = mesh
    body.add_child(appearance)
    var solid := CollisionShape3D.new()
    solid.name = "PhysicalSurface"
    solid.shape = mesh.create_trimesh_shape()
    body.add_child(solid)

func _structures(parent: Node3D) -> void:
    var scale: float = float(record.get("map_unit_to_m", 1.0))
    for raw in record.get("structures", []):
        var structure: Dictionary = raw
        var corners: Array = structure.get("corners", [])
        if corners.size() != 4:
            continue
        var a := Vector2(float(corners[0][0]), float(corners[0][1])) * scale
        var b := Vector2(float(corners[1][0]), float(corners[1][1])) * scale
        var c := Vector2(float(corners[2][0]), float(corners[2][1])) * scale
        var d := Vector2(float(corners[3][0]), float(corners[3][1])) * scale
        var dir: Vector2 = (b - a).normalized()
        var side := Vector2(-dir.y, dir.x)
        var length_m: float = a.distance_to(b)
        var depth_m: float = absf((d - a).dot(side))
        if length_m < 2.0 or depth_m < 1.0:
            continue
        var kind: String = str(structure.get("kind", ""))
        var height_m: float = 5.5 if kind == "garage" else (11.0 if kind == "stand" else 15.0)
        var block := BoxMesh.new()
        block.size = Vector3(length_m, height_m, depth_m)
        block.material = _material("acc3c7" if kind == "garage" else ("5a7c86" if kind == "stand" else "57738a"))
        var obj := MeshInstance3D.new()
        obj.name = "Approximate_%s" % kind
        obj.mesh = block
        var center: Vector2 = (a + b + c + d) * 0.25
        obj.position = Vector3(center.x, height_m * 0.5, center.y)
        obj.basis = Basis(Vector3(dir.x, 0.0, dir.y), Vector3.UP, Vector3(side.x, 0.0, side.y))
        parent.add_child(obj)

func generate(track_id: String) -> bool:
    record = Atlas.get_track(track_id)
    if record.is_empty():
        push_error("Unknown circuit: " + track_id)
        return false
    track_path = Atlas.points_m(record)
    var pit: PackedVector2Array = Atlas.points_m(record, "pit")
    if track_path.size() < 20 or pit.size() < 5:
        push_error("Incomplete geometry: " + track_id)
        return false
    _road(self, "TrackRoad", _ribbon(track_path, ROAD_WIDTH, true, 0.12, _material("303b48")))
    _road(self, "PitRoad", _ribbon(pit, PIT_WIDTH, false, 0.17, _material("6b737c")))
    _structures(self)
    var bounds: Rect2 = Atlas.bounds(track_path)
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = bounds.size + Vector2(260.0, 260.0)
    ground_mesh.material = _material("b4a68d")
    var ground := MeshInstance3D.new()
    ground.name = "GroundVisualOnly"
    ground.mesh = ground_mesh
    ground.position = Vector3(bounds.get_center().x, -0.18, bounds.get_center().y)
    add_child(ground)
    camera = Camera3D.new()
    camera.name = "TrackCamera"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = maxf(bounds.size.x, bounds.size.y) * 1.24
    camera.position = Vector3(bounds.get_center().x,
        maxf(bounds.size.x, bounds.size.y) * 1.05, bounds.get_center().y)
    camera.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
    camera.current = true
    add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.name = "PreviewLighting"
    sun.rotation = Vector3(-0.85, -0.4, 0.3)
    sun.light_energy = 1.4
    add_child(sun)
    set_meta("unverified_track_geometry", true)
    set_meta("source_track", track_id)
    return true

func start_transform() -> Transform3D:
    if track_path.size() < 2:
        return Transform3D.IDENTITY
    var p: Vector2 = track_path[0]
    var heading: Vector2 = (track_path[1] - track_path[0]).normalized()
    var rotation_y: float = atan2(-heading.x, -heading.y)
    return Transform3D(Basis(Vector3.UP, rotation_y), Vector3(p.x, 2.2, p.y))

func overview_camera() -> void:
    var bounds: Rect2 = Atlas.bounds(track_path)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = maxf(bounds.size.x, bounds.size.y) * 1.24
    camera.position = Vector3(bounds.get_center().x,
        maxf(bounds.size.x, bounds.size.y) * 1.05, bounds.get_center().y)
    camera.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
