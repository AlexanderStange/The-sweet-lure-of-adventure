extends Node3D
class_name PlayerSpawner

var player_scene = preload("res://player/player_3d.tscn")
@export var spawn_points_path: NodePath = "SpawnPoints"

var active_players: Array = []
var used_indices := {}

func spawn_player(player_index: int, position: Vector3) -> Node:
	if not player_scene:
		push_error("Player scene not set!")
		return null

	var player = player_scene.instantiate()
	if not player:
		push_error("no Player")

	# 🔹 Fetch the correct PlayerData
	var pdata: PlayerData = PlayerManager.get_data_for_index(player_index)
	if pdata == null:
		push_error("No PlayerData found for index %s" % player_index)
		return null

	# 🔹 Assign PlayerData before adding to scene
	var combat_actor := player.get_node("CombatActor") # adjust path if needed
	combat_actor.player_data = pdata

	get_tree().current_scene.add_child(player)
	player.global_transform.origin = position

	# --- Camera setup ---
	var camera := preload("res://multiplayer/FollowCamera.gd").new()
	camera.name = "PlayerCamera%d" % player_index
	camera.target = player
	camera.screen_index = player_index
	camera.follow_distance = Vector3(0, 8, -15)
	camera.follow_speed = 5.0

	var split_screen_manager = get_tree().get_first_node_in_group("SplitScreenManager")
	if split_screen_manager:
		split_screen_manager.add_camera(camera)
		


	# --- HealthBar setup ---
	var healthbar_scene = preload("res://player/Combat/HealthBar.tscn")
	var healthbar = healthbar_scene.instantiate()
	healthbar.name = "PlayerHealthBar%d" % player_index
	healthbar.init(pdata)

	split_screen_manager.add_player_ui(player_index, healthbar)
	player.set_meta("healthbar", healthbar)


	player.set_camera(camera) 
	active_players.append(player)
	used_indices[player_index] = true
	return player

func get_next_spawn_position() -> Vector3:
	var spawn_points = get_tree().current_scene.get_node_or_null(spawn_points_path)
	if not spawn_points:
		push_error("SpawnPoints node not found in scene!")
		return Vector3.ZERO

	var next_index = active_players.size() + 1
	var spawn_node = spawn_points.get_node_or_null("Spawn%d" % next_index)
	if not spawn_node:
		push_warning("Missing Spawn%d. Falling back to origin." % next_index)
		return Vector3.ZERO

	return spawn_node.global_transform.origin
