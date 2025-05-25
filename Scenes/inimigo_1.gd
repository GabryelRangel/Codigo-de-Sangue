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
	# Remover esta linha se estiver conectado no editor:
	# $Timer.connect("timeout", Callable(self, "shoot"))

func _process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		look_at(player.global_position)
		speed = min(speed + accell * delta, max_speed)
		global_position += direction * speed * delta


func _on_timer_timeout():
	shoot()

func shoot():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.pos = $Spawn_bala.global_position
		# Direção da bala (vetor unitário para o player)
		var direction = (player.global_position - global_position).normalized()
		bullet.dir = direction.angle()
		bullet.rota = direction.angle() # Se quiser girar o sprite para o player
		bullet.is_enemy_bullet = true  # ← Aqui você marca que é do inimigo
		bullet.configurar_colisao(4, 1)  # layer 3 (balas do player), mask 1 (inimigos)add_child(bala)
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
