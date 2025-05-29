extends CanvasLayer

@onready var hearts = [
	$HBoxContainer/Heart1,
	$HBoxContainer/Heart2,
	$HBoxContainer/Heart3
]

var previous_health := 3

func _ready():
	for heart in hearts:
		heart.animation_finished.connect(_on_animation_finished.bind(heart))
		heart.play("cheio")

func update_hearts(current_health: int):
	for i in range(hearts.size()):
		if current_health > i:
			# Mantém ou restaura coração cheio
			if hearts[i].animation != "cheio":
				hearts[i].play("cheio")
		else:
			# Só inicia transição se estava cheio anteriormente
			if previous_health > i and hearts[i].animation == "cheio":
				hearts[i].play("transicao")
	
	previous_health = current_health

func _on_animation_finished(heart: AnimatedSprite2D):
	if heart.animation == "transicao":
		heart.play("vazio")
