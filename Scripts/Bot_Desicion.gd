extends Node2D

var bots = ["Thomas.cs", "Timmothy.gd",  "Nico.gd", "Neko.gd", "Coltin.gd", "Elton.gd"]
var IPs = ["10.47.223.249", "192.168.8.75", "10.64.250.239"]

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var nue

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(bots.size()):
		get_node("SelBot/Bots").add_item(bots[i], i)
	for i in range(IPs.size()):
		get_node("SelBot/IPDEC").add_item(IPs[i], i)
	

func _on_SelBot_pressed():
	var input_ip = get_node("SelBot/IP").text
	var x = input_ip.split(":")
	global.ip = IPs[get_node("SelBot/IPDEC").selected]
	### Set custom port if exists
	if x.size() == 2:
		global.port = int(x[1])
	
	global.username = get_node("SelBot/name").text
	
	global.bot = bots[get_node("SelBot/Bots").selected]
	
	### load login screen
	nue = get_tree().change_scene("res://Scenes/Bot.tscn")
