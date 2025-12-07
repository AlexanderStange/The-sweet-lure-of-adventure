
extends Node3D
class_name Interactable

func interact(player: Node) -> void:
	push_warning("%s has no interaction defined!" % name)
