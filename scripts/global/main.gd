extends Node

@onready var round_manager: = $Game/RoundManager

	
func _ready():
	await get_tree().process_frame
	round_manager.start_game()
