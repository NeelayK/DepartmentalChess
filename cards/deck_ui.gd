extends Control

@onready var hand: HBoxContainer = $HandArea/Hand 
@onready var hand_container: HBoxContainer = $HandArea/Hand
@onready var hand_area: Control = $HandArea
@onready var played_container_1: HBoxContainer = $PlayedHand_1
@onready var played_container_2: HBoxContainer = $PlayedHand_2
@onready var ap_label_1: Label = $AP_1
@onready var ap_label_2: Label = $AP_2
@onready var play_button: Button = $PlayButton
@onready var round_manager: RoundManager = $"../RoundManager"
@onready var card_manager: CardManager = $"../CardManager"
@onready var tooltip: CardTooltip = $CardTooltip
@onready var current_player_label: Label = $CurrentPlayerLabel
@onready var board = $"../../BoardRoot/Board"

const CARD_SCALE := 0.75
const EXPANDED_SPACING := -30

var expanded := false
var card_width: float = 0.0

func _ready() -> void:
	round_manager.active_player_changed.connect(_on_active_player_changed)
	round_manager.round_started.connect(_on_round_started)
	round_manager.phase_changed.connect(_on_phase_changed)
	card_manager.hand_changed.connect(update_hand)
	play_button.pressed.connect(on_play_pressed)

	var temp := preload("res://cards/card_ui.tscn").instantiate()
	card_width = temp.size.x * CARD_SCALE
	temp.queue_free()
func _on_round_started(_index: int) -> void:
	_update_ap_ui()
	# Ensure signals are connected once players are initialized
	if not round_manager.players[0].ap_changed.is_connected(_update_ap_ui):
		round_manager.players[0].ap_changed.connect(func(_v): _update_ap_ui())
		round_manager.players[1].ap_changed.connect(func(_v): _update_ap_ui())

func _update_ap_ui() -> void:
	if round_manager.players.is_empty(): return
	ap_label_1.text = "AP: %d" % round_manager.players[0].ap
	ap_label_2.text = "AP: %d" % round_manager.players[1].ap

func _on_active_player_changed(index: int) -> void:
	if board: board.set_active_player(index)
	current_player_label.text = "Player %d Turn" % (index + 1)
	update_hand() # Refresh highlights/red tint when player swaps

func _on_phase_changed(phase: int) -> void:
	match phase:
		RoundManager.RoundPhase.CARD_SELECTION:
			hand_area.visible = true
			play_button.text = "Confirm Selection"
			play_button.visible = true
			clear_played_hand()
			update_hand()
			
		RoundManager.RoundPhase.REVEAL:
			hand_area.visible = false
			play_button.visible = false
			collapse_hand()
			_animate_reveal_sequence()
			
		RoundManager.RoundPhase.PLAY:
			hand_area.visible = true
			play_button.text = "End Turn"
			play_button.visible = true
			update_hand()



func _handle_card_click(card: CardInstance, card_ui: CardUI) -> void:
	var p_idx = round_manager.active_player_index
	
	if round_manager.phase == RoundManager.RoundPhase.CARD_SELECTION:
		round_manager.toggle_select(p_idx, card)
		card_ui.set_selected(round_manager.selected_cards[p_idx].has(card))
	
	elif round_manager.phase == RoundManager.RoundPhase.PLAY:
		var p = round_manager.players[p_idx]
		if p.ap >= card.data.ap_cost:
			if card.data.algorithm_type != CardData.AlgorithmType.NONE:
				# Pulse animation (ensure this exists in your CardUI.gd)
				if card_ui.has_method("animate_active_targeting"):
					card_ui.animate_active_targeting() 
				round_manager.play_card_from_hand(card)
			else:
				round_manager.play_card_from_hand(card)
				card_ui.animate_fade_out()
		else:
			print("Not enough AP!")

func get_visual_for_card(card_instance: CardInstance) -> Node:
	if not hand: 
		push_error("Hand reference is missing in DeckUI!")
		return null
		
	# Look through the Hand container for the UI node representing this instance
	for card_ui in hand.get_children():
		# This assumes your CardUI script has a variable: var card_instance
		if "card_instance" in card_ui and card_ui.card_instance == card_instance:
			return card_ui
	return null


func _animate_reveal_sequence() -> void:
	clear_played_hand()
	
	# Add cards invisibly first
	for i in range(2):
		for card in round_manager.selected_cards[i]:
			var card_ui = add_to_played_hand(card, i)
			card_ui.modulate.a = 0.0
			card_ui.scale = Vector2.ZERO
			
			# Pop-in animation
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(card_ui, "modulate:a", 1.0, 0.3)
			tween.parallel().tween_property(card_ui, "scale", Vector2.ONE * 0.5, 0.4)
			# Stagger slightly
			await get_tree().create_timer(0.1).timeout

func fade_ap_cards_visuals(player_index: int, card_data_list: Array) -> void:
	var container = played_container_1 if player_index == 0 else played_container_2
	for child in container.get_children():
		if child is CardUI and child.card in card_data_list:
			child.animate_fade_out()
func expand_hand() -> void:
	if expanded: return
	expanded = true
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v): hand_container.add_theme_constant_override("separation", v), -int(card_width * 0.8), EXPANDED_SPACING, 0.3)
	for child in hand_container.get_children():
		child.set_state(CardUI.CardVisualState.IN_HAND)
		var rot = (child.get_index() - (hand_container.get_child_count() / 2.0)) * 0.05
		tween.tween_property(child, "rotation", rot, 0.2)

func collapse_hand() -> void:
	if not expanded: return
	expanded = false
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(v): hand_container.add_theme_constant_override("separation", v), EXPANDED_SPACING, -int(card_width * 0.8), 0.3)
	for child in hand_container.get_children():
		child.set_state(CardUI.CardVisualState.STACKED)
		tween.tween_property(child, "rotation", 0.0, 0.2)

func force_collapse_hand() -> void:
	expanded = false
	hand_container.add_theme_constant_override("separation", -int(card_width * 0.8))
	for child in hand_container.get_children():
		child.set_state(CardUI.CardVisualState.STACKED)
		child.rotation = 0

func on_play_pressed() -> void:
	if round_manager.phase == RoundManager.RoundPhase.CARD_SELECTION:
		round_manager.confirm_selection(round_manager.active_player_index)
	elif round_manager.phase == RoundManager.RoundPhase.PLAY:
		round_manager.end_action_turn()

func clear_played_hand() -> void:
	for child in played_container_1.get_children(): child.queue_free()
	for child in played_container_2.get_children(): child.queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and expanded:
		if not hand_container.get_global_rect().grow(30).has_point(get_global_mouse_position()):
			collapse_hand()
			
			


# ... (Top of script remains the same) ...

func update_hand() -> void:
	if round_manager.players.is_empty(): return
	
	# 1. Update the main hand
	for child in hand_container.get_children():
		child.queue_free()

	var current_player_idx = round_manager.active_player_index
	var current_ap = round_manager.players[current_player_idx].ap

	for card in card_manager.hand:
		var card_ui := _create_card_ui(card)
		hand_container.add_child(card_ui)
		_setup_card_interaction(card_ui, card, current_ap)

	# 2. Update revealed cards (played_hands) to show red tint if unaffordable
	_refresh_played_containers(current_player_idx, current_ap)

	force_collapse_hand()

# Helper to refresh the cards already sitting on the table
func _refresh_played_containers(active_idx: int, current_ap: int):
	var containers = [played_container_1, played_container_2]
	for i in range(2):
		for child in containers[i].get_children():
			if child is CardUI:
				# Tint red if it's the active player's card and they can't afford it
				if round_manager.phase == RoundManager.RoundPhase.PLAY and i == active_idx:
					child.modulate = Color(1, 0.4, 0.4) if child.card.data.ap_cost > current_ap else Color.WHITE
					child.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				else:
					child.modulate = Color.WHITE
					child.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _create_card_ui(card: CardInstance) -> CardUI:
	var card_ui := preload("res://cards/card_ui.tscn").instantiate()
	card_ui.scale = Vector2.ONE * CARD_SCALE
	card_ui.setup(card)
	return card_ui

func _setup_card_interaction(card_ui: CardUI, card: CardInstance, current_ap: int):
	# Red Tint Logic
	if round_manager.phase == RoundManager.RoundPhase.PLAY:
		card_ui.modulate = Color(1, 0.4, 0.4) if card.data.ap_cost > current_ap else Color.WHITE

	card_ui.pressed.connect(func():
		if not expanded:
			expand_hand()
		else:
			_handle_card_click(card, card_ui)
	)
	card_ui.hovered.connect(func(inst, _pos): if expanded: tooltip.show_card(inst))
	card_ui.unhovered.connect(func(): tooltip.hide_tooltip())

func add_to_played_hand(card: CardInstance, player_index: int) -> CardUI:
	var container := played_container_1 if player_index == 0 else played_container_2
	var card_ui := preload("res://cards/card_ui.tscn").instantiate()
	container.add_child(card_ui)
	card_ui.setup(card)
	card_ui.show_front()
	card_ui.scale = Vector2.ONE * 0.5
	
	# Enable interaction for cards on the table
	card_ui.pressed.connect(func():
		if round_manager.phase == RoundManager.RoundPhase.PLAY and round_manager.active_player_index == player_index:
			_handle_card_click(card, card_ui)
	)
	
	return card_ui

# ... (Remaining Animation functions: expand, collapse, reveal sequence) ...
