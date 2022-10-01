extends Node2D

var peer = null

var is_connected = false
puppet var my_id = 0

func _ready():
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(global.ip, global.port)
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	is_connected = true
	get_tree().connect("connected_to_server", self, "connected_to_server")
	get_tree().connect("connection_failed", self, "connection_failed")



func connected_to_server():
	print("am connected")
	var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
	player.set_name("player")
	get_parent().add_child(player)


func _physics_process(delta):
	if is_connected:
		var w = Input.is_key_pressed(KEY_W)
		var a = Input.is_key_pressed(KEY_A)
		var s = Input.is_key_pressed(KEY_S)
		var d = Input.is_key_pressed(KEY_D)
		if w or a or s or d:
			get_parent().get_node("player").get_node("player").move(w,a,s,d)
			rpc_id(1, "move", my_id, w, a, s, d)

func _on_PRESS_pressed():
	rpc_id(1, "test")

func _on_Disconnect_pressed():
	get_tree().network_peer = null

func connection_failed():
	print("Failed to connect to server...")
	get_tree().change_scene("res://Scenes/TestScene.tscn")

remote func test():
	print("BigBoiiiiiiii")
