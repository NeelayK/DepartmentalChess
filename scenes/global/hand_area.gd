extends Control

@onready var hand: HBoxContainer = $Hand

var card_width: float = 0.0 # Will be calculated dynamically
var expanded := false
var hover_time := 0.0

# CHANGE: This must be positive to see the cards spread out!
const EXPANDED_SPACING := 20
const ANIM_TIME := 0.3 
const HIDE_DELAY := 1.0 
const CARD_SCENE := preload("res://cards/card_ui.tscn")

func _ready():
	# 1. Instantiate a temp card to get REAL dimensions
	var temp_card = CARD_SCENE.instantiate()
	add_child(temp_card) # Add briefly to ensure size is calculated
	
	# 2. Calculate the scaled width
	# If your card is 100px and scale is 0.75, width is 75px
	card_width = temp_card.get_combined_minimum_size().x * 0.75
	
	temp_card.queue_free()
	
	# 3. Start perfectly stacked
	# Negative separation = card_width means the left edge of card B 
	# sits exactly on the left edge of card A.
	hand.add_theme_constant_override("separation", -int(card_width))

func expand_hand():
	if expanded: return
	expanded = true
	hover_time = 0.0
	
	# Animates from fully stacked (-width) to spread out (positive spacing)
	animate_hand_separation(-int(card_width), EXPANDED_SPACING)
	
	for card in hand.get_children():
		if card.has_method("set_state"):
			card.set_state(CardUI.CardVisualState.IN_HAND)

func collapse_hand():
	if not expanded: return
	expanded = false
	
	# Animates from spread out back to fully stacked
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
