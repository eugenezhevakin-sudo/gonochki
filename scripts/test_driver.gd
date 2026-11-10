extends CharacterBody3D
## Independently authored low-poly racing prototype for the public Track Lab.
## This is a kinematic arcade/sim-lite controller, NOT private APEX GRID physics.
const MAX_SPEED_MPS := 88.0
const REVERSE_SPEED_MPS := 7.0
const WHEELBASE_M := 3.55
const MAX_LATERAL_ACCEL := 32.0
const TYRE_RADIUS := 0.36

var throttle := false
var braking := false
var left_turn := false
var right_turn := false
var speed_mps := 0.0
var steering_axis := 0.0
var respawn_transform := Transform3D.IDENTITY
var track_surface := "НЕИЗВЕСТНО"
var last_on_track := false
var automatic_gear := 1

var _wheels: Array[Node3D] = []
var _front_pivots: Array[Node3D] = []
var _racing_paint: StandardMaterial3D
var _contact_ticks := 0

func _material(color_code: String) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color_code)
    material.metallic = 0.15
    material.roughness = 0.68
    return material

func _piece(label: String, size_m: Vector3, at: Vector3,
        color: StandardMaterial3D, parent: Node3D) -> MeshInstance3D:
    var object := MeshInstance3D.new()
    object.name = label
    var mesh := BoxMesh.new()
    mesh.size = size_m
    mesh.material = color
    object.mesh = mesh
    object.position = at
    parent.add_child(object)
    return object

func _wheel(label: String, x: float, z: float,
        tyre_material: StandardMaterial3D, hub_material: StandardMaterial3D) -> void:
    var pivot := Node3D.new()
    pivot.name = label
    pivot.position = Vector3(x, -0.03, z)
    add_child(pivot)
    var wheel := MeshInstance3D.new()
    wheel.name = "Tyre"
    var rubber := CylinderMesh.new()
    rubber.top_radius = TYRE_RADIUS
    rubber.bottom_radius = TYRE_RADIUS
    rubber.height = 0.32
    rubber.radial_segments = 12
    rubber.material = tyre_material
    wheel.mesh = rubber
    wheel.rotation.z = PI * 0.5
    pivot.add_child(wheel)
    var hub := MeshInstance3D.new()
    hub.name = "Hub"
    var inner := CylinderMesh.new()
    inner.top_radius = 0.16
    inner.bottom_radius = 0.16
    inner.height = 0.34
    inner.radial_segments = 10
    inner.material = hub_material
    hub.mesh = inner
    hub.rotation.z = PI * 0.5
    pivot.add_child(hub)
    _wheels.append(pivot)
    if z < 0.0:
        _front_pivots.append(pivot)

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 0.46
    floor_max_angle = deg_to_rad(50)
    _racing_paint = _material("d43d41")
    var dark := _material("17202b")
    var rubber := _material("101318")
    var accent := _material("f0b54d")
    var steel := _material("8799a8")
    _piece("Monocoque", Vector3(1.36, 0.39, 3.55), Vector3(0, 0.07, 0),
        _racing_paint, self)
    _piece("FrontNose", Vector3(0.53, 0.20, 1.85), Vector3(0, -0.02, -2.33),
        _racing_paint, self)
    _piece("FrontWing", Vector3(2.65, 0.12, 0.53), Vector3(0, -0.15, -3.08),
        dark, self)
    _piece("RearWing", Vector3(2.27, 0.16, 0.53), Vector3(0, 0.69, 1.78),
        dark, self)
    _piece("EngineCover", Vector3(0.87, 0.55, 1.15), Vector3(0, 0.38, 0.84),
        _racing_paint, self)
    _piece("AirIntake", Vector3(0.54, 0.37, 0.47), Vector3(0, 0.77, 0.32),
        dark, self)
    _piece("Cockpit", Vector3(0.77, 0.12, 1.10), Vector3(0, 0.34, -0.43),
        dark, self)
    _piece("PilotHelmet", Vector3(0.39, 0.37, 0.38), Vector3(0, 0.59, -0.48),
        accent, self)
    _piece("HaloCrossbar", Vector3(0.10, 0.10, 1.13), Vector3(0, 0.82, -0.65),
        dark, self)
    _piece("RearDiffuser", Vector3(1.70, 0.14, 0.75), Vector3(0, -0.14, 1.56),
        dark, self)
    _piece("FrontDetail", Vector3(0.40, 0.07, 0.54), Vector3(0, 0.10, -2.67),
        accent, self)
    for z in [-1.35, 1.20]:
        for x in [-1.03, 1.03]:
            _wheel("FrontWheel" if z < 0.0 else "RearWheel",
                x, z, rubber, steel)
    var collision := CollisionShape3D.new()
    collision.name = "CarCollision"
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.56, 0.70, 3.8)
    collision.shape = shape
    add_child(collision)
    _sample_road()

func reset_inputs() -> void:
    throttle = false
    braking = false
    left_turn = false
    right_turn = false

func respawn() -> void:
    reset_inputs()
    global_transform = respawn_transform
    velocity = Vector3.ZERO
    speed_mps = 0.0
    steering_axis = 0.0
    _contact_ticks = 0
    automatic_gear = 1

func _sample_road() -> void:
    var state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var from: Vector3 = global_position + Vector3.UP * 0.8
    var to: Vector3 = global_position + Vector3.DOWN * 2.0
    var query := PhysicsRayQueryParameters3D.create(from, to, 1)
    var hit: Dictionary = state.intersect_ray(query)
    track_surface = "ВНЕ ТРАССЫ"
    last_on_track = false
    if hit.is_empty():
        return
    var body: Object = hit.get("collider")
    if body is Node:
        var name_of_surface: String = str((body as Node).name)
        if name_of_surface == "TrackRoad":
            last_on_track = true
            track_surface = "АСФАЛЬТ"
        elif name_of_surface == "PitRoad":
            last_on_track = true
            track_surface = "ПИТ"
        elif name_of_surface == "RunoffGround":
            track_surface = "ЗОНА ВЫЛЕТА"

func _physics_process(delta: float) -> void:
    _sample_road()
    var go: bool = throttle or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    var stop: bool = braking or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    var steering_request: float = float(int(left_turn or Input.is_key_pressed(KEY_A)
        or Input.is_key_pressed(KEY_LEFT)) - int(right_turn or Input.is_key_pressed(KEY_D)
        or Input.is_key_pressed(KEY_RIGHT)))
    steering_axis = move_toward(steering_axis, steering_request, 5.4 * delta)
    var v: float = absf(speed_mps)
    var ground_factor: float = 1.0 if last_on_track else 0.48
    if go and not stop:
        var acceleration: float = (15.3 - 9.0 * clampf(v / MAX_SPEED_MPS, 0.0, 1.0))
        speed_mps += acceleration * ground_factor * delta
    elif stop and not go:
        if speed_mps > 0.0:
            speed_mps = maxf(0.0, speed_mps - 27.0 * ground_factor * delta)
        else:
            speed_mps = maxf(-REVERSE_SPEED_MPS, speed_mps - 4.0 * delta)
    else:
        speed_mps = move_toward(speed_mps, 0.0,
            (1.8 + 0.0010 * v * v) * delta)
    if go and stop:
        speed_mps = move_toward(speed_mps, 0.0, 25.0 * delta)
    speed_mps = clampf(speed_mps, -REVERSE_SPEED_MPS, MAX_SPEED_MPS)
    var speed_abs: float = absf(speed_mps)
    var steering_angle: float = lerpf(0.46, 0.082,
        clampf(speed_abs / MAX_SPEED_MPS, 0.0, 1.0))
    var turn_rate: float = speed_mps / WHEELBASE_M * tan(steering_axis * steering_angle)
    var turn_limit: float = (MAX_LATERAL_ACCEL * ground_factor) / maxf(speed_abs, 3.0)
    rotation.y += clampf(turn_rate, -turn_limit, turn_limit) * delta
    var forward: Vector3 = -global_transform.basis.z
    var target_motion: Vector3 = forward * speed_mps
    var current_motion := Vector3(velocity.x, 0.0, velocity.z)
    var traction: float = 9.0 if last_on_track else 2.1
    var plane_motion: Vector3 = current_motion.lerp(target_motion, clampf(traction * delta, 0.0, 1.0))
    velocity.x = plane_motion.x
    velocity.z = plane_motion.z
    velocity.y = -2.0 if is_on_floor() else velocity.y - 21.0 * delta
    move_and_slide()
    if is_on_wall():
        speed_mps *= 0.77
    if global_position.y < -15.0:
        respawn()
    automatic_gear = 1 + int(clampf(speed_abs / 12.0, 0.0, 6.0))
    if speed_mps < -0.2:
        automatic_gear = -1
    for wheel in _wheels:
        wheel.rotation.x -= speed_mps * delta / TYRE_RADIUS
    for pivot in _front_pivots:
        pivot.rotation.y = steering_axis * steering_angle

func get_speed_kmh() -> float:
    return absf(speed_mps) * 3.6
