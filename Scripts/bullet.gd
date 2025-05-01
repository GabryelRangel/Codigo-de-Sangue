extends CharacterBody2D
var pos:Vector2
var rota:float
var dir : float
var speed= 1500 #velocidade da bala

func _ready():
	global_position=pos
	global_rotation=rota

func _physics_process(_delta):
	velocity=Vector2(speed,0).rotated(dir)
	move_and_slide()

func _on_life_timeout():
	print("morreu")
	queue_free()

func _on_area_2d_body_entered(body):
	print("hit")
	queue_free()
