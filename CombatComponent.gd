# ========================================
# res://player/components/CombatComponent.gd
# ========================================
# Handles combat input (X, Y, B buttons for attacks)
# Triggers attack animations via AnimationComponent
# Calls CombatActor.perform_attack() to spawn telegraphs
# Prevents attacking while holding items
# ========================================

extends Node
class_name CombatComponent

# ========================================
# EXPORTS
# ========================================
@export var combat_actor_path: NodePath = "CombatActor"

# ========================================
# SIGNALS
# ========================================
signal attack_started(attack_type: String)
signal attack_finished()

# ========================================
# STATE
# ========================================
var is_attacking := false
var can_attack := true
var attack_button_pressed_last_frame := false

# ========================================
# REFERENCES
# ========================================
var player: Node
var player_index: int = 0
var combat_actor: CombatActor
var holdable_component: HoldableComponent

# ========================================
# INITIALIZATION
# ========================================
func _ready() -> void:
	player = get_parent()
	call_deferred("_setup_references")

func _setup_references() -> void:
	combat_actor = player.get_node_or_null(combat_actor_path) as CombatActor
	if not combat_actor:
		push_warning("CombatActor not found at: %s" % combat_actor_path)
	
	# Find holdable component sibling
	holdable_component = player.get_node_or_null("HoldableComponent") as HoldableComponent

# ========================================
# PUBLIC API
# ========================================
func enable_combat(enabled: bool) -> void:
	"""Disable during dialogue, cutscenes, etc."""
	can_attack = enabled

func perform_attack(attack_type: String = "basic") -> bool:
	"""Executes an attack. Returns true if successful."""
	if not can_attack or is_attacking:
		return false
	
	# Can't attack while holding items
	if holdable_component and holdable_component.is_holding_item:
		return false
	
	is_attacking = true
	emit_signal("attack_started", attack_type)
	
	# Tell CombatActor to spawn telegraph
	if combat_actor:
		combat_actor.perform_attack()
	
	return true

func finish_attack() -> void:
	"""Called by animation or timer to end attack state"""
	is_attacking = false
	emit_signal("attack_finished")

# ========================================
# INPUT PROCESSING
# ========================================
func process_input(body: CharacterBody3D) -> void:
	# X button = basic attack
	var attack_x := Input.is_joy_button_pressed(player_index, JOY_BUTTON_X)
	# Y button = special attack
	var attack_y := Input.is_joy_button_pressed(player_index, JOY_BUTTON_Y)
	
	# B button can also attack if not holding item (as fallback)
	var attack_b := Input.is_joy_button_pressed(player_index, JOY_BUTTON_B)
	var can_use_b_for_attack := not (holdable_component and holdable_component.is_holding_item)
	
	if attack_x and not attack_button_pressed_last_frame:
		if body.is_on_floor():
			perform_attack("slice")
		else:
			perform_attack("chop")
	elif attack_y and not attack_button_pressed_last_frame:
		perform_attack("spin")
	elif attack_b and can_use_b_for_attack and not attack_button_pressed_last_frame:
		perform_attack("basic")
	
	attack_button_pressed_last_frame = attack_x or attack_y or attack_b
