extends Node

# -----------------------------
# GAME MODES
# -----------------------------

enum GameMode {
	STANDARD,
	NO_CASTLING,
	KING_CAPTURE_WINS,
	CUSTOM
}

var current_mode: GameMode = GameMode.STANDARD

# -----------------------------
# RULE TOGGLES
# -----------------------------

var allow_castling := true
var allow_en_passant := true
var check_required := true
var show_check := true
var king_can_be_captured := false

# -----------------------------
# STARTING SETUP
# -----------------------------

var standard_back_rank := [
	Piece.PieceType.ROOK,
	Piece.PieceType.KNIGHT,
	Piece.PieceType.BISHOP,
	Piece.PieceType.QUEEN,
	Piece.PieceType.KING,
	Piece.PieceType.BISHOP,
	Piece.PieceType.KNIGHT,
	Piece.PieceType.ROOK
]

func apply_mode(mode: GameMode) -> void:
	current_mode = mode

	match mode:
		GameMode.STANDARD:
			allow_castling = true
			allow_en_passant = true
			check_required = true
			king_can_be_captured = false

		GameMode.KING_CAPTURE_WINS:
			check_required = false
			king_can_be_captured = true
