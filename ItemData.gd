class_name ItemData
extends Resource

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var max_stack: int = 1
@export var stat_modifiers: Dictionary = {}  # {"strength": +2, "magic": -1}
@export var type: String = "misc"  # misc, weapon, armor, consumable, etc
