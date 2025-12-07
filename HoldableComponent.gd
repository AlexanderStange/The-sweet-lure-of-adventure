# ========================================
# res://player/components/HoldableComponent.gd
# ========================================
# Manages picking up and carrying items (apples, bombs, barrels)
# Reduces movement speed when holding
# Hides weapons while carrying
# Handles B button to drop items
# ========================================

extends Node
class_name HoldableComponent

# ========================================
# EXPORTS
# ========================================
@export var hand_attachment_path: NodePath = "Knight/Hand"
@export var weapon_visibility_paths: Array[NodePath] = []
@export var speed_reduction_when_holding := 0.5

# ========================================
# SIGNALS
# ========================================
signal item_picked_up(item: Node3D)
signal item_dropped(item: Node3D)

# ========================================
# STATE
# ========================================
var is_holding_item := false
var held_item: Node3D = null
var drop_button_pressed_last_frame := false

# ========================================
# REFERENCES
# ========================================
var player: Node
var player_index: int = 0
var hand_node: Node3D
var weapon_nodes: Array[Node3D] = []
var movement_component: MovementComponent

# ========================================
# INITIALIZATION
# ========================================
func _ready() -> void:
	player = get_parent()
	call_deferred("_setup_references")

func _setup_references() -> void:
	hand_node = player.get_node_or_null(hand_attachment_path) as Node3D
	if not hand_node:
		push_warning("Hand attachment point not found at: %s" % hand_attachment_path)
	
	# Get weapon nodes for hiding/showing
	for path in weapon_visibility_paths:
		var node := player.get_node_or_null(path) as Node3D
		if node:
			weapon_nodes.append(node)
	
	# Find movement component sibling
	movement_component = player.get_node_or_null("MovementComponent") as MovementComponent

# ========================================
# PUBLIC API
# ========================================
func hold_item(item: Node3D) -> void:
	"""Called by Holdable objects when picked up"""
	if is_holding_item:
		release_item()  # Drop current item first
	
	is_holding_item = true
	held_item = item
	
	# Reduce movement speed
	if movement_component:
		movement_component.set_speed_multiplier(speed_reduction_when_holding)
	
	# Hide weapons
	_set_weapons_visible(false)
	
	emit_signal("item_picked_up", item)
	EventBus.emit_signal("item_picked_up", player, item, 1)

func release_item() -> void:
	"""Drop the currently held item"""
	if not held_item:
		return
	
	var item := held_item
	held_item = null
	is_holding_item = false
	
	# Call drop method on the item if it has one
	if item.has_method("drop"):
		item.drop(player)
	
	# Restore movement speed
	if movement_component:
		movement_component.set_speed_multiplier(1.0)
	
	# Show weapons again
	_set_weapons_visible(true)
	
	emit_signal("item_dropped", item)
	EventBus.emit_signal("item_dropped", player, item, 1)

func get_hand_position() -> Vector3:
	"""Returns the global position of the hand attachment point"""
	if hand_node:
		return hand_node.global_position
	return player.global_position

# ========================================
# INPUT PROCESSING
# ========================================
func process_input() -> void:
	var drop_pressed := Input.is_joy_button_pressed(player_index, JOY_BUTTON_B)
	
	# Only trigger on button press (not hold)
	if drop_pressed and not drop_button_pressed_last_frame:
		if is_holding_item:
			release_item()
	
	drop_button_pressed_last_frame = drop_pressed

# ========================================
# PRIVATE METHODS
# ========================================
func _set_weapons_visible(visible: bool) -> void:
	for weapon in weapon_nodes:
		weapon.visible = visible
