extends Control
class_name InventoryUI

func update(items: Array):
	# Clear old
	for c in get_children():
		c.queue_free()

	# Render inventory items
	for item_dict in items:
		var hbox = HBoxContainer.new()

		# Item icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = item_dict["icon"]  # ItemData.icon
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(32, 32)  # adjust as needed
		hbox.add_child(icon_rect)

		# Item name
		var name_label = Label.new()
		name_label.text = item_dict["id"]
		hbox.add_child(name_label)

		# Item quantity
		var qty_label = Label.new()
		qty_label.text = "x%d" % item_dict["qty"]
		hbox.add_child(qty_label)

		add_child(hbox)
