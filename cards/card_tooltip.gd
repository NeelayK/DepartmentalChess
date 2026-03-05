extends Panel
class_name CardTooltip

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var desc_label: Label = $VBoxContainer/DescriptionLabel
@onready var ap_label: Label = $VBoxContainer/APLabel

func _ready():
	set_as_top_level(true)
	visible = false
	# Prevents the tooltip from blocking the mouse itself
	mouse_filter = Control.MOUSE_FILTER_IGNORE 

func _process(_delta):
	if visible:
		# Follow the mouse with a slight offset so it's not under the cursor
		global_position = get_global_mouse_position() + Vector2(20, -140)

func show_card(card: CardInstance):
	name_label.text = card.data.card_name
	desc_label.text = card.data.description

	if card.data.ap_cost > 0:
		ap_label.text = "AP Cost: %d" % card.data.ap_cost
	elif card.data.ap_gain > 0:
		ap_label.text = "AP Gain: %d" % card.data.ap_gain
	else:
		ap_label.text = ""

	visible = true

func hide_tooltip():
	visible = false
