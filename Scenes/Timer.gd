extends Timer
# Declare member variables here. Examples:
var r = 0    # value of red
var g = 1    # value of green
var r_t = 60 # round time

# Called when the node enters the scene tree for the first time.
func _ready():
	start(r_t)
	
func _on_Timer_timeout():
	r = 0
	g = 1
	
func _physics_process(delta):
	get_node("ColorRect").set_size(Vector2(30,2*self.time_left))
	get_node("ColorRect").set_global_position(Vector2(0,320-2*self.time_left))
	get_node("ColorRect").color = Color(r,g,0,1)
	
	r = r + float(1) / (r_t*60)
	g = g - float(1) / (r_t*60)
