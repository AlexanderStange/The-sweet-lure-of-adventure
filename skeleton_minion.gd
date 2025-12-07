
extends CharacterBody3D

# --- Condition States ---
var is_attacking = false
var is_running = false
var is_dying = false
var is_dead = false
var is_ressurecting = false
var is_sleeping = false
var is_awakening = false


@onready var combat_actor: CombatActor = $CombatActor
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/playback")

func _ready() -> void:
	# Connect to the CombatActor's signal
	combat_actor.dying.connect(_on_dying)

func _physics_process(float) -> void:
	# Animation switching
	if is_dying:
		playback.travel("Death_C_Skeletons")
	elif is_attacking:
		is_attacking = false
	elif is_running:
		playback.travel("Running_A")
	else:
		playback.travel("Idle")

	set_anim_condition("IsRunning", is_running)

	

func set_anim_condition(name: String, value: bool) -> void:
	animation_tree.set("parameters/conditions/%s" % name, value)
	
func _on_dying() -> void: 
	is_dying = true
	
