extends Node3D
class_name SplitScreenManager

var viewports: Array[SubViewport] = []
var viewport_containers: Array[TextureRect] = []
var cameras: Array[Camera3D] = []
var ui_layers: Array[Control] = []

func _ready():
	add_to_group("SplitScreenManager")
	print("SplitScreenManager ready, window size:", get_viewport().size)


func add_camera(camera: Camera3D) -> void:
	print("Adding camera:", camera)

	var viewport := SubViewport.new()
	viewport.name = "PlayerViewport%d" % (cameras.size() + 1)
	viewport.size = get_viewport().size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.msaa_3d = Viewport.MSAA_4X
	viewports.append(viewport)
	add_child(viewport)

	# 🎯 UI root for this viewport
	var ui_layer := Control.new()
	ui_layer.name = "UIRoot%d" % (cameras.size() + 1)
	ui_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui_layer.anchor_right = 1.0
	ui_layer.anchor_bottom = 1.0
	viewport.add_child(ui_layer)
	ui_layers.append(ui_layer)

	# Move the camera into this viewport
	if camera.get_parent():
		camera.get_parent().remove_child(camera)
	camera.current = true
	camera.owner = null
	viewport.add_child(camera)
	cameras.append(camera)

	# 📺 Setup the output screen
	var screen := TextureRect.new()
	screen.name = "PlayerScreen%d" % cameras.size()
	screen.texture = viewport.get_texture()
	if cameras.size() + 1 >= 2:
		screen.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.anchor_left = 0
	screen.anchor_top = 0
	screen.anchor_right = 1
	screen.anchor_bottom = 1
	add_child(screen)
	viewport_containers.append(screen)

	update_layout()


func update_layout() -> void:
	var count := cameras.size()
	if count == 0:
		return

	for i in range(count):
		var screen := viewport_containers[i]
		match count:
			1:
				screen.anchor_left = 0.0
				screen.anchor_top = 0.0
				screen.anchor_right = 1.0
				screen.anchor_bottom = 1.0
			2:
				screen.anchor_left = 0.0
				screen.anchor_right = 0.5 if i == 0 else 1.0
				screen.anchor_top = 0.0
				screen.anchor_bottom = 1.0
				if i == 1:
					screen.anchor_left = 0.5
			3:
				if i == 0:
					screen.anchor_left = 0.0
					screen.anchor_top = 0.0
					screen.anchor_right = 0.5
					screen.anchor_bottom = 0.5
				elif i == 1:
					screen.anchor_left = 0.5
					screen.anchor_top = 0.0
					screen.anchor_right = 1.0
					screen.anchor_bottom = 0.5
				elif i == 2:
					screen.anchor_left = 0.0
					screen.anchor_top = 0.5
					screen.anchor_right = 1.0
					screen.anchor_bottom = 1.0
			4:
				match i:
					0:
						screen.anchor_left = 0.0
						screen.anchor_top = 0.0
						screen.anchor_right = 0.5
						screen.anchor_bottom = 0.5
					1:
						screen.anchor_left = 0.5
						screen.anchor_top = 0.0
						screen.anchor_right = 1.0
						screen.anchor_bottom = 0.5
					2:
						screen.anchor_left = 0.0
						screen.anchor_top = 0.5
						screen.anchor_right = 0.5
						screen.anchor_bottom = 1.0
					3:
						screen.anchor_left = 0.5
						screen.anchor_top = 0.5
						screen.anchor_right = 1.0
						screen.anchor_bottom = 1.0


func get_ui_layer_for_player(player_index: int) -> Control:
	if player_index < ui_layers.size():
		return ui_layers[player_index]
	return null


# 🔹 NEW: attach a UI element to a player's UI root
func add_player_ui(player_index: int, ui_element: Control) -> void:
	var ui_layer := get_ui_layer_for_player(player_index)
	if not ui_layer:
		push_error("UI layer for player %d not found!" % player_index)
		return

	ui_layer.add_child(ui_element)

	# Default placement: bottom-center of screen
	ui_element.anchor_left = 0.5
	ui_element.anchor_right = 0.5
	ui_element.anchor_top = 1.0
	ui_element.anchor_bottom = 1.0
	ui_element.pivot_offset = Vector2(ui_element.size.x / 2, ui_element.size.y)
	ui_element.position = Vector2(0, -20)  # 20px above bottom
