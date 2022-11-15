extends Node2D
var nue #no useless errors (returns a never used value)

func _ready():
	pass

func _on_Client_pressed():
	var input_ip = get_node("Client/target_IP").text
	var x = input_ip.split(":")
	global.ip = x[0]
	if x.size() == 2:
		global.port = int(x[1])
	global.username = get_node("Client/name").text
	nue = get_tree().change_scene("res://Scenes/Login-Screen.tscn")

func _on_Host_pressed():
	global.port = int(get_node("Host/host_port").text)
	for adress in IP.get_local_addresses():
		if(adress.split(".").size() == 4 and (adress.split(".")[0] == "192" or adress.split(".")[0] == "10" )):
			global.ip = adress
	if global.ip == "":
		global.ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)

	nue = get_tree().change_scene("res://Scenes/UtNeO_host.tscn")


func _on_Client_LH_pressed():
	global.ip = "localhost"
	nue = get_tree().change_scene("res://Scenes/UtNeO_host.tscn")
	


func _on_Host_LH_pressed():
	global.ip = "localhost"
	global.username = get_node("Client/name").text
	nue = get_tree().change_scene("res://Scenes/Login-Screen.tscn")
