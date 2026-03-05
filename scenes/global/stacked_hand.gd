extends Control

func add_card(card_ui: CardUI):
	add_child(card_ui)
	card_ui.position = Vector2.ZERO
	card_ui.z_index = get_child_count()
