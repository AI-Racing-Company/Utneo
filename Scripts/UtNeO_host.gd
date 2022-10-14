extends Node2D


var all_cards = []
var player_cards = []
var player_IDs = []
var player_names = {}
var players_ignore = []

var win = [false, false] # 0= Player won, 1 = Continue after player win

var current_card = 0
var game_started = false
var current_player = 0

var peer = null


var rnd = RandomNumberGenerator.new()
var rand = 0

var r_t = 60 # round time

onready var timer = get_node("Timer")

func _ready():
	get_viewport().connect("size_changed", self, "resized")
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	get_node("ClientConnect").text = "Connected Clients: 0"
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(global.port, 5)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected", self, "client_connect")
	get_tree().connect("network_peer_disconnected", self, "client_disconnect")
	#get_viewport().connect("size_changed", self, "resized")

func resized():
	var x = get_viewport().get_visible_rect().size.x
	var y = get_viewport().get_visible_rect().size.y
	get_node("Button").set_global_position(Vector2(x-250,0))
	get_node("win").set_global_position(Vector2(x-250,75))
	get_node("Continue").set_global_position(Vector2(x-250,150))
	get_node("End").set_global_position(Vector2(x-250,225))

func client_connect(id):
	player_IDs.append(id)
	player_cards.append([])
	#rpc("client_connect", id)
	rpc_id(id, "connection_established", id)
	#rpc_id(id, "r_t", r_t)
	set_client_text()

func client_disconnect(id):
	if id == current_player:
		next_player()
	var player_id = player_IDs.find(id)
	player_IDs.erase(id)
	player_cards.remove(player_id)
	rpc("client_disconnect", id)
	player_names.erase(id)
	set_client_text()


master func add_card(id):
	if !win[0] || (win[0] && win[1]):
		if current_player == id:
			rand = rnd.randi_range(0,9)

			all_cards.append(rnd)
			var player_id = player_IDs.find(id,0)
			player_cards[player_id].append(rand)

			rpc_id(id, "master_add_card", rand)
			next_player()
		else:
			print("not your turn")

	
master func cards_pushed(id, ops):
	if !win[0] || (win[0] && win[1]):
		if current_player == id && players_ignore.find(id) == 0:
			if ops[2] == "":
				var c1 = int(ops[1])
				var player_id = player_IDs.find(id)
				if player_cards[player_id].find(c1) >= 0:
					if c1 == current_card:
						rpc_id(id, "card_removed")
						player_cards[player_id].erase(c1)
						current_card = c1
						rpc("set_current_card", current_card)
						set_client_text()
						next_player()
			else:
				var player_id = player_IDs.find(id)
				var op = ops[0]
				var c1 = int(ops[1])
				var c2 = int(ops[2])
				var ex1 = player_cards[player_id].find(c1)
				var ex2 = player_cards[player_id].find(c2)
				if ex2 >= 0 && ex2 >= 0:
					if c1 == c2 && player_cards[player_id].count(c1) < 2:
						return null
					var res = -1
					match op:
						" + ":
							res = str(int(c1 + c2))
							res = res[res.length()-1]
						" - ":
							res = c1-c2
						" * ":
							res = str(int(c1)*int(c2))
							res = res[res.length()-1]
						" / ":
							res = str(int(float(c1)/c2))
						" ^ ":
							res = str(pow(c1,c2))
							res = res[res.length()-1]
						" √ ":
							res = pow(c2,float(1)/c1)
					if int(res) == current_card:
						rpc_id(id, "card_removed")
						player_cards[player_id].erase(c1)
						player_cards[player_id].erase(c2)
						if(player_cards[player_id].size() == 0):
							player_won(id)
						current_card = c2
						rpc("set_current_card", current_card)
						set_client_text()
						next_player()

				else:
					print("clientside cards don't match serverside cards")
		else:
			print("not your turn or already won")
	else:
		print("Someone, waiting on host to continue or end")

func player_won(id):
	players_ignore.append(id)
	rpc("player_won", player_names[id])

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
	if players_ignore.size < player_IDs.size:
		while players_ignore.find(current_player):
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
	var insnme = nme
	while player_names.values().find(insnme) > 0:
		insnme = nme + str(rnd.randi())
	player_names[id] = insnme
	set_client_text()

func set_client_text():
	var sendstr = ""
	get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size())
	for i in player_names:
		get_node("ClientConnect").text = str(get_node("ClientConnect").text) + "\n" + str(player_names[i])
		if game_started:
			sendstr = sendstr + str(player_names[i]) + ": " + str(player_cards[player_IDs.find(i)].size()) + "\n"
		else:
			sendstr = sendstr  + str(player_names[i]) + "\n"
	rpc("update_player_list", sendstr)


func _on_win_pressed():
	player_won(player_IDs[0])


func _on_Contunue_pressed():
	win[1] = true


func _on_End_pressed():
	game_end()
