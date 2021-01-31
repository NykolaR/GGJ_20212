extends Node

func _enter_tree() -> void:
	randomize()
	var game : Node = load("res://Scenes/Network/lobby.tscn").instance()

	get_parent().call_deferred("add_child", game)
	self.queue_free()
