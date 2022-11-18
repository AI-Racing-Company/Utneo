extends Node2D

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
var db

var player_cards = {}
var player_IDs = []
var player_names = {}
var players_ignore = []
var player_classment = []
var end_of_game = false

var key_names = {"mty":"22"}

var max_players = 6
var starting_hand = 7

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
	db = SQLite.new()
	db.path = "res://Data/UserData"
	get_viewport().connect("size_changed", self, "resized")
	resized()
	#get_viewport().connect("size_changed", self, "resized")

func resized():
	var x = get_viewport().get_visible_rect().size.x
	var y = get_viewport().get_visible_rect().size.y
	get_node("Button").set_global_position(Vector2(x-250,0))
	get_node("win").set_global_position(Vector2(x-250,50))
	get_node("Continue").set_global_position(Vector2(x-250,100))
	get_node("End").set_global_position(Vector2(x-250,150))
	get_node("Disconnect").set_global_position(Vector2(x-250,150))

func client_connect(id):
	print("Connecting")
	rpc_id(id, "connection_established", id)
	set_client_text()

master func give_key(id, key):
	print("giving key " + str(id))
	print(key)
	if key_names.has(key):
		print("key valid")
		
		player_cards[id] = []
		player_names[id] = key_names[key]
		print("append playerIDs by " + str(id))
		player_IDs.append(id)
		
		#rpc("client_connect", id)
		rpc_id(id, "r_t", r_t)
		set_client_text()
		if player_IDs.size() >= int(max_players):
			get_tree().set_refuse_new_network_connections(true)

func client_disconnect(id):
	print("disconnecting")
	if player_IDs.has(id):
		if id == current_player:
			next_player()
		var player_id = player_IDs.find(id)
		
		player_cards.erase(player_id)
		player_names.erase(id)
		player_IDs.erase(id)
		
		rpc("client_disconnect", id)
		set_client_text()
	


master func add_card(id):
	if (!win[0] || (win[0] && win[1])) && !end_of_game:
		if current_player == id:
			rand = rnd.randi_range(0,9)

			player_cards[id].append(rand)

			rpc_id(id, "master_add_card", rand)
			next_player()
		else:
			print("not your turn")


master func cards_pushed(id, ops):
	if (!win[0] || (win[0] && win[1])) && !end_of_game:
		if current_player == id && players_ignore.count(id) == 0:
			if ops[2] == "":
				var c1 = int(ops[1])
				if player_cards[id].find(c1) >= 0:
					if c1 == current_card:
						rpc_id(id, "card_removed")
						player_cards[id].erase(c1)
						current_card = c1
						rpc("set_current_card", current_card)
						set_client_text()
						next_player()
			else:
				var player_id = id
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
							player_done(id)
						var pis = players_ignore.size()
						if(pis == pis-1 && pis > 0):
							game_end()
						current_card = c2
						rpc("set_current_card", current_card)
						set_client_text()
						next_player()
						if int(res) == current_card:
							rpc_id(id, "card_removed")
							player_cards[player_id].erase(c1)
							player_cards[player_id].erase(c2)
							if(player_cards[player_id].size() == 0):
								player_done(id)
							current_card = c2
							rpc("set_current_card", current_card)
							set_client_text()
							next_player()
					else:
						print("clientside cards don't match serverside cards")
		else:
			print("not your turn or already won")
	else:
		print("Someone won, waiting on host to continue or end")

func player_done(id):
	players_ignore.append(id)
	player_classment.append(id)
	rpc("player_done", player_names[id], player_classment.size())
	set_client_text()
	

func game_end():
	end_of_game = true
	rpc("game_end")

func _physics_process(delta):
	rand = rnd.randi()



func _on_Button_pressed(): # Start game
	if not game_started && player_IDs.size()>0:
		print("num of games started")
		current_card = rnd.randi_range(0,9)
		rpc("set_current_card", current_card)
		var randplay = rnd.randi_range(0, player_IDs.size()-1)
		current_player = player_IDs[randplay]
		rset_id(current_player, "my_turn", true)
		print(player_IDs)
		for i in player_IDs:
			for j in range(starting_hand):
				rand = rnd.randi_range(0,9)
				player_cards[i].append(rand)
				rpc_id(i, "master_add_card", rand)
		
		timer.start(r_t)
		rpc_id(current_player, "startOfRound")
		game_started = true
		set_client_text()
		rpc("set_current_player", player_names[current_player])

func next_player():
	if player_IDs.count(current_player) > 0:
		rpc_id(current_player, "endOfRound")
	current_player = player_IDs[(player_IDs.find(current_player)+1)%player_IDs.size()]
	
	rset("my_turn", false)
	rset_id(current_player, "my_turn", true)
	rpc_id(current_player, "startOfRound")
	timer.start(r_t)
	set_client_text()
	rpc("set_current_player", player_names[current_player])

func _on_Timer_timeout():
	add_card(current_player)
	add_card(current_player)
	rpc_id(current_player, "endOfRound")
	next_player()


func set_client_text():
	print("setting text...")
	var sendstr = ""
	get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size())
	for i in player_names:
		get_node("ClientConnect").text = str(get_node("ClientConnect").text) + "\n" + str(player_names[i] + " (" + str(i) + ")")
		if game_started:
			print(players_ignore.count(i))
			if(players_ignore.count(i) > 0):
				sendstr = sendstr +"(Done) "+ str(player_names[i]) + ": " + str(player_cards[player_IDs.find(i)].size()) + "\n"
			else:
				sendstr = sendstr + str(player_names[i]) + ": " + str(player_cards[i].size()) + "\n"
		else:
			sendstr = sendstr  + str(player_names[i]) + "\n"
	rpc("update_player_list", sendstr)


func _on_win_pressed():
	if player_IDs.size() != 0:
		player_done(player_IDs[0])

func _on_Contunue_pressed():
	win[1] = true
	
func _on_End_pressed():
	
	game_end()

func _on_start_host_pressed():
	
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	get_node("ClientConnect").text = "Connected Clients: 0"
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(global.port, 5)
	peer.compression_mode = NetworkedMultiplayerENet.COMPRESS_ZLIB
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected", self, "client_connect")
	get_tree().connect("network_peer_disconnected", self, "client_disconnect")
	if get_node("max_play").text != "":
		max_players = get_node("max_play").text
	if get_node("start_card").text != "":
		starting_hand = int(get_node("start_card").text)
	if get_node("max_round").text != "":
		r_t = int(get_node("max_round").text)
	remove_child(get_node("max_play"))
	remove_child(get_node("start_card"))
	remove_child(get_node("start_host"))
	remove_child(get_node("max_round"))


func _on_Disconnect_pressed():
	
	get_tree().network_peer = null
	peer.close_connection()
	get_tree().change_scene("res://Scenes/LobbyScene.tscn")
	
master func register(id, name, pwd, mail):
	print("registering")
	db.open_db()
	var query = "SELECT * FROM Users WHERE Name = ? OR email = ?"
	var bindings = [name,mail]
	db.query_with_bindings(query, bindings)
	if db.query_result.size() == 0:
		var row_array : Array = []
		var row_dict : Dictionary = Dictionary()

		row_dict["name"] = name
		row_dict["Played_Games"] = 0
		row_dict["Won_Games"] = 0
		row_dict["Points"] = 0
		row_dict["email"] = mail
		row_dict["pwd"] = pwd
		row_array.append(row_dict.duplicate())
		db.insert_rows("Users", row_array)
		row_dict.clear()
		rpc_id(id, "Register_return", true)
	else:
		rpc_id(id, "Register_return", false)
	db.close_db()

master func login(id, name, pwd, time):
	db.open_db()
	var query = "SELECT pwd FROM Users WHERE Name = ?"
	var bindings = [name]
	db.query_with_bindings(query, bindings)
	if db.query_result.size() > 0:
		var db_pwd = db.query_result[0]["pwd"]
		var local_pwd = (db_pwd+time).sha256_text()
		if local_pwd == pwd:
			var key = PoolStringArray(OS.get_time().values()).join("")
			key = (key + name).sha256_text()
			key_names[key] = name
			print(key_names)
			rpc_id(id, "Login_return", true, key)
		else:
			print("Acces Denied")
			rpc_id(id, "Login_return", false, "")
	db.close_db()
	set_client_text()














