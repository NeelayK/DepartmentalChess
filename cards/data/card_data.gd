extends Resource
class_name CardData

enum CardType {
	ACTION,
	ALGORITHM,
	PASSIVE
}

enum AlgorithmType {
	NONE,
	BFS,
	DFS,
	ASTAR
}

@export var card_name: String
@export var description: String

@export var front_texture: Texture2D
@export var back_texture: Texture2D

@export var ap_cost: int = 0
@export var ap_gain: int = 0

@export var card_type: CardType = CardType.ACTION
@export var algorithm_type: AlgorithmType = AlgorithmType.NONE

@export var is_passive: bool = false
