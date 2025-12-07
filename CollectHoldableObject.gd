# CollectHoldableObject.gd
extends Node3D
class_name CollectHoldableObject

@export var holdable_scene: PackedScene   # The item to give (Apple.tscn, Bomb.tscn, etc.)
@export var max_items: int = -1           # -1 = infinite
var given_items: int = 0


func interact(player: Player) -> void:
	if max_items >= 0 and given_items >= max_items:
		return  # Out of stock
	
	if not holdable_scene:
		push_warning("No holdable_scene assigned on %s" % name)
		return

	# Create the item
	var item = holdable_scene.instantiate()
	get_tree().current_scene.add_child(item)

	# Position item near barrel (so it's not spawned at (0,0,0))
	item.global_transform.origin = global_transform.origin + Vector3(0, 1, 0)

	# If it's a Holdable, automatically pick it up
	if item.has_method("pickup"):
		item.pickup(player)

	given_items += 1
