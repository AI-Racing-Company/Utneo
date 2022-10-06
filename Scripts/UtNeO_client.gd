extends Node2D

var my_id = 0
var my_card_num = 0
var my_cards = []
var my_card_nodes = []
var operation_value0_value1_cname0_cname1 = ["",0,0, "", ""]
var selected_card = 0

onready var timerRect = get_node("Timer/ColorRect")
onready var timer = get_node("Timer") 
var r = 0    # value of red
var g = 1    # value of green
var r_t = 60 # round time

var peer = null

func _ready():
	get_viewport().connect("size_changed", self, "resized")
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(global.ip, global.port)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	get_node("ClientText").text = "Connected To " + global.ip + ":" + str(global.port)
	#get_tree().connect("connected_to_server", self, "connected_to_server")
	#get_tree().connect("connection_failed", self, "connection_failed")
	get_tree().connect("server_disconnected", self, "serversided_disconnect")

puppet func connection_established(id):
	my_id = id
	print("Connection succsess")

func resized():
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	var add = width / (my_card_num+1)
	for i in range(len(my_card_nodes)):
		var vec = Vector2((i+1)*add - 75/2,height-100)
		my_card_nodes[i].set_global_position(vec)

func add_card():
	rpc_id(0, "add_card", my_id)

puppet func master_add_card(rand):

	var card = null
	match rand:
		0:
			card = preload("res://Prefabs/Cards/card_0_dev.tscn").instance()
		1:
			card = preload("res://Prefabs/Cards/card_1_dev.tscn").instance()
		2:
			card = preload("res://Prefabs/Cards/card_2_dev.tscn").instance()
		3:
			card = preload("res://Prefabs/Cards/card_3_dev.tscn").instance()
		4:
			card = preload("res://Prefabs/Cards/card_4_dev.tscn").instance()
		5:
			card = preload("res://Prefabs/Cards/card_5_dev.tscn").instance()
		6:
			card = preload("res://Prefabs/Cards/card_6_dev.tscn").instance()
		7:
			card = preload("res://Prefabs/Cards/card_7_dev.tscn").instance()
		8:
			card = preload("res://Prefabs/Cards/card_8_dev.tscn").instance()
		9:
			card = preload("res://Prefabs/Cards/card_9_dev.tscn").instance()

	card.set_name("card_"+str(rand)+"_")
	card.set_size(Vector2(75,100))

	my_card_num += 1
	get_node("Cards").call_deferred("add_child", card)

	my_card_nodes.append(card)
	resized()

puppet func card_removed():
	my_card_nodes.erase(get_node("Cards").get_node(operation_value0_value1_cname0_cname1[3]))
	my_card_nodes.erase(get_node("Cards").get_node(operation_value0_value1_cname0_cname1[4]))
	get_node("Cards").remove_child(get_node("Cards").get_node(operation_value0_value1_cname0_cname1[3]))
	get_node("Cards").remove_child(get_node("Cards").get_node(operation_value0_value1_cname0_cname1[4]))
	my_card_num -= 2
	resized()

func hand_card_pressed(card):
	var value = card.name.split("_")
	if(!selected_card):
		operation_value0_value1_cname0_cname1[1] = value[1]
		operation_value0_value1_cname0_cname1[3] = card.name
		print(operation_value0_value1_cname0_cname1[3])
		selected_card = 1
	else:
		operation_value0_value1_cname0_cname1[2] = value[1]
		operation_value0_value1_cname0_cname1[4] = card.name
		selected_card = 0

func serversided_disconnect():
	print("Server disconnected")
	get_tree().network_peer = null
	peer.close_connection()
	for i in my_card_nodes:
		get_node("Cards").remove_child(i)
	my_card_nodes.clear()
	get_tree().change_scene("res://Scenes/LobbyScene.tscn")

func button_pressed(operation):

	if(operation != "Pus"):
		operation_value0_value1_cname0_cname1[0] = operation
	elif(operation == "Pus"):
		rpc_id(1,"cards_pushed",my_id,operation_value0_value1_cname0_cname1)

func _physics_process(delta):
	timerRect.set_size(Vector2(30,2*timer.time_left))
	timerRect.set_global_position(Vector2(0,320-2*timer.time_left))
	timerRect.color = Color(r,g,0,1)
	
	r = r + float(1) / (r_t*60)
	g = g - float(1) / (r_t*60)

puppet func startGame():
	timer.start(r_t)

puppet func endOfRound():
	print("Round end")
