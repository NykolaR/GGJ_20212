extends Spatial

const testPossessable = preload("res://Scenes/Possessable/Possessables/TestPossessable.tscn")

func _ready():
	for child in $Spawns.get_children():
		var newPossessable = testPossessable.instance()
		#newPossessable.rotate_y(rand.range(0,pi))
		add_child(newPossessable)
		newPossessable.global_transform = child.global_transform
