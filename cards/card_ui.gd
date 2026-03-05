extends TextureButton
class_name CardUI

enum CardVisualState { STACKED, IN_HAND }

signal hovered(card: CardInstance, position: Vector2)
signal unhovered

@onready var round_manager:RoundManager
var card: CardInstance
var visual_state := CardVisualState.STACKED
var selected := false

# Tuning for the "Raise" effect
const RAISE_AMOUNT := -30.0 


func _ready():
	mouse_entered.connect(func(): hovered.emit(card, global_position + Vector2(0, -120)))
	mouse_exited.connect(func(): unhovered.emit())

func setup(_card: CardInstance):
	card = _card
	show_back()
	disabled = false 

func set_selected(value: bool):
	selected = value
	var target_y = RAISE_AMOUNT if value else 0.0
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", target_y, 0.15)

func set_state(state: CardVisualState):
	visual_state = state
	match state:
		CardVisualState.STACKED:
			show_back()
			set_selected(false) 
		CardVisualState.IN_HAND:
			show_front()

func show_front():
	texture_normal = card.data.front_texture

func show_back():
	texture_normal = card.data.back_texture

func _on_mouse_entered():
	if round_manager.cards_locked: 
		# Shake the card slightly to show it's locked
		var t = create_tween()
		t.tween_property(self, "rotation", deg_to_rad(2), 0.05)
		t.tween_property(self, "rotation", deg_to_rad(-2), 0.05)
		t.tween_property(self, "rotation", 0, 0.05)
		return
	
	# Normal hover lift
	var t = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	t.parallel().tween_property(self, "position:y", -20, 0.2) # Lift up

func _on_mouse_exited():
	var t = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	t.parallel().tween_property(self, "position:y", 0, 0.2)

func animate_fade_out() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE # Stop all clicks immediately
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2.ONE * 0.3, 0.4)
	tween.tween_property(self, "position:y", position.y - 50, 0.4) # Slight float up
	await tween.finished
	queue_free()

# Inside card_ui.gd
