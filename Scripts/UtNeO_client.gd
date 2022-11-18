extends Node2D

var my_card_num = 0
var my_cards = []
var my_card_nodes = []
var current_calc = ["","","","",""] # Array for Operation, value 1, value 2, name 1 and name 2
var selected_card = 0
var current_card = -1
var current_card_node = null
puppet var my_turn = false
var nue

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
	get_node("ClientText").text = "Connected To " + global.ip + ":" + str(global.port)
	nue = get_tree().connect("server_disconnected", self, "serversided_disconnect")
	timer.set_autostart(false)
	resized()
	rpc_id(1, "give_key", global.my_id, global.login_key)
	

puppet func connection_established(id):
	global.my_id = id
	print("Connection succsess")
	

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

	get_node("OverColorRect").set_size(Vector2(width,100))
	get_node("OverColorRect").set_global_position(Vector2(0,height - 100 + overRectAdd))

func add_card():
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
	current_calc = ["","","","",""]
	resized()
	selected_card = 0

func hand_card_pressed(card):
	if my_turn && card.name != "":
		var value = card.name.split("_")
		print("c name: " + card.name)
		if(!selected_card):
			if(card.name != current_calc[4]):
				current_calc[1] = value[1]
				current_calc[3] = card.name
				selected_card = 1
		else:
			if(card.name != current_calc[3]):
				current_calc[2] = value[1]
				current_calc[4] = card.name
				selected_card = 0

func serversided_disconnect():
	print("Server disconnected")
	peer.close_connection()
	get_tree().network_peer = null
	
	for i in my_card_nodes:
		get_node("Cards").remove_child(i)
	my_card_nodes.clear()
	my_cards.clear()
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")

func button_pressed(operation):
	if my_turn:
		if(operation != "Pus" && operation != "clear"):
			current_calc[0] = operation
		elif(operation == "Pus"):
			rpc_id(1,"cards_pushed",global.my_id,current_calc)
			selected_card = 0
		elif(operation == "clear"):
			current_calc = ["","","","",""]
			selected_card = 0


func _physics_process(delta):
	
	nue = delta
	update_player_timer()
	get_node("ClientText").text = str(current_card)
	if my_turn:
		get_node("ClientText").text = get_node("ClientText").text + " (My turn)"
		if !timer.is_stopped():
			timerRect.set_size(Vector2(20,2*timer.time_left))
			timerRect.set_global_position(Vector2(0,get_viewport().get_visible_rect().size.y/2-2*timer.time_left+r_t/2))
			timerRect.color = Color(r,g,0,1)

			r = r + float(1) / (r_t*60)
			g = g - float(1) / (r_t*60)
	else:
		timerRect.set_size(Vector2(0,0))


	get_node("Current Calculation").text = str(current_calc[1])
	var txt = get_node("Current Calculation").text
	get_node("Current Calculation").text = txt + str(current_calc[0])
	get_node("Current Calculation").text = get_node("Current Calculation").text + str(current_calc[2])


puppet func endOfRound():
	current_calc = ["","","","",""]
	timer.stop()
	overRectAdd = 0
	get_node("OverColorRect").set_global_position(Vector2(0,s_height - 100 + overRectAdd))

puppet func startOfRound():
	current_calc = ["","","","",""]
	r=0
	g=1
	timer.start(r_t)
	overRectAdd = 150
	get_node("OverColorRect").set_global_position(Vector2(0,s_height - 100 + overRectAdd))

puppet func set_current_card(c):
	if current_card_node != null:
		remove_child(current_card_node)
	current_card = c
	current_card_node = load("res://Prefabs/Cards/card_" + str(c) + "_dev.tscn").instance()
	current_card_node.set_name("current_card")
	current_card_node.set_size(Vector2(75,100))
	add_child(current_card_node)
	resized()

puppet func update_player_list(sendstr):
	get_node("Player List").text = sendstr

func update_player_timer():
	get_node("Current Player").text = current_player_name + ": " + str(int(timer.time_left))

puppet func player_done(p_name, pos):
	p_name = pos
	pass
	#get_node("WinnerMessage").text = str(p_name) + " Won"

puppet func game_end():
	pass

puppet func set_current_player(pname):
	current_player_name = pname
	timer.start(r_t)
func disconnect_from_server():
	nue = get_tree().change_scene("res://Scenes/LobbyScene.tscn")
	get_tree().network_peer = null
	peer.close_connection()



func start_hover_above_card(card):
	card.modulate.a8 = 255

func end_hover_above_card(card):
	card.modulate.a8 = 100
