extends HBoxContainer
class_name ActiveDeckUI

var player_state: PlayerState

func set_player(p: PlayerState) -> void:
	player_state = p
	refresh()

func refresh() -> void:
	for c in get_children():
		c.queue_free()

	if player_state == null:
		return

	for card in player_state.active_deck:
		var label := Label.new()
		label.text = card.name
		add_child(label)
