extends Control
class_name CardView

var card_data: Card
var selected := false

@onready var name_label := $PanelContainer/VBoxContainer/CardName
@onready var desc_label := $PanelContainer/VBoxContainer/Desc
@onready var cost_label := $PanelContainer/VBoxContainer/Cost

func setup(card: Card) -> void:
	card_data = card
	name_label.text = card.name
	desc_label.text = card.description
	cost_label.text = "AP: %d" % card.ap_cost

func set_selected(v: bool) -> void:
	selected = v
	modulate = Color(1,1,1,1) if not v else Color(0.8,1,0.8,1)
