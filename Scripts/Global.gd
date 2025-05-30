extends Node
var node_creation_parent: Node = null
var player: Node2D = null
var score: int = 0

func add_score(amount: int):
	score += amount
	print("Score atual:", score)

	var hud = get_tree().get_current_scene().get_node("hud")
	hud.update_score_label()

	if score >= 30:
		hud.show_victory_screen()

func instance_node(node, location, parent):
	var node_instance = node.instantiate()
	parent.add_child(node_instance)
	node_instance.global_position = location 
	return node_instance 
