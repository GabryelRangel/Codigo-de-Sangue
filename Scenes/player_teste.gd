extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	pass
	
func _physics_process(delta: float) -> void:
	# Add the gravity.

	# Handle jump.
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	
