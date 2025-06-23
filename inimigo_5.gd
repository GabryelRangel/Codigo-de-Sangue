extends Node2D

var xp_orb_scene = preload("res://Scenes/xp.tscn")

@export var speed := 100.0
@export var attack_range := 100.0 # quando estiver nessa distância, ataca
@export var stop_distance := 160.0 # distância mínima, para não colar
@export var debuff_duration := 5.0
@export var debuff_speed_multiplier := 0.4
@export var attack_cooldown := 3.0

var player: Node2D = null
var current_health := 100
var can_attack := true
var is_attacking := false

func _ready():
	call_deferred("_find_player")
	$cooldown_timer.wait_time = attack_cooldown
	$cooldown_timer.one_shot = true
	$DebuffCone.connect("body_entered", Callable(self, "_on_cone_body_entered"))
	$DebuffCone.monitoring = false

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

	# Movimento apenas se estiver fora da distância ideal
	if distance > stop_distance:
		global_position += to_player.normalized() * speed * delta

	# Se dentro do alcance de ataque e pode atacar
	elif distance <= attack_range and can_attack:
		start_attack()

func start_attack():
	can_attack = false
	is_attacking = true

	$DebuffCone.monitoring = true
	$DebuffCone.visible = true
	await get_tree().create_timer(0.5).timeout

	$DebuffCone.monitoring = false
	$DebuffCone.visible = false

	$cooldown_timer.start()
	is_attacking = false

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
	queue_free()

func _on_cone_body_entered(body):
	if body.name == "Player" and body.has_method("apply_debuff"):
		body.apply_debuff(debuff_speed_multiplier, debuff_duration)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var bullet = area.get_parent()
	if bullet.is_in_group("player_bullet"):
		take_damage(bullet.damage)
		bullet.queue_free()
