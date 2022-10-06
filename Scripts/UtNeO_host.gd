extends Node2D


var all_cards = []
var player_cards = []
var player_IDs = []

var current_card = 0
var game_started = false
var current_player = 0

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
	var player = preload("res://Prefabs/PlayerPrefab.tscn").instance()
	player.set_name("player_"+str(id))
	player_cards.append([])
	player.set_network_master(id) # Each other connected peer has authority over their own player.
	get_parent().add_child(player)
	#rpc("client_connect", id)
	rpc_id(id, "connection_established", id)

func client_disconnect(id):
	var player_id = player_IDs.find(id)
	player_IDs.erase(id)
	player_cards.remove(player_id)
	print("disconnected player ID: ",id)
	var player = get_parent().get_node("player_"+str(id))
	get_parent().remove_child(player)
	rpc("client_disconnect", id)


master func add_card(id):
	if current_player == id:
		rand = rnd.randi_range(0,9)
		
		all_cards.append(rnd)
		var player_id = player_IDs.find(id,0)
		print("player in array ID:" + str(player_id))
		player_cards[player_id].append(rand)
		print("Array: " + str(player_cards))
		
		rpc_id(id, "master_add_card", rand)
	else:
		print("not your turn")

	
master func cards_pushed(id, ops):
	if current_player == id:
		print("Player-ID: " + str(id))
		var player_id = player_IDs.find(id)
		print("player in array ID:" + str(player_id))
		var op = ops[0]
		var c1 = int(ops[1])
		var c2 = int(ops[2])
		print("Card 1 in array: " + str(player_cards[player_id].find(c1)))
		print("Card 2 in array: " + str(player_cards[player_id].find(c2)))
		if player_cards[player_id].find(c1,0)+player_cards.find(c2,0) >= -10:
			print("move possible")
			var res = -1
			match op:
				"Add":
					res = str(int(c1 + c2))
					res = res[res.length()-1]
					print(res)
				"Sub":
					res = c1-c2
					print(res)
				"Mul":
					res = str(int(c1)*int(c2))
					res = res[res.length()-1]
					print(res)
				"Div":
					res = str(int(float(c1)/c2))
					print(res)
				"Pot":
					res = str(pow(c1,c2))
					res = res[res.length()-1]
					print(res)
				"Sqr":
					res = pow(c2,float(1)/c1)
					print(res)
			if int(res) == current_card:
				rpc_id(id, "card_removed")
				current_card = rnd.randi_range(0,9)
				rset("current_card", current_card)
				
				current_player = player_IDs[(player_id+1)%player_IDs.size()]
				
		else:
			print("clientside cards don't match serverside cards")
	else:
		print("not your turn")
	

func _physics_process(delta):
	rand = rnd.randi()
	


func _on_Button_pressed():
	if not game_started:
		current_card = rnd.randi_range(0,9)
		rset("current_card", current_card)
		current_player = player_IDs[rnd.randi_range(0, player_IDs.size()-1)]
		
		for i in range(player_IDs.size()):
			for j in range(7):
				rand = rnd.randi_range(0,9)
		
				all_cards.append(rnd)
				player_cards[i].append(rand)
				rpc_id(player_IDs[i], "master_add_card", rand)
		game_started = true
		
	
	
	
	
	
