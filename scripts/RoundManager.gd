extends Node
class_name RoundManager

signal game_started
signal hands_updated

var white: PlayerState
var black: PlayerState

const BASE_AP := 2

func start_game():
	print("RoundManager: start_game")

	white = PlayerState.new()
	white.is_white = true

	black = PlayerState.new()
	black.is_white = false

	white.deck = CardDatabase.make_test_deck()
	black.deck = CardDatabase.make_test_deck()

	white.draw(5)
	black.draw(5)

	emit_signal("game_started")
	emit_signal("hands_updated")

func start_round():
	print("RoundManager: start_round")

	white.ap = white.saved_ap + BASE_AP
	black.ap = black.saved_ap + BASE_AP

	white.draw(2)
	black.draw(2)

	emit_signal("hands_updated")
