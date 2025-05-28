extends Area2D

@export var speed: float = 400.0
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

	# Se sair da tela, destruir
	if not get_viewport_rect().has_point(global_position):
		queue_free()
	
	var to_target = (target.global_position - global_position).normalized()
	var current_direction = Vector2.RIGHT.rotated(rotation)
	var new_direction = current_direction.lerp(to_target, turn_speed * delta).normalized()
	rotation = new_direction.angle()
	position += new_direction * speed * delta

func _on_timer_timeout():
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("player"):
		queue_free()
