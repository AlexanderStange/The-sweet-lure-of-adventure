extends CombatActor
class_name Enemy

@export var enemy_data: EnemyData

func _ready():
	health = enemy_data.max_health
	max_health = enemy_data.max_health

func _die(source: CombatActor):
	emit_signal("died", self)
	print("%s defeated by %s" % [enemy_data.name, source])
	queue_free()
