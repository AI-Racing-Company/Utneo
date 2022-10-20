extends TextureButton

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Card_pressed():
	get_parent().get_parent().hand_card_pressed(self)



func _on_Area2D_mouse_entered():
	get_parent().get_parent().start_hover_above_card(self)


func _on_Area2D_mouse_exited():
	get_parent().get_parent().end_hover_above_card(self)
