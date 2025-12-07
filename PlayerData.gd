extends Resource
class_name PlayerData

@export var player_index: int
@export var controller_id: int
@export var inventory_size: int = 20

# Base stats (growth + scaling)
@export var base_stats: Dictionary = {
	"strength": 5,
	"intelligence": 5,
	"magic": 5,
	"speed": 5,
	"defense": 5,
	"vitality": 5
}

# Stateful values (tracked during gameplay)
@export var level: int = 1
@export var xp: int = 0

@export var max_health: int
@export var health: int 

@export var max_mana: int 
@export var mana: int 

# Inventory & equipment
@export var inventory_items: Array = [] # [{"item": ItemData, "amount": int}]
@export var equipment: Dictionary = {}  # {"weapon": null, "armor": null}
