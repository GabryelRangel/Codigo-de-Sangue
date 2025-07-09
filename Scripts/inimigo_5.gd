extends Node2D

var xp_orb_scene = preload("res://Scenes/xp.tscn")
var cone_attack_scene = preload("res://Scenes/ataque_cone.tscn")
@export var speed := 300.0
@export var attack_range := 100.0 # quando estiver nessa distância, ataca
@export var stop_distance := 100.0
@export var debuff_duration := 5.0
@export var debuff_speed_multiplier := 0.1
@export var attack_cooldown := 2.5
@export var damage: int = 5

var player: Node2D = null
var current_health := 100
var can_attack := true
var is_attacking := false

func _ready():
	call_deferred("_find_player")
	$cooldown_timer.wait_time = attack_cooldown
	$cooldown_timer.one_shot = true

func _find_player():
	await get_tree().create_timer(0.2).timeout
	player = Global.player

func _process(delta):
	if not is_instance_valid(player):
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	look_at(player.global_position)

	if is_attacking:
		return

	if distance > stop_distance:
		# Persegue o player
		global_position += to_player.normalized() * speed * delta
	elif distance <= attack_range:
		if can_attack:
			start_attack()
	else:
		pass


func start_attack():
	can_attack = false
	is_attacking = true

	# Dispara dois cones nos dois pontos
	disparar_cone_em($spawn_bala_1)
	disparar_cone_em($spawn_bala_2)
	$cooldown_timer.start()
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func disparar_cone_em(spawn_point: Node2D):
	var cone = cone_attack_scene.instantiate()
	cone.global_position = spawn_point.global_position
	cone.rotation = rotation
	get_parent().add_child(cone)


func _on_cooldown_timer_timeout():
	can_attack = true

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		call_deferred("die")

func die():
	Global.add_score(1)
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

func _on_hitbox_area_entered(area: Area2D) -> void:
	var bullet = area.get_parent()
	if bullet.is_in_group("player_bullet"):
		take_damage(bullet.damage)
		bullet.queue_free()
