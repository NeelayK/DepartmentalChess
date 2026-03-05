extends Node
class_name RoundManager

const BASE_AP_PER_ROUND := 2
const MAX_SELECTION := 3
const HAND_CAP := 6

enum RoundPhase { CARD_SELECTION, REVEAL, PLAY }

signal round_started(player_index: int)
signal phase_changed(new_phase)
signal active_player_changed(player_index: int)

@onready var card_manager: CardManager = $"../CardManager"
@onready var deck_ui: Control = $"../UI"
@onready var player1: PlayerState = $"../Player1"
@onready var player2: PlayerState = $"../Player2"
@onready var board := $"../../BoardRoot/Board"
@onready var round_manager := $"."

@onready var hand_area = $"../UI/HandArea"
@onready var play_button = $"../UI/PlayButton"
var players: Array[PlayerState]
var active_player_index := 0
var selected_cards: Array[Array] = [[], []]
var confirmed_players := [false, false]
var phase := RoundPhase.CARD_SELECTION
var round_index := 0
var last_round_ender := 1

var cards_locked := false


var check_starter_override := -1

func end_action_turn():
	var other = 1 - active_player_index

	if players[other].ap <= 0:
		print("Next player has no AP. Ending round.")
		end_round()
		return

	set_active_player(other)



func _on_phase_changed(new_phase):
	match new_phase:
		RoundManager.RoundPhase.CARD_SELECTION:
			hand_area.show()
			play_button.show()
		
		RoundManager.RoundPhase.PLAY:
			hand_area.hide()
			play_button.hide()
			
		RoundManager.RoundPhase.REVEAL:
			play_button.hide()

func end_round():
	check_starter_override = -1
	if board.is_king_in_check(true):
		check_starter_override = 0
	elif board.is_king_in_check(false):
		check_starter_override = 1
		
	for p in players: p.hand.clear()
	round_index += 1
	start_round()

func determine_starting_player():
	if check_starter_override != -1:
		set_active_player(check_starter_override)
		return
		
	if players[0].ap > players[1].ap:
		set_active_player(0)
	elif players[1].ap > players[0].ap:
		set_active_player(1)
	else:
		set_active_player(0 if round_index == 0 else 1 - last_round_ender)


func confirm_selection(player_index: int):
	confirmed_players[player_index] = true
	if confirmed_players[0] and confirmed_players[1]:
		cards_locked = true
		start_reveal_phase()
	else:
		set_active_player(1 - player_index)

func _ready():
	round_manager.phase_changed.connect(_on_phase_changed)
	players = [player1, player2]
	for p in players: p.ap = 0 
	start_game()

func start_game():
	round_index = 0
	start_round()

func start_round():
	phase = RoundPhase.CARD_SELECTION
	cards_locked = false
	confirmed_players = [false, false]
	selected_cards = [[], []]
	
	for p in players:
		p.gain_ap(BASE_AP_PER_ROUND)
		var draw_count = min(3, HAND_CAP - p.hand.size())
		if draw_count > 0: card_manager.draw_cards_for_player(p, draw_count)
	
	active_player_index = 0
	_sync_active_player_context()
	emit_signal("round_started", round_index)
	set_phase(RoundPhase.CARD_SELECTION)

func play_card_from_hand(card: CardInstance):
	if phase != RoundPhase.PLAY: return
	var p = players[active_player_index]
	
	if card.data.algorithm_type != CardData.AlgorithmType.NONE:
		board.enter_algorithm_targeting(card.data.algorithm_type, card)
	else:
		if p.ap >= card.data.ap_cost:
			p.spend_ap(card.data.ap_cost)
			
			if p.hand.has(card):
				p.hand.erase(card)
			else:
				selected_cards[active_player_index].erase(card)
				
			_sync_active_player_context()
			deck_ui.update_hand() 
			end_action_turn()


func start_reveal_phase():
	set_phase(RoundPhase.REVEAL)
	await get_tree().create_timer(1.5).timeout
	
	for i in range(2):
		var ap_cards_to_remove = []
		for card in selected_cards[i]:
			if card.data.ap_gain > 0:
				ap_cards_to_remove.append(card)
		
		if not ap_cards_to_remove.is_empty():
			deck_ui.fade_ap_cards_visuals(i, ap_cards_to_remove)
			for card in ap_cards_to_remove:
				players[i].gain_ap(card.data.ap_gain)
				players[i].hand.erase(card)
				selected_cards[i].erase(card)
	
	await get_tree().create_timer(0.6).timeout
	determine_starting_player()
	set_phase(RoundPhase.PLAY)



func set_active_player(index: int):
	active_player_index = index
	_sync_active_player_context()
	emit_signal("active_player_changed", index)

func _sync_active_player_context():
	card_manager.sync_from_player(players[active_player_index])
	card_manager.hand_changed.emit()

func toggle_select(player_index: int, card: CardInstance):
	var list = selected_cards[player_index]
	if list.has(card):
		list.erase(card)
	elif list.size() < MAX_SELECTION:
		list.append(card)
		
		

func set_phase(p: RoundPhase):
	phase = p
	emit_signal("phase_changed", phase)
	
	if p == RoundPhase.PLAY:
		deck_ui.hand_area.hide()
		deck_ui.play_button.hide()
	elif p == RoundPhase.CARD_SELECTION:
		deck_ui.hand_area.show()
		deck_ui.play_button.show()

func check_play_turn_end():
	if phase != RoundPhase.PLAY: return

	if players[active_player_index].ap <= 0:
		end_action_turn()
