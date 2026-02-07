extends Node

@onready var round_manager: RoundManager = $RoundManager
@onready var white_hand: HandUI = $UI/WhiteHand
@onready var black_hand: HandUI = $UI/BlackHand
@onready var white_active: ActiveDeckUI = $UI/WhiteActiveDeck
@onready var black_active: ActiveDeckUI = $UI/BlackActiveDeck

func _ready() -> void:
	print("Main ready")

	round_manager.game_started.connect(_on_game_started)
	round_manager.hands_updated.connect(_on_hands_updated)

	round_manager.start_game()

func _on_game_started() -> void:
	white_hand.set_player(round_manager.white)
	black_hand.set_player(round_manager.black)

	white_active.set_player(round_manager.white)
	black_active.set_player(round_manager.black)

	white_hand.active_deck_changed.connect(func():
		white_active.refresh()
	)

	black_hand.active_deck_changed.connect(func():
		black_active.refresh()
	)

func _on_hands_updated() -> void:
	print("Main: hands updated")

	white_hand.refresh()
	black_hand.refresh()
