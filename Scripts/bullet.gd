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

func _physics_process(_delta):
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()

func configurar_colisao(layer: int, mask: int):
	collision_layer = layer
	collision_mask = mask
	$Area2D.collision_layer = layer
	$Area2D.collision_mask = mask

func _on_life_timeout():
	print("morreu")
	queue_free()

func _on_area_2d_body_entered(_body):
	print("hit")
	queue_free()
