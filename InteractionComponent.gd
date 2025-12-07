# ========================================
# res://player/components/InteractionComponent.gd
# ========================================
# Detects nearby interactable objects (NPCs, chests, doors, barrels)
# Handles A button press to interact
# Finds nearest interactable if multiple are overlapping
# ========================================

extends Node
class_name InteractionComponent

# ========================================
# EXPORTS
# ========================================
@export var interaction_detector_path: NodePath = "InteractionDetector"

# ========================================
# SIGNALS
# ========================================
signal interact_pressed()
signal interactable_found(interactable: Node)
signal interactable_lost(interactable: Node)

# ========================================
# STATE
# ========================================
var overlapping_interactables: Array = []
var interaction_enabled := true
var interact_button_pressed_last_frame := false
var interaction_prompt: InteractionPrompt = null  # NEW

# ========================================
# REFERENCES
# ========================================
var interaction_detector: Area3D
var player: Node  # Reference to parent player
var player_index: int = 0

# ========================================
# INITIALIZATION
# ========================================
func _ready() -> void:
	player = get_parent()
	call_deferred("_setup_detector")

func _setup_detector() -> void:
	interaction_detector = player.get_node_or_null(interaction_detector_path) as Area3D
	if interaction_detector:
		interaction_detector.body_entered.connect(_on_body_entered)
		interaction_detector.body_exited.connect(_on_body_exited)
	else:
		push_warning("InteractionDetector not found at path: %s" % interaction_detector_path)
	
	# Setup interaction prompt UI
	_setup_interaction_prompt()

func _setup_interaction_prompt() -> void:
	# Get the split screen manager to add UI to player's viewport
	var ssm = player.get_tree().get_first_node_in_group("SplitScreenManager")
	if not ssm:
		push_warning("SplitScreenManager not found!")
		return
	
	var ui_layer: Control = ssm.get_ui_layer_for_player(player_index)
	if not ui_layer:
		push_warning("UI layer not found for player %d" % player_index)
		return
	
	# Instantiate the interaction prompt
	var prompt_scene = load("res://ui/InteractionPrompt.tscn")
	if prompt_scene:
		interaction_prompt = prompt_scene.instantiate() as InteractionPrompt
		interaction_prompt.player_index = player_index
		ui_layer.add_child(interaction_prompt)

# ========================================
# PUBLIC API
# ========================================
func enable_interaction(enabled: bool) -> void:
	"""Disable during dialogue, cutscenes, etc."""
	interaction_enabled = enabled

func get_nearest_interactable() -> Node:
	"""Returns the closest interactable object"""
	if overlapping_interactables.size() == 0:
		return null
	
	var nearest = overlapping_interactables[0]
	var nearest_dist: float = player.global_position.distance_to(nearest.global_position)
	
	for interactable in overlapping_interactables:
		var dist: float = player.global_position.distance_to(interactable.global_position)
		if dist < nearest_dist:
			nearest = interactable
			nearest_dist = dist
	
	return nearest

func try_interact() -> bool:
	"""Attempts to interact with nearest object. Returns true if successful."""
	if not interaction_enabled:
		print("InteractionComponent: Interaction disabled")
		return false
	
	var nearest := get_nearest_interactable()
	if nearest and nearest.has_method("interact"):
		print("InteractionComponent: Interacting with ", nearest.name, " (", nearest.get_class(), ")")
		nearest.interact(player)
		print("InteractionComponent: Emitting interact_pressed signal")
		emit_signal("interact_pressed")
		EventBus.emit_signal("interaction_started", player, nearest)
		return true
	
	# No interactable found - still emit signal for jump
	print("InteractionComponent: No interactable, emitting interact_pressed for jump")
	emit_signal("interact_pressed")
	return false

# ========================================
# INPUT PROCESSING
# ========================================
func process_input() -> void:
	var interact_pressed := Input.is_joy_button_pressed(player_index, JOY_BUTTON_A)
	
	# Only trigger on button press (not hold)
	if interact_pressed and not interact_button_pressed_last_frame:
		print("InteractionComponent: A button pressed for player ", player_index)
		try_interact()
	
	interact_button_pressed_last_frame = interact_pressed

# ========================================
# DETECTION CALLBACKS
# ========================================
func _on_body_entered(body: Node) -> void:
	if body.has_method("interact"):
		overlapping_interactables.append(body)
		emit_signal("interactable_found", body)
		_update_prompt()

func _on_body_exited(body: Node) -> void:
	if body.has_method("interact"):
		overlapping_interactables.erase(body)
		emit_signal("interactable_lost", body)
		_update_prompt()

func _update_prompt() -> void:
	"""Show/hide interaction prompt based on what's nearby"""
	if not interaction_prompt:
		return
	
	if overlapping_interactables.size() > 0:
		var nearest := get_nearest_interactable()
		var prompt_text := "Interact"
		
		# Customize text based on object type
		if nearest is Holdable:
			if nearest.is_held:
				prompt_text = "Drop"
			else:
				prompt_text = "Pick Up"
		elif nearest is Pickable:
			prompt_text = "Pick Up"
		elif nearest is NPCDialogue:
			prompt_text = "Talk"
		elif nearest is CollectHoldableObject:
			prompt_text = "Collect"
		
		interaction_prompt.show_prompt(prompt_text)
	else:
		interaction_prompt.hide_prompt()
