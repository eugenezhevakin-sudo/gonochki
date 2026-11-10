extends CharacterBody3D
## Simplified drivable shape for collision/road-continuity testing only.
## Does NOT reuse the private APEX GRID tyre, suspension, AI or F1 physics.
var throttle := false
var braking := false
var left_turn := false
var right_turn := false
var speed_mps := 0.0
var respawn_transform := Transform3D.IDENTITY

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 0.85
    var body := MeshInstance3D.new()
    body.name = "TestCarBody"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.9, 0.5, 4.2)
    var paint := StandardMaterial3D.new()
    paint.albedo_color = Color("d6504d")
    mesh.material = paint
    body.mesh = mesh
    body.position.y = 0.15
    add_child(body)
    var nose := MeshInstance3D.new()
    var marker := BoxMesh.new()
    marker.size = Vector3(1.3, 0.15, 0.65)
    var marker_material := StandardMaterial3D.new()
    marker_material.albedo_color = Color("f6e2a8")
    marker.material = marker_material
    nose.mesh = marker
    nose.position = Vector3(0.0, 0.4, -1.6)
    add_child(nose)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.8, 0.8, 4.0)
    collider.shape = shape
    add_child(collider)

func respawn() -> void:
    global_transform = respawn_transform
    velocity = Vector3.ZERO
    speed_mps = 0.0

func _physics_process(delta: float) -> void:
    var forward_input: bool = throttle or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    var brake_input: bool = braking or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    var turn_left: bool = left_turn or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
    var turn_right: bool = right_turn or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
    var target_speed := 0.0
    if forward_input:
        target_speed = 29.0
    elif brake_input:
        target_speed = -6.0 if speed_mps <= 0.0 else 0.0
    var change: float = 16.0 if (forward_input or brake_input) else 9.0
    speed_mps = move_toward(speed_mps, target_speed, change * delta)
    var steer: float = float(int(turn_left) - int(turn_right))
    if absf(speed_mps) > 0.6:
        rotation.y += steer * minf(0.9, absf(speed_mps) * 0.045) * delta * signf(speed_mps)
    var heading: Vector3 = -global_transform.basis.z
    velocity.x = heading.x * speed_mps
    velocity.z = heading.z * speed_mps
    velocity.y = -4.5 if is_on_floor() else velocity.y - 24.0 * delta
    move_and_slide()
    if global_position.y < -18.0:
        respawn()
