extends Node3D

@export var body_entered_reciever = ""
# Called when the node enters the scene tree for the first time.

func on_body_entered(body):
	if body.has_node(body_entered_reciever):
		body.get_node(body_entered_reciever).on_body_entered(self)
