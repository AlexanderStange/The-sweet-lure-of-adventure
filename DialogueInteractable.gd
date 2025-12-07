# InteractableDialogue.gd
extends Interactable

@export var dialogue_timeline_name: String = "Torstein_timeline"

func on_interact(player: Player) -> void:
	if dialogue_timeline_name != "":
		# Assuming you have a Dialogic wrapper function that accepts a player to handle split screen
		Dialogic.start_timeline_for_player(dialogue_timeline_name, player)
