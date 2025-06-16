extends Area2D

@export var xp_amount: int = 30
@export var speed: float = 200.0

var attracted := false
var target: Node2D = null

func _ready():
	add_to_group("xp_orb")
	connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta):
	if attracted and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		position += direction * speed * delta

func start_attraction(player_node):
	attracted = true
	target = player_node

func _on_area_entered(area: Area2D):
	if area.name == "Xp_Attractor":
		print("Detectou zona de atração!")
		var player_node = area.get_parent()
		start_attraction(player_node)  # Só inicia atração

	elif area.is_in_group("player") and attracted:
		print("XP chegou ao player, concedendo XP")
		var player_node = area.get_parent()
		player_node.gain_xp(xp_amount)
		queue_free()
