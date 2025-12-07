extends MeshInstance3D

@onready var blade = $building_windmill_top_green/building_windmill_top_fan_green
@export var speed : Vector3 = Vector3(0,0,75)  
# Called when the node enters the scene tree for the first time.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	blade.rotation_degrees += speed * delta 
