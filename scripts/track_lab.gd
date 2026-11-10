extends Control
## Public standalone atlas-test UI. Does not import any private racing scripts.
const Atlas = preload("res://scripts/atlas.gd")
const MapView = preload("res://scripts/map_view.gd")
const TrackGeometry = preload("res://scripts/track_geometry.gd")
const Driver = preload("res://scripts/test_driver.gd")

var chooser: OptionButton
var map_view: Control
var scene_panel: SubViewportContainer
var viewport: SubViewport
var world: Node3D
var controls: HBoxContainer
var info: Label
var telemetry: Label
var geometry: Node3D
var car
var mode := "map"
var selected_id := "silverstone_gp"

func _label(text_value: String, font_size: int = 18) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("edf5f7"))
    return label

func _button(text_value: String, min_width: float = 126.0) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(min_width, 46.0)
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
    header.custom_minimum_size.y = 56
    header.add_theme_constant_override("separation", 8)
    outer.add_child(header)
    var brand := _label("APEX GRID  ·  TRACK LAB", 24)
    brand.custom_minimum_size.x = 305.0
    header.add_child(brand)
    chooser = OptionButton.new()
    chooser.name = "CircuitSelector"
    chooser.custom_minimum_size = Vector2(285.0, 47.0)
    chooser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var tracks: Array = Atlas.records()
    for index in range(tracks.size()):
        var record: Dictionary = tracks[index]
        chooser.add_item(str(record.get("name", "")), index)
        chooser.set_item_metadata(index, str(record.get("track_id", "")))
    chooser.item_selected.connect(_on_track_selected)
    header.add_child(chooser)

    var map_button := _button("2D-СХЕМА")
    map_button.name = "MapMode"
    map_button.pressed.connect(func(): change_mode("map"))
    header.add_child(map_button)
    var preview_button := _button("3D-ОСМОТР")
    preview_button.name = "PreviewMode"
    preview_button.pressed.connect(func(): change_mode("preview"))
    header.add_child(preview_button)
    var drive_button := _button("ТЕСТ-ДРАЙВ", 145.0)
    drive_button.name = "DriveMode"
    drive_button.pressed.connect(func(): change_mode("drive"))
    header.add_child(drive_button)

    info = _label("", 17)
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
    controls.custom_minimum_size.y = 61
    controls.add_theme_constant_override("separation", 12)
    outer.add_child(controls)
    _hold_button("◀ ПОВОРОТ", "left_turn")
    _hold_button("ПОВОРОТ ▶", "right_turn")
    _hold_button("ГАЗ", "throttle")
    _hold_button("ТОРМОЗ", "braking")
    var reset := _button("СБРОС", 125)
    reset.name = "ResetCar"
    reset.pressed.connect(func():
        if is_instance_valid(car):
            car.call("respawn"))
    controls.add_child(reset)
    controls.visible = false

    var bottom := HBoxContainer.new()
    bottom.name = "Footer"
    outer.add_child(bottom)
    telemetry = _label("Готово", 15)
    telemetry.name = "Telemetry"
    telemetry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(telemetry)
    var credit := _label("Tomislav Bacinger (MIT) · © OpenStreetMap contributors (ODbL)", 13)
    bottom.add_child(credit)

    var starting_index := 0
    for index in range(chooser.item_count):
        if str(chooser.get_item_metadata(index)) == selected_id:
            starting_index = index
            break
    chooser.select(starting_index)
    change_mode("map")

func _hold_button(label_value: String, field: String) -> void:
    var button := _button(label_value, 142.0)
    button.name = "Hold_" + field
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
    mode = next_mode
    var record: Dictionary = Atlas.get_track(selected_id)
    if record.is_empty():
        return
    var length_km: float = float(record.get("length_m", 0)) / 1000.0
    info.text = "%s   |   %.3f км   |   23 схемы · 23 пит-лейна · предварительные данные" % [
        str(record.get("name", "")), length_km]
    map_view.visible = mode == "map"
    scene_panel.visible = mode != "map"
    controls.visible = mode == "drive"
    if mode == "map":
        map_view.call("set_track", selected_id)
        telemetry.text = "2D-схема · выбор трассы сверху · не проверена для гонок"
        return
    _prepare_3d()
    telemetry.text = (
        "Тест-драйв · газ/тормоз/повороты · W/A/S/D · трасса без ограждений"
        if mode == "drive" else
        "3D-черновик · физические дорожные поверхности · высоты и пит не сертифицированы")

func _prepare_3d() -> void:
    for previous in world.get_children():
        previous.queue_free()
    car = null
    geometry = TrackGeometry.new()
    geometry.name = "SelectedCircuit"
    world.add_child(geometry)
    if not geometry.call("generate", selected_id):
        telemetry.text = "Ошибка построения трассы"
        return
    if mode == "drive":
        car = Driver.new()
        car.name = "PublicTestCar"
        world.add_child(car)
        var spawn: Transform3D = geometry.call("start_transform")
        car.set("respawn_transform", spawn)
        car.global_transform = spawn
        var cam: Camera3D = geometry.get("camera")
        cam.size = 110.0

func _process(_delta: float) -> void:
    if mode == "drive" and is_instance_valid(car) and is_instance_valid(geometry):
        var follow_cam: Camera3D = geometry.get("camera")
        if is_instance_valid(follow_cam):
            var target: Vector3 = car.global_position
            follow_cam.position = target + Vector3(0.0, 52.0, 40.0)
            follow_cam.look_at(target, Vector3.UP)
        var car_speed: float = float(car.get("speed_mps"))
        telemetry.text = "ТЕСТ-ДРАЙВ  ·  %.0f км/ч  |  FPS: %d  |  СБРОС при съезде с асфальта" % [
            absf(car_speed) * 3.6, Engine.get_frames_per_second()]
    elif mode == "preview":
        telemetry.text = "3D-ОСМОТР  ·  FPS: %d  |  геометрия не проверена для гоночного режима" % Engine.get_frames_per_second()
