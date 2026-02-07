extends HBoxContainer
class_name HandUI

@export var card_view_scene: PackedScene
var player_state: PlayerState = null

func set_player(p: PlayerState) -> void:
	player_state = p
	refresh()

func refresh() -> void:
	clear()
	if player_state == null:
		return

	for card in player_state.hand:
		var view: CardView = card_view_scene.instantiate()
		add_child(view)
		view.setup(card)

func clear() -> void:
	for c in get_children():
		c.queue_free()
