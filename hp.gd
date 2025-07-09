extends Area2D

@export var hp_amount: int = 30
@export var speed: float = 200.0

var attracted := false
var target: Node2D = null

func _ready():
	add_to_group("hp_orb")

func _physics_process(delta):
	if attracted and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		position += direction * speed * delta

func start_attraction(player_node):
	attracted = true
	target = player_node

func _on_area_entered(area: Area2D):
	if area.name == "xp_magnet" and area.get_parent().name == "Player":
		start_attraction(area.get_parent())


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if body.has_method("heal"):
			body.heal(hp_amount)
		queue_free()
