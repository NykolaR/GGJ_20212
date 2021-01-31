extends Node

onready var tween : Tween = $Tween
onready var black : ColorRect = $ColorRect

func _ready() -> void:
	fade_in()

func fade_in() -> void:
	tween.stop_all()
	tween.interpolate_property(black, "color:a", black.color.a, 0.0, 1.0, Tween.TRANS_EXPO, Tween.EASE_IN)
	tween.start()

func fade_out() -> void:
	tween.stop_all()
	tween.interpolate_property(black, "color:a", black.color.a, 1.0, 1.0, Tween.TRANS_EXPO, Tween.EASE_IN)
	tween.start()

func set_label():
	$Label.text = str(get_tree().get_network_unique_id()) + "\n" + str(NetHelper.player2id)
