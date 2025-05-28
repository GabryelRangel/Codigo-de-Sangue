extends Node2D

@export var speed: float = 200.0
@export var bullet_scene: PackedScene
@export var fire_interval: float = 1.5
@export var max_health: int = 3
@export var accell: float = 100
@export var max_speed: float = 400

var current_health: int
var player: Node2D = null

func _ready():
	current_health = max_health
	var game_root = get_tree().get_current_scene()
	player = game_root.get_node("Player")
	$Timer.wait_time = fire_interval
	$Timer.start()
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	
@export var follow_distance: float = 300.0

func _process(delta):
	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		var distance = to_player.length()
		if distance > follow_distance:
			var direction = to_player.normalized()
			global_position += direction * speed * delta
		look_at(player.global_position)

func _on_timer_timeout():
	shoot()

func shoot():
	if bullet_scene and is_instance_valid(player):
		var bullet = bullet_scene.instantiate()
		bullet.pos = $Spawn_bala.global_position
		var direction = (player.global_position - global_position).normalized()
		bullet.dir = direction.angle()
		bullet.rota = direction.angle()
		bullet.is_enemy_bullet = true
		bullet.configurar_colisao(4, 1)
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
	if bullet_node.is_in_group("player_bullet"):
		print("Bala do player detectada!")
		take_damage(1)
		bullet_node.queue_free()
