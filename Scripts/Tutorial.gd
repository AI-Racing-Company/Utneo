extends Node2D

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

var tutData

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
	var db = SQLite.new()
	db.path = "res://Data/tutorial"
	
	db.open_db()
	var query = "SELECT * FROM tutorial"
	db.query(query)
	tutData = db.query_result
	
	db.close_db()
	
	#print(tutData)
		
	

func resized():
	
	width = get_viewport().get_visible_rect().size.x
	height = get_viewport().get_visible_rect().size.y
	if my_card_nodes:
		
		var add = width / (my_card_nodes.size()+1)
		for i in range(len(my_card_nodes)):
			var vec = Vector2((i+1)*add - 75/2,height-90)
			my_card_nodes[i].set_global_position(vec)
	get_node("Current Calculation").set_global_position(Vector2(width/2-75, height-185))
	if current_card_node != null:
		current_card_node.set_global_position(Vector2(width/2-100,height/2-150))
	get_node("Player List").set_global_position(Vector2(width-get_node("Player List").get_rect().size.x-5, 5))

	get_node("Current Player").set_global_position(Vector2(width/2-75, 5))
	get_node("Timer/Time").set_global_position(Vector2(width/2-50, height - 165))

	get_node("OverColorRect").set_size(Vector2(width,100))
	timerRect.set_global_position(Vector2(0,height - 160))
	get_node("past Calculations").set_global_position(Vector2(10,height - 325))

func _physics_process(delta):
	OS.set_window_size(Vector2(900, 600))
