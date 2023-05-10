extends Node2D

var nue #no useless errors (returns a never used value)


var secret = ""

func _ready():
	pass

func _on_Client_pressed():
	### Get target IP and Port
	var input_ip = get_node("Client/target_IP").text
	decode_ip(input_ip)
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
		


func _on_Bot_pressed():
	
	nue = get_tree().change_scene("res://Scenes/Bot_Desicion.tscn")


func dec2bin(var decimal_value): 
	var binary_string = "" 
	var temp 
	var count = 7 # Checking up to 32 bits 
 
	while(count >= 0): 
		temp = decimal_value >> count 
		if(temp & 1): 
			binary_string = binary_string + "1" 
		else: 
			binary_string = binary_string + "0" 
		count -= 1 

	return binary_string

func bin2dec(var binary_value): 
	var decimal_value = 0 
	var count = 0 
	var temp 
 
	while(binary_value != 0): 
		temp = binary_value % 10 
		binary_value /= 10 
		decimal_value += temp * pow(2, count) 
		count += 1 
 
	return decimal_value

var bin_lookup = {
	"Q": "00000",
	"W": "00001",
	"E": "00010",
	"R": "00011",
	"T": "00100",
	"Z": "00101",
	"U": "00110",
	"I": "00111",
	"O": "01000",
	"P": "01001",
	"A": "01010",
	"S": "01011",
	"D": "01100",
	"F": "01101",
	"G": "01110",
	"H": "01111",
	"J": "10000",
	"K": "10001",
	"L": "10010",
	"Y": "10011",
	"X": "10100",
	"C": "10101",
	"V": "10110",
	"B": "10111",
	"N": "11000",
	"M": "11001",
	"a": "11010",
	"b": "11011",
	"g": "11100",
	"h": "11101",
	"r": "11110",
	"c": "11111"
}

func decode_ip(ip):
	var split_ip = []
	for c in ip:
		split_ip.append(c)
	
	var bin_str = ""
	for c in split_ip:
		bin_str += bin_lookup[c]
	
	var binip0 = bin_str.substr(0, 8)
	var binip1 = bin_str.substr(8, 8)
	var binip2 = bin_str.substr(16, 8)
	var binip3 = bin_str.substr(24, 8)
	
	var decip0 = bin2dec(int(binip0))
	var decip1 = bin2dec(int(binip1))
	var decip2 = bin2dec(int(binip2))
	var decip3 = bin2dec(int(binip3))
	
	print(decip0,".",decip1,".",decip2,".",decip3)
