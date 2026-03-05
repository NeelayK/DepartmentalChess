extends Control

@onready var hand: HBoxContainer = $Hand
var round_manager: RoundManager
var card_width: float = 0.0 
var expanded := false
var hover_time := 0.0

const EXPANDED_SPACING := 20
const ANIM_TIME := 0.3 
const CARD_SCENE := preload("res://cards/card_ui.tscn")

func _set_cards_interactable(enabled: bool):
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE if not enabled else Control.MOUSE_FILTER_STOP
   
	var target_modulate = Color(1, 1, 1, 1) if enabled else Color(0.7, 0.7, 0.7, 1)
	var tween = create_tween()
	tween.tween_property(hand, "modulate", target_modulate, 0.3)

func expand_hand():
	if expanded or (round_manager and round_manager.phase != RoundManager.RoundPhase.CARD_SELECTION): 
		return
		
	expanded = true
	hover_time = 0.0
	animate_hand_separation(-int(card_width), EXPANDED_SPACING)
	
	for card in hand.get_children():
		if card.has_method("set_state"):
			card.set_state(CardUI.CardVisualState.IN_HAND)

func collapse_hand():
	if not expanded: return
	expanded = false
	animate_hand_separation(EXPANDED_SPACING, -int(card_width))
	
	for card in hand.get_children():
		if card.has_method("set_state"):
			card.set_state(CardUI.CardVisualState.STACKED)

func animate_hand_separation(start: int, end: int):
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(v: int): hand.add_theme_constant_override("separation", v),
		start, end, ANIM_TIME
	)


func _ready():
	# Finds the RoundManager wherever it is in the 'Game' or 'Main' branch
	round_manager = get_tree().get_first_node_in_group("round_manager")
	
