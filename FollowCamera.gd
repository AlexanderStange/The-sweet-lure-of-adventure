extends Camera3D

@export var follow_distance := Vector3(0, 4, -6)
@export var follow_speed := 5.0
@export var look_at_offset := Vector3.ZERO
@export var screen_index := 0

var target: Node3D

func _ready():
	keep_aspect = Camera3D.KEEP_WIDTH  # Maintains horizontal FOV consistency

func _process(delta):
	if not is_instance_valid(target):
		return

	# Follow player position (but not rotation)
	var desired_position = target.global_transform.origin + follow_distance
	global_transform.origin = global_transform.origin.lerp(desired_position, follow_speed * delta)

	# FIXED angle - always look at player from the same direction
	look_at(target.global_transform.origin + look_at_offset, Vector3.UP)
