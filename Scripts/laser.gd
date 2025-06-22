extends Node2D

@export var damage: int = 20
@export var length: float = 2000

var direction := Vector2.RIGHT

func configurar_direcao_e_posicao(origem: Vector2, target: Vector2):
	global_position = origem
	direction = (target - origem).normalized()
	update_laser()

func _ready():
	$Timer.start()

func update_laser():
	var end = direction * length
	$Line2D.points = [Vector2.ZERO, end]

	# Aumentar a largura da colisão para garantir que o player seja atingido mesmo longe
	var shape: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape.extents = Vector2(length / 2, 20)  # largura aumentada de 5 → 20
		$CollisionShape2D.position = direction * (length / 2)
		$CollisionShape2D.rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player" and area.has_method("take_damage"):
		area.take_damage(damage)

func _on_timer_timeout() -> void:
	queue_free()
