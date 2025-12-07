extends CharacterBody3D
class_name Player

# --- Camera ---
var camera: Camera3D

func set_camera(cam: Camera3D) -> void:
	camera = cam


@export var player_data: PlayerData 
@onready var animation_tree = $AnimationTree
@onready var playback = animation_tree.get("parameters/playback")
@onready var interaction_detector: Area3D = $Knight/InteractionDetector
@onready var inventory: Inventory = $Inventory
@onready var telegraph_scene = preload("res://combat/Telegraph.tscn")
@onready var combat_actor: CombatActor = $CombatActor

# --- Condition States ---
var is_attacking = false
var is_walking = false	
var is_running = false
var is_dying = false

# --- Movement and physics ---
@export var walk_speed := 3.5
@export var run_speed := 7.5
@export var jump_velocity := 7.0
@export var gravity := 9.8
@export var rotation_speed := 10.0

var original_walk_speed := walk_speed
var original_run_speed := run_speed

# --- Interaction / Holding ---
var is_holding_item := false
var is_in_conversation := false
var overlapping_interactables: Array = []
var held_item: Node3D = null
var jump_buffered := false

var last_direction = Vector3.FORWARD
var interacted_last_frame := false


func _ready() -> void:
	if interaction_detector:
		interaction_detector.body_entered.connect(_on_body_entered)
		interaction_detector.body_exited.connect(_on_body_exited)
	else:
		push_error("InteractionDetector not found in Player scene!")


func _on_body_entered(body: Node) -> void:
	if body.has_method("interact"):
		overlapping_interactables.append(body)


func _on_body_exited(body: Node) -> void:
	if body.has_method("interact"):
		overlapping_interactables.erase(body)


func try_interact_or_jump() -> void:
	# Interact if something is near, else jump
	if overlapping_interactables.size() > 0:
		var nearest = overlapping_interactables[0]
		var nearest_dist = global_position.distance_to(nearest.global_position)
		for i in overlapping_interactables:
			var d = global_position.distance_to(i.global_position)
			if d < nearest_dist:
				nearest = i
				nearest_dist = d
		nearest.interact(self)
	else:
		# Buffer jump
		if is_on_floor():
			velocity.y = jump_velocity


func hold_item(item: Node3D) -> void:
	is_holding_item = true
	held_item = item
	walk_speed = original_walk_speed * 0.5
	run_speed = original_run_speed * 0.5
	_hide_other_held_items(true)


func release_item() -> void:
	is_holding_item = false
	if held_item:
		held_item = null
	walk_speed = original_walk_speed
	run_speed = original_run_speed
	
	_hide_other_held_items(false)


func _hide_other_held_items(held: bool) -> void:
	var lefthand = $"Knight/Rig/Skeleton3D/2H_Sword"
	
	if held == true:
		lefthand.visible = false
	
	if held == false:
		lefthand.visible = true
	



func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	# Block movement if holding or in conversation
	if is_in_conversation:
		return

	# Read joystick input
	var input_vector = Vector3.ZERO
	var x_axis = Input.get_joy_axis(player_data.player_index, JOY_AXIS_LEFT_X)
	var y_axis = -Input.get_joy_axis(player_data.player_index, JOY_AXIS_LEFT_Y)
	if abs(x_axis) > 0.1:
		input_vector.x = x_axis
	if abs(y_axis) > 0.1:
		input_vector.z = y_axis

	is_walking = input_vector.length() > 0.1
	is_running = is_walking and Input.is_joy_button_pressed(player_data.player_index, 8)
	var speed = run_speed if is_running else walk_speed

	var direction = Vector3.ZERO
	if is_walking and camera:
		input_vector = input_vector.normalized()
		var cam_basis = camera.global_transform.basis
		var cam_forward = -cam_basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		var cam_right = cam_basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		direction = (cam_forward * input_vector.z + cam_right * input_vector.x).normalized()
		last_direction = direction
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Interact / Jump / Drop / Attack
	var interact_pressed = Input.is_joy_button_pressed(player_data.player_index, 0)
	var drop_pressed = Input.is_joy_button_pressed(player_data.player_index, 1)  # B button

	if interact_pressed and not interacted_last_frame:
		try_interact_or_jump()
	elif drop_pressed and held_item:
		held_item.drop(self)  # Call drop on the held item
	if drop_pressed and not held_item and not interacted_last_frame :
		# Attack fallback
		is_attacking = true
		if not is_on_floor():
			playback.travel("1H_Melee_Attack_Chop") 
		else:
			playback.travel("2H_Melee_Attack_Slice") 


	# Rotate model toward movement direction
	if is_walking:
		$Knight.rotation.y = lerp_angle($Knight.rotation.y, atan2(last_direction.x, last_direction.z), delta * rotation_speed)

	# Other attacks (X, Y) if not holding
	if not is_holding_item:
		if Input.is_joy_button_pressed(player_data.player_index, 2):
			is_attacking = true
			if not is_on_floor():
				playback.travel("1H_Melee_Attack_Chop") 
				
			else:
				playback.travel("2H_Melee_Attack_Slice")
				combat_actor.perform_attack()
				print("player_controller: we are hitting the button")
		elif Input.is_joy_button_pressed(player_data.player_index, 3):
			is_attacking = true
			playback.travel("2H_Melee_Attack_Spin")  

	move_and_slide()

	# Animation switching
	if is_dying:
		playback.travel("Death_B")
	elif not is_on_floor() and not is_attacking:
		playback.travel("Jump_Full_Short")
	elif is_attacking:
		is_attacking = false
	elif is_running:
		playback.travel("Running_B")
	elif is_walking:
		playback.travel("Walking_B")
	else:
		playback.travel("Idle")

	set_anim_condition("IsOnFloor", is_on_floor())
	set_anim_condition("IsWalking", is_walking)
	set_anim_condition("IsRunning", is_running)

	interacted_last_frame = interact_pressed or drop_pressed


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0


func set_anim_condition(name: String, value: bool) -> void:
	animation_tree.set("parameters/conditions/%s" % name, value)


# --- Dialogue signals ---
func _on_dialogue_started(timeline_name: String) -> void:
	is_in_conversation = true

func _on_dialogue_ended(timeline_name: String) -> void:
	is_in_conversation = false
	
#-- For inventory ---
func init_inventory():
	# Get the SplitScreenManager singleton
	var ssm = get_tree().get_first_node_in_group("SplitScreenManager")
	if not ssm:
		push_warning("SplitScreenManager not found in scene tree!")
		return

	# Get the UI layer for this player
	var ui_layer = ssm.get_ui_layer_for_player(player_data.player_index)
	if not ui_layer:
		push_warning("UI layer not found for player %d" % player_data.player_index)
		return

	# Find the InventoryUI node in this player's UI layer
	var inv_ui: InventoryUI = ui_layer.get_node_or_null("InventoryUI") as InventoryUI
	if not inv_ui:
	# If not found, instantiate the scene
		var inv_ui_scene = preload("res://player/Inventory/InventoryUI.tscn")
		inv_ui = inv_ui_scene.instantiate() as InventoryUI
		inv_ui.name = "InventoryUI"
		ui_layer.add_child(inv_ui)

# Initialize the Inventory node with PlayerData and InventoryUI reference
	inventory.init(player_data, inv_ui)
	
