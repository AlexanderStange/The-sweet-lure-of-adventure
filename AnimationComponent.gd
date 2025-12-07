# ========================================
# res://player/components/AnimationComponent.gd
# ========================================
# Manages all animations based on player state
# Rotates the visual model (Knight) to face movement direction
# Listens to other components via signals
# Plays: Idle, Walking, Running, Jumping, Attack animations
# ========================================

extends Node
class_name PlayerAnimationComponent

# ========================================
# EXPORTS
# ========================================
@export var animation_tree_path: NodePath = "AnimationTree"
@export var visual_root_path: NodePath = "Knight"  # The mesh that rotates

# ========================================
# STATE
# ========================================
var current_animation := "Idle"
var player_index: int = 0  # Added for consistency

# ========================================
# REFERENCES
# ========================================
var player: CharacterBody3D
var animation_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var visual_root: Node3D

var movement_component: MovementComponent
var combat_component: CombatComponent

# ========================================
# INITIALIZATION
# ========================================
func _ready() -> void:
	player = get_parent() as CharacterBody3D
	call_deferred("_setup_references")

func _setup_references() -> void:
	animation_tree = player.get_node_or_null(animation_tree_path) as AnimationTree
	if animation_tree:
		playback = animation_tree.get("parameters/playback")
	else:
		push_warning("AnimationTree not found at: %s" % animation_tree_path)
	
	visual_root = player.get_node_or_null(visual_root_path) as Node3D
	if not visual_root:
		push_warning("Visual root not found at: %s" % visual_root_path)
	
	# Find component siblings
	movement_component = player.get_node_or_null("MovementComponent") as MovementComponent
	combat_component = player.get_node_or_null("CombatComponent") as CombatComponent
	
	# Connect to component signals
	if combat_component:
		combat_component.attack_started.connect(_on_attack_started)
		combat_component.attack_finished.connect(_on_attack_finished)

# ========================================
# PUBLIC API
# ========================================
func play_animation(anim_name: String) -> void:
	"""Manually play an animation"""
	if playback:
		playback.travel(anim_name)
		current_animation = anim_name

func set_animation_condition(condition_name: String, value: bool) -> void:
	"""Set an AnimationTree condition"""
	if animation_tree:
		animation_tree.set("parameters/conditions/%s" % condition_name, value)

func play_death_animation() -> void:
	play_animation("Death_B")

# ========================================
# PROCESSING
# ========================================
func process_animations(delta: float) -> void:
	if not playback or not player:
		return
	
	_update_rotation(delta)
	_update_animation_state()

# ========================================
# PRIVATE METHODS
# ========================================
func _update_rotation(delta: float) -> void:
	"""Rotate character model to face movement direction"""
	if not visual_root or not movement_component:
		return
	
	if movement_component.is_walking:
		var direction := movement_component.get_movement_direction()
		var target_rotation := atan2(direction.x, direction.z)
		visual_root.rotation.y = lerp_angle(
			visual_root.rotation.y,
			target_rotation,
			delta * movement_component.rotation_speed
		)

func _update_animation_state() -> void:
	"""Determine which animation should play based on state"""
	if not movement_component or not combat_component:
		return
	
	var is_on_floor := player.is_on_floor()
	var is_walking := movement_component.is_walking
	var is_running := movement_component.is_running
	var is_attacking := combat_component.is_attacking
	
	# Priority order: death > attacking > jumping > running > walking > idle
	if is_attacking:
		# Attack animations are set by combat component
		pass
	elif not is_on_floor:
		play_animation("Jump_Full_Short")
	elif is_running:
		play_animation("Running_B")
	elif is_walking:
		play_animation("Walking_B")
	else:
		play_animation("Idle")
	
	# Update AnimationTree conditions
	set_animation_condition("IsOnFloor", is_on_floor)
	set_animation_condition("IsWalking", is_walking)
	set_animation_condition("IsRunning", is_running)

# ========================================
# SIGNAL HANDLERS
# ========================================
func _on_attack_started(attack_type: String) -> void:
	"""Play the appropriate attack animation"""
	match attack_type:
		"slice":
			play_animation("2H_Melee_Attack_Slice")
		"chop":
			play_animation("1H_Melee_Attack_Chop")
		"spin":
			play_animation("2H_Melee_Attack_Spin")
		_:
			play_animation("2H_Melee_Attack_Slice")
	
	# Auto-finish attack after animation (you can adjust timing)
	get_tree().create_timer(0.5).timeout.connect(func(): 
		if combat_component:
			combat_component.finish_attack()
	)

func _on_attack_finished() -> void:
	# Animation will naturally transition back to idle/walk/run
	pass
