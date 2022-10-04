extends Node2D


var peer = null
var peer_id = 0
var playerPos = {}

var player_IDs = []

#test

func _ready():
	global.ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(global.port, 5)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	print(get_tree().get_network_peer())
	print(get_tree().is_network_server())
	get_tree().connect("network_peer_connected", self, "client_connect")
	get_tree().connect("network_peer_disconnected", self, "client_disconnect")
	get_viewport().connect("size_changed", self, "resized")


func resized():
	get_node("Disconnect").set_global_position(Vector2(get_viewport().get_visible_rect().size.x - 100,5))

master func connection_established():
	return true

func client_connect(id):
	print("connected player ID: ",id)
	peer_id = id
	player_IDs.append(id)
	rset_id(id, "my_id", id)
	var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
	player.set_name("player_"+str(id))
	player.set_network_master(id) # Each other connected peer has authority over their own player.
	get_parent().add_child(player)
	rpc("client_connect", id)

func client_disconnect(id):
	player_IDs.erase(id)
	print("disconnected player ID: ",id)
	var player = get_parent().get_node("player_"+str(id))
	get_parent().remove_child(player)
	rpc("client_disconnect", id)

master func move(id, w, a, s, d):
	var player = get_parent().get_node("player_" + str(id)).get_node("player")
	player.move(w,a,s,d)
	playerPos[str(id)] = player.get_global_position()
	rpc("player_pos_change", id, playerPos[str(id)])
	

master func getPos(id):
	rset_id(id,"playerPos",playerPos)


func _on_Disconnect_pressed():
	print("Disconnect all clients")
	rpc("serversided_disconnect", true)
	print("sent message to all connected clients")
	
	for i in player_IDs:
		var player = get_parent().get_node("player_"+str(i))
		get_parent().remove_child(player)
	player_IDs.clear()
	get_tree().network_peer = null
	peer.close_connection()
	
	get_tree().change_scene("res://Scenes/TestScene.tscn")


	
