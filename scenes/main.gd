extends Node

@onready var round_manager: RoundManager = $RoundManager
@onready var white_hand: HandUI = $UI/WhiteHand
@onready var black_hand: HandUI = $UI/BlackHand

func _ready() -> void:
	print("Main ready")

	round_manager.game_started.connect(_on_game_started)
	round_manager.hands_updated.connect(_on_hands_updated)

	round_manager.start_game()

func _on_game_started() -> void:
	print("Main: game started")

	white_hand.set_player(round_manager.white)
	black_hand.set_player(round_manager.black)

func _on_hands_updated() -> void:
	print("Main: hands updated")

	white_hand.refresh()
	black_hand.refresh()
