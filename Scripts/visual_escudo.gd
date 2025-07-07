extends Area2D

@export var max_hp := 100
var current_hp := 100

func _ready():
	current_hp = max_hp
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area):
	if area.is_in_group("enemy_bullet"):
		var dano = 25  # valor padrão
		if "damage" in area:
			dano = area.damage

		current_hp -= dano
		area.queue_free()

		if current_hp <= 0:
			queue_free()  # escudo destruído
