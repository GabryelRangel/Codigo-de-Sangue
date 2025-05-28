extends CanvasLayer

@onready var hearts = [
	$HBoxContainer/heart1,
	$HBoxContainer/heart2,
	$HBoxContainer/heart3,
]

func update_hearts(health: int):
	for i in range(hearts.size()):
		var fill = hearts[i].get_node("fill")
		if i < health:
			fill.visible = true
		else:
			fill.visible = false
