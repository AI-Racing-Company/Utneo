extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var peer = null
var peer_id = 0
var is_connected = false
var my_id = 0

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
	print("fresh id:",id)
	peer_id = id
	rset("my_id", id)
	var player = preload("res://PlayerPrefab.tscn").instance()
	player.set_name("player_"+str(id))
	player.set_network_master(id) # Each other connected peer has authority over their own player.
	get_parent().add_child(player)
	
func client_disconnect(id):
	print("conn")
	print("gone id:",id)

func _on_Client_pressed():
	if not is_connected:
		print("Client")
		peer = NetworkedMultiplayerENet.new()
		peer.create_client("192.168.43.116", 7777)
		get_tree().network_peer = peer
		print(get_tree().network_peer)
		is_connected = true
	
func connection_failed():
	print("FAIL")

remote func test():
	print("BigBoiiiiiiii")
	
master func move(id, w, a, s, d):
	get_parent().get_node("player_" + str(id)).move(w,a,s,d)

func _on_Host_pressed():
	print("Host")
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(7777, 5)
	get_tree().network_peer = peer
	print(get_tree().get_network_peer())
	print(get_tree().is_network_server())
	get_tree().connect("network_peer_connected", self, "client_connect")
	get_tree().connect("network_peer_disconnected", self, "client_disconnect")

func _physics_process(delta):
	if is_connected:
		rpc_id(1, "move", my_id, Input.is_key_pressed(KEY_W), Input.is_key_pressed(KEY_A), Input.is_key_pressed(KEY_S), Input.is_key_pressed(KEY_D))

func _on_PRESS_pressed():
	rpc_id(peer_id, "test")


func _on_Disconnect_pressed():
	get_tree().network_peer = null
