extends RigidBody3D
class_name Holdable

@export var attach_point_name := "Hand"  # name of the node in Player to attach to
@export var item_type: String = "item"   # could be "apple", "rock", etc.

var is_held := false
var holder: Player = null

func interact(player: Player) -> void:
	if not is_held:
		pickup(player)
	else:
		drop(player)
		

func pickup(player: Player) -> void:
	is_held = true
	holder = player
	
	freeze = true  # freeze physics
	collision_layer = 0
	collision_mask = 0
	var hand = player.get_node("Knight/Hand")
	if hand:
		reparent(hand)
		transform = Transform3D.IDENTITY 
		global_transform = hand.global_transform
		
	player.hold_item(self)
func drop(player: Player) -> void:

	if holder:
		reparent(get_tree().current_scene)
		freeze = false  # unfreeze physics
		collision_layer = 1
		collision_mask = 1
		linear_velocity =  Vector3(0.1, 3, 0.1)
		holder = null
		is_held = false
		player.release_item()
