extends Node

class_name PlayerState

signal ap_changed(new_ap: int)

# Cards owned by this player
var hand: Array = []

# Action Points
var ap: int = 0
const MAX_AP := 10

func gain_ap(amount: int) -> void:
	ap = min(ap + amount, MAX_AP)
	ap_changed.emit(ap)

func spend_ap(amount: int) -> bool:
	if ap < amount:
		return false
	ap -= amount
	ap_changed.emit(ap)
	return true

func can_spend(amount: int) -> bool:
	return ap >= amount

func reset_for_round() -> void:
	ap = 0
	ap_changed.emit(ap)
