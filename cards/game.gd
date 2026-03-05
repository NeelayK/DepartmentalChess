# Game.gd
extends Node

@onready var round_manager: = $RoundManager

func _ready():
	round_manager.start_game()
	
