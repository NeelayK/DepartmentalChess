extends VBoxContainer

@onready var rules: GameRules = GameRules

@onready var castling_cb := $castling
@onready var enpassant_cb := $enpass
@onready var check_required_cb := $check
@onready var show_check_cb := $showcheck
@onready var king_capture_cb := $"king cap"

func _ready() -> void:
	castling_cb.button_pressed = rules.allow_castling
	enpassant_cb.button_pressed = rules.allow_en_passant
	check_required_cb.button_pressed = rules.check_required
	show_check_cb.button_pressed = rules.show_check
	king_capture_cb.button_pressed = rules.king_can_be_captured

	castling_cb.toggled.connect(func(v: bool): rules.allow_castling = v)
	enpassant_cb.toggled.connect(func(v: bool): rules.allow_en_passant = v)
	check_required_cb.toggled.connect(func(v: bool): rules.check_required = v)
	show_check_cb.toggled.connect(func(v: bool): rules.show_check = v)
	king_capture_cb.toggled.connect(func(v: bool): rules.king_can_be_captured = v)
