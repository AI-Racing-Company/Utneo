extends Node2D


func _ready():
	pass

func _on_Client_pressed():
	var input_ip = get_node("Client/target_IP").text
	var x = input_ip.split(":")
	global.ip = x[0]
	if x.size() == 2:
		global.port = int(x[1])
	get_tree().change_scene("res://Scenes/UtNeO_client.tscn")

func _on_Host_pressed():
	global.port = int(get_node("Host/host_port").text)
	global.ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	get_tree().change_scene("res://Scenes/UtNeO_host.tscn")
