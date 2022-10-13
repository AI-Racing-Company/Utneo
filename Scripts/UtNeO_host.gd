extends Node2D


var all_cards = []
var player_cards = []
var player_IDs = []
var player_names = {}

var current_card = 0
var game_started = false
var current_player = 0

var peer = null


var rnd = RandomNumberGenerator.new()
var rand = 0

var r_t = 60 # round time

onready var timer = get_node("Timer") 

func _ready():
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	get_node("ClientConnect").text = "Connected Clients: 0"
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
	player_cards.append([])
	#rpc("client_connect", id)
	rpc_id(id, "connection_established", id)
	rpc_id(id, "r_t", r_t)
	set_client_text()

func client_disconnect(id):
	if id == current_player:
		next_player()
	var player_id = player_IDs.find(id)
	player_IDs.erase(id)
	player_cards.remove(player_id)
	print("disconnected player ID: ",id)
	var player = get_parent().get_node("player_"+str(id))
	get_parent().remove_child(player)
	rpc("client_disconnect", id)
	set_client_text()


master func add_card(id):
	if current_player == id:
		rand = rnd.randi_range(0,9)
		
		all_cards.append(rnd)
		var player_id = player_IDs.find(id,0)
		print("player in array ID:" + str(player_id))
		player_cards[player_id].append(rand)
		print("Array: " + str(player_cards))
		
		rpc_id(id, "master_add_card", rand)
		next_player()
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
		var ex1 = player_cards[player_id].find(c1)
		var ex2 = player_cards[player_id].find(c2)
		print("Card 1 in array: " + str(ex1))
		print("Card 2 in array: " + str(ex2))
		if ex2 >= 0 && ex2 >= 0:
			print(player_cards[player_id].count(c1))
			if c1 == c2 && player_cards[player_id].count(c1) < 2:
				return null
			print("move possible")
			var res = -1
			match op:
				" + ":
					res = str(int(c1 + c2))
					res = res[res.length()-1]
					print(res)
				" - ":
					res = c1-c2
					print(res)
				" * ":
					res = str(int(c1)*int(c2))
					res = res[res.length()-1]
					print(res)
				" / ":
					res = str(int(float(c1)/c2))
					print(res)
				" ^ ":
					res = str(pow(c1,c2))
					res = res[res.length()-1]
					print(res)
				" √ ":
					res = pow(c2,float(1)/c1)
					print(res)
			if int(res) == current_card:
				rpc_id(id, "card_removed")
				player_cards[player_id].remove(c1)
				player_cards[player_id].remove(c2)
				current_card = c2
				rpc("set_current_card", current_card)
				set_client_text()
				next_player()
				
				
		else:
			print("clientside cards don't match serverside cards")
	else:
		print("not your turn")
	

func _physics_process(delta):
	rand = rnd.randi()
	


func _on_Button_pressed():
	if not game_started && player_IDs.size()>0:
		current_card = rnd.randi_range(0,9)
		rpc("set_current_card", current_card)
		var randplay = rnd.randi_range(0, player_IDs.size()-1)
		current_player = player_IDs[randplay]
		rset_id(current_player, "my_turn", true)
		timer.start(r_t)
		rpc_id(current_player, "startGame")
		
		for i in range(player_IDs.size()):
			for j in range(7):
				rand = rnd.randi_range(0,9)
				all_cards.append(rnd)
				player_cards[i].append(rand)
				rpc_id(player_IDs[i], "master_add_card", rand)
		game_started = true
		set_client_text()
		
func next_player():
	
	rpc_id(current_player, "endOfRound")
	current_player = player_IDs[(player_IDs.find(current_player)+1)%player_IDs.size()]
	rset("my_turn", false)
	rset_id(current_player, "my_turn", true)
	rpc_id(current_player, "startOfRound")
	timer.start(r_t)
	set_client_text()

func _on_Timer_timeout():
	rpc_id(current_player, "endOfRound")
	next_player()

master func set_player_name(nme, id):
	print(nme)
	var insnme = nme
	while player_names.values().find(insnme) > 0:
		insnme = nme + str(rnd.randi())
	player_names[id] = insnme
	set_client_text()

func set_client_text():
	var sendstr = ""
	get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size())
	for i in player_names:
		print(i)
		get_node("ClientConnect").text = str(get_node("ClientConnect").text) + "\n" + str(player_names[i])
		if game_started:
			sendstr = sendstr + str(player_names[i]) + ": " + str(player_cards[player_IDs.find(i)].size()) + "\n" 
		else:
			sendstr = sendstr  + str(player_names[i]) + "\n"
	rpc("update_player_list", sendstr)


