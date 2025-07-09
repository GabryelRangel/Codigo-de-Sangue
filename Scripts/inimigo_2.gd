extends Node2D
var xp_orb_scene = preload("res://Scenes/xp.tscn")
@export var speed: float = 300.0
var on_screen := false
@export var bala_curva_scene: PackedScene
@export var fire_interval: float = 1.5
@export var max_health: int = 100
@export var accell: float = 100
@export var max_speed: float = 400
@export var damage: int = 25

var current_health: int
var player: Node2D = null

func _ready():
	current_health = max_health
	call_deferred("_wait_for_player")
	$Timer.wait_time = fire_interval
	$Timer.start()
	
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
	if not on_screen:
		return  # Não atira se estiver fora da tela
	if bala_curva_scene and is_instance_valid(player):
		var bullet = bala_curva_scene.instantiate()
		
		var spawns = [$Spawn_bala.global_position, $Spawn_bala2.global_position]
		bullet.global_position = spawns[randi() % spawns.size()]
		
		bullet.rotation = (player.global_position - bullet.global_position).angle()
		bullet.configurar_colisao(2, 1)
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
	if randi() % 100 < 5:
		var life_orb = preload("res://Scenes/hp.tscn").instantiate()
		life_orb.global_position = global_position
		get_parent().add_child(life_orb)
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


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	on_screen = true

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	on_screen = false
