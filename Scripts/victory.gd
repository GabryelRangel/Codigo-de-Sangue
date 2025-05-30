extends Control

func show_victory():
	visible = true

func _on_RestartButton_pressed():
	Global.score = 0
	get_tree().reload_current_scene()
