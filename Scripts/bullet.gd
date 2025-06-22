extends Area2D
@export var damage: int = 30
@export var speed: float = 1500
var dir: float
var is_enemy_bullet: bool = false
var velocity_inherited: Vector2 = Vector2.ZERO


func _ready():
	rotation = dir
	add_to_group("enemy_bullet" if is_enemy_bullet else "player_bullet")
	if has_node("Timer"):
		$Timer.start()
	connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	position += (direction * speed + velocity_inherited) * delta
	if has_node("VisibilityNotifier2D") and not $VisibilityNotifier2D.is_on_screen():
		#print("Bala saiu de cena")
		queue_free()



func _on_area_entered(area: Area2D):
	var parent = area.get_parent()
	# Evita colidir com outras balas ou o próprio atirador
	if parent == self or parent.is_in_group("enemy" if is_enemy_bullet else "player"):
		return
	# Atinge apenas o grupo oposto
	if is_enemy_bullet and area.is_in_group("player"):
		if parent.has_method("take_damage"):
			parent.take_damage(25)
		queue_free()
	elif not is_enemy_bullet and area.is_in_group("enemy"):
		if parent.has_method("take_damage"):
			parent.take_damage(damage)
		queue_free()

func configurar_cor(cor: Color):
	$projectile.modulate = cor

func configurar_colisao(layer: int, mask: int):
	collision_layer = layer
	collision_mask = mask


func _on_Timer_timeout():
	queue_free()
