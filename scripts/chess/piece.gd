extends Node2D
class_name Piece

enum PieceType { PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING }

var type: PieceType
var is_white: bool
var coord: Vector2i
var has_moved := false
@onready var sprite: Sprite2D = $Body

func setup(p_type: PieceType, white: bool, start_coord: Vector2i) -> void:
	type = p_type
	is_white = white
	coord = start_coord

	sprite.texture = get_texture()
	sprite.centered = true

	# SCALE PIECE TO SQUARE
	var target_size:int = get_parent().square_size * 0.85
	var tex_size := sprite.texture.get_size()
	sprite.scale = Vector2.ONE * (target_size / tex_size.x)

func get_texture() -> Texture2D:
	var color := "white" if is_white else "black"
	
	match type:
		PieceType.KING:
			return load("res://assets/pieces/%s_king.png" % color)
		PieceType.QUEEN:
			return load("res://assets/pieces/%s_queen.png" % color)
		PieceType.ROOK:
			return load("res://assets/pieces/%s_rook.png" % color)
		PieceType.BISHOP:
			return load("res://assets/pieces/%s_bishop.png" % color)
		PieceType.KNIGHT:
			return load("res://assets/pieces/%s_knight.png" % color)
		PieceType.PAWN:
			return load("res://assets/pieces/%s_pawn.png" % color)

	return null
