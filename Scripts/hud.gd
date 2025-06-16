extends CanvasLayer

@onready var score_label = $Score
@onready var victory_screen = $Victory
@onready var health_bar = $HealthBar/HealthBar

func update_score_label():
	$Score.text = "Placar: " + str(Global.score)

func show_victory_screen():
	$Victory.visible = true
	get_tree().paused = true

func _process(_delta):
	$Score.text = "Pontuação: %d" % Global.score

func _ready():
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))

func _on_restart_button_pressed() -> void:
	print("Botão Tentar Novamente pressionado!")
	Global.score = 0
	get_tree().paused = false
	get_tree().reload_current_scene()
	
var health_tween: Tween = null
func _on_player_health_changed(current: int, max: int) -> void:
	health_bar.max_value = max

	if health_tween:
		health_tween.kill()  # Para qualquer animação anterior

	health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", current, 0.3)
