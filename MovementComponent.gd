# ========================================
# res://player/components/MovementComponent.gd
# ========================================
# Handles all player movement: walking, running, jumping, gravity
# Works with joystick input for up to 4 players
# Camera-relative movement direction
# ========================================

extends Node
class_name MovementComponent

# ========================================
# EXPORTS
# ========================================
@export var walk_speed := 3.5
@export var run_speed := 7.5
@export var jump_velocity := 7.0
@export var gravity := 9.8
@export var rotation_speed := 10.0

# ========================================
# SIGNALS
# ========================================
signal movement_state_changed(is_walking: bool, is_running: bool)
signal jumped()
signal landed()

# ========================================
# STATE
# ========================================
var is_walking := false
var is_running := false
var was_on_floor := true
var movement_enabled := true
var speed_multiplier := 1.0  # For status effects (slow, speed boost, etc.)

var last_direction := Vector3.FORWARD
var original_walk_speed := walk_speed
var original_run_speed := run_speed

# ========================================
# REFERENCES (set by parent)
# ========================================
var body: CharacterBody3D
var camera: Camera3D
var player_index: int = 0

# ========================================
# INITIALIZATION
# ========================================
func _ready() -> void:
	body = get_parent() as CharacterBody3D
	if not body:
		push_error("MovementComponent must be child of CharacterBody3D!")
	
	original_walk_speed = walk_speed
	original_run_speed = run_speed

# ========================================
# PUBLIC API
# ========================================
func set_speed_multiplier(multiplier: float) -> void:
	"""Used by other components (e.g., holding items reduces speed)"""
	speed_multiplier = multiplier
	walk_speed = original_walk_speed * multiplier
	run_speed = original_run_speed * multiplier

func enable_movement(enabled: bool) -> void:
	"""Disable during dialogue, cutscenes, etc."""
	movement_enabled = enabled

func request_jump() -> bool:
	"""Returns true if jump was executed"""
	if body.is_on_floor():
		body.velocity.y = jump_velocity
		emit_signal("jumped")
		return true
	return false

# ========================================
# PHYSICS PROCESSING
# ========================================
func physics_process(delta: float) -> void:
	if not body:
		return
	
	_apply_gravity(delta)
	
	# Detect landing
	if body.is_on_floor() and not was_on_floor:
		emit_signal("landed")
	was_on_floor = body.is_on_floor()
	
	if not movement_enabled:
		_apply_friction(delta)
		return
	
	_handle_movement_input(delta)

# ========================================
# PRIVATE METHODS
# ========================================
func _apply_gravity(delta: float) -> void:
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta
	else:
		body.velocity.y = 0

func _apply_friction(delta: float) -> void:
	"""Gradually stop movement when disabled"""
	var speed = run_speed if is_running else walk_speed
	body.velocity.x = move_toward(body.velocity.x, 0, speed)
	body.velocity.z = move_toward(body.velocity.z, 0, speed)

func _handle_movement_input(delta: float) -> void:
	# Read joystick input
	var input_vector := Vector3.ZERO
	var x_axis := Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
	var y_axis := -Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y)
	
	if abs(x_axis) > 0.1:
		input_vector.x = x_axis
	if abs(y_axis) > 0.1:
		input_vector.z = y_axis
	
	var was_walking := is_walking
	var was_running := is_running
	
	is_walking = input_vector.length() > 0.1
	# Check both L button (JOY_BUTTON_LEFT_SHOULDER = 9) and Right Stick press (JOY_BUTTON_RIGHT_STICK = 12)
	is_running = is_walking and (Input.is_joy_button_pressed(player_index, JOY_BUTTON_LEFT_SHOULDER) or Input.is_joy_button_pressed(player_index, JOY_BUTTON_RIGHT_STICK))
	
	# Emit state change
	if was_walking != is_walking or was_running != is_running:
		emit_signal("movement_state_changed", is_walking, is_running)
	
	var speed := (run_speed if is_running else walk_speed) * speed_multiplier
	
	# Calculate movement direction relative to camera
	if is_walking and camera:
		input_vector = input_vector.normalized()
		
		var cam_basis := camera.global_transform.basis
		var cam_forward := -cam_basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		var cam_right := cam_basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		var direction := (cam_forward * input_vector.z + cam_right * input_vector.x).normalized()
		last_direction = direction
		
		body.velocity.x = direction.x * speed
		body.velocity.z = direction.z * speed
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, speed)
		body.velocity.z = move_toward(body.velocity.z, 0, speed)

func get_movement_direction() -> Vector3:
	"""Returns the last movement direction (used for rotation)"""
	return last_direction
