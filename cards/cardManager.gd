extends Node
class_name CardManager

@export var card_pool: Array[CardData]
const HAND_LIMIT := 6

var hand: Array[CardInstance] = []
signal hand_changed

func create_card() -> CardInstance:
	var data = card_pool.pick_random()
	return CardInstance.new(data)

func draw_cards_for_player(player: PlayerState, amount: int):
	for i in range(amount):
		player.hand.append(create_card())

func sync_from_player(player: PlayerState):
	hand.clear()
	for c in player.hand:
		hand.append(c)
	enforce_hand_limit()

func enforce_hand_limit():
	while hand.size() > HAND_LIMIT:
		hand.pop_front()
