extends RigidBody3D
class_name Pickable

@export var item_data: ItemData
@export var amount: int = 1

func interact(player: Player) -> void:
	if player.inventory and player.inventory.has_method("add_item"):
		if player.inventory.add_item(item_data, amount):
			queue_free()
