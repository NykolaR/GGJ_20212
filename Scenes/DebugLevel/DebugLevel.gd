extends Spatial

func _ready() -> void:
	return
	#var player1 : Spatial = preload("res://Scenes/FPSCharacter/FPSCharacter.tscn").instance()

	#player1.set_name(str(get_tree().get_network_unique_id()))
	#player1.set_network_master(get_tree().get_network_unique_id())

	#var player2 : Spatial = preload("res://Scenes/Ghost/Ghost.tscn").instance()
	#var player2 : Spatial = preload("res://Scenes/FPSCharacter/FPSCharacter.tscn").instance()
	#player2.set_name(str(NetHelper.player2id))
	#player2.set_network_master(NetHelper.player2id)
	#print(NetHelper.player2id)

	#add_child(player1)
	#add_child(player2)
