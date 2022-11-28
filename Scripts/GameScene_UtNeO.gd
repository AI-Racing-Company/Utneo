extends Node2D
var nue
var btns = ["Add","Sub","Mul","Div","Pot","Sqr"]

func _ready():
		nue = get_viewport().connect("size_changed", self, "resized")
		resized()


func resized():
	var x = get_viewport().get_visible_rect().size.x
	var y = get_viewport().get_visible_rect().size.y
	get_node("HandPos/ColorRect").set_size(Vector2(x,100))
	get_node("HandPos/ColorRect").set_global_position(Vector2(0,y - 100))
	get_node("ColorRect2").set_size(Vector2(x,20))
	get_node("ColorRect2").set_global_position(Vector2(0,y - 200))
	var offset = x/6
	for i in range(len(btns)):
		get_node("SelectActionButtons/"+str(btns[i])).set_global_position(Vector2(i*offset,y-140))
		get_node("SelectActionButtons/"+str(btns[i])).set_size(Vector2(offset,40))
	get_node("SelectActionButtons/ULTIMATE_PUSH").set_size(Vector2(x,40))
	get_node("SelectActionButtons/ULTIMATE_PUSH").set_global_position(Vector2(0,y-180))
	get_node("PutCardsHere").set_global_position(Vector2(x/2-105,y/2-155))
	get_node("Draw_Card").set_global_position(Vector2(x/2+25,y/2-150))
	
	get_node("SelectActionButtons/Clear").set_size(Vector2(offset,40))
	get_node("SelectActionButtons/Clear").set_global_position(Vector2(x-offset,y-240))
	

func _on_Draw_Card_pressed():
	get_parent().add_card()


func _on_Add_pressed():
	get_parent().button_pressed(global.btn_modes.add)


func _on_Sub_pressed():
	get_parent().button_pressed(global.btn_modes.sub)


func _on_Mul_pressed():
	get_parent().button_pressed(global.btn_modes.mul)


func _on_Div_pressed():
	get_parent().button_pressed(global.btn_modes.div)


func _on_Pot_pressed():
	get_parent().button_pressed(global.btn_modes.pot)

func _on_Sqr_pressed():
	get_parent().button_pressed(global.btn_modes.sqr)

func _on_Clear_pressed():
	get_parent().button_pressed(global.btn_modes.clr)


func _on_ULTIMATE_PUSH_pressed():
	get_parent().button_pressed(global.btn_modes.pus)

func _on_Disconnect_pressed():
	get_parent().disconnect_from_server()
	
	
