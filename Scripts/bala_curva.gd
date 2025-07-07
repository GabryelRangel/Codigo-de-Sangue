extends Area2D

var explosion_scene = preload("res://Scenes/Explosion.tscn")
@export var speed: float = 400.0
@export var damage: int = 25
@export var turn_speed: float = 3.0  # maior = curva mais rápida
var target: Node2D

func configurar_colisao(layer: int, mask: int):
	collision_layer = layer
	collision_mask = mask

func _ready():
	$Timer.start()
	add_to_group("enemy_bullet")
	target = get_tree().get_current_scene().get_node("Player")

func _process(delta):
	if not is_instance_valid(target):
		queue_free()
		return
	var to_target = (target.global_position - global_position).normalized()
	var current_direction = Vector2.RIGHT.rotated(rotation)
	var new_direction = current_direction.lerp(to_target, turn_speed * delta).normalized()
	rotation = new_direction.angle()
	position += new_direction * speed * delta

func _on_timer_timeout():
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		print("Hurtbox atingido!")
		var player = area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(20)

		# Instancia explosão igual ao inimigo 3
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().get_current_scene().add_child(explosion)

		queue_free()
