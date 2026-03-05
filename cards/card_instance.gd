extends RefCounted
class_name CardInstance

var data: CardData
var created_at := Time.get_ticks_msec()

func _init(_data: CardData):
	data = _data

func play(player: PlayerState) -> bool:
	if data.ap_cost > 0:
		if not player.spend_ap(data.ap_cost):
			return false
	return true
