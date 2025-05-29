extends Node2D

@export var speed: float = 100.0
@export var bullet_scene: PackedScene
@export var fire_interval: float = 1.5
@export var max_health: int = 3
@export var accell: float = 100
@export var max_speed: float = 400

var current_health: int
var player: Node2D = null

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
		speed = min(speed + accell * delta, max_speed)
		global_position += direction * speed * delta

func _on_timer_timeout():
	shoot()

func shoot():
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
		die()

func die():
	queue_free()

func _on_Area2D_body_entered(body):
	if body.has_method("is_player_bullet") and body.is_player_bullet():
		take_damage(1)
		body.queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	var bullet_node = area.get_parent()
	print("Algo entrou:", area.name, " Grupos do pai:", bullet_node.get_groups())
	if bullet_node.is_in_group("player_bullets"):
		print("Bala do player detectada!")
		take_damage(1)
		bullet_node.queue_free()
