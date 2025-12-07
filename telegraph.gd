extends Area3D
class_name Telegraph

@export var owner_actor: CombatActor = null
@export var damage: int = 10
@export var duration: float = 0.75
@export var shape_size: Vector3 = Vector3(2, 0.2, 2)
@export var color: Color = Color(1, 0, 0, 0.45)

var _timer: Timer

func _ready() -> void:
	monitoring = true
	monitorable = true

	# CollisionShape
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = shape_size
	shape.shape = box
	add_child(shape)

	# Mesh for visual telegraph
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = shape_size
	mesh_instance.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_unshaded = true
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	# Timer
	_timer = Timer.new()
	_timer.wait_time = duration
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	_timer.start()

func _on_timeout() -> void:
	for body in get_overlapping_bodies():
		if body is CombatActor and body != owner_actor:
			body.take_damage(damage)
			print("%s hit %s for %d damage" % [owner_actor.name, body.name, damage])

	queue_free()
