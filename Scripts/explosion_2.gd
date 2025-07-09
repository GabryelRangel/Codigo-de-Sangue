extends Node2D

func _ready():
	$AnimatedSprite2D.play("default")  # toca a animação manualmente
func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
