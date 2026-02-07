extends Resource
class_name Card

enum CardType {
	AP_GAIN,
	ALGO_MOVE,
	PASSIVE
}

@export var name: String
@export var description: String
@export var type: CardType

@export var ap_cost: int = 0
@export var ap_gain: int = 0

# algorithm-specific (unused for now)
@export var algorithm := ""
@export var max_depth := 0
