extends Node
class_name MultiplayerManager

var split_screen: SplitScreenManager

func _ready():
	split_screen = get_tree().get_root().get_node("/root/Node3D/CanvasLayer/SplitScreenManager")

func get_viewport_for_player(player_index: int) -> SubViewport:
	if split_screen and player_index < split_screen.viewports.size():
		return split_screen.viewports[player_index]
	return null

func get_ui_layer_for_player(player_index: int) -> Control:
	if split_screen and player_index < split_screen.ui_layers.size():
		return split_screen.ui_layers[player_index]
	return null
