extends Control
var is_paused := false
var can_toggle := true

func _ready():
	$AnimationPlayer.play("RESET")
	$AnimationPlayer.connect("animation_finished", Callable(self, "_on_animation_finished"))

func pause():
	if is_paused or not can_toggle:
		return
	is_paused = true
	can_toggle = false
	get_tree().paused = true
	$AnimationPlayer.play("blurr")

func resume():
	if not is_paused or not can_toggle:
		return
	is_paused = false
	can_toggle = false
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blurr")

func _on_animation_finished(anim_name):
	if anim_name == "blurr":
		can_toggle = true

func _input(event):
	if event.is_action_pressed("escape") and can_toggle:
		if is_paused:
			resume()
		else:
			pause()

func _on_resume_pressed():
	if can_toggle:
		resume()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

func _on_restart_pressed() -> void:
	if can_toggle:
		Global.score = 0
		resume()
		get_tree().reload_current_scene()
