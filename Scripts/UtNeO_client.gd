extends Node2D

var my_card_num = 0
var my_cards = []
var my_card_nodes = []
var rnd = RandomNumberGenerator.new()

func _ready():
	get_viewport().connect("size_changed", self, "resized")
	card_drawn(1)


func resized():
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	var add = width / (my_card_num+1)
	for i in range(len(my_card_nodes)):
		var vec = Vector2((i+1)*add - 75/2,height-100)
		my_card_nodes[i].set_global_position(vec)
	

func card_drawn(card):
	my_card_num += 1
	
	var tcard = preload("res://Prefabs/Cards/Card_0_dev.tscn").instance()
	tcard.set_name("player_"+str(1))


	tcard.set_size(Vector2(75,100))
	get_node("Cards").call_deferred("add_child", tcard)
	my_card_nodes.append(tcard)
	resized()
	
func card_removed(card):
	my_card_nodes.erase(card)
	my_card_num -= 1
