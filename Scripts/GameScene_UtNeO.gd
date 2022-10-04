extends Node2D

var btns = ["Add","Sub","Mul","Div","Pot"]

func _ready():
		get_viewport().connect("size_changed", self, "resized")


func resized():
	var x = get_viewport().get_visible_rect().size.x
	var y = get_viewport().get_visible_rect().size.y
	get_node("HandPos/ColorRect").set_size(Vector2(x,100))
	get_node("HandPos/ColorRect").set_global_position(Vector2(0,y - 100))
	var offset = x/5
	for i in range(len(btns)):
		get_node("SelectActionButtons/"+str(btns[i])).set_global_position(Vector2(i*offset,y-140))
		get_node("SelectActionButtons/"+str(btns[i])).set_size(Vector2(offset,40))
	
