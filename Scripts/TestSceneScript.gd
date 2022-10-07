extends Node2D


func _ready():
	pass

func _on_Client_pressed():
	var input_ip = get_node("Client/target_IP").text
	var x = input_ip.split(":")
	global.ip = x[0]
	if x.size() == 2:
		global.port = int(x[1])
	get_tree().change_scene("res://Scenes/client_scene.tscn")

func _on_Host_pressed():
	global.port = int(get_node("Host/host_port").text)
	get_tree().change_scene("res://Scenes/host_scene.tscn")
