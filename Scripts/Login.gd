extends Node2D

var peer
var width
var height


var nue


# Called when the node enters the scene tree for the first time.
func _ready():
	nue = get_viewport().connect("size_changed", self, "resized")
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(global.ip, global.port)
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	nue = get_tree().connect("server_disconnected", self, "serversided_disconnect")
	resized()

func resized():
	width = get_viewport().get_visible_rect().size.x
	height = get_viewport().get_visible_rect().size.y

func serversided_disconnect():
	print("Server disconnected")
	get_tree().network_peer = null
	peer.close_connection()
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")

puppet func connection_established(id):
	global.my_id = id[0]
	print("Connection succsess")
	remove_child(get_node("Overlay"))

puppet func connection_established_DELETE(id, x):
	global.my_id = id
	print("Connection succsess")
	remove_child(get_node("Overlay"))
	get_node("Login/Username").text = str(x)
	get_node("Login/Pasword").text = str(x)


func Login():
	print("Login function called")
	var username = "" + get_node("Login/Username").text
	var pwd = "" + get_node("Login/Pasword").text
	var hashpwd = (username+pwd).sha256_text()
	var time = PoolStringArray(OS.get_time().values()).join("")
	hashpwd = (hashpwd+time).sha256_text()
	rpc_id(1, "login", global.my_id, username, hashpwd, time)

puppet func Login_return(worked, login_key):
	if(worked):
		global.login_key = login_key
		nue = get_tree().change_scene("res://Scenes/UtNeO_client.tscn")


func Register():
	var username = "" + get_node("Register/Username").text
	var email = "" + get_node("Register/email").text
	var pwd = "" + get_node("Register/Pasword").text
	if pwd == "" + get_node("Register/Pasword2").text:
		var hashpwd = (username+pwd).sha256_text()
		rpc_id(1, "register", global.my_id, username, hashpwd, email)

puppet func Register_return(worked, login_key):
	if(worked):
		global.login_key = login_key
		nue = get_tree().change_scene("res://Scenes/UtNeO_client.tscn")


func _on_Button_pressed():
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")
