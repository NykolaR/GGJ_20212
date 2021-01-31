extends Control

var ip : String = "127.0.0.1"
const PORT : int = 8584

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")

func _host_pressed():
	var net : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	net.create_server(PORT, 2)
	get_tree().network_peer = net
	print("hosting")

func _join_pressed():
	var net : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
	net.create_client(ip, PORT)
	get_tree().network_peer = net

func _player_connected(id : int) -> void:
	NetHelper.player2id = id
	visible = false

	var game : Spatial = load("res://Scenes/DebugLevel/DebugLevel.tscn").instance()
	add_child(game)
	get_parent().set_label()
