extends Node2D

var TB_pos = []
var TutNow = 0
var TutText

var nue
var width
var height

var my_card_nodes
var current_card_node

var overRectAdd

onready var timerRect = get_node("Timer/ColorRect")
onready var timer = get_node("Timer")

func _ready():
	timer.set_autostart(false)
	resized()
	
	var file = File.new()
	file.open("res://Data/tutorial.json", File.READ)
	TutText = parse_json(file.get_as_text())
	file.close()
	print(TutText["tutorial"])
	print(TutText["tutorial"][1]["text"])
	

func resized():
	width = get_viewport().get_visible_rect().size.x
	height = get_viewport().get_visible_rect().size.y
	if my_card_nodes:
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
		get_node("Timer/Time").set_global_position(Vector2(width/2-50, height - 205))

		get_node("OverColorRect").set_size(Vector2(width,100))
		get_node("OverColorRect").set_global_position(Vector2(0,height - 100 + overRectAdd))
		timerRect.set_global_position(Vector2(0,height - 200))
		get_node("past Calculations").set_global_position(Vector2(10,height - 360))
