extends Node
class_name Inventory

var player_data: PlayerData
var inv_ui: InventoryUI

func init(p_data: PlayerData, ui: InventoryUI):
	player_data = p_data
	inv_ui = ui
	_refresh_ui()

func add_item(item: ItemData, amount: int = 1) -> bool:
	# Find existing item
	for entry in player_data.inventory_items:
		if entry["item"] == item:
			entry["amount"] += amount
			_refresh_ui()
			return true
	
	# If not found, add new entry
	player_data.inventory_items.append({"item": item, "amount": amount})
	_refresh_ui()
	return true

func _refresh_ui():
	if not inv_ui:
		return

	var items_for_ui: Array = []
	for entry in player_data.inventory_items:
		items_for_ui.append({
			"id": entry["item"].display_name,
			"icon": entry["item"].icon,  # use your texture here
			"qty": entry["amount"]
		})

	inv_ui.update(items_for_ui)
