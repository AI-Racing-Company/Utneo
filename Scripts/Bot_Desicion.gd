extends Node2D

var bots = ["Coltin", "Neko", "Nico"]

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var nue

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(bots.size()):
		get_node("SelBot/Bots").add_item(bots[i], i)
	

func _on_SelBot_pressed():
	var input_ip = get_node("SelBot/IP").text
	var x = input_ip.split(":")
	global.ip = x[0]
	### Set custom port if exists
	if x.size() == 2:
		global.port = int(x[1])
	
	global.username = get_node("SelBot/name").text
	
	global.bot = bots[get_node("SelBot/Bots").selected]
	
	### load login screen
	nue = get_tree().change_scene("res://Scenes/Bot.tscn")
