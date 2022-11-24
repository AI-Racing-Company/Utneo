extends Node2D

var my_card_num = 0
var my_cards = []
var my_card_nodes = []
var current_calc = ["","","","","","",""] # Array for Operation, value 1, value 2, name 1, name 2, card_id 1 and card_id 2
var selected_card = 0
var current_card = -1
var current_card_node = null
puppet var my_turn = false
var nue

var end_of_game = false

var my_end = false

var overRectAdd = 0

var s_width = 0
var s_height = 0

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
	nue = get_viewport().connect("size_changed", self, "resized")
	nue = get_tree().connect("server_disconnected", self, "serversided_disconnect")
	timer.set_autostart(false)
	resized()
	rpc_id(1, "give_key", global.my_id, global.login_key)


puppet func connection_established(id):
	global.my_id = id


func resized():
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	s_width = width
	s_height = height
	var add = width / (my_card_nodes.size()+1)
	for i in range(len(my_card_nodes)):
		var vec = Vector2((i+1)*add - 75/2,height-100)
		my_card_nodes[i].set_global_position(vec)
	get_node("Current Calculation").set_global_position(Vector2(width/2-75, height-225))
	if current_card_node != null:
		current_card_node.set_global_position(Vector2(width/2-100,height/2-150))
	get_node("Player List").set_global_position(Vector2(width-get_node("Player List").get_rect().size.x-5, 5))
	get_node("WinnerMessage").set_global_position(Vector2(0,height-275))
	get_node("WinnerMessage").set_size(Vector2(width,50))

	get_node("Current Player").set_global_position(Vector2(width/2-75, 5))
	get_node("Timer/Time").set_global_position(Vector2(width/2-75, s_height - 205))

	get_node("OverColorRect").set_size(Vector2(width,100))
	get_node("OverColorRect").set_global_position(Vector2(0,height - 100 + overRectAdd))
	timerRect.set_global_position(Vector2(0,s_height - 200))
	get_node("past Calculations").set_global_position(Vector2(10,s_height - 360))

func add_card():
	if !my_end:
		rpc_id(1, "add_card", global.my_id)

puppet func master_add_card(rand):

	var card = null

	card = load("res://Prefabs/Cards/card_" + str(rand) + "_dev.tscn").instance()

	card.set_name("card_"+str(rand)+"_")
	card.set_size(Vector2(75,100))

	my_card_num += 1
	get_node("Cards").add_child(card)

	my_card_nodes.append(card)
	my_cards.append(rand)
	resized()
	end_hover_above_card(card)

puppet func card_removed():
	if(current_calc[3] != ""):
		var x = my_card_nodes.find(get_node("Cards").get_node(current_calc[3]))
		my_card_nodes.remove(x)
		my_cards.remove(x)

		get_node("Cards").remove_child(get_node("Cards").get_node(current_calc[3]))
	if(current_calc[4] != ""):
		var x = my_card_nodes.find(get_node("Cards").get_node(current_calc[4]))
		my_card_nodes.remove(x)
		my_cards.remove(x)
		get_node("Cards").remove_child(get_node("Cards").get_node(current_calc[4]))
		my_card_num -= 1
	my_card_num -= 1
	current_calc = ["","","","","","",""]
	resized()
	selected_card = 0

func hand_card_pressed(card):
	if my_turn && card.name != "" && !my_end && !end_of_game:
		var value = card.name.split("_")
		if(!selected_card):
			if(card.name != current_calc[4]):
				if current_calc[3] != "":
					current_calc[5].modulate.a8 = 100
				current_calc[5] = card
				current_calc[1] = value[1]
				current_calc[3] = card.name
				selected_card = 1
				card.modulate.a8 = 255
		else:
			if(card.name != current_calc[3]):
				if current_calc[4] != "":
					current_calc[6].modulate.a8 = 100
				current_calc[6] = card
				current_calc[2] = value[1]
				current_calc[4] = card.name
				selected_card = 0
				card.modulate.a8 = 255

func serversided_disconnect():
	get_tree().network_peer = null

	for i in my_card_nodes:
		get_node("Cards").remove_child(i)
	my_card_nodes.clear()
	my_cards.clear()
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")


func button_pressed(operation):

	if my_turn && !my_end:

		match operation:
			"Pus":
				rpc_id(1,"cards_pushed",global.my_id,current_calc)
				selected_card = 0
			"clear":
				current_calc[5].modulate.a8 = 100
				current_calc[6].modulate.a8 = 100
				current_calc = ["","","","","","",""]
				selected_card = 0

			_:
				current_calc[0] = operation


func _physics_process(_delta):
	if !timer.is_stopped():
		get_node("Timer/Time").text = str(int(timer.time_left))
	if my_turn:
		if !timer.is_stopped():
			timerRect.set_size(Vector2(s_width*(timer.time_left/r_t),20))

			timerRect.color = Color(r,g,0,1)


			r = r + float(1) / (r_t*60)
			g = g - float(1) / (r_t*60)
	else:
		timerRect.set_size(Vector2(0,0))


	get_node("Current Calculation").text = str(current_calc[1])
	var txt = get_node("Current Calculation").text
	get_node("Current Calculation").text = txt + str(current_calc[0])
	get_node("Current Calculation").text = get_node("Current Calculation").text + str(current_calc[2])

puppet func r_t_h(newRT):
	r_t = newRT
	get_node("Timer/Time").text = str(r_t)

puppet func endOfRound():
	current_calc = ["","","","","","",""]
	timer.stop()
	overRectAdd = 0
	get_node("OverColorRect").set_global_position(Vector2(0,s_height - 100 + overRectAdd))

puppet func startOfRound():
	current_calc = ["","","","","","",""]
	r=0
	g=1
	timer.start(r_t)
	overRectAdd = 150
	get_node("OverColorRect").set_global_position(Vector2(0,s_height - 100 + overRectAdd))

puppet func set_current_card(_c):
	if current_card_node != null:
		remove_child(current_card_node)
	current_card = _c
	current_card_node = load("res://Prefabs/Cards/card_" + str(_c) + "_dev.tscn").instance()
	current_card_node.set_name("current_card")
	current_card_node.set_size(Vector2(75,100))
	add_child(current_card_node)
	resized()

puppet func update_player_list(sendstr):
	get_node("Player List").text = sendstr



puppet func player_done(_p_name, _pos):
	pass
	#get_node("WinnerMessage").text = str(p_name) + " Won"

puppet func game_end():
	my_end = true
	end_of_game = true
	timer.stop()

puppet func set_current_player(pname):
	get_node("Current Player").text = pname
	timer.start(r_t)

func disconnect_from_server():
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")
	get_tree().network_peer = null
	peer.close_connection()

puppet func set_past_calc(newText):
	get_node("past Calculations").text = str(newText)

puppet func my_end():
	my_end = true

func start_hover_above_card(card):
	if !my_end:
		card.modulate.a8 = 255

func end_hover_above_card(card):
	if current_calc[3] != card.name && current_calc[4] != card.name && !my_end:
		card.modulate.a8 = 100
