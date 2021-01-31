extends Spatial

const testPossessable = preload("res://Scenes/Possessable/Possessables/TestPossessable.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in $Spawns.get_children():
		var newPossessable = testPossessable.instance()
		#newPossessable.rotate_y(rand.range(0,pi))
		add_child(newPossessable)
		newPossessable.global_transform = child.global_transform


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
