extends Node2D

var xp_orb_scene = preload("res://Scenes/xp.tscn")
@export var speed: float = 50.0
@export var fire_interval: float = 2.0
@export var laser_scene: PackedScene
@export var desired_distance: float = 600.0
@export var tolerance: float = 10.0
@export var max_health := 80

var current_health := max_health
var player: Node2D = null

func _ready():
	current_health = max_health
	$Timer.wait_time = fire_interval
	$Timer.start()
	call_deferred("_find_player")

func _find_player():
	await get_tree().create_timer(0.2).timeout
	player = Global.player

func _process(delta):
	if not is_instance_valid(player): return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized()

	var move = Vector2.ZERO

	if dist < desired_distance - tolerance:
		move = -dir
	elif dist > desired_distance + tolerance:
		move = dir
	else:
		# Dentro da faixa ideal, mas ainda se ajusta um pouco para manter posição
		var adjustment_strength = (dist - desired_distance) / tolerance
		move = dir * adjustment_strength

	global_position += move * speed * delta
	look_at(player.global_position)

func shoot():
	if not is_instance_valid(player): return

	var laser_p = laser_scene.instantiate()

	var origem = $spawn_bala.global_position
	var destino = player.global_position

	laser_p.configurar_direcao_e_posicao(origem, destino)

	get_tree().get_current_scene().add_child(laser_p)

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		call_deferred("die")

func die():
	Global.add_score(1)
	var orb = xp_orb_scene.instantiate()
	orb.global_position = global_position
	get_parent().add_child(orb)
	queue_free()

func _on_timer_timeout() -> void:
	shoot()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var bullet_node = area.get_parent()
	print("Algo entrou:", area.name, " Grupos do pai:", bullet_node.get_groups())
	if bullet_node.is_in_group("player_bullet"):
		print("Bala do player detectada!")
		take_damage(bullet_node.damage)
		bullet_node.queue_free()
