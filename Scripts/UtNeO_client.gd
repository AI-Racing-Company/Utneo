extends Node2D

### TODO:
###
### Move "update current calculation" from _physics_process to button_pressed
###

var my_card_num = 0
var my_cards = []
var my_card_nodes = []
var current_calc = ["","","","","",null,null] # Array for Operation, value 1, value 2, name 1, name 2, card_id 1 and card_id 2
var selected_card = 0
var current_card = -1
var current_card_node = null
puppet var my_turn = false
var nue

var end_of_game = false

var my_end = false

var overRectAdd = 0

var width = 0
var height = 0

puppet var current_player = 0
puppet var current_player_name = ""

onready var timerRect = get_node("Timer/ColorRect")
onready var timer = get_node("Timer")
var r = 0    # value of red
var g = 1    # value of green
puppet var r_t = 60 # round time

var c = 0

var peer = null

func _ready():
	
	### Connect system functions to self-implemented ones:
	nue = get_viewport().connect("size_changed", self, "resized")
	nue = get_tree().connect("server_disconnected", self, "serversided_disconnect")
	
	### Init important things
	timer.set_autostart(false)
	resized()
	rpc_id(1, "give_key", global.my_id, global.login_key)
	
	


puppet func connection_established(id):
	global.my_id = id


func resized():
	
	### get new window size
	width = get_viewport().get_visible_rect().size.x
	height = get_viewport().get_visible_rect().size.y


	### calculate and set positions for hand cards
	var add = width / (my_card_nodes.size()+1)
	for i in range(len(my_card_nodes)):
		var vec = Vector2((i+1)*add - 75/2,height-90)
		my_card_nodes[i].set_global_position(vec)
		
	### center texts and objects
	get_node("Current Calculation").set_global_position(Vector2(width/2-75, height-185))
	get_node("Current Player").set_global_position(Vector2(width/2-75, 5))
	get_node("Timer/Time").set_global_position(Vector2(width/2-50, height - 165))
	if current_card_node != null:
		current_card_node.set_global_position(Vector2(width/2-100,height/2-150))
	
	### right side bound
	get_node("Player List").set_global_position(Vector2(width-get_node("Player List").get_rect().size.x-5, 5))
	
	### left side bound
	timerRect.set_global_position(Vector2(0,height - 160))
	get_node("past Calculations").set_global_position(Vector2(10,height - 325))
	
	### full-width
	get_node("WinnerMessage").set_global_position(Vector2(0,height-260))
	get_node("WinnerMessage").set_size(Vector2(width,50))

	get_node("OverColorRect").set_size(Vector2(width,100))
	get_node("OverColorRect").set_global_position(Vector2(0,height - 95 + overRectAdd))
	

func add_card():
	### mall master function to draw card
	if !my_end:
		rpc_id(1, "add_card", global.my_id)

puppet func master_add_card(rand):
	### return from function "add_card"
	
	### load card node
	var card = null
	card = load("res://Prefabs/Cards/NORM/Card_" + str(rand) + ".tscn").instance()

	### set card values
	card.set_name("card_"+str(rand)+"_")
	card.set_size(Vector2(75,100))

	### add card to screen and hand
	my_card_num += 1
	get_node("Cards").add_child(card)
	my_card_nodes.append(card)
	my_cards.append(rand)
	
	### call functions for visualazation
	resized()
	end_hover_above_card(card)

puppet func card_removed():
	
	### check if card has to be removed
	if(current_calc[3] != ""):
		### get card
		var x = my_card_nodes.find(get_node("Cards").get_node(current_calc[3]))
		
		### remove card from program and screen
		my_card_nodes.remove(x)
		my_cards.remove(x)
		get_node("Cards").remove_child(get_node("Cards").get_node(current_calc[3]))
		my_card_num -= 1
		
	### check if card has to be removed
	if(current_calc[4] != ""):
		### get card
		var x = my_card_nodes.find(get_node("Cards").get_node(current_calc[4]))
		
		### remove card from program and screen
		my_card_nodes.remove(x)
		my_cards.remove(x)
		get_node("Cards").remove_child(get_node("Cards").get_node(current_calc[4]))
		my_card_num -= 1
		
	### reset selected cards
	current_calc = ["","","","","","",""]
	selected_card = 0
	
	### reload graphics
	resized()
	

func hand_card_pressed(card):
	### check if move is allowed
	if my_turn && card.name != "" && !my_end && !end_of_game:
		### get value of card
		var value = card.name.split("_")
		var add = 0
		if selected_card:
			add = 1
		### add cards to current calc and make them less opace
		if(card.name != current_calc[4]):
			if current_calc[3+add] != "":
				current_calc[5+add].modulate.a8 = 100
			current_calc[5+add] = card
			current_calc[1+add] = value[1]
			current_calc[3+add] = card.name
			selected_card = 1-add
			card.modulate.a8 = 255
		


func serversided_disconnect():
	### remove server connection
	get_tree().network_peer = null

	### clear hand cards from program and screen
	for i in my_card_nodes:
		get_node("Cards").remove_child(i)
	my_card_nodes.clear()
	my_cards.clear()
	
	### return to lobby
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")


func button_pressed(operation):
	### check if move is allowed
	if my_turn && !my_end:

		### switch between different operations
		match operation:
			global.btn_modes.pus:
				### call master function cards pushed
				rpc_id(1,"cards_pushed",global.my_id,current_calc)
				selected_card = 0
			global.btn_modes.clr:
				### clear current cards and make them opace
				if str(current_calc[5]) != "" and current_calc[5] != null:
					current_calc[5].modulate.a8 = 100
				if str(current_calc[6]) != "" and current_calc[6] != null:
					current_calc[6].modulate.a8 = 100
				### reset current cards
				current_calc = ["","","","","",null,null]
				selected_card = 0

			_:
				### set operation
				current_calc[0] = operation


func _physics_process(_delta):
	### update timer text
	if !timer.is_stopped():
		get_node("Timer/Time").text = str(int(timer.time_left))
	
	### update timer rectangle
	if my_turn && str(r_t) != "infinite":
		if !timer.is_stopped():
			### set with and color according to left time
			timerRect.set_size(Vector2(width*(timer.time_left/r_t),20))

			timerRect.color = Color(r,g,0,1)

			### calculate color for next tick
			r = r + float(1) / (r_t*60)
			g = g - float(1) / (r_t*60)
	else:
		timerRect.set_size(Vector2(0,0))

	### Update current calculation
	get_node("Current Calculation").text = str(current_calc[1])
	var txt = get_node("Current Calculation").text
	get_node("Current Calculation").text = txt + str(current_calc[0])
	get_node("Current Calculation").text = get_node("Current Calculation").text + str(current_calc[2])

puppet func r_t_h(newRT):
	### set maximal round time
	r_t = newRT
	get_node("Timer/Time").text = str(r_t)

puppet func endOfRound():
	### reset currend cards and timer
	current_calc = ["","","","","","",""]
	timer.stop()
	overRectAdd = 0
	get_node("OverColorRect").set_global_position(Vector2(0,height - 100 + overRectAdd))

puppet func startOfRound():
	### reset currend cards, time color and timer
	current_calc = ["","","","","","",""]
	r=0
	g=1
	if str(r_t) != "infinite":
		timer.start(r_t)
	overRectAdd = 150
	get_node("OverColorRect").set_global_position(Vector2(0,height - 100 + overRectAdd))

puppet func set_current_card(_c):
	### update current card
	
	### remove current current_card_node, if exists
	if current_card_node != null:
		remove_child(current_card_node)
		
	### set numeric value of current card
	current_card = _c
	### load current card prefab
	current_card_node = load("res://Prefabs/Cards/NORM/Card_" + str(_c) + ".tscn").instance()
	current_card_node.set_name("current_card")
	current_card_node.set_size(Vector2(75,100))
	### add current card to screen 
	add_child(current_card_node)
	resized()

puppet func update_player_list(sendstr):
	### update player list
	get_node("Player List").text = sendstr

puppet func player_done(_p_name, _pos):
	pass
	#get_node("WinnerMessage").text = str(p_name) + " Won"

puppet func game_end():
	### end the game
	my_end = true
	end_of_game = true
	timer.stop()

puppet func set_current_player(pname):
	### set name and time of current player
	get_node("Current Player").text = pname
	if str(r_t) != "infinite":
		timer.start(r_t)

func disconnect_from_server():
	### Remove connection
	peer.close_connection()
	get_tree().network_peer = null
	### Go to Lobby
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")

puppet func set_past_calc(newText):
	get_node("past Calculations").text = str(newText)

puppet func my_end_f():
	my_end = true

func start_hover_above_card(card):
	### Make card less opace if player not done
	if !my_end:
		card.modulate.a8 = 255

func end_hover_above_card(card):
	### Make card more opace
	if current_calc[3] != card.name && current_calc[4] != card.name && !my_end:
		card.modulate.a8 = 100

puppet func set_winner(win):
	get_node("WinnerMessage").text = str(win) + " won"
