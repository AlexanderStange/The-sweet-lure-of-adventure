extends Node3D

@onready var spawner: PlayerSpawner = $PlayerSpawner
@onready var screen_manager = $CanvasLayer/SplitScreenManager
@onready var player_data_manager: PlayerManager = $PlayerManager

const JOY_START := 6  

func _ready():
	spawn_new_player(0) # Always spawn player 0

func _process(_delta):
	for i in range(1, 4): # Players 1-3 join with Start button
		if Input.is_joy_button_pressed(i, JOY_START) and !spawner.used_indices.has(i):
			spawn_new_player(i)

func spawn_new_player(player_index: int):
	var positioning = spawner.get_next_spawn_position()
	var player = spawner.spawn_player(player_index, positioning)

## Assign PlayerData (from your PlayerDataManager or however you load .tres)
	var data := PlayerManager.get_data_for_index(player_index)
	player.player_data = data

## Initialize inventory now that player_data exists
	var ssm = get_tree().get_first_node_in_group("SplitScreenManager")
	if ssm:
		player.init_inventory()
	else:
		push_error("No PlayerData for player index %d" % player_index)

	#return player
