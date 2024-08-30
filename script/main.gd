extends Node2D

func _ready() -> void:
	pass

func _process(delta):
	var paper_count = len(get_tree().get_nodes_in_group("paper"))
	var rock_count = len(get_tree().get_nodes_in_group("rock"))
	var scissors_count = len(get_tree().get_nodes_in_group("scissors"))

	$Count.text = "布：" + str(paper_count) + "\n石头：" + str(rock_count) + "\n剪刀：" + str(scissors_count)

	if paper_count == 0 and rock_count == 0 and scissors_count > 0:
		show_victory("剪刀")
	elif rock_count == 0 and scissors_count == 0 and paper_count > 0:
		show_victory("布")
	elif paper_count == 0 and scissors_count == 0 and rock_count > 0:
		show_victory("石头")


func show_victory(winner: String):
	get_tree().paused = true
	
	var victory_popup = $VictoryPopup
	var victory_label = victory_popup.get_node("Label")
	
	victory_label.text = winner + " 获胜了！"
	
	victory_popup.popup_centered()
