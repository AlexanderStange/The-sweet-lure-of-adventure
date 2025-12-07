class_name Stats
extends Node

var player_data: PlayerData

func init(data: PlayerData):
	player_data = data

func get_stat(stat: String) -> int:
	var base = player_data.base_stats.get(stat, 0)
	var bonus = 0
	
	# Add bonuses from equipment
	for item in player_data.equipment.values():
		if item and item.stat_modifiers.has(stat):
			bonus += item.stat_modifiers[stat]
	
	return base + bonus
