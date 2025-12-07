extends Node
class_name PlayerDataManager

# Preload your player data resources
var player_datas: Array[PlayerData] = [
	preload("res://player/PlayerData/PlayerData_0.tres"),
	preload("res://player/PlayerData/PlayerData_1.tres"),
	preload("res://player/PlayerData/PlayerData_2.tres"),
	preload("res://player/PlayerData/PlayerData_3.tres"),
]

func get_data_for_index(index: int) -> PlayerData:
	if index >= 0 and index < player_datas.size():
		return player_datas[index]
	push_error("No PlayerData found for index %d" % index)
	return null
