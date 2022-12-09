extends Node2D

enum PC_mode{ ### enum for past calculations
	norm = 0,
	fail = 1,
	time = 2,
	drew = 3,
	join = 4,
	left = 5,
	done = 6
}

#export (NodePath) var advertiserPath: NodePath
#onready var advertiser := get_node(advertiserPath)

### load database
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
var db

var nue
var settings


var player_cards = {}
var player_IDs = []
var player_names = {}
var players_ignore = []
var player_classment = []
var end_of_game = false
var unverified = []
var last_round = false

var host_started = false

var pir = [] # Player position in round

var past_calcs = []

var key_names = {"mty":"22"}

var max_players = 6
var starting_hand = 7
var late_hand = 7
var hum_play
var unlimit_player = false
var unlimit_time = false
var alp = true

var win = [false, false] # 0= Player won, 1 = Continue after player win

var current_card = 0
var game_started = false
var current_player = 0
var current_player_num = 0

var peer = null

var MenuButtons


var rnd = RandomNumberGenerator.new()
var rand = 0

var r_t = 60 # round time

onready var timer = get_node("Timer")

func _ready():
	### create basis for sql connection
	db = SQLite.new()
	db.path = "res://Data/UserData"
	
	### connect system functions to self implemented ones
	nue = get_viewport().connect("size_changed", self, "resized")
	
	### save MenuButtons for later, not needed at start of program
	MenuButtons = get_node("MenuButtons")
	remove_child(get_node("MenuButtons"))
	resized()

func resized():
	var x = get_viewport().get_visible_rect().size.x

	if host_started:
		### move all buttons to right side of screen
		get_node("MenuButtons/Button").set_global_position(Vector2(x-250,0))
		get_node("MenuButtons/Continue").set_global_position(Vector2(x-250,100))
		get_node("MenuButtons/Disconnect").set_global_position(Vector2(x-250,150))

func client_connect(id):
	unverified.append(id)
	### if max player count is reached refuse new logins
	if !unlimit_player && unverified.size() >= int(max_players):
			get_tree().set_refuse_new_network_connections(true)
	
	rpc_id(id, "connection_established_DELETE", id, player_IDs.size())
	set_client_text()

master func give_key(id, key):
	### check if key is valid
	if key_names.has(key):
		### add player to arrays
		player_cards[id] = []
		player_names[id] = key_names[key]
		player_IDs.append(id)

		pir.append(id)
		rpc_id(id, "r_t_h", r_t)

		if game_started:
			### if game started, give player imprtand information
			rpc_id(id, "set_past_calc", set_past_calc(PC_mode.join, str(player_names[id])))
			rpc_id(id, "set_current_card", current_card)
			if(str(late_hand) == "avg"):
				### calculate average hand card number of all players
				var x = 0
				var n = 0
				for i in player_IDs:
					if player_cards[i].size() > 0:
						x += player_cards[i].size()
						n += 1
				x = x/n
				### give new player average number of cards
				for _i in range(x):
					rand = rnd.randi_range(0,9)
					player_cards[id].append(rand)
					rpc_id(id, "master_add_card", rand)
			else:
				for _i in range(late_hand):
					rand = rnd.randi_range(0,9)
					player_cards[id].append(rand)
					rpc_id(id, "master_add_card", rand)


		set_client_text()

func client_disconnect(id):
	if player_IDs.has(id):
		### add info to past calc
		rpc("set_past_calc", set_past_calc(PC_mode.left, str(player_names[id])))
		
		### get player index
		var player_id = player_IDs.find(id)
		
		### remove player from all arrays
		player_cards.erase(player_id)
		player_names.erase(id)
		unverified.erase(id)
		player_IDs.erase(id)
		pir.erase(id)
		
		### Next player if disconnected one was current one
		if id == current_player:
			next_player()
		rpc("client_disconnect", id)
		set_client_text()
		### Allow new players to join if lobby was full
		if !unlimit_player && unverified.size() < int(max_players) && alp:
			get_tree().set_refuse_new_network_connections(false)
		



master func add_card(id):
	### check if move is allowed by player
	if (!win[0] || (win[0] && win[1])) && !end_of_game:
		if current_player == id:
			### create card
			rand = rnd.randi_range(0,9)

			### save card on server
			player_cards[id].append(rand)

			### upfate past calculations
			rpc("set_past_calc", set_past_calc(PC_mode.drew, str(player_names[current_player])))

			### give card to player
			rpc_id(id, "master_add_card", rand)
			if(last_round):
				game_end()
			else:
				next_player()
		else:
			print("not your turn")

func set_past_calc(mode, args):
	### remove oldest line if neccecary
	if past_calcs.size() >= 5:
		past_calcs.remove(0)
	
	match mode:
		0: #Default (name: number / name: number + number)
			if args[2] == "":
				past_calcs.append(str(player_names[current_player]) + ": " + str(args[1]))
			else:
				past_calcs.append(player_names[current_player] + ": " + str(args[1]) + str(args[0]) + str(args[2]))

		1: #Fail (name tried x = y / name tried x+y = z)
			if args[2] == "":
				past_calcs.append(str(player_names[current_player]) + " tried " + str(args[1]) + " = " + str(current_card))
			else:
				past_calcs.append(str(player_names[current_player]) + " tried " + str(args[1]) + str(args[0]) + str(args[2]) + " = " + str(current_card))

		2: #time (name ran out if time)
			past_calcs.append(str(player_names[current_player]) + " ran out of time")

		3: #drew (name drew a card)
			past_calcs.append(str(args) + " drew a card")

		4: #join (name joined the game)
			past_calcs.append(str(args) + " joined the game")
		
		5: #left (name left the game)
			past_calcs.append(str(args) + " left the game")

		6: #done (name is in nth place)
			past_calcs.append(str(args) + " is on " + str(player_classment.size()) + " place")
	
	return create_past_calc_str()

func create_past_calc_str():
	var sendstr = ""
	### add all lines of past calcs to string
	for i in range(past_calcs.size()):
		if i < past_calcs.size()-1:
			sendstr += past_calcs[i] + "\n"
		else:
			sendstr += past_calcs[i]
	return sendstr


master func cards_pushed(id, ops):
	### check if move is allowed
	if (!win[0] || (win[0] && win[1])) && !end_of_game:
		if current_player == id && players_ignore.count(id) == 0:
			### check if one or wto cards are pushed
			if ops[2] == "":
				var c1 = int(ops[1])
				### check if player has card he claims to have
				if player_cards[id].find(c1) >= 0:
					### check if cards match
					if c1 == current_card:
						### remove card from client and server
						rpc_id(id, "card_removed")
						player_cards[id].erase(c1)
						
						### set new current card
						current_card = c1
						rpc("set_current_card", current_card)
						
						### set texts
						set_client_text()
						rpc("set_past_calc", set_past_calc(PC_mode.norm, ops))
						
						if(last_round):
							game_end()
						else:
							### check if player is done
							if(player_cards[id].size() == 0):
								player_done(id)
							next_player()
					else:
						if hum_play:
							rpc("set_past_calc", set_past_calc(PC_mode.fail, ops))

			else:
				### get cards
				var player_id = id
				var op = ops[0]
				var c1 = int(ops[1])
				var c2 = int(ops[2])
				### check if player has cards he claims to have
				var ex1 = player_cards[player_id].find(c1)
				var ex2 = player_cards[player_id].find(c2)
				### check if cards match
				if ex1 >= 0 && ex2 >= 0:
					### if both cards are the same, make sure the player has at least two of that kind
					if c1 == c2 && player_cards[player_id].count(c1) < 2:
						return null
					var res = -1
					### calculate result of calculation
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
							if c2 != 0:
								res = str(int(float(c1)/c2))
						" ^ ":
							res = str(pow(c1,c2))
							res = res[res.length()-1]
						" √ ":
							if c2 != 0:
								res = pow(c2,float(1)/c1)
					### check if result matches current card
					if int(res) == current_card:
						
						
						
						### remove cards
						rpc_id(player_id, "card_removed")
						player_cards[player_id].erase(c1)
						player_cards[player_id].erase(c2)
						
						### set new current card
						current_card = c2
						rpc("set_current_card", current_card)
						
						### set texts
						set_client_text()
						rpc("set_past_calc", set_past_calc(PC_mode.norm, ops))
						
						if(last_round):
							game_end()
						else:
							### check if player is done
							if(player_cards[player_id].size() == 0):
								player_done(player_id)
							next_player()
					else:
						if hum_play:
							rpc("set_past_calc", set_past_calc(PC_mode.fail, ops))
				else:
					print("clientside cards don't match serverside cards")
		else:
			print("not your turn or already won")
	else:
		print("Someone won, waiting on host to continue or end")

func player_done(id):
	
	### add player to needed arrays
	players_ignore.append(id)
	player_classment.append(id)
	
	### set texts
	rpc("set_past_calc", set_past_calc(PC_mode.done, player_names[id]))
	
	### call player done functions
	rpc_id(id, "my_end_f")
	rpc("player_done", player_names[id], player_classment.size())
	
	### set winner if first done player
	if players_ignore.size() == 1:
		rpc("set_winner", player_names[id])
	set_client_text()
	next_player()
	
	### check if all players are done
	if players_ignore.size() >= player_IDs.size()-1:
		### end game if last player in round, else let last player finnish
		if current_player_num == player_IDs.size()-1:
			game_end()
		else:
			last_round = true
	


func game_end():
	### call game end
	end_of_game = true
	rpc("game_end")
	### stop timer
	if !unlimit_time:
		timer.stop()
	### set texts
	set_client_winner_text()

func set_client_winner_text():
	var sendstr = ""
	### first line: x clients out of y
	if !unlimit_player:
		get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size()) + "/" + str(max_players)
	else:
		get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size()) + "/ unlimited"
	### draw players in winner order
	for i in range(player_classment.size()):
		sendstr = sendstr + str(i+1) + ": " + str(player_names[player_classment[i]]) + "\n"
	
	### update list on every client
	for i in player_IDs:
		rpc_id(i, "update_player_list", sendstr)

func _physics_process(_delta):
	### for "true randomness" calculate random number every tick
	rand = rnd.randi()


func _on_Button_pressed(): # Start game
	if not game_started && player_IDs.size()>0:
		### if late players are forebidden, refuse new connections
		if !alp:
			get_tree().set_refuse_new_network_connections(true)
		### random calculations
		pir.shuffle()
		current_card = rnd.randi_range(0,9)
		var randplay = rnd.randi_range(0, player_IDs.size()-1)
		
		
		
		### get current player
		current_player = player_IDs[randplay]
		current_player_num = pir.find(current_player)
		
		
		
		### generate hand cards for every player
		for i in player_IDs:
			for _j in range(starting_hand):
				rand = rnd.randi_range(0,9)
				player_cards[i].append(rand)
				rpc_id(i, "master_add_card", rand)
				
		### start timer if time is not endless
		if !unlimit_time:
			timer.start(r_t)
		
		### initiate game
		game_started = true
		set_client_text()
		
		### call client functions
		rset_id(current_player, "my_turn", true)
		rpc("set_current_card", current_card)
		rpc_id(current_player, "startOfRound")
		rpc("set_current_player", player_names[current_player])
		
		
		

func next_player():
	if !end_of_game:
		### check if current player exists and stop his round
		if player_IDs.count(current_player) > 0:
			rpc_id(current_player, "endOfRound")
		### check if any player is left
		if pir.size() > 0:
			### next player in round, after last comes first
			current_player = pir[(pir.find(current_player)+1)%pir.size()]
			current_player_num = pir.find(current_player)
			
			var c = 0
			### check if player is done ( is in players_ignore)
			while(players_ignore.count(current_player) > 0 && c < player_IDs.size()):
				current_player = pir[(pir.find(current_player)+1)%pir.size()]
				current_player_num = pir.find(current_player)
				c += 1
			
			### call client functions
			rset("my_turn", false)
			rset_id(current_player, "my_turn", true)
			rpc_id(current_player, "startOfRound")
			rpc("set_current_player", player_names[current_player])
			
			### start timer for new player
			if !unlimit_time:
				timer.start(r_t)
			set_client_text()
			

func _on_Timer_timeout():
	### check if any player is left
	if player_IDs.size() > 0:
		### end players round
		rpc_id(current_player, "endOfRound")
		### update past calc
		rpc("set_past_calc", set_past_calc(PC_mode.time, ""))
		if(last_round):
			game_end()
		else:
			add_card_timeout(current_player)
			next_player()

func add_card_timeout(id):
	if (!win[0] || (win[0] && win[1])) && !end_of_game:
		if current_player == id:
			for _i in range(2):
				rand = rnd.randi_range(0,9)
				player_cards[id].append(rand)
				rpc_id(id, "master_add_card", rand)


func set_client_text():
	var sendstr
	if !unlimit_player:
		sendstr = "Players: " + str(player_IDs.size()) + "/" + str(max_players) + "\n"
		get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size()) + "/" + str(max_players)
	else:
		sendstr = "Players: " + str(player_IDs.size()) + "/ unlimited\n"
		get_node("ClientConnect").text = "Connected Clients: " + str(player_IDs.size()) + "/ unlimited"
	
	for i in player_names:
		get_node("ClientConnect").text = str(get_node("ClientConnect").text) + "\n" + str(player_names[i] + " (" + str(i) + ")")
		if game_started:
			if(players_ignore.count(i) > 0):
				sendstr = sendstr +"(Done) "+ str(player_names[i]) + ": " + str(player_cards[i]) + "\n"
			else:
				sendstr = sendstr + str(player_names[i]) + ": " + str(player_cards[i].size()) + "\n"
		else:
			sendstr = sendstr  + str(player_names[i]) + "\n"
	for i in player_IDs:
		rpc_id(i, "update_player_list", sendstr)


func _on_win_pressed():
	if player_IDs.size() != 0:
		player_done(player_IDs[0])

func _on_Contunue_pressed():
	win[1] = true
	if player_IDs.size() != 0:
		player_done(player_IDs[0])

func _on_End_pressed():

	game_end()

func _on_start_host_pressed():
	settings = get_node("Settings")

	add_child(MenuButtons)
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port)
	
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(global.port)
	peer.compression_mode = NetworkedMultiplayerENet.COMPRESS_ZLIB
	get_tree().network_peer = peer
	
	
	
	nue = get_tree().connect("network_peer_connected", self, "client_connect")
	nue = get_tree().connect("network_peer_disconnected", self, "client_disconnect")

	if get_node("Settings/max_play/cb").is_pressed() && get_node("Settings/max_play/ip").text != "":
		max_players = int(get_node("Settings/max_play/ip").text)
	if get_node("Settings/start_cards/ip").text != "":
		starting_hand = int(get_node("Settings/start_cards/ip").text)
	if get_node("Settings/max_rt/cb").is_pressed() && get_node("Settings/max_rt/ip").text != "":
		r_t = int(get_node("Settings/max_rt/ip").text)
	if !get_node("Settings/max_rt/cb").is_pressed():
		r_t = "infinite"
	match int(get_node("Settings/late_cards/sl").value):
		0:
			late_hand = starting_hand
		1:
			late_hand = "avg"
		2:
			late_hand = int(get_node("Settings/late_cards/ip").text)
	hum_play = get_node("Settings/hum_play/cb")
	alp = get_node("Settings/allow_late/cb")
	
	unlimit_time = !get_node("Settings/max_rt/cb").is_pressed()
	unlimit_player = !get_node("Settings/max_play/cb").is_pressed()
	print(unlimit_player)
	
	if !unlimit_player:
		get_node("ClientConnect").text = "Connected Clients: 0/"+str(max_players)
	else:
		get_node("ClientConnect").text = "Connected Clients: 0/ infinite"

	remove_child(get_node("Settings"))
	host_started = true
	resized()
	
#	advertiser.serverInfo["name"] = "A great lobby"
#	advertiser.serverInfo["port"] = global.port

func _on_Disconnect_pressed():

	get_tree().network_peer = null
	peer.close_connection()
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")

master func register(id, name, pwd, mail):
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
		var key = PoolStringArray(OS.get_time().values()).join("")
		key = (key + name).sha256_text()
		key_names[key] = name
		rpc_id(id, "Register_return", true, key)
	else:
		rpc_id(id, "Register_return", false, "")
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
			rpc_id(id, "Login_return", true, key)
		else:
			rpc_id(id, "Login_return", false, "")
	db.close_db()
	set_client_text()



func _on_Button2_pressed():
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")
