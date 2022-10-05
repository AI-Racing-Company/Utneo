extends Node2D

var my_card_num = 0
var my_cards = []
var my_card_nodes = []
var rnd = RandomNumberGenerator.new()
var rand = 0

func _ready():
	get_viewport().connect("size_changed", self, "resized")



func resized():
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	var add = width / (my_card_num+1)
	for i in range(len(my_card_nodes)):
		var vec = Vector2((i+1)*add - 75/2,height-100)
		my_card_nodes[i].set_global_position(vec)

func add_card():
	var player = null
	rand = rnd.randi_range(0,9)
	match rand:
		0:
			player = preload("res://Prefabs/Cards/card_0_dev.tscn").instance()
		1:
			player = preload("res://Prefabs/Cards/card_1_dev.tscn").instance()
		2:
			player = preload("res://Prefabs/Cards/card_2_dev.tscn").instance()
		3:
			player = preload("res://Prefabs/Cards/card_3_dev.tscn").instance()
		4:
			player = preload("res://Prefabs/Cards/card_4_dev.tscn").instance()
		5:
			player = preload("res://Prefabs/Cards/card_5_dev.tscn").instance()
		6:
			player = preload("res://Prefabs/Cards/card_6_dev.tscn").instance()
		7:
			player = preload("res://Prefabs/Cards/card_7_dev.tscn").instance()
		8:
			player = preload("res://Prefabs/Cards/card_8_dev.tscn").instance()
		9:
			player = preload("res://Prefabs/Cards/card_9_dev.tscn").instance()

	player.set_name("player_"+str(1))
	card_drawn(player)

func card_drawn(card):
	my_card_num += 1

	card.set_size(Vector2(75,100))
	get_node("Cards").call_deferred("add_child", card)

	my_card_nodes.append(card)
	resized()

func card_removed(card):
	my_card_nodes.erase(card)
	my_card_num -= 1

func hand_card_pressed(card_id):
	print("I've been pressed")


func _physics_process(delta):
	rand = rnd.randi()
