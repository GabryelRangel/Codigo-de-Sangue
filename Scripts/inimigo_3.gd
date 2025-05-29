extends Node2D

@export var speed: float = 300.0
@export var damage: int = 1
@export var max_health: int = 1

var current_health: int
var player: Node2D = null

func _ready():
	current_health = max_health
	call_deferred("_wait_for_player")

func _wait_for_player():
	while get_tree() == null or Global.player == null:
		await get_tree().process_frame
	player = Global.player

func _process(delta):
	if is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		look_at(player.global_position)
		global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		explode()

func explode():
	# Adicione efeitos visuais ou som aqui, se quiser
	queue_free()

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		explode()

func _on_area_2d_body_entered(body):
	print("Colidiu com:", body.name)
	if body.is_in_group("player"):
		print("É o player, aplicando dano!")
		body.take_damage(1)
		queue_free()
