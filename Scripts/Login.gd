extends Node2D

var peer
var width
var height
var my_id


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().connect("size_changed", self, "resized")
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(global.ip, global.port)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	#get_tree().connect("connected_to_server", self, "connected_to_server")
	#get_tree().connect("connection_failed", self, "connection_failed")
	get_tree().connect("server_disconnected", self, "serversided_disconnect")
	resized()

func resized():
	width = get_viewport().get_visible_rect().size.x
	height = get_viewport().get_visible_rect().size.y

func serversided_disconnect():
	print("Server disconnected")
	get_tree().network_peer = null
	peer.close_connection()
	get_tree().change_scene("res://Scenes/LobbyScene.tscn")

puppet func connection_established(id):
	my_id = id
	print("Connection succsess")
	rpc_id(1, "set_player_name", global.username, my_id)
	remove_child(get_node("Overlay"))




func Login():
	var username = get_node("Login/Username").text
	var pwd = get_node("Login/Pasword").text
	var hashpwd = (username+pwd).sha256_text()
	rpc_id(1, "login", my_id, username, hashpwd)

puppet func Login_return(worked):
	if(worked):
		get_tree().change_scene("res://Scenes/UtNeO_client.tscn")


func Register():
	var username = get_node("Register/Username").text
	var email = get_node("Register/email").text
	var pwd = get_node("Register/Pasword").text
	print("first")
	if pwd == get_node("Register/Pasword2").text:
		print("second")
		var hashpwd = (username+pwd).sha256_text()
		rpc_id(1, "register", my_id, username, hashpwd, email)

puppet func Register_return(worked):
	if(worked):
		get_tree().change_scene("res://Scenes/UtNeO_client.tscn")
