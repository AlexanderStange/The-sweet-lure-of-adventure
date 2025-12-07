# ========================================
# res://player/Player.gd (NEW REFACTORED VERSION)
# ========================================
# This replaces your old player_controller.tres.gd
# The player script is now much simpler - components do the work!
# ========================================

extends CharacterBody3D
class_name Player

# ========================================
# EXPORTS
# ========================================
@export var player_data: PlayerData

# ========================================
# REFERENCES - Components do the work!
# ========================================
@onready var movement_component: MovementComponent = $MovementComponent
@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var holdable_component: HoldableComponent = $HoldableComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var animation_component: PlayerAnimationComponent = $AnimationComponent
@onready var combat_actor: CombatActor = $CombatActor
@onready var inventory: Inventory = $Inventory

# ========================================
# STATE
# ========================================
var camera: Camera3D
var is_in_conversation := false

# ========================================
# INITIALIZATION
# ========================================
func _ready() -> void:
	# Defer setup until player_data is assigned
	call_deferred("_setup_components")
	call_deferred("_connect_signals")

func _setup_components() -> void:
	"""Pass necessary data to components"""
	if not player_data:
		push_error("Player._setup_components: player_data is null!")
		return
	
	var player_index := player_data.player_index
	
	if movement_component:
		movement_component.player_index = player_index
		movement_component.camera = camera
	
	if interaction_component:
		interaction_component.player_index = player_index
	
	if holdable_component:
		holdable_component.player_index = player_index
	
	if combat_component:
		combat_component.player_index = player_index
	
	if animation_component:
		animation_component.player_index = player_index
	
	# Notify the world this player exists
	EventBus.emit_signal("player_spawned", self, player_data.player_index)

func _connect_signals() -> void:
	"""Listen to EventBus for global events"""
	if not player_data:
		push_warning("Player._connect_signals: player_data is null, deferring...")
		call_deferred("_connect_signals")
		return
	
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	
	# Listen to component signals
	if interaction_component:
		interaction_component.interact_pressed.connect(_on_interact_or_jump)
		print("Player: Connected interact_pressed signal for player ", player_data.player_index)
	else:
		push_warning("Player: interaction_component not found!")

# ========================================
# PHYSICS PROCESSING
# ========================================
func _physics_process(delta: float) -> void:
	# Movement component handles velocity
	if movement_component:
		movement_component.physics_process(delta)
	
	# Process input from all components
	if not is_in_conversation:
		if interaction_component:
			interaction_component.process_input()
		if holdable_component:
			holdable_component.process_input()
		if combat_component:
			combat_component.process_input(self)
	
	# Apply velocity to CharacterBody3D
	move_and_slide()
	
	# Update animations
	if animation_component:
		animation_component.process_animations(delta)

# ========================================
# PUBLIC API (called by external systems)
# ========================================
func set_camera(cam: Camera3D) -> void:
	"""Called by PlayerSpawner to assign camera"""
	camera = cam
	if movement_component:
		movement_component.camera = cam

func hold_item(item: Node3D) -> void:
	"""Called by Holdable objects when picked up"""
	if holdable_component:
		holdable_component.hold_item(item)

func release_item() -> void:
	"""Called by Holdable objects when dropped"""
	if holdable_component:
		holdable_component.release_item()

func init_inventory() -> void:
	"""Initialize inventory UI (called by arena after spawn)"""
	var ssm = get_tree().get_first_node_in_group("SplitScreenManager")
	if not ssm:
		push_warning("SplitScreenManager not found!")
		return
	
	var ui_layer: Control = ssm.get_ui_layer_for_player(player_data.player_index)
	if not ui_layer:
		push_warning("UI layer not found for player %d" % player_data.player_index)
		return
	
	# Find or create InventoryUI
	var inv_ui: InventoryUI = ui_layer.get_node_or_null("InventoryUI") as InventoryUI
	if not inv_ui:
		var inv_ui_scene := preload("res://player/Inventory/InventoryUI.tscn")
		inv_ui = inv_ui_scene.instantiate() as InventoryUI
		inv_ui.name = "InventoryUI"
		ui_layer.add_child(inv_ui)
	
	inventory.init(player_data, inv_ui)

# ========================================
# SIGNAL HANDLERS
# ========================================
func _on_interact_or_jump() -> void:
	"""Interaction component pressed interact - try interact first, then jump"""
	print("Player: Interact pressed! Overlapping count: ", interaction_component.overlapping_interactables.size())
	
	if interaction_component.overlapping_interactables.size() == 0:
		# No interactables nearby - jump instead
		if movement_component:
			var jumped := movement_component.request_jump()
			print("Player: Attempted jump, success: ", jumped)
	else:
		print("Player: Interacting with object instead of jumping")

func _on_dialogue_started(player_who_started: Node, timeline: String) -> void:
	"""React to ANY player starting dialogue"""
	if player_who_started == self:
		is_in_conversation = true
		if movement_component:
			movement_component.enable_movement(false)
		if combat_component:
			combat_component.enable_combat(false)

func _on_dialogue_ended(player_who_ended: Node, timeline: String) -> void:
	"""React to ANY player ending dialogue"""
	if player_who_ended == self:
		is_in_conversation = false
		if movement_component:
			movement_component.enable_movement(true)
		if combat_component:
			combat_component.enable_combat(true)
