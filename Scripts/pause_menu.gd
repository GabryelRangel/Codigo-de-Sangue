extends Control

func _ready():
	$AnimationPlayer.play("RESET")

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blurr")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blurr")

func testEsc():
	if Input.is_action_just_pressed("escape") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()


func _on_resume_pressed():
	resume()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

func _process(delta):
	testEsc()


func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()
