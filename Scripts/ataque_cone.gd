extends Area2D

@export var duration := 0.5
@export var debuff_multiplier := 0.1
@export var debuff_duration := 5.0
var already_hit := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	$CollisionPolygon2D.disabled = false
	$raios.visible = true
	await get_tree().create_timer(duration).timeout
	$CollisionPolygon2D.disabled = true
	queue_free()

func _on_body_entered(body):
	if already_hit or not is_instance_valid(body):
		return
	already_hit = true

	if body.name == "Player":
		if body.has_method("apply_debuff"):
			body.apply_debuff(debuff_multiplier, debuff_duration)
		if body.has_method("take_damage"):
			body.take_damage(5)
