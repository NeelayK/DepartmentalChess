# CardInstance.gd
extends RefCounted
class_name CardInstance

var data: CardData
var created_at: int

func _init(_data: CardData):
	data = _data
	created_at = Time.get_ticks_msec()


# CardInstance.gd
func play(player: PlayerState) -> bool:
	if data.ap_cost > 0:
		if not player.spend_ap(data.ap_cost):
			return false
	# effect logic later
	return true


func execute_algorithm():
	match data.algorithm_type:
		CardData.AlgorithmType.BFS:
			print("BFS algorithm executed")

		CardData.AlgorithmType.DFS:
			print("DFS algorithm executed")
