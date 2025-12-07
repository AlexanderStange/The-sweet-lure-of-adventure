extends Area3D
class_name DropOffSpot

@export var required_item: String = "golden_apple"
@export var required_count: int = 3

var item_count: int = 0
var condition_met: bool = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node):
	if body is Holdable and not body.is_held:
		if body.item_type == required_item:
			item_count += 1
			print("Dropped %s! Total: %d" % [required_item, item_count])



			if item_count >= required_count and !condition_met:
				condition_met = true
				print(condition_met)
				print("✅ Requirement met: %d %s(s)" % [required_count, required_item])
