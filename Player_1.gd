extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var vel = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	


func move(w,a,s,d):
	if Input.is_action_pressed(a):
		vel.x = -10
	elif Input.is_action_pressed(d):
		vel.x =  10
	else:
		vel.x = 0
	if Input.is_action_pressed(w):
		vel.y = -10
	elif Input.is_action_pressed(s):
		vel.y =  10
	else:
		vel.y = 0
	
	move_and_collide(vel)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
