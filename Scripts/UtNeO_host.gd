extends Node2D


var all_cards = []
var player_cards = [[]]
var player_IDs = []

var peer = null


var rnd = RandomNumberGenerator.new()
var rand = 0

func _ready():
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(global.port, 5)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	print(get_tree().get_network_peer())
	print(get_tree().is_network_server())
	get_tree().connect("network_peer_connected", self, "client_connect")
	get_tree().connect("network_peer_disconnected", self, "client_disconnect")
	#get_viewport().connect("size_changed", self, "resized")

func client_connect(id):
	print("connected player ID: ",id)
	player_IDs.append(id)
	rset_id(id, "my_id", id)
	var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
	player.set_name("player_"+str(id))
	player.set_network_master(id) # Each other connected peer has authority over their own player.
	get_parent().add_child(player)
	rpc("client_connect", id)
	rpc_id(id, "connection_established", id)

func client_disconnect(id):
	player_IDs.erase(id)
	print("disconnected player ID: ",id)
	var player = get_parent().get_node("player_"+str(id))
	get_parent().remove_child(player)
	rpc("client_disconnect", id)


master func add_card(id):
	rand = rnd.randi_range(0,9)
	
	all_cards.append(rnd)
	var player_id = player_IDs.find(id,0)
	player_cards[player_id].append(rnd)
	print(id)
	
	rpc_id(id, "master_add_card", rand)
	

	
master func cards_pushed(id, ops):
	print(id)
	var player_id = player_IDs.find(id)
	print(player_id)
	var op = ops[0]
	var c1 = ops[1]
	var c2 = ops[2]
	print(player_cards[player_id].find(c1))
	if player_cards[player_id].find(c1,0)+player_cards.find(c2,0) >= 0:
		print("move possible")
		match op:
			"Add":
				print(int(c1)+int(c2))
			"Sub":
				print(int(c1)-int(c2))
			"Mul":
				print(int(c1)*int(c2))
			"Div":
				print(int(c1)/int(c2))
			"Pot":
				print(pow(c1,c2))
	else:
		print("clientside cards don't match serverside cards")
	
	
	

func hand_card_pressed(card):
	print(card.name)
	var value = card.name.split("_")
	print(int(value[1]))

func button_pressed(switch):
	print(switch)

func _physics_process(delta):
	rand = rnd.randi()
	
