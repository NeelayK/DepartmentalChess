extends Node2D

@export var board_width := 8
@export var board_height := 8
@export var square_size := 64

# Dependencies
@onready var round_manager: RoundManager = $"../../Game/RoundManager"

const MAX_ALGO_DEPTH := 3
# Algorithm State
var active_algorithm = CardData.AlgorithmType.NONE
var current_card_being_played: CardInstance
var is_targeting_for_card := false
var algorithm_start_piece_coord := Vector2i(-1, -1)

# Game State
var chess_enabled := false
var current_player := 0
var selected_square := Vector2i(-1, -1)
var highlighted_moves: Array[Vector2i] = []
var last_double_step_pawn := Vector2i(-1, -1)
var last_move_from: Vector2i = Vector2i(-1, -1)
var last_move_to: Vector2i = Vector2i(-1, -1)

# Data
var squares: Dictionary = {}    # Vector2i -> Square
var pieces: Dictionary = {}     # Vector2i -> Piece

# Scenes
var square_scene := preload("res://scenes/chess/square.tscn")
var piece_scene := preload("res://scenes/chess/piece.tscn")


func _ready() -> void:
	create_board()
	spawn_standard_chess()
	self.position = Vector2(-board_width * square_size / 2, -board_height * square_size / 2)

func set_active_player(index: int):
	current_player = index
	chess_enabled = true


func on_square_pressed(coord: Vector2i) -> void:
	if round_manager.phase != RoundManager.RoundPhase.PLAY: return
	
	if is_targeting_for_card:
		
		if pieces.has(coord) and pieces[coord].is_white == (current_player == 0):
			var type = pieces[coord].type
			if type in [Piece.PieceType.PAWN, Piece.PieceType.KNIGHT, Piece.PieceType.ROOK, Piece.PieceType.BISHOP]:
				execute_algorithm_move(coord) # This is now async
		else:
			cancel_targeting()
		return

	if highlighted_moves.has(coord):
		if try_move(selected_square, coord):
			round_manager.players[current_player].spend_ap(1)
			clear_highlights()
			selected_square = Vector2i(-1, -1)
			round_manager.end_action_turn() # Force turn swap
		return
	
	
	if pieces.has(coord):
		var is_white_piece = pieces[coord].is_white
		var is_my_piece = (is_white_piece and current_player == 0) or (not is_white_piece and current_player == 1)
		
		if is_my_piece:
			# Check AP
			if round_manager.players[current_player].ap < 1:
				print("Not enough AP to select/move")
				return
				
			clear_highlights()
			selected_square = coord
			highlight_moves(pieces[coord])
			return

	clear_highlights()
	selected_square = Vector2i(-1, -1)


func execute_algorithm_move(start_coord: Vector2i):
	var card_to_destroy = current_card_being_played
	reset_all_square_colors()
	is_targeting_for_card = false 
	
	var result_coord = Vector2i(-1, -1)
	
	if active_algorithm == CardData.AlgorithmType.BFS:
		result_coord = await visualize_chess_bfs(start_coord)
	elif active_algorithm == CardData.AlgorithmType.DFS:
		result_coord = await visualize_chess_dfs(start_coord)
	elif active_algorithm == CardData.AlgorithmType.ASTAR:
		result_coord = await visualize_chess_astar(start_coord) # A* added here

	if result_coord != Vector2i(-1, -1) and result_coord != start_coord:
		force_move_and_capture(start_coord, result_coord)
		
		var p = round_manager.players[current_player]
		p.spend_ap(card_to_destroy.data.ap_cost)
		p.hand.erase(card_to_destroy)
		
		var card_visual = round_manager.deck_ui.get_visual_for_card(card_to_destroy)
		if card_visual:
			card_visual.queue_free()
	
	reset_all_square_colors()
	
	# Cleanup
	active_algorithm = CardData.AlgorithmType.NONE
	current_card_being_played = null
	
	var other_player = 1 - current_player
	if round_manager.players[other_player].ap > 0:
		round_manager.set_active_player(other_player)
	else:
		round_manager.end_action_turn()
func enter_algorithm_targeting(type: CardData.AlgorithmType, card: CardInstance):

	clear_highlights()
	selected_square = Vector2i(-1, -1)
	
	active_algorithm = type
	current_card_being_played = card
	is_targeting_for_card = true
	
	for coord in pieces:
		var p = pieces[coord]
		if p.is_white == (current_player == 0):
			if p.type in [Piece.PieceType.PAWN, Piece.PieceType.KNIGHT, Piece.PieceType.ROOK, Piece.PieceType.BISHOP]:
				var sq = squares[coord]
				var t = create_tween().set_loops(3) # Pulse 3 times then stop
				t.tween_property(sq, "modulate", Color(0, 1, 1, 1), 0.5)
				t.tween_property(sq, "modulate", Color.WHITE, 0.5)

func cancel_targeting():
	is_targeting_for_card = false
	active_algorithm = CardData.AlgorithmType.NONE
	current_card_being_played = null
	reset_all_square_colors()
	print("Targeting canceled")

func get_simulated_moves(coord: Vector2i, piece_type, is_white) -> Array[Vector2i]:

	var moves: Array[Vector2i] = []
	
	var _in = func(c): return c.x >= 0 and c.y >= 0 and c.x < board_width and c.y < board_height
	
	var _is_blocked = func(c): 
		if not pieces.has(c): return false
		if c == algorithm_start_piece_coord: return false # Ignore self at start
		return true
		
	var _is_enemy = func(c):
		if not pieces.has(c): return false
		if c == algorithm_start_piece_coord: return false
		return pieces[c].is_white != is_white

	match piece_type:
		Piece.PieceType.PAWN:
			var dir = -1 if is_white else 1
			var fwd = coord + Vector2i(0, dir)
			if _in.call(fwd) and not _is_blocked.call(fwd):
				moves.append(fwd)
			# Captures
			for dx in [-1, 1]:
				var diag = coord + Vector2i(dx, dir)
				if _in.call(diag) and _is_enemy.call(diag):
					moves.append(diag)

		Piece.PieceType.KNIGHT:
			var jumps = [Vector2i(2,1), Vector2i(2,-1), Vector2i(1,2), Vector2i(1,-2),
						 Vector2i(-2,1), Vector2i(-2,-1), Vector2i(-1,2), Vector2i(-1,-2)]
			for j in jumps:
				var t = coord + j
				if _in.call(t):
					if not _is_blocked.call(t) or _is_enemy.call(t):
						moves.append(t)
						
		Piece.PieceType.ROOK, Piece.PieceType.BISHOP:
			var dirs = []
			if piece_type == Piece.PieceType.ROOK:
				dirs = [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]
			else:
				dirs = [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]
			
			for d in dirs:
				var t = coord + d
				while _in.call(t):
					if _is_blocked.call(t):
						if _is_enemy.call(t): moves.append(t) # Capture
						break # Blocked
					moves.append(t)
					t += d

	return moves

# --- ALGORITHMS ---

func run_chess_bfs(start: Vector2i) -> Vector2i:
	algorithm_start_piece_coord = start
	var MAX_ALGO_DEPTH := 2 
	var piece = pieces[start]
	var queue = [{ "coord": start, "depth": 0 }]
	var visited = { start: true }
	var last_valid_spot = start
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var curr_coord = current["coord"]
		var depth = current["depth"]
		
		# Check for capture (Enemy)
		if pieces.has(curr_coord) and curr_coord != start:
			if pieces[curr_coord].is_white != piece.is_white:
				return curr_coord # Found target!
		
		last_valid_spot = curr_coord
		
		if depth >= MAX_ALGO_DEPTH:
			continue
			
		var moves = get_simulated_moves(curr_coord, piece.type, piece.is_white)
		
		for m in moves:
			if not visited.has(m):
				visited[m] = true
				queue.push_back({ "coord": m, "depth": depth + 1 })
				
	return last_valid_spot

func run_chess_dfs(start: Vector2i) -> Vector2i:
	algorithm_start_piece_coord = start
	var piece = pieces[start]
	var MAX_ALGO_DEPTH := 3 
	# Stack stores dictionary: { coord, depth }
	var stack = [{ "coord": start, "depth": 0 }]
	var visited = { start: true }
	var last_valid_spot = start
	
	while stack.size() > 0:
		var current = stack.pop_back()
		var curr_coord = current["coord"]
		var depth = current["depth"]
		
		# Check capture
		if pieces.has(curr_coord) and curr_coord != start:
			if pieces[curr_coord].is_white != piece.is_white:
				return curr_coord # Found target
		
		last_valid_spot = curr_coord
		
		if depth >= MAX_ALGO_DEPTH:
			continue
			
		var moves = get_simulated_moves(curr_coord, piece.type, piece.is_white)
		
		# Shuffle moves for DFS so it doesn't always pick the same direction first
		moves.shuffle()
		
		for m in moves:
			if not visited.has(m):
				visited[m] = true
				stack.push_back({ "coord": m, "depth": depth + 1 })
	
	return last_valid_spot

func force_move_and_capture(from: Vector2i, to: Vector2i):
	# 1. Capture logic
	if pieces.has(to):
		pieces[to].queue_free()
		pieces.erase(to)
		
	# 2. Move logic
	if pieces.has(from):
		var piece = pieces[from]
		pieces.erase(from)
		pieces[to] = piece
		
		# Update piece internal data
		piece.coord = to
		piece.position = Vector2(to) * square_size + Vector2(square_size/2, square_size/2)
		piece.has_moved = true # Important for castling/pawns
		
		show_last_move_highlight(from, to, piece)
	else:
		print("ERROR: Tried to move non-existent piece from ", from)

func create_board() -> void:
	for y in range(board_height):
		for x in range(board_width):
			var coord := Vector2i(x, y)
			var sq: Square = square_scene.instantiate()
			add_child(sq)
			sq.position = Vector2(coord) * square_size
			sq.setup(x, y, square_size)
			squares[coord] = sq
			reset_square_color(coord)

func reset_square_color(coord: Vector2i) -> void:
	var sq = squares[coord]
	if (coord.x + coord.y) % 2 == 0:
		sq.set_color(Color("#eeeed2"))
	else:
		sq.set_color(Color("#769656"))

func reset_all_square_colors():
	for coord in squares:
		reset_square_color(coord)


func spawn_piece(coord: Vector2i, type, white: bool) -> void:
	var piece: Piece = piece_scene.instantiate()
	add_child(piece)
	piece.setup(type, white, coord)
	piece.position = Vector2(coord) * square_size + Vector2(square_size / 2, square_size / 2)
	pieces[coord] = piece

func spawn_standard_chess() -> void:
	pieces.clear()
	var back_rank = [Piece.PieceType.ROOK, Piece.PieceType.KNIGHT, Piece.PieceType.BISHOP, Piece.PieceType.QUEEN, Piece.PieceType.KING, Piece.PieceType.BISHOP, Piece.PieceType.KNIGHT, Piece.PieceType.ROOK]
	for x in range(8):
		spawn_piece(Vector2i(x, 0), back_rank[x], false)
		spawn_piece(Vector2i(x, 1), Piece.PieceType.PAWN, false)
		spawn_piece(Vector2i(x, 6), Piece.PieceType.PAWN, true)
		spawn_piece(Vector2i(x, 7), back_rank[x], true)


func highlight_moves(piece: Piece) -> void:
	clear_highlights()
	var moves := get_moves(piece)
	var piece_texture: Texture2D = piece.sprite.texture
	for m in moves:
		var sq: Square = squares[m]
		highlighted_moves.append(m)
		sq.show_piece_overlay(piece_texture)

func clear_highlights() -> void:
	for m in highlighted_moves:
		squares[m].hide_overlay()
	highlighted_moves.clear()

func show_last_move_highlight(from: Vector2i, to: Vector2i, piece: Piece) -> void:
	if last_move_from != Vector2i(-1, -1): squares[last_move_from].hide_overlay()
	if last_move_to != Vector2i(-1, -1): squares[last_move_to].hide_overlay()
	last_move_from = from
	last_move_to = to
	var tex: Texture2D = piece.sprite.texture
	squares[from].show_piece_overlay(tex)
	squares[to].show_piece_overlay(tex)

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < board_width and p.y < board_height

func clear_last_move_highlight() -> void:
	if last_move_from != Vector2i(-1, -1):
		squares[last_move_from].hide_overlay()
	if last_move_to != Vector2i(-1, -1):
		squares[last_move_to].hide_overlay()
		
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

func visualize_chess_astar(start: Vector2i) -> Vector2i:
	var piece = pieces[start]
	var enemy_king_coord = find_king_coord(not piece.is_white)
	
	# Priority queue simulation: Array of dictionaries, sorted by f_cost
	var open_set = [{ "coord": start, "g_cost": 0, "f_cost": 0 }]
	var visited = { start: true }
	var last_valid = start
	
	var active_ghosts: Array[Node2D] = []
	var algo_color = Color(0.8, 0.2, 0.8) # Purple for A*
	
	while open_set.size() > 0:
		# Sort to simulate priority queue (lowest f_cost first)
		open_set.sort_custom(func(a, b): return a["f_cost"] < b["f_cost"])
		var current = open_set.pop_front()
		var curr_coord = current["coord"]
		var g_cost = current["g_cost"]
		
		# VISUALIZE
		if curr_coord != start:
			var g = spawn_persistent_ghost(piece.type, piece.is_white, curr_coord, algo_color)
			active_ghosts.append(g)
			squares[curr_coord].set_color(algo_color.lightened(0.5))
			await get_tree().create_timer(0.2).timeout
		
		# CHECK CAPTURE
		if pieces.has(curr_coord) and curr_coord != start:
			var target = pieces[curr_coord]
			if target.is_white != piece.is_white:
				if target.type == Piece.PieceType.KING:
					continue # King Protection: keep pathfinding around it
				
				# Found an enemy piece along the optimal path!
				squares[curr_coord].set_color(Color.GREEN)
				await get_tree().create_timer(0.5).timeout
				await cleanup_ghosts(active_ghosts)
				return curr_coord
		
		last_valid = curr_coord
		if g_cost >= MAX_ALGO_DEPTH: continue
			
		var moves = get_simulated_moves(curr_coord, piece.type, piece.is_white)
		
		for m in moves:
			if not visited.has(m):
				visited[m] = true
				var new_g = g_cost + 1
				# Manhattan distance heuristic to the enemy king
				var h_cost = abs(m.x - enemy_king_coord.x) + abs(m.y - enemy_king_coord.y)
				var new_f = new_g + h_cost
				
				open_set.push_back({ "coord": m, "g_cost": new_g, "f_cost": new_f })

	await cleanup_ghosts(active_ghosts)
	return last_valid

# Helper function to find the King's coordinate for A* heuristic
func find_king_coord(is_white: bool) -> Vector2i:
	for coord in pieces:
		var p = pieces[coord]
		if p.type == Piece.PieceType.KING and p.is_white == is_white:
			return coord
	return Vector2i.ZERO # Fallback


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


# --------------------
# PIECE MOVE LOGIC
# ------------\-------

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

	var forward := piece.coord + Vector2i(0, dir)
	if in_bounds(forward) and not pieces.has(forward):
		moves.append(forward)

		var double_forward := piece.coord + Vector2i(0, dir * 2)
		if piece.coord.y == start_row and not pieces.has(double_forward):
			moves.append(double_forward)

	for dx in [-1, 1]:
		var diag := piece.coord + Vector2i(dx, dir)
		if not in_bounds(diag):
			continue

		if pieces.has(diag) and pieces[diag].is_white != piece.is_white:
			moves.append(diag)

		# en passant
		if GameRules.allow_en_passant and diag == last_double_step_pawn:
			moves.append(diag)

	return moves

# -----------------------------
# MOVE EXECUTION
# --------------------------

func try_move(from: Vector2i, to: Vector2i) -> bool:
	if not pieces.has(from):
		return false

	var piece = pieces[from]
	var legal_moves := get_moves(piece)

	if not legal_moves.has(to):
		return false

	if piece.type == Piece.PieceType.PAWN and to == last_double_step_pawn:
		var dir := 1 if piece.is_white else -1
		var captured := to + Vector2i(0, dir)
		if pieces.has(captured):
			pieces[captured].queue_free()
			pieces.erase(captured)

	if pieces.has(to):
		if pieces[to].type == Piece.PieceType.KING and not GameRules.king_can_be_captured:
			return false

		pieces[to].queue_free()
		pieces.erase(to)

	last_double_step_pawn = Vector2i(-1, -1)
	if piece.type == Piece.PieceType.PAWN and abs(to.y - from.y) == 2:
		last_double_step_pawn = to + Vector2i(0, 1 if piece.is_white else -1)

	pieces.erase(from)
	pieces[to] = piece
	if piece.type == Piece.PieceType.KING and abs(to.x - from.x) == 2:
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

	show_last_move_highlight(from, to, piece)

	return true


func find_target_bfs(start: Vector2i) -> Vector2i:
	var queue = [start]
	var visited = {start: true}
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, 
					 Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]
	
	while queue.size() > 0:
		var curr = queue.pop_front()
		if pieces.has(curr) and curr != start:
			if pieces[curr].is_white != (current_player == 0):
				return curr
		
		for d in directions:
			var next = curr + d
			if in_bounds(next) and not visited.has(next):
				visited[next] = true
				queue.push_back(next)
	return Vector2i(-1, -1)

func find_target_dfs(curr: Vector2i, visited: Array) -> Vector2i:
	visited.append(curr)
	if pieces.has(curr) and pieces[curr].is_white != (current_player == 0):
		return curr
		
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in directions:
		var next = curr + d
		if in_bounds(next) and not visited.has(next):
			var res = find_target_dfs(next, visited)
			if res != Vector2i(-1, -1): return res
	return Vector2i(-1, -1)


func spawn_persistent_ghost(type: Piece.PieceType, is_white: bool, coord: Vector2i, color: Color) -> Node2D:
	var ghost = piece_scene.instantiate()
	add_child(ghost)
	ghost.setup(type, is_white, coord)
	
	ghost.position = Vector2(coord) * square_size + Vector2(square_size/2, square_size/2)
	
	ghost.modulate = color
	ghost.modulate.a = 0.6 
	ghost.scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2(1.0, 1.0), 0.4)
	
	return ghost

func cleanup_ghosts(ghost_list: Array):
	if ghost_list.is_empty(): return
	
	var tween = create_tween().set_parallel(true)
	for g in ghost_list:
		if is_instance_valid(g):
			tween.tween_property(g, "modulate:a", 0.0, 0.3)
			tween.tween_property(g, "scale", Vector2(1.2, 1.2), 0.3) # Slight expand while fading
	
	await tween.finished
	
	for g in ghost_list:
		if is_instance_valid(g):
			g.queue_free()

#-----------------------
# ALGORITHMS
# -----------------------------

func visualize_chess_bfs(start: Vector2i) -> Vector2i:
	var piece = pieces[start]
	var queue = [{ "coord": start, "depth": 0 }]
	var visited = { start: true }
	var last_valid = start
	var MAX_ALGO_DEPTH := 2 
	var active_ghosts: Array[Node2D] = []
	
	var algo_color = Color(0.791, 0.0, 0.413, 0.3)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var curr_coord = current["coord"]
		var depth = current["depth"]
		if curr_coord != start:
			var g = spawn_persistent_ghost(piece.type, piece.is_white, curr_coord, algo_color)
			active_ghosts.append(g)
			
			await get_tree().create_timer(0.2).timeout
		
		if pieces.has(curr_coord) and curr_coord != start:
			var target = pieces[curr_coord]
			if target.is_white != piece.is_white:
				if target.type == Piece.PieceType.KING:
					continue
				squares[curr_coord].set_color(Color.GREEN)
				await get_tree().create_timer(0.4).timeout
				await cleanup_ghosts(active_ghosts)
				return curr_coord
		
		last_valid = curr_coord
		if depth >= MAX_ALGO_DEPTH: continue
			
		var moves = get_simulated_moves(curr_coord, piece.type, piece.is_white)
		moves.shuffle()
		
		for m in moves:
			if not visited.has(m):
				visited[m] = true
				queue.push_back({ "coord": m, "depth": depth + 1 })

	await cleanup_ghosts(active_ghosts)
	return last_valid


func visualize_chess_dfs(start: Vector2i) -> Vector2i:
	var piece = pieces[start]
	var stack = [{ "coord": start, "depth": 0 }]
	var visited = { start: true }
	var last_valid = start
	var MAX_ALGO_DEPTH := 2
	var active_ghosts: Array[Node2D] = []
	
	var algo_color = Color(0.3, 0.3, 1.0, 0.3)
	while stack.size() > 0:
		var current = stack.pop_back()
		var curr_coord = current["coord"]
		var depth = current["depth"]
		
		if curr_coord != start:
			var g = spawn_persistent_ghost(piece.type, piece.is_white, curr_coord, algo_color)
			active_ghosts.append(g)
			
			await get_tree().create_timer(0.2).timeout

		if pieces.has(curr_coord) and curr_coord != start:
			var target = pieces[curr_coord]
			if target.is_white != piece.is_white:
				# THE KING FILTER
				if target.type == Piece.PieceType.KING:
					continue
				squares[curr_coord].set_color(Color.GREEN)
				await get_tree().create_timer(0.4).timeout
				await cleanup_ghosts(active_ghosts)
				return curr_coord
		
		last_valid = curr_coord
		if depth >= MAX_ALGO_DEPTH: continue
			
		var moves = get_simulated_moves(curr_coord, piece.type, piece.is_white)
		moves.shuffle()
		
		for m in moves:
			if not visited.has(m):
				visited[m] = true
				stack.push_back({ "coord": m, "depth": depth + 1 })

	await cleanup_ghosts(active_ghosts)
	return last_valid
