extends StaticBody
class_name Possessable

onready var center : Position3D = $Center

var n : Vector3 = Vector3()
var magnitude : float = 0.0

func _ready() -> void:
	#set_process(false)
	n = Vector3(rand_range(-1000000,1000000), rand_range(-1000000,1000000), rand_range(-1000000, 1000000))

func possess(value : bool) -> void:
	set_process(value)
	if not value:
		magnitude = 0.0

func _process(delta: float) -> void:
	rotation = Vector3(Time.get_noise_normalized(n.x), Time.get_noise_normalized(n.y), Time.get_noise_normalized(n.z)) * magnitude
