extends Button
class_name CardView

var card: Card
var selected := false

signal card_toggled(card: Card, selected: bool)

func setup(c: Card) -> void:
	card = c
	text = c.name
	update_visual()

func _pressed() -> void:
	selected = !selected
	update_visual()
	card_toggled.emit(card, selected)

func update_visual() -> void:
	if selected:
		modulate = Color(0.8, 0.9, 1.0) # light blue
	else:
		modulate = Color.WHITE
