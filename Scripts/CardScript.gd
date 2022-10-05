extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Card_pressed():
	get_parent().get_parent().hand_card_pressed(self)
