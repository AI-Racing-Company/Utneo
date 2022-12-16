extends Node2D

var nue #no useless errors (returns a never used value)


var secret = ""

func _ready():
	
#	print("waiting for success respsonse")
#	var upnp = UPNP.new()
#	var discover_result = upnp.discover()
#
#
#	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
#		print("half success")
#		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
#			print("full success")
#	print("no success")

	pass

func _on_Client_pressed():
	### Get target IP and Port
	var input_ip = get_node("Client/target_IP").text
	var x = input_ip.split(":")
	global.ip = x[0]
	### Set custom port if exists
	if x.size() == 2:
		global.port = int(x[1])
	
	### load login screen
	nue = get_tree().change_scene("res://Scenes/Login-Screen.tscn")

func _on_Host_pressed():
	### set custom port if specified
	global.port = int(get_node("Host/host_port").text)
	
	### Get hosting IP
	for adress in IP.get_local_addresses():
		### check if IP is in local network
		if(adress.split(".").size() == 4 and (adress.split(".")[0] == "192" or adress.split(".")[0] == "10" )):
			global.ip = adress
	### alternative way to get IP
	if global.ip == "":
		global.ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)

	### load host scene
	nue = get_tree().change_scene("res://Scenes/UtNeO_host.tscn")


func _on_Client_LH_pressed():
	### set ip and get port
	global.ip = "localhost"
	global.port = int(get_node("Host/host_port").text)
	nue = get_tree().change_scene("res://Scenes/UtNeO_host.tscn")
	


func _on_Host_LH_pressed():
	### set ip and get port
	global.ip = "localhost"
	global.port = int(get_node("Host/host_port").text)
	nue = get_tree().change_scene("res://Scenes/Login-Screen.tscn")


func _on_Tutorial_pressed():
	### open tutorial url
	nue = OS.shell_open("http://utneo.rf.gd/")


func _input(_ev):
	if Input.is_key_pressed(KEY_D):
		secret += "D"
	if Input.is_key_pressed(KEY_E):
		secret += "E"
	if Input.is_key_pressed(KEY_V):
		secret += "V"
	if Input.is_key_pressed(KEY_L):
		secret += "L"
	if Input.is_key_pressed(KEY_O):
		secret += "O"
	if Input.is_key_pressed(KEY_P):
		secret += "P"
	if Input.is_key_pressed(KEY_R):
		secret += "R"
	if secret == "DEVELOPER":
		global.use_folder = "DEV"
		global.use_card_end = "_dev"
		
