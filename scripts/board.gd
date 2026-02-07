extends Node2D

# -----------------------------
# GAME STATE
# -----------------------------

@export var board_width := 8
@export var board_height := 8
@export var square_size := 64

var white_turn := true
var selected_square := Vector2i(-1, -1)
var highlighted_moves: Array[Vector2i] = []
var last_double_step_pawn := Vector2i(-1, -1)
var last_move_from: Vector2i = Vector2i(-1, -1)
var last_move_to: Vector2i = Vector2i(-1, -1)
# -----------------------------
# SCENES
# -----------------------------

var square_scene := preload("res://scenes/Square.tscn")
var piece_scene := preload("res://scenes/Piece.tscn")

# -----------------------------
# DATA
# -----------------------------

var squares: Dictionary = {}   # Vector2i -> Square
var pieces: Dictionary = {}    # Vector2i -> Piece

# -----------------------------
# SETUP
# -----------------------------

func _ready() -> void:
	create_board()
	spawn_standard_chess()
	self.position = Vector2(-board_width * square_size / 2, -board_height * square_size / 2)

# -----------------------------
# BOARD CREATION
# -----------------------------

func create_board() -> void:
	for y in range(board_height):
		for x in range(board_width):
			var coord := Vector2i(x, y)
			var sq: Square = square_scene.instantiate()
			add_child(sq)

			sq.position = Vector2(coord) * square_size
			sq.setup(x, y, square_size)

			# IMPORTANT: store FIRST
			squares[coord] = sq

			# then color
			reset_square_color(coord)

func reset_square_color(coord: Vector2i) -> void:
	var sq = squares[coord]
	if (coord.x + coord.y) % 2 == 0:
		sq.set_color(Color("d5d49bff")) # light
	else:
		sq.set_color(Color("#769656")) # dark
# -----------------------------
# PIECES
# -----------------------------

func spawn_piece(coord: Vector2i, type, white: bool) -> void:
	var piece: Piece = piece_scene.instantiate()
	add_child(piece)

	piece.setup(type, white, coord)
	piece.position = Vector2(coord) * square_size + Vector2(square_size / 2, square_size / 2)

	pieces[coord] = piece

func spawn_standard_chess() -> void:
	pieces.clear()

	var back_rank = [
		Piece.PieceType.ROOK,
		Piece.PieceType.KNIGHT,
		Piece.PieceType.BISHOP,
		Piece.PieceType.QUEEN,
		Piece.PieceType.KING,
		Piece.PieceType.BISHOP,
		Piece.PieceType.KNIGHT,
		Piece.PieceType.ROOK
	]

	# Black
	for x in range(8):
		spawn_piece(Vector2i(x, 0), back_rank[x], false)
		spawn_piece(Vector2i(x, 1), Piece.PieceType.PAWN, false)

	# White
	for x in range(8):
		spawn_piece(Vector2i(x, 6), Piece.PieceType.PAWN, true)
		spawn_piece(Vector2i(x, 7), back_rank[x], true)
# -----------------------------
# INPUT
# -----------------------------

func on_square_pressed(coord: Vector2i) -> void:
	# Clicked highlighted square → try move
	if highlighted_moves.has(coord):
		try_move(selected_square, coord)
		clear_highlights()
		selected_square = Vector2i(-1, -1)
		white_turn = !white_turn
		return

	# Clicked friendly piece → change selection
	if pieces.has(coord) and pieces[coord].is_white == white_turn:
		clear_highlights()
		selected_square = coord
		highlight_moves(pieces[coord])
		return

	# Clicked anything else → clear
	clear_highlights()
	selected_square = Vector2i(-1, -1)

# -----------------------------
# HIGHLIGHTING
# -----------------------------

func highlight_moves(piece: Piece) -> void:
	var moves := get_moves(piece)
	for m in moves:
		var sq: Square = squares[m]
		highlighted_moves.append(m)
		if pieces.has(m):
			sq.show_overlay(Color(0.953, 0.114, 0.0, 0.75)) # capture
		else:
			sq.show_overlay(Color(0.209, 0.0, 0.487, 0.75)) # move

func clear_highlights() -> void:
	for m in highlighted_moves:
		reset_square_color(m)
		var sq: Square = squares[m]
		sq.hide_overlay()
	highlighted_moves.clear()

func clear_last_move_highlight() -> void:
	if last_move_from != Vector2i(-1, -1):
		squares[last_move_from].hide_overlay()
	if last_move_to != Vector2i(-1, -1):
		squares[last_move_to].hide_overlay()
		
func show_last_move_highlight(from: Vector2i, to: Vector2i) -> void:
	clear_last_move_highlight()

	last_move_from = from
	last_move_to = to

	squares[from].show_overlay(Color(0.582, 0.383, 0.392, 1.0))
	squares[to].show_overlay(Color(0.925, 0.0, 0.435, 0.882))
# -----------------------------
# MOVE GENERATION
# -----------------------------

func get_moves(piece: Piece) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []

	match piece.type:
		Piece.PieceType.PAWN:
			moves = get_pawn_moves(piece)
		Piece.PieceType.ROOK:
			moves = get_sliding_moves(piece, [
				Vector2i(1, 0), Vector2i(-1, 0),
				Vector2i(0, 1), Vector2i(0, -1)
			])
		Piece.PieceType.BISHOP:
			moves = get_sliding_moves(piece, [
				Vector2i(1, 1), Vector2i(-1, -1),
				Vector2i(-1, 1), Vector2i(1, -1)
			])
		Piece.PieceType.QUEEN:
			moves = get_sliding_moves(piece, [
				Vector2i(1, 0), Vector2i(-1, 0),
				Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, -1),
				Vector2i(-1, 1), Vector2i(1, -1)
			])
		Piece.PieceType.KNIGHT:
			moves = get_knight_moves(piece)
		Piece.PieceType.KING:
			moves = get_king_moves(piece)

	if GameRules.check_required:
		moves = filter_self_check_moves(piece, moves)

	return moves

func filter_self_check_moves(piece: Piece, moves: Array[Vector2i]) -> Array[Vector2i]:
	var legal: Array[Vector2i] = []

	for to in moves:
		var from := piece.coord
		var captured = pieces.get(to, null)

		# simulate
		pieces.erase(from)
		pieces[to] = piece
		piece.coord = to

		var in_check := is_king_in_check(piece.is_white)

		# rollback
		piece.coord = from
		pieces.erase(to)
		pieces[from] = piece
		if captured:
			pieces[to] = captured

		if not in_check:
			legal.append(to)

	return legal

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < board_width and p.y < board_height


func find_king(is_white: bool) -> Vector2i:
	for coord in pieces:
		var p = pieces[coord]
		if p.type == Piece.PieceType.KING and p.is_white == is_white:
			return coord
	return Vector2i(-1, -1)

func is_king_in_check(is_white: bool) -> bool:
	var king_pos := find_king(is_white)
	if king_pos == Vector2i(-1, -1):
		return false

	for p in pieces.values():
		if p.is_white == is_white:
			continue

		var attacks: Array[Vector2i]

		match p.type:
			Piece.PieceType.PAWN:
				attacks = get_pawn_attacks(p)
			Piece.PieceType.KING:
				attacks = get_king_adjacent_attacks(p)
			Piece.PieceType.KNIGHT:
				attacks = get_knight_moves(p)
			_:
				attacks = get_sliding_moves(p, get_piece_dirs(p))

		if attacks.has(king_pos):
			return true

	return false

func get_king_adjacent_attacks(piece: Piece) -> Array[Vector2i]:
	var attacks: Array[Vector2i] = []

	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x == 0 and y == 0:
				continue
			var t := piece.coord + Vector2i(x, y)
			if in_bounds(t):
				attacks.append(t)

	return attacks

func get_piece_dirs(piece: Piece) -> Array:
	match piece.type:
		Piece.PieceType.ROOK:
			return [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		Piece.PieceType.BISHOP:
			return [Vector2i(1,1), Vector2i(-1,-1), Vector2i(-1,1), Vector2i(1,-1)]
		Piece.PieceType.QUEEN:
			return [
				Vector2i(1,0), Vector2i(-1,0),
				Vector2i(0,1), Vector2i(0,-1),
				Vector2i(1,1), Vector2i(-1,-1),
				Vector2i(-1,1), Vector2i(1,-1)
			]
	return []


func get_pawn_attacks(piece: Piece) -> Array[Vector2i]:
	var attacks: Array[Vector2i] = []
	var dir := -1 if piece.is_white else 1

	for dx in [-1, 1]:
		var t := piece.coord + Vector2i(dx, dir)
		if in_bounds(t):
			attacks.append(t)

	return attacks


# -----------------------------
# PIECE MOVE LOGIC
# -----------------------------

func get_knight_moves(piece: Piece) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var dirs = [
		Vector2i(2, 1), Vector2i(2, -1),
		Vector2i(1, 2), Vector2i(1, -2),
		Vector2i(-2, 1), Vector2i(-2, -1),
		Vector2i(-1, 2), Vector2i(-1, -2)
	]

	for d in dirs:
		var t = piece.coord + d
		if not in_bounds(t):
			continue
		if not pieces.has(t) or pieces[t].is_white != piece.is_white:
			moves.append(t)

	return moves

func get_king_moves(piece: Piece) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x == 0 and y == 0:
				continue
			var t := piece.coord + Vector2i(x, y)
			if in_bounds(t) and (not pieces.has(t) or pieces[t].is_white != piece.is_white):
				moves.append(t)

	# castling
	if GameRules.allow_castling and not piece.has_moved:
		var y := piece.coord.y

		# king side
		var rook_pos := Vector2i(7, y)
		if pieces.has(rook_pos):
			var rook = pieces[rook_pos]
			if rook.type == Piece.PieceType.ROOK and not rook.has_moved:
				if not pieces.has(Vector2i(5, y)) and not pieces.has(Vector2i(6, y)):
					moves.append(Vector2i(6, y))

		# queen side
		rook_pos = Vector2i(0, y)
		if pieces.has(rook_pos):
			var rook = pieces[rook_pos]
			if rook.type == Piece.PieceType.ROOK and not rook.has_moved:
				if not pieces.has(Vector2i(1, y)) and not pieces.has(Vector2i(2, y)) and not pieces.has(Vector2i(3, y)):
					moves.append(Vector2i(2, y))

	return moves

func get_sliding_moves(piece: Piece, dirs: Array) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for d in dirs:
		var t = piece.coord + d
		while in_bounds(t):
			if pieces.has(t):
				if pieces[t].is_white != piece.is_white:
					moves.append(t)
				break
			moves.append(t)
			t += d
	return moves

func get_pawn_moves(piece: Piece) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var dir := -1 if piece.is_white else 1
	var start_row := 6 if piece.is_white else 1

	# one square forward
	var forward := piece.coord + Vector2i(0, dir)
	if in_bounds(forward) and not pieces.has(forward):
		moves.append(forward)

		# two squares forward (first move)
		var double_forward := piece.coord + Vector2i(0, dir * 2)
		if piece.coord.y == start_row and not pieces.has(double_forward):
			moves.append(double_forward)

	# captures
	for dx in [-1, 1]:
		var diag := piece.coord + Vector2i(dx, dir)
		if not in_bounds(diag):
			continue

		# normal capture
		if pieces.has(diag) and pieces[diag].is_white != piece.is_white:
			moves.append(diag)

		# en passant
		if GameRules.allow_en_passant and diag == last_double_step_pawn:
			moves.append(diag)

	return moves

# -----------------------------
# MOVE EXECUTION
# -----------------------------

func try_move(from: Vector2i, to: Vector2i) -> bool:
	if not pieces.has(from):
		return false

	var piece = pieces[from]
	var legal_moves := get_moves(piece)

	if not legal_moves.has(to):
		return false

	# en passant capture
	if piece.type == Piece.PieceType.PAWN and to == last_double_step_pawn:
		var dir := 1 if piece.is_white else -1
		var captured := to + Vector2i(0, dir)
		if pieces.has(captured):
			pieces[captured].queue_free()
			pieces.erase(captured)

	# normal capture
# normal capture
	if pieces.has(to):
		if pieces[to].type == Piece.PieceType.KING and not GameRules.king_can_be_captured:
			return false

		pieces[to].queue_free()
		pieces.erase(to)

	# update en passant state
	last_double_step_pawn = Vector2i(-1, -1)
	if piece.type == Piece.PieceType.PAWN and abs(to.y - from.y) == 2:
		last_double_step_pawn = to + Vector2i(0, 1 if piece.is_white else -1)

	pieces.erase(from)
	pieces[to] = piece
	
	# castling rook move
	if piece.type == Piece.PieceType.KING and is_king_in_check(piece.is_white) and abs(to.x - from.x) == 2:
		var y := from.y

		if to.x == 6: # king side
			var rook_from := Vector2i(7, y)
			var rook_to := Vector2i(5, y)
			var rook = pieces[rook_from]
			pieces.erase(rook_from)
			pieces[rook_to] = rook
			rook.coord = rook_to
			rook.position = Vector2(rook_to) * square_size + Vector2(square_size / 2, square_size / 2)
			rook.has_moved = true

		elif to.x == 2: # queen side
			var rook_from := Vector2i(0, y)
			var rook_to := Vector2i(3, y)
			var rook = pieces[rook_from]
			pieces.erase(rook_from)
			pieces[rook_to] = rook
			rook.coord = rook_to
			rook.position = Vector2(rook_to) * square_size + Vector2(square_size / 2, square_size / 2)
			rook.has_moved = true
	
	pieces.erase(from)
	pieces[to] = piece

	piece.coord = to
	piece.position = Vector2(to) * square_size + Vector2(square_size / 2, square_size / 2)
	piece.has_moved = true

	show_last_move_highlight(from, to)

	return true
