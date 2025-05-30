extends Node2D

@export var speed: float = 300.0
@export var bala_curva_scene: PackedScene
@export var fire_interval: float = 1.5
@export var max_health: int = 3
@export var accell: float = 100
@export var max_speed: float = 400

var current_health: int
var player: Node2D = null

func _ready():
	current_health = max_health
	call_deferred("_wait_for_player")
	$Timer.wait_time = fire_interval
	$Timer.start()
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	
@export var follow_distance: float = 300.0

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
	look_at(player.global_position)

	if distance > follow_distance:
		var direction = to_player.normalized()
		global_position += direction * speed * delta


func _on_timer_timeout():
	shoot()

func shoot():
	if bala_curva_scene and is_instance_valid(player):
		var bullet = bala_curva_scene.instantiate()
		bullet.global_position = $Spawn_bala.global_position
		bullet.rotation = (player.global_position - bullet.global_position).angle()
		bullet.configurar_colisao(2, 1)
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
