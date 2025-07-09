extends Node2D
var explosion_scene = preload("res://Scenes/explosion2.tscn")
@export var speed: float = 400.0
@export var damage: int = 30
@export var max_health: int = 100
var current_health: int
var player: Node2D = null
var xp_orb_scene = preload("res://Scenes/xp.tscn")

func _ready():
	current_health = max_health
	call_deferred("_wait_for_player")

func _wait_for_player():
	while get_tree() == null:
		await Engine.get_main_loop().idle_frame
	while Global.player == null or not is_instance_valid(Global.player):
		await get_tree().create_timer(0.1).timeout
	player = Global.player

func _process(delta):
	if is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		look_at(player.global_position)
		global_position += direction * speed * delta

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		call_deferred("die")

func die():
	Global.add_score(1)
	var orb = xp_orb_scene.instantiate()
	orb.global_position = global_position
	get_parent().add_child(orb)
	if randi() % 100 < 5:
		var life_orb = preload("res://Scenes/hp.tscn").instantiate()
		life_orb.global_position = global_position
		get_parent().add_child(life_orb)
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
		take_damage(bullet.damage)
		bullet.queue_free()
