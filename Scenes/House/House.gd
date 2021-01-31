extends Spatial

const testPossessable = preload("res://Scenes/Possessable/Possessables/TestPossessable.tscn")
const PossessableFactory : PackedScene = preload("res://Scenes/Possessable/PossessableFactory.tscn")

# since we're seeding different RNG, generate level through host and pass to clients
func _ready():
	if true or is_network_master():
		var factory : Array = PossessableFactory.instance().get_children()
		for child in $Spawns.get_children():
			var newPossessable = factory[randi()%factory.size()].duplicate()
			#var newPossessable = testPossessable.instance()
			#newPossessable.rotate_y(rand.range(0,pi))
			
			add_child(newPossessable)
			newPossessable.global_transform = child.global_transform
			newPossessable.rotate_y(rand_range(0, 2*PI))
			
			# TODO
			#rpc("add_factory_child", child, newPossessable, rand_range(0, 2*PI))

remotesync func add_factory_child(spawn : Spatial, child : Spatial, rot : float) -> void:
	add_child(child)
	child.global_transform = spawn.global_transform
	child.rotate_y(rot)
