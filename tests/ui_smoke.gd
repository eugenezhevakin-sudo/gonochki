extends SceneTree
const MainScene = preload("res://scenes/main.tscn")
var failures := 0

func _expect(ok: bool, description: String) -> void:
    if ok:
        print("UI PASS: ", description)
    else:
        failures += 1
        push_error("UI FAIL: " + description)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: Control = MainScene.instantiate()
    root.add_child(game)
    await process_frame
    var selector: OptionButton = game.get_node_or_null("Layout/Header/CircuitSelector")
    _expect(selector != null and selector.item_count == 32,
        "32 options available in Android dropdown")
    var map_view: Control = game.get_node_or_null("Layout/View/MapPreview")
    _expect(map_view != null and map_view.visible,
        "2D map is safe initial mode")
    game.call("select_track", "jeddah_gp")
    _expect(str(game.get("selected_id")) == "jeddah_gp",
        "Jeddah changes via selector")
    game.call("change_mode", "preview")
    await process_frame
    var road: Node = game.get_node_or_null(
        "Layout/View/Scene3D/WorldViewport/TrackWorld/SelectedCircuit/TrackRoad")
    _expect(road != null, "3D preview generates circuit")
    game.call("change_mode", "drive")
    await process_frame
    var driver: Node = game.get_node_or_null(
        "Layout/View/Scene3D/WorldViewport/TrackWorld/PublicTestCar")
    _expect(driver != null, "free-drive test vehicle spawns")
    var buttons: Control = game.get_node_or_null("Layout/DriveControls")
    _expect(buttons != null and buttons.visible,
        "Android touch controls visible in drive mode")
    var camera: Button = game.get_node_or_null("Layout/DriveControls/CameraMode")
    _expect(camera != null and camera.visible, "driving camera toggle present")
    var progress: ProgressBar = game.get_node_or_null("Layout/LapProgress")
    _expect(progress != null and progress.visible, "lap progress indicator present")
    game.call("change_mode", "map")
    await process_frame
    _expect(map_view.visible and not buttons.visible,
        "switching back to 2D releases test controls")
    game.queue_free()
    await process_frame
    print("UI SUMMARY failures=", failures)
    quit(1 if failures else 0)
