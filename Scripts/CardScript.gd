extends TextureButton

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Card_pressed():
	if self.name != "current_card":
		get_parent().get_parent().hand_card_pressed(self)

func _on_Card_mouse_entered():
	if self.name != "current_card":
		get_parent().get_parent().start_hover_above_card(self)
		

func _on_Card_mouse_exited():
	if self.name != "current_card":
		get_parent().get_parent().end_hover_above_card(self)
		
