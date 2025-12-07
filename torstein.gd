extends NPCDialogue

@export var dropoff_required: NodePath

func interact(player):
	var dropoff: DropOffSpot = get_node_or_null(dropoff_required)
	
	if dropoff and dropoff.condition_met:
		dialogue(player, "torstein_apple" )
	else:
		dialogue(player, "Torstein_timeline")
