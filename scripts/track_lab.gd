extends Control
## Public standalone 32-circuit geometry/race-feel test, not production F1 code.
const Atlas = preload("res://scripts/atlas.gd")
const MapView = preload("res://scripts/map_view.gd")
const TrackGeometry = preload("res://scripts/track_geometry.gd")
const Driver = preload("res://scripts/test_driver.gd")
const LapTiming = preload("res://scripts/lap_timing.gd")

var chooser: OptionButton
var map_view: Control
var scene_panel: SubViewportContainer
var viewport: SubViewport
var world: Node3D
var controls: HBoxContainer
var info: Label
var telemetry: Label
var progress_bar: ProgressBar
var camera_button: Button
var geometry: Node3D
var car: CharacterBody3D
var lap_tracker: RefCounted
var mode := "map"
var selected_id := "silverstone_gp"
var camera_mode := 0

func _label(text_value: String, font_size: int = 18) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("edf5f7"))
    return label

func _button(text_value: String, min_width: float = 126.0) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(min_width, 52.0)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 17)
    return button

func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color("091721")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var outer := VBoxContainer.new()
    outer.name = "Layout"
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.offset_left = 12
    outer.offset_top = 8
    outer.offset_right = -12
    outer.offset_bottom = -8
    outer.add_theme_constant_override("separation", 6)
    add_child(outer)

    var header := HBoxContainer.new()
    header.name = "Header"
    header.custom_minimum_size.y = 54
    header.add_theme_constant_override("separation", 7)
    outer.add_child(header)
    var brand := _label("APEX GRID · TRACK LAB", 23)
    brand.custom_minimum_size.x = 280.0
    header.add_child(brand)
    chooser = OptionButton.new()
    chooser.name = "CircuitSelector"
    chooser.custom_minimum_size = Vector2(250.0, 48.0)
    chooser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var tracks: Array = Atlas.records()
    for index in range(tracks.size()):
        var record: Dictionary = tracks[index]
        chooser.add_item(str(record.get("name", "")), index)
        chooser.set_item_metadata(index, str(record.get("track_id", "")))
    chooser.item_selected.connect(_on_track_selected)
    header.add_child(chooser)

    var map_button := _button("2D-КАРТА", 120)
    map_button.name = "MapMode"
    map_button.pressed.connect(func(): change_mode("map"))
    header.add_child(map_button)
    var preview_button := _button("3D-ОСМОТР", 135)
    preview_button.name = "PreviewMode"
    preview_button.pressed.connect(func(): change_mode("preview"))
    header.add_child(preview_button)
    var drive_button := _button("ЗАЕЗД", 126)
    drive_button.name = "DriveMode"
    drive_button.pressed.connect(func(): change_mode("drive"))
    header.add_child(drive_button)

    info = _label("", 16)
    info.name = "CircuitInfo"
    outer.add_child(info)

    var view := Control.new()
    view.name = "View"
    view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(view)
    map_view = MapView.new()
    map_view.name = "MapPreview"
    map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    view.add_child(map_view)
    scene_panel = SubViewportContainer.new()
    scene_panel.name = "Scene3D"
    scene_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scene_panel.stretch = true
    scene_panel.visible = false
    view.add_child(scene_panel)
    viewport = SubViewport.new()
    viewport.name = "WorldViewport"
    viewport.size = Vector2i(1280, 640)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    scene_panel.add_child(viewport)
    world = Node3D.new()
    world.name = "TrackWorld"
    viewport.add_child(world)

    controls = HBoxContainer.new()
    controls.name = "DriveControls"
    controls.custom_minimum_size.y = 70
    controls.add_theme_constant_override("separation", 7)
    outer.add_child(controls)
    _hold_button("◀ РУЛЬ", "left_turn")
    _hold_button("РУЛЬ ▶", "right_turn")
    _hold_button("ГАЗ", "throttle")
    _hold_button("ТОРМОЗ", "braking")
    camera_button = _button("КАМЕРА 1/3", 150)
    camera_button.name = "CameraMode"
    camera_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    camera_button.pressed.connect(cycle_camera)
    controls.add_child(camera_button)
    var reset := _button("СБРОС", 114)
    reset.name = "ResetCar"
    reset.pressed.connect(_reset_drive)
    controls.add_child(reset)
    controls.visible = false

    progress_bar = ProgressBar.new()
    progress_bar.name = "LapProgress"
    progress_bar.custom_minimum_size.y = 9.0
    progress_bar.min_value = 0.0
    progress_bar.max_value = 100.0
    progress_bar.value = 0.0
    progress_bar.show_percentage = false
    progress_bar.visible = false
    outer.add_child(progress_bar)

    var bottom := HBoxContainer.new()
    bottom.name = "Footer"
    outer.add_child(bottom)
    telemetry = _label("Готово", 16)
    telemetry.name = "Telemetry"
    telemetry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(telemetry)
    var credit := _label("Tomislav Bacinger (MIT) · © OpenStreetMap (ODbL)", 12)
    bottom.add_child(credit)

    var starting_index := 0
    for index in range(chooser.item_count):
        if str(chooser.get_item_metadata(index)) == selected_id:
            starting_index = index
            break
    chooser.select(starting_index)
    change_mode("map")

func _hold_button(label_value: String, field: String) -> void:
    var button := _button(label_value, 136)
    button.name = "Hold_" + field
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.keep_pressed_outside = true
    button.button_down.connect(func(): _set_car_input(field, true))
    button.button_up.connect(func(): _set_car_input(field, false))
    controls.add_child(button)

func _set_car_input(field: String, pressed: bool) -> void:
    if is_instance_valid(car):
        car.set(field, pressed)

func _on_track_selected(index: int) -> void:
    selected_id = str(chooser.get_item_metadata(index))
    change_mode("map")

func select_track(id: String) -> void:
    for i in range(chooser.item_count):
        if str(chooser.get_item_metadata(i)) == id:
            chooser.select(i)
            selected_id = id
            change_mode("map")
            return

func change_mode(next_mode: String) -> void:
    if next_mode != "map" and next_mode != "preview" and next_mode != "drive":
        return
    if is_instance_valid(car):
        car.call("reset_inputs")
    mode = next_mode
    var record: Dictionary = Atlas.get_track(selected_id)
    if record.is_empty():
        return
    var length_km: float = float(record.get("length_m", 0)) / 1000.0
    var pit_info: Dictionary = record.get("pit", {})
    var pit_status: String = "ПИТ: УСЛОВНЫЙ" if bool(pit_info.get("approximate", false)) else "ПИТ: НЕ ПРОВЕРЕН"
    info.text = "%s   |   %.3f км   |   %d трассы   |   %s" % [
        str(record.get("name", "")), length_km, chooser.item_count, pit_status]
    map_view.visible = mode == "map"
    scene_panel.visible = mode != "map"
    controls.visible = mode == "drive"
    progress_bar.visible = mode == "drive"
    if mode == "map":
        map_view.call("set_track", selected_id)
        telemetry.text = "2D-схема · все трассы являются черновыми геометрическими моделями"
        return
    _prepare_3d()
    telemetry.text = (
        "ЗАЕЗД · W/A/S/D или экранные кнопки · камера · сброс"
        if mode == "drive" else
        "3D-осмотр · дорожные коллизии · окружение и пит-лейн не сертифицированы")

func _prepare_3d() -> void:
    for previous in world.get_children():
        world.remove_child(previous)
        previous.queue_free()
    car = null
    geometry = TrackGeometry.new()
    geometry.name = "SelectedCircuit"
    world.add_child(geometry)
    if not bool(geometry.call("generate", selected_id)):
        telemetry.text = "Ошибка построения трассы"
        return
    if mode == "drive":
        car = Driver.new()
        car.name = "PublicTestCar"
        world.add_child(car)
        var spawn: Transform3D = geometry.call("start_transform")
        car.set("respawn_transform", spawn)
        car.global_transform = spawn
        lap_tracker = LapTiming.new()
        lap_tracker.call("configure", geometry.get("track_path"))
        camera_mode = 0
        camera_button.text = "КАМЕРА 1/3"
        _update_follow_camera(0.0, true)

func _reset_drive() -> void:
    if is_instance_valid(car):
        car.call("respawn")
    if lap_tracker != null:
        lap_tracker.call("reset_run")
    progress_bar.value = 0.0
    _update_follow_camera(0.0, true)

func cycle_camera() -> void:
    if mode != "drive" or not is_instance_valid(car):
        return
    camera_mode = (camera_mode + 1) % 3
    camera_button.text = "КАМЕРА %d/3" % (camera_mode + 1)
    _update_follow_camera(0.0, true)

func _update_follow_camera(delta: float, instant: bool = false) -> void:
    if not is_instance_valid(car) or not is_instance_valid(geometry):
        return
    var cam: Camera3D = geometry.get("camera")
    if not is_instance_valid(cam):
        return
    cam.projection = Camera3D.PROJECTION_PERSPECTIVE
    cam.fov = 76.0 if camera_mode == 0 else (83.0 if camera_mode == 1 else 65.0)
    var center: Vector3 = car.global_position
    var forward: Vector3 = -car.global_transform.basis.z
    var target: Vector3
    var gaze: Vector3
    if camera_mode == 0:
        target = center - forward * 11.5 + Vector3.UP * 5.0
        gaze = center + forward * 18.0 + Vector3.UP * 1.0
    elif camera_mode == 1:
        target = center + forward * 0.25 + Vector3.UP * 0.84
        gaze = center + forward * 22.0 + Vector3.UP * 0.80
    else:
        target = center - forward * 4.0 + Vector3.UP * 48.0
        gaze = center + forward * 5.0
    var blend: float = 1.0 if instant else clampf(delta * 7.5, 0.0, 1.0)
    cam.global_position = cam.global_position.lerp(target, blend)
    cam.look_at(gaze, Vector3.UP)

func _physics_process(_delta: float) -> void:
    if mode == "drive" and is_instance_valid(car) and lap_tracker != null:
        lap_tracker.call("update_position", car.global_position,
            bool(car.get("last_on_track")))

func _process(delta: float) -> void:
    if mode == "drive" and is_instance_valid(car) and is_instance_valid(geometry):
        _update_follow_camera(delta)
        var kmh: float = float(car.call("get_speed_kmh"))
        var gear: int = int(car.get("automatic_gear"))
        var gear_text := "R" if gear < 0 else str(gear)
        var lap_number: int = int(lap_tracker.get("laps")) + 1
        var current_seconds: float = float(lap_tracker.get("current_lap_s"))
        var best_seconds: float = float(lap_tracker.get("best_lap_s"))
        var progress: float = float(lap_tracker.get("fraction"))
        var good: bool = bool(lap_tracker.get("lap_valid"))
        var valid_label := "" if good else " · КРУГ НЕЗАЧЁТ"
        var current_time: String = str(LapTiming.format_time(current_seconds))
        var best_time: String = str(LapTiming.format_time(best_seconds))
        progress_bar.value = progress * 100.0
        telemetry.text = "%.0f км/ч · %s передача · Круг %d · %s · Лучший %s · FPS %d%s" % [
            kmh, gear_text, lap_number, current_time, best_time,
            Engine.get_frames_per_second(), valid_label]
    elif mode == "preview":
        telemetry.text = "3D-ОСМОТР · FPS %d · модель трассы без проверки безопасности" % Engine.get_frames_per_second()
