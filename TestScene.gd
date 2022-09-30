extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var peer = null
var peer_id = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func connected_to_server():
	print("am connected")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func client_connect(id):
	print("conn")
	print("fresh id:" + id)
	peer_id = id

func _on_Client_pressed():
	print("Client")
	peer = NetworkedMultiplayerENet.new()
	peer.create_client("192.168.43.116", 7777)
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	
func connection_failed():
	print("FAIL")

func test():
	print("BigBoiiiiiiii")

func _on_Host_pressed():
	print("Host")
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(7777, 5)
	get_tree().network_peer = peer
	print(get_tree().get_network_peer())
	print(get_tree().is_network_server())
	get_tree().connect("network_peer_connected", self, "client_connect")


func _on_PRESS_pressed():
	rpc_id(peer_id, "test")


func _on_Disconnect_pressed():
	get_tree().network_peer = null
