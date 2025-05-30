extends Control

func _ready():
	visible = false
	$Button.text = "Tentar novamente"
	$Button.pressed.connect(restart_game)

func show_game_over():
	visible = true

func restart_game():
	Global.score = 0
	get_tree().reload_current_scene()
