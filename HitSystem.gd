extends Area3D
class_name HitZone 
@export var owner_actor: CombatActor
@export var damage: int = 10
@export var duration: float = 0.5 

func _ready():
	$CollisionShape3D.disabled = false 
	$"../Timer".start(duration) 
	
func _on_body_entered(body):
	if body is CombatActor and body != owner_actor:
		body.take_damage(damage, owner_actor)

func _on_Timer_timeout():
	queue_free()
