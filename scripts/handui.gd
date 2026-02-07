extends HBoxContainer
class_name HandUI

@export var card_view_scene: PackedScene
var player_state: PlayerState = null
signal active_deck_changed

func set_player(p: PlayerState) -> void:
	player_state = p
	refresh()

func refresh() -> void:
	clear()

	if player_state == null:
		return

	if card_view_scene == null:
		push_error("HandUI: card_view_scene is NULL")
		return

	for card in player_state.hand:
		var view: CardView = card_view_scene.instantiate()
		add_child(view)
		view.setup(card)

		view.card_toggled.connect(func(c, selected):
			_on_card_toggled(c, selected, view)
		)
		
func _on_card_toggled(card: Card, selected: bool, view: CardView) -> void:
	if selected:
		if not player_state.can_select_more_cards():
			view.selected = false
			view.update_visual()
			return

		player_state.select_card(card)
	else:
		player_state.unselect_card(card)

	active_deck_changed.emit()

func clear() -> void:
	for c in get_children():
		c.queue_free()
