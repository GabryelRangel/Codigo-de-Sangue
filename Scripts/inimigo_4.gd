extends Node2D

var xp_orb_scene = preload("res://Scenes/xp.tscn")
@export var speed: float = 100.0
@export var fire_interval: float = 2.0
@export var laser_scene: PackedScene
@export var max_health := 80
@export var damage: int = 25
# armazenar a direção congelada pro tiro
var laser_direcao_salva := Vector2.ZERO
var laser_origem_salva := Vector2.ZERO

var current_health := max_health
var player: Node2D = null
var can_move := true
var is_shooting := false

func _ready():
	current_health = max_health
	call_deferred("_find_player")

func _find_player():
	await get_tree().create_timer(0.2).timeout
	player = Global.player
	$Timer.wait_time = fire_interval
	$Timer.start()

func _process(delta):
	if not is_instance_valid(player) or not can_move or is_shooting:
		return
#segue player
	var to_player = player.global_position - global_position
	global_position += to_player.normalized() * speed * delta
	look_at(player.global_position)

func _on_timer_timeout():
	if not is_instance_valid(player):
		return
	if not $VisibleOnScreenNotifier2D.is_on_screen():
		return
	is_shooting = true
	can_move = false
	# Salva origem e direção para manter consistência após o preview
	laser_origem_salva = $spawn_bala.global_position
	var destino = player.global_position
	laser_direcao_salva = (destino - laser_origem_salva).normalized()

	var comprimento := 2000.0
	var fim_global = laser_origem_salva + laser_direcao_salva * comprimento

	$PreviewLine.global_position = laser_origem_salva
	$PreviewLine.points = [Vector2.ZERO, $PreviewLine.to_local(fim_global)]
	$PreviewLine.visible = true
	await get_tree().create_timer(0.5).timeout
	shoot()
	$PreviewLine.visible = false
	is_shooting = false
	can_move = true


func shoot():
	var laser_p = laser_scene.instantiate()
	laser_p.configurar_direcao_e_posicao(laser_origem_salva, laser_origem_salva + laser_direcao_salva * 2000)
	get_tree().get_current_scene().add_child(laser_p)

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		call_deferred("die")

func die():
	var orb = xp_orb_scene.instantiate()
	orb.global_position = global_position
	get_parent().add_child(orb)
	var chance_total := 5.0
	if is_instance_valid(player):
		chance_total += player.bonus_drop_vida * 100.0

	if randf() * 100.0 < chance_total:
		var life_orb = preload("res://Scenes/hp.tscn").instantiate()
		life_orb.global_position = global_position
		get_parent().add_child(life_orb)
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var bullet_node = area.get_parent()
	if bullet_node.is_in_group("player_bullet"):
		take_damage(bullet_node.damage)
		bullet_node.queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	pass
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	pass
