extends Node

var n : OpenSimplexNoise = OpenSimplexNoise.new()
var time : float = 0.0

func _ready() -> void:
	randomize()
	n.seed = randi()
	n.period = 8.0

# increase the time var. Wraps the float juuuuuuust in case they play for over 10 million seconds to prevent INF
func _process(delta: float) -> void:
	time += delta
	time = wrapf(time, -10000000, 10000000)

func get_noise_normalized(value : float) -> float:
	return (n.get_noise_1d(value + time) - 0.5)
