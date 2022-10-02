extends Node2D


var peer = null

var is_connected = false
puppet var my_id = null

var playerPos = {}

func _ready():
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(global.ip, global.port)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	get_node("ClientText").text = "Connected To " + global.ip + ":" + str(global.port)
	is_connected = true
	get_tree().connect("connected_to_server", self, "connected_to_server")
	get_tree().connect("connection_failed", self, "connection_failed")



func connected_to_server():
	print("am connected")



func _physics_process(delta):
	if is_connected:
		var w = Input.is_key_pressed(KEY_W)
		var a = Input.is_key_pressed(KEY_A)
		var s = Input.is_key_pressed(KEY_S)
		var d = Input.is_key_pressed(KEY_D)
		if w or a or s or d:
			rpc_id(1, "move", my_id, w, a, s, d)

puppet func player_pos_change(id, pos):
	playerPos[str(id)] = pos
	if get_parent().get_node("player_"+str(id)) == null:
		var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
		player.set_name("player_"+ str(id))
		get_parent().add_child(player)
		print("created player")
	get_parent().get_node("player_"+str(id)).get_node("player").set_global_position(pos)

puppet func client_connect(id):
	var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
	player.set_name("player_"+str(id))
	get_parent().add_child(player)

puppet func client_disconnect(id):
	var player = get_parent().get_node("player_"+str(id))
	get_parent().remove_child(player)


func _on_PRESS_pressed():
	rpc_id(1, "test")

func _on_Disconnect_pressed():
	get_tree().network_peer = null

func connection_failed():
	print("Failed to connect to server...")
	get_tree().change_scene("res://Scenes/TestScene.tscn")

remote func test():
	print("BigBoiiiiiiii")
