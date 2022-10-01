extends Node2D

var peer = null
var peer_id = 0

func _ready():
	global.ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(global.port, 5)
	get_tree().network_peer = peer
	print(get_tree().get_network_peer())
	print(get_tree().is_network_server())
	get_tree().connect("network_peer_connected", self, "client_connect")
	get_tree().connect("network_peer_disconnected", self, "client_disconnect")

master func connection_established():
	return true

func client_connect(id):
	print("connected player ID: ",id)
	peer_id = id
	rset_id(id, "my_id", id)
	var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
	player.set_name("player_"+str(id))
	player.set_network_master(id) # Each other connected peer has authority over their own player.
	get_parent().add_child(player)

func client_disconnect(id):
	print("disconnected player ID: ",id)

master func move(id, w, a, s, d):
	get_parent().get_node("player_" + str(id)).get_node("player").move(w,a,s,d)
