extends Node2D

@export var damage: int = 20
@export var length: float = 800

var direction := Vector2.RIGHT  # direção padrão

func configurar_direcao_e_posicao(origem: Vector2, target: Vector2):
	global_position = origem
	direction = (target - origem).normalized()
	update_laser()

func _ready():
	$Timer.start()


func update_laser():
	var start = Vector2.ZERO
	var end = direction * length
	$Line2D.points = [start, end]

	# Ajustar CollisionShape2D
	var shape: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape.extents = Vector2(length / 2, 5)
		$CollisionShape2D.position = direction * (length / 2)

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player" and area.has_method("take_damage"):
		area.take_damage(damage)

func _on_timer_timeout() -> void:
	queue_free()
