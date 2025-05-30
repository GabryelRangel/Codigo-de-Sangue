extends Node2D
var explosion_scene = preload("res://Scenes/Explosion.tscn")
@export var speed: float = 400.0
@export var damage: int = 1
@export var max_health: int = 3  # Alterado para 3 vidas
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

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		Global.score += 1
		queue_free()
		
# Função para colisão com o jogador

func explode():
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		current_health = 0  # Perde toda a vida ao colidir
		explode()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var bullet = area.get_parent()
	if bullet.is_in_group("player_bullet"):
		take_damage(1)
		bullet.queue_free()
