extends TextureButton

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Card_pressed():
	parent.get_parent().hand_card_pressed(self)


func _on_Area2D_mouse_entered():
	self.set_global_position(self.get_global_position().x, self.get_global_position().y - 50)


func _on_Area2D_mouse_exited():
	self.set_global_position(self.get_global_position().x, self.get_global_position().y + 50)
