extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var peer = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Client_pressed():
	print("Client")
	peer = NetworkedMultiplayerENet.new()
	peer.create_client("192.168.43.116", 7777)
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	
func connection_failed():
	print("FAIL")


func _on_Host_pressed():
	print("Host")
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(7777, 5)
	get_tree().network_peer = peer
	print(get_tree().get_network_peer())
	print(get_tree().is_network_server())
