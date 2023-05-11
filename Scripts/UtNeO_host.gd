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


var bot_functions = [
	"set_current_card",
	"master_add_card",
	"card_removed",
	"startOfRound"
]

var bots = ["Elton.gd", "Timmothy.gd"]

#export (NodePath) var advertiserPath: NodePath
#onready var advertiser := get_node(advertiserPath)

### load database
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
var db

var bot_ids = 100

var rounds = 0

var nue
var settings

var first_player

var players = {}

var players_done = 0
var end_of_game = false
var unverified = []
var last_round = false

var firstWinner = 0

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
var define_winner = 1

var current_card = 0
var game_started = false
var current_player = 0
var current_player_num = 0

var peer = null

var MenuButtons


var rnd = RandomNumberGenerator.new()
var rand = 0

var ipstring = ""

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
	if !unlimit_player && unverified.size() + players.size() >= int(max_players):
			get_tree().set_refuse_new_network_connections(true)
	yield(get_tree().create_timer(0.1), "timeout")
	rpc_id(id, "connection_established", [id])
	set_client_text()


master func give_key(id, key):
	### check if key is valid
	if key_names.has(key):
		unverified.erase(id)
		### add player to arrays
		players[id] = {}
		players[id]["name"] = null
		players[id]["place"] = null
		players[id]["cards"] = null
		players[id]["points"] = 0
		players[id]["name"] = key_names[key]
		players[id]["place"] = -1
		players[id]["cards"] = []
		players[id]["type"] = "human"
		pir.append(id)
		
		yield(get_tree().create_timer(0.5), "timeout")

		rpc_one(id, "r_t_h", [r_t])

		if game_started:
			### if game started, give player imprtand information
			rpc_one(id, "set_past_calc", [set_past_calc(PC_mode.join, str(players[id]["name"]))])
			rpc_one(id, "set_current_card", [current_card])
			if(str(late_hand) == "avg"):
				### calculate average hand card number of all players
				var x = 0
				var n = 0
				for i in players:
					if players[i]["cards"].size() > 0:
						x += players[i]["cards"].size()
						n += 1
				x = x/n
				### give new player average number of cards
				for _i in range(x):
					rand = rnd.randi_range(0,9)
					players[id]["cards"].append(rand)
				rpc_one(id, "master_add_card", [players[id]["cards"]])
			else:
				for _i in range(late_hand):
					rand = rnd.randi_range(0,9)
					
					players[id]["cards"].append(rand)
				rpc_one(id, "master_add_card", [players[id]["cards"]])


		if !end_of_game:
			set_client_text()

func client_disconnect(id):
	if players.has(id):
		### remove player from all arrays
		
		unverified.erase(id)
		players.erase(id)
		
		### add info to past calc
		rpc_all("set_past_calc", set_past_calc(PC_mode.left, str(players[id]["name"])))
		
		### Next player if disconnected one was current one
		if id == current_player:
			next_player()
		set_client_text()
		### Allow new players to join if lobby was full
		if !unlimit_player && unverified.size() < int(max_players) && alp:
			get_tree().set_refuse_new_network_connections(false)
		



master func add_card(id):
	### check if move is allowed by player
	#print("I drew a card")
	if !end_of_game:
		if current_player == id:
			### create card
			rand = rnd.randi_range(0,9)
			### save card on server
			players[id]["cards"].append(rand)

			### upfate past calculations
			rpc_all("set_past_calc", set_past_calc(PC_mode.drew, str(players[current_player]["name"])))

			### give card to player
			
			#print("gave card: ", rand)
			rpc_one(id, "master_add_card", [[rand]])
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
				past_calcs.append(str(players[current_player]["name"]) + ": " + str(args[1]))
			else:
				past_calcs.append(players[current_player]["name"] + ": " + str(args[1]) + str(args[0]) + str(args[2]))

		1: #Fail (name tried x = y / name tried x+y = z)
			if args[2] == "":
				past_calcs.append(str(players[current_player]["name"]) + " tried " + str(args[1]) + " = " + str(current_card))
			else:
				past_calcs.append(str(players[current_player]["name"]) + " tried " + str(args[1]) + str(args[0]) + str(args[2]) + " = " + str(current_card))

		2: #time (name ran out if time)
			past_calcs.append(str(players[current_player]["name"]) + " ran out of time")

		3: #drew (name drew a card)
			past_calcs.append(str(args) + " drew a card")

		4: #join (name joined the game)
			past_calcs.append(str(args) + " joined the game")
		
		5: #left (name left the game)
			past_calcs.append(str(args) + " left the game")

		6: #done (name is in nth place)
			past_calcs.append(str(args) + " is on " + str(players_done) + " place")
	
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
	if !end_of_game:
		if current_player == id:
			### check if one or two cards are pushed
			if ops[2] == "":
				var c1 = int(ops[1])
				### check if player has card he claims to have
				if players[id]["cards"].find(c1) >= 0:
					### check if cards match
					if c1 == current_card:
						players[id]["points"] += int(c1)
						
						### remove card from client and server
						rpc_one(id, "card_removed", [players[id]["points"]])
						players[id]["cards"].erase(c1)
						
						### set new current card
						current_card = c1
						rpc_all("set_current_card", current_card)
						
						### set texts
						if !end_of_game:
							set_client_text()
						rpc_all("set_past_calc", set_past_calc(PC_mode.norm, ops))

						if(last_round):
							### check if player is done
							if(players[id]["cards"].size() == 0):
								player_done(id)
							if !end_of_game:
								game_end()
						else:
							### check if player is done
							if(players[id]["cards"].size() == 0):
								player_done(id)
							else:
								next_player()
					else:
						if hum_play:
							rpc_all("set_past_calc", set_past_calc(PC_mode.fail, ops))

			else:
				### get cards
				var op = ops[0]
				var c1 = int(ops[1])
				var c2 = int(ops[2])
				### check if player has cards he claims to have
				var ex1 = players[id]["cards"].find(c1)
				var ex2 = players[id]["cards"].find(c2)
				### check if cards match
				if ex1 >= 0 && ex2 >= 0:
					### if both cards are the same, make sure the player has at least two of that kind
					if c1 == c2 && players[id]["cards"].count(c1) < 2:
						return null
					var res = -1
					var trueRes = -1
					### calculate result of calculation
					match op:
						global.btn_modes.add:
							trueRes = int(c1 + c2)
							res = str(trueRes)[str(trueRes).length()-1]
						global.btn_modes.sub:
							trueRes = c1-c2
							res = str(trueRes)
						global.btn_modes.mul:
							trueRes = int(c1)*int(c2)
							res = str(trueRes)[str(trueRes).length()-1]
						global.btn_modes.div:
							if c2 != 0:
								trueRes = int(float(c1)/c2)
								res = str(trueRes)[str(trueRes).length()-1]
						global.btn_modes.pot:
							trueRes = pow(c1,c2)
							res = str(trueRes)[str(trueRes).length()-1]
						global.btn_modes.sqr:
							if c2 != 0:
								trueRes = int(pow(c2,float(1)/c1))
								res = str(trueRes)[str(trueRes).length()-1]
					### check if result matches current card
					if int(res) == current_card:
						
						players[id]["points"] += int(trueRes)
						
						### remove cards
						rpc_one(id, "card_removed", [players[id]["points"]])
						players[id]["cards"].erase(c1)
						players[id]["cards"].erase(c2)
						
						### set new current card
						current_card = c2
						rpc_all("set_current_card", current_card)
						
						### set texts
						if !end_of_game:
							set_client_text()
						rpc_all("set_past_calc", set_past_calc(PC_mode.norm, ops))
						
						if(last_round):
							### check if player is done
							if(players[id]["cards"].size() == 0):
								player_done(id)
							if !end_of_game:
								game_end()
						else:
							### check if player is done
							if(players[id]["cards"].size() == 0):
								player_done(id)
							else:
								next_player()
					else:
						if hum_play:
							rpc_all("set_past_calc", set_past_calc(PC_mode.fail, ops))
						print("not the right solution")
				else:
					print("clientside cards don't match serverside cards")
		else:
			print("not your turn or already won")
	else:
		print("Someone won, waiting on host to continue or end")

func player_done(id):
	print(players[id]["name"], " won")
	### add player to needed arrays
	players_done += 1
	players[id]["place"] = players_done
	
	
	### set texts
	rpc_all("set_past_calc", set_past_calc(PC_mode.done, players[current_player]["name"]))
	
	### call player done functions
	rpc_one(id, "my_end_f", null)
	rpc_all("player_done", players[id]["name"])
	
	### set winner if first done player
	db.open_db()
	
	if players_done == 1:
		rpc_all("set_winner", players[id]["name"])
		firstWinner = rounds
		var query = "SELECT Won_Games FROM Users WHERE Name = ?"
		var bindings = [players[id]["name"]]
		db.query_with_bindings(query, bindings)
		if db.query_result.size() > 0:
			var res = db.query_result[0]["Won_Games"]
			query = "UPDATE Users SET Won_Games = " + str(res+1) + " WHERE Name = " + players[id]["name"]
			db.query(query)
		
	var query = "SELECT Points FROM Users WHERE Name = ?"
	var bindings = [players[id]["name"]]
	db.query_with_bindings(query, bindings)
	if db.query_result.size() > 0:
		var res = db.query_result[0]["Points"]
		var inPoints = players[id]["points"] /(1+0.05*players_done*rounds)
		query = "UPDATE Users SET Points = " + str(inPoints+res) + " WHERE Name = " + players[id]["name"]
		db.query(query)
	db.close_db()
	
	pir.erase(id)
	
	
	
	### check if all players are done
	if players_done >= players.size()-1:
		### end game if last player in round, else let last player finnish
		if players.size() > 2 and current_player == first_player:
			game_end()
		else:
			last_round = true
	
	if !end_of_game:
		set_client_text()
	next_player()
	


func game_end():
	### call game end
	end_of_game = true
	for i in players:
		rpc_one(i,"game_end", null)
	### stop timer
	if !unlimit_time:
		timer.stop()
	### set texts
	set_client_winner_text()

func set_client_winner_text():
	
	### first line: x clients out of y
	if !unlimit_player:
		get_node("ClientConnect").text = "Connected Clients: " + str(players.size()) + "/" + str(max_players)
	else:
		get_node("ClientConnect").text = "Connected Clients: " + str(players.size()) + "/ unlimited"
	
	
	### draw players in winner order
	var sendstr = ""
	if define_winner == 1:
		
		
		var arr = []
		for _i in range(players.size()):
			arr.append(0)
		var cou = 1
		for i in players:
			if players[i]["place"] > 0:
				arr[players[i]["place"]-1] = players[i]["name"]
			else:
				arr[players.size()-cou] = players[i]["name"]
				cou += 1
		for i in range(arr.size()):
			sendstr += str(i) + ": " + arr[i] + "\n"
		

					
		### update list on every client
		sendstr = "[right]" + sendstr + "[/right]"
	
	else:
		
		var arr = []
		for i in players:
			arr.append(players[i]["points"])

		arr.sort()
		var c = 0
		for i in players:
			for j in range(arr.size()):
				if players[i]["points"] == arr[j]:
					sendstr += str(c) + " " + players[i]["name"] + "("+players[i]["points"] + ")\n"
			c+=1
					
		### update list on every client
		sendstr = "[right]" + sendstr + "[/right]"
	rpc_all("update_player_list", [sendstr])

func _physics_process(_delta):
	### for "true randomness" calculate random number every tick
	rand = rnd.randi()


func _on_Button_pressed(): # Start game
	if not game_started && players.size()>0:
		### if late players are forebidden, refuse new connections
		if !alp:
			get_tree().set_refuse_new_network_connections(true)
		### random calculations
		pir.shuffle()
		current_card = rnd.randi_range(0,9)
		
		
		var randplay = rnd.randi_range(0, players.size()-1)
		
		### get current player
		current_player = pir[randplay]
		current_player_num = pir.find(current_player)
		first_player = current_player
		
		### generate hand cards for every player
		for i in players:
			for _j in range(starting_hand):
				rand = rnd.randi_range(0,9)
				
				players[i]["cards"].append(rand)
			rpc_one(i, "master_add_card", [players[i]["cards"]])
				
		### start timer if time is not endless
		if !unlimit_time:
			timer.start(r_t)
		
		### initiate game
		game_started = true
		set_client_text()
		yield(get_tree().create_timer(2), "timeout")
		### call client functions
		rset_one(current_player, "my_turn", true)
		rpc_all("set_current_card", current_card)
		rpc_one(current_player, "startOfRound", null)
		rpc_all("set_current_player", players[current_player]["name"])
		
		for i in players:
			db.open_db()
			var query = "SELECT Played_Games FROM Users WHERE Name = ?"
			var bindings = [players[i]["name"]]
			db.query_with_bindings(query, bindings)
			if db.query_result.size() > 0:
				var res = db.query_result[0]["Played_Games"]
				query = "UPDATE Users SET Played_Games = " + str(res+1) + " WHERE Name = " + players[i]["name"]
				db.query(query)
				
			db.close_db()
		
		
	
	if end_of_game:
		
		rpc_all("continue_game", null)
		players_done = 0
		
		if !alp:
			get_tree().set_refuse_new_network_connections(true)
		### random calculations
		pir.clear()
		for i in players:
			pir.append(i[0])
		
		pir.shuffle()
		current_card = rnd.randi_range(0,9)
		
		
		var randplay = rnd.randi_range(0, players.size()-1)
				
		### get current player
		current_player = pir[randplay]
		current_player_num = pir.find(current_player)
		first_player = current_player
		
		### generate hand cards for every player
		for i in players:
			players[i]["cards"] = []
			players[i]["place"] = 0
			for _j in range(starting_hand):
				rand = rnd.randi_range(0,9)
				
				players[i]["cards"].append(rand)
			rpc_one(i, "master_add_card", [players[i]["cards"]])
				
				
		### start timer if time is not endless
		if !unlimit_time:
			timer.start(r_t)
		
		### initiate game
		game_started = true
		set_client_text()
		
		### call client functions
		rset_one(current_player, "my_turn", true)
		rpc_all("set_current_card", current_card)
		rpc_one(current_player, "startOfRound", null)
		rpc_all("set_current_player", players[current_player]["name"])
	

func next_player():
	if !end_of_game:
		### check if current player exists and stop his round
		if players.has(current_player):
			rpc_one(current_player, "endOfRound", null)
		### check if any player is left
		if pir.size() > 0:
			### next player in round, after last comes first
			current_player = pir[(pir.find(current_player)+1)%pir.size()]
			current_player_num = pir.find(current_player)
			
			var c = 0
			### check if player is done
			if players.has(current_player):
				while(players[current_player]["place"] != 0 && c < players.size()):
					current_player = pir[(pir.find(current_player)+1)%pir.size()]
					current_player_num = pir.find(current_player)
					c += 1
				if players.has(current_player):
					### call client functions
					rset("my_turn", false)
					rset_one(current_player, "my_turn", true)
					rpc_one(current_player, "startOfRound", null)
					rpc_all("set_current_player", [players[current_player]["name"]])
					
					### start timer for new player
					if !unlimit_time:
						timer.start(r_t)
					if !end_of_game:
						set_client_text()
		rounds += 1
			

func _on_Timer_timeout():
	### check if any player is left
	if players.size() > 0:
		### end players round
		rpc_one(current_player, "endOfRound", null)
		### update past calc
		rpc_all("set_past_calc", set_past_calc(PC_mode.time, ""))
		if(last_round):
			game_end()
		else:
			add_card_timeout(current_player)
			next_player()

func add_card_timeout(id):
	if !end_of_game:
		if current_player == id:
			for _i in range(2):
				rand = rnd.randi_range(0,9)
				
				players[id]["cards"].append(rand)
				rpc_one(id, "master_add_card", [[rand]])


func set_client_text():
	var sendstr = "[right]"
	if !unlimit_player:
		sendstr += "Players: " + str(players.size()) + "/" + str(max_players) + "\n"
		get_node("ClientConnect").text = "Connected Clients: " + str(players.size()) + "/" + str(max_players)
	else:
		sendstr += "Players: " + str(players.size()) + "/ unlimited\n"
		get_node("ClientConnect").text = "Connected Clients: " + str(players.size()) + "/ unlimited"
	
	for i in players:
		get_node("ClientConnect").text = str(get_node("ClientConnect").text) + "\n" + str(players[i]["name"] + " (" + str(i) + ")")
		if game_started:
			if(players[i]["place"] > 0):
				sendstr = sendstr +"(Done) "+ str(players[i]["name"]) + ": " + str(players[i]["cards"].size()) + "\n"
			elif i == current_player:
				sendstr = sendstr + "[color=black]" + str(players[i]["name"]) + ": " + str(players[i]["cards"].size()) + "[/color]\n"
			else:
				sendstr = sendstr + str(players[i]["name"]) + ": " + str(players[i]["cards"].size()) + "\n"
		else:
			sendstr = sendstr  + str(players[i]["name"]) + "\n"
	sendstr += "[/right]"
	rpc_all("update_player_list", [sendstr])


func _on_win_pressed():
	if players.size() != 0:
		player_done(players[0])

func _on_Contunue_pressed():
	if players.size() != 0:
		player_done(current_player)

func _on_End_pressed():
	pass

func _on_start_host_pressed():
	settings = get_node("Settings")

	add_child(MenuButtons)
	for i in range(bots.size()):
		get_node("MenuButtons/SelBot/Bots").add_item(bots[i], i)
	
	ipstring = encode_ip(global.ip)
	
	get_node("HostText").text = "Hosting on " + global.ip + ":" + str(global.port) + "\nLobby-Code: " + ipstring
	
	
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
	define_winner = get_node("Settings/order_by/sl").value
	
	unlimit_time = !get_node("Settings/max_rt/cb").is_pressed()
	unlimit_player = !get_node("Settings/max_play/cb").is_pressed()

	
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
		rpc_one(id, "Register_return", [true, key])
	else:
		rpc_one(id, "Register_return", [false, ""])
	db.close_db()

master func login(id, name, pwd, time):
	db.open_db()
	var query = "SELECT pwd FROM Users WHERE Name = ?"
	var bindings = [name]
	db.query_with_bindings(query, bindings)
	if db.query_result.size() > 0:
		var db_pwd = db.query_result[0]["pwd"]
		var local_pwd = str(db_pwd+time).sha256_text()
		if local_pwd == pwd:
			var key = PoolStringArray(OS.get_time().values()).join("")
			key = (key + name).sha256_text()
			key_names[key] = name
			rpc_id(id, "Login_return", true, key)
		else:
			rpc_id(id, "Login_return", false, 0)
	db.close_db()
	set_client_text()



func _on_Button2_pressed():
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			scrolled(-5)
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			scrolled(5)

func scrolled(move):#
	if(!host_started):
		var node = get_node("Settings")
		var screen = get_viewport().get_visible_rect().size.y
		
		node.set_global_position(Vector2(0,node.get_global_position().y + move))
		if(node.get_global_position().y > 0):
			node.set_global_position(Vector2(0,0))
		if node.get_global_position().y+400 < screen:
			if(screen > 400):
				node.set_global_position(Vector2(0,0))
			else:
				node.set_global_position(Vector2(0,screen-400))

func dec2bin(var decimal_value): 
	var binary_string = "" 
	var temp 
	var count = 7 # Checking up to 32 bits 
 
	while(count >= 0): 
		temp = decimal_value >> count 
		if(temp & 1): 
			binary_string = binary_string + "1" 
		else: 
			binary_string = binary_string + "0" 
		count -= 1 

	return binary_string

func bin2dec(var binary_value): 
	var decimal_value = 0 
	var count = 0 
	var temp 
 
	while(binary_value != 0): 
		temp = binary_value % 10 
		binary_value /= 10 
		decimal_value += temp * pow(2, count) 
		count += 1 
 
	return decimal_value


func rpc_all(function, values):

	for id in players:
		if players[id]["type"] == "bot" && function == "set_current_card":
			if bot_functions.has(function):		
				match bot_functions.find(function):
					0:
						get_node(str(id)).set_current_card(values)
					1:
						get_node(str(id)).master_add_card(values)
					2:
						get_node(str(id)).card_removed(values)
					3:
						get_node(str(id)).startOfRound()
		elif players[id]["type"] != "bot":
			if values != null:
				rpc_id(id, function, values)
			else:
				rpc_id(id, function)

func rpc_one(id, function, values):
	if players[id]["type"] != "bot":
		if values != null:
			if values.size() > 1:
				rpc_id(id, function, values[0], values[1])
			else:
				rpc_id(id, function, values[0])
		else:
			rpc_id(id, function)
		return
	
	if bot_functions.has(function):		
		match bot_functions.find(function):
			0:
				get_node(str(id)).set_current_card(values[0])
			1:
				get_node(str(id)).master_add_card(values[0])
			2:
				get_node(str(id)).card_removed(values[0])
			3:
				get_node(str(id)).startOfRound()


func rset_one(id, variable, value):
	if players[id]["type"] != "bot":
		rset_id(id, variable, value)
		return
	get_node(str(id)).set_variable(variable, value)
	
	



func _on_SelBot_pressed():
	bot_ids += 1

	players[bot_ids] = {}
	players[bot_ids]["name"] = null
	players[bot_ids]["place"] = null
	players[bot_ids]["cards"] = null
	players[bot_ids]["points"] = 0
	players[bot_ids]["name"] = get_node("MenuButtons/SelBot/name").text
	players[bot_ids]["place"] = -1
	players[bot_ids]["cards"] = []
	players[bot_ids]["type"] = "bot"
	pir.append(bot_ids)
	
	var bot = Node.new()
	
	bot.name = str(bot_ids);
	bot.set_script(load("res://Scripts/Bots/"+bots[get_node("MenuButtons/SelBot/Bots").selected]))
	
	self.add_child(bot)
	
	get_node(str(bot_ids)).give_id(bot_ids)


	if game_started:
		### if game started, give player imprtand information
		rpc_one(bot_ids, "set_current_card", [current_card])
		if(str(late_hand) == "avg"):
			### calculate average hand card number of all players
			var x = 0
			var n = 0
			for i in players:
				if players[i]["cards"].size() > 0:
					x += players[i]["cards"].size()
					n += 1
			x = x/n
			### give new player average number of cards
			for _i in range(x):
				rand = rnd.randi_range(0,9)
				
				players[bot_ids]["cards"].append(rand)
			rpc_one(bot_ids, "master_add_card", [players[bot_ids]["cards"]])
		else:
			for _i in range(late_hand):
				rand = rnd.randi_range(0,9)
				
				players[bot_ids]["cards"].append(rand)
			rpc_one(bot_ids, "master_add_card", [players[bot_ids]["cards"]])


	if !end_of_game:
		set_client_text()

func encode_ip(ip):
	var letters = ["Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Y", "X", "C", "V", "B", "N", "M", "a", "b", "g", "h", "r", "c"]
	var binip = ""
	
	for octet in ip.split("."):
		binip += dec2bin(int(octet))
	
	var out = ""
	
	for i in range(7):
		var start = i * 5
		var end = start + 5
		var bits = binip.substr(i,5)
		out += letters[bin2dec(int(bits))]
	
	return out




