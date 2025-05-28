extends CharacterBody2D

@export var speed: float = 1500
@export var is_enemy_bullet: bool = false

var dir: float
var pos: Vector2
var rota: float

func is_player_bullet():
	return !is_enemy_bullet

func _ready():
	global_position = pos
	rotation = rota
	if is_enemy_bullet:
		add_to_group("enemy_bullet")
		$Area2D.add_to_group("enemy_bullet")
	else:
		add_to_group("player_bullet")
		$Area2D.add_to_group("player_bullet")


func _physics_process(delta):
	velocity = Vector2(speed, 0).rotated(dir)
	var motion = Vector2(speed * delta, 0).rotated(dir)
	var collision = move_and_collide(motion)
	if collision:
		queue_free()  # ou causar dano, etc.

func configurar_colisao(layer: int, mask: int):
	$Area2D.collision_layer = layer
	$Area2D.collision_mask = mask

func _on_life_timeout():
	print("morreu")
	queue_free()

func _on_area_2d_body_entered(_body):
	print("hit")
	queue_free()
