extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().get_node(self.get_name()).set_script(load("res://Scripts/Bots/"+global.bot+".gd"))
	print("connected Script")
	get_parent().get_node(self.get_name())._ready()

