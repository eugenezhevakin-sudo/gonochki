extends SceneTree
## Acceptance gate for actual forward movement, braking, steering and cameras.
const MainScene = preload("res://scenes/main.tscn")
var failures := 0

func _expect(ok: bool, label: String) -> void:
    if ok:
        print("DRIVING PASS: ", label)
    else:
        failures += 1
        push_error("DRIVING FAIL: " + label)

func _initialize() -> void:
    call_deferred("_execute")

func _execute() -> void:
    var game: Control = MainScene.instantiate()
    root.add_child(game)
    await process_frame
    for circuit in ["silverstone_gp", "jeddah_gp", "sochi_autodrom_gp"]:
        game.call("select_track", circuit)
        game.call("change_mode", "drive")
        await physics_frame
        await physics_frame
        var world: Node = game.get_node("Layout/View/Scene3D/WorldViewport/TrackWorld")
        var car: CharacterBody3D = world.get_node_or_null("PublicTestCar")
        var circuit_node: Node3D = world.get_node_or_null("SelectedCircuit")
        _expect(car != null and circuit_node != null, circuit + " car and world spawned")
        if car == null or circuit_node == null:
            continue
        var camera: Camera3D = circuit_node.get_node_or_null("TrackCamera")
        _expect(camera != null and camera.projection == Camera3D.PROJECTION_PERSPECTIVE,
            circuit + " perspective follow camera")
        var initial: Vector3 = car.global_position
        car.set("throttle", true)
        for frame in range(120):
            await physics_frame
        car.set("throttle", false)
        var achieved: float = float(car.call("get_speed_kmh"))
        var distance: float = Vector2(car.global_position.x,
            car.global_position.z).distance_to(Vector2(initial.x, initial.z))
        print("DRIVE PROBE ", circuit, " start=", initial, " finish=", car.global_position,
            " distance=", distance, " kmh=", achieved, " velocity=", car.velocity,
            " floor=", car.is_on_floor(), " wall=", car.is_on_wall(),
            " surface=", str(car.get("track_surface")))
        _expect(achieved > 25.0, circuit + " accelerates under real physics ticks")
        _expect(distance > 8.0, circuit + " moves along a road in 3D")
        car.set("braking", true)
        for frame in range(75):
            await physics_frame
        car.set("braking", false)
        _expect(float(car.call("get_speed_kmh")) < achieved,
            circuit + " decelerates under braking")
        game.call("cycle_camera")
        _expect(int(game.get("camera_mode")) == 1, circuit + " cockpit camera")
        game.call("cycle_camera")
        _expect(int(game.get("camera_mode")) == 2, circuit + " overhead camera")
        game.call("cycle_camera")
        _expect(int(game.get("camera_mode")) == 0, circuit + " chase camera returns")
        var reset: Transform3D = car.get("respawn_transform")
        game.call("_reset_drive")
        _expect(float(car.call("get_speed_kmh")) < 0.001,
            circuit + " reset stops test car")
        _expect(car.global_position.distance_to(reset.origin) < 0.01,
            circuit + " reset returns to start")
        var tracker: RefCounted = game.get("lap_tracker")
        _expect(tracker != null, circuit + " isolated lap timer attached")
    game.queue_free()
    await process_frame
    print("DRIVING SUMMARY failures=", failures)
    quit(1 if failures else 0)
