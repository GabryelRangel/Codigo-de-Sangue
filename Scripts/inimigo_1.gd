extends Node2D

@export var speed: float = 100.0
@export var bullet_scene: PackedScene
@export var fire_interval: float = 1.5
@export var max_health: int = 100
@export var accell: float = 100
@export var max_speed: float = 400
var current_health: int
var player: Node2D = null
var orbitando := false
var orbit_angle := 0.0
var orbit_radius := 250.0
var orbit_direction := 1.0
var orbit_speed := 1.0
var xp_orb_scene = preload("res://Scenes/xp.tscn")
var on_screen := false


func _ready():
	randomize() #Permite que a orbita do inimigo mude a cada run
	current_health = max_health
	call_deferred("_wait_for_player")

func _wait_for_player():
	while get_tree() == null:
		await Engine.get_main_loop().idle_frame
	while Global.player == null or not is_instance_valid(Global.player):
		await get_tree().create_timer(0.1).timeout
	player = Global.player

func _process(delta):
	if not is_instance_valid(player):
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if orbitando:
		# Sai da órbita se o player se afastar demais
		if distance > orbit_radius * 1.8:
			orbitando = false
		else:
			# Gira suavemente em torno do player
			orbit_angle += orbit_speed * delta * orbit_direction  # Pode ser -1 ou 1
			var target_pos = player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
			global_position = global_position.lerp(target_pos, 0.1)  # Suaviza o movimento
	else:
		# Entra na órbita se estiver perto o suficiente
		if distance <= orbit_radius:
			orbitando = true
			orbit_angle = (global_position - player.global_position).angle()
			orbit_direction = [-1.0, 1.0][randi() % 2]  # Escolhe aleatoriamente o sentido da órbita
		else:
	# Movimento normal de perseguição
			var direction = to_player.normalized()
			speed = min(speed + accell * delta, max_speed)
			global_position += direction * speed * delta
	look_at(player.global_position)

func _on_timer_timeout():
	shoot()

func shoot():
	if not on_screen:
		#print("Bala impossibilitada")
		return  # Não atira se estiver fora da tela
	if not is_instance_valid(player):
		return  # Player foi destruído, não tenta fazer mais nada
	
	var distance = global_position.distance_to(player.global_position)
	if distance > 470:
		#print("Inimigo longe")
		return  # Só atira se o player estiver a menos de 500px de distância

	if bullet_scene and is_instance_valid(player):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = $Spawn_bala.global_position
		var direction = (player.global_position - global_position).normalized()
		bullet.dir = direction.angle()
		bullet.is_enemy_bullet = true
		bullet.configurar_colisao(2, 1)  # Bala inimiga: está na camada 4, colide com camada 1 (player)
		bullet.configurar_cor(Color(1, 1, 1))  # branco
		get_tree().get_current_scene().add_child(bullet)

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


func _on_Area2D_body_entered(body):
	if body.has_method("is_player_bullet") and body.is_player_bullet():
		take_damage(body.damage)
		body.queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	var bullet_node = area.get_parent()
	print("Algo entrou:", area.name, " Grupos do pai:", bullet_node.get_groups())
	if bullet_node.is_in_group("player_bullet"):
		print("Bala do player detectada!")
		take_damage(bullet_node.damage)
		bullet_node.queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	on_screen = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	on_screen = false
