extends CanvasLayer
@onready var arrow_scene = preload("res://Scenes/Seta.tscn")
var enemy_arrows = {}  # Dicionário: inimigo -> seta
var arrows_enabled := true
@onready var wave_label = $Wave
@onready var victory_screen = $Victory
@onready var health_bar = $HealthBar/HealthBar

func update_wave(wave: int):
	$Wave.text = "Wave " + str(wave)

func show_victory_screen():
	$Victory.visible = true
	get_tree().paused = true

func _process(_delta):
	if Input.is_action_just_pressed("ui_ctrl"):
		arrows_enabled = !arrows_enabled
		for arrow in enemy_arrows.values():
			arrow.visible = arrows_enabled

	if arrows_enabled:
		update_enemy_arrows()

func _ready():
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))

func _on_restart_button_pressed() -> void:
	print("Botão Tentar Novamente pressionado!")
	get_tree().paused = false
	call_deferred("_recarregar_cena")

func _recarregar_cena():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

var health_tween: Tween = null
func _on_player_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health

	if health_tween:
		health_tween.kill()  # Para qualquer animação anterior

	health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", current, 0.3)

func update_enemy_arrows():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var viewport = get_viewport().get_visible_rect()
	var camera = get_viewport().get_camera_2d()

	if camera == null or not is_instance_valid(camera):
		return  # Câmera foi destruída (ex: player morreu), evita erro

	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue  # Pula inimigos destruídos

		var arrow
		if not enemy_arrows.has(enemy):
			arrow = arrow_scene.instantiate()
			add_child(arrow)
			enemy_arrows[enemy] = arrow
		else:
			arrow = enemy_arrows[enemy]

		var screen_center = viewport.size / 2
		var screen_pos = screen_center + (enemy.global_position - camera.global_position)

		if viewport.has_point(screen_pos):
			arrow.visible = false
		else:
			arrow.visible = true
			var direction = (enemy.global_position - camera.global_position).normalized()
			var edge_pos = screen_pos.clamp(viewport.position + Vector2(20, 20), viewport.end - Vector2(20, 20))
			arrow.position = edge_pos
			arrow.rotation = direction.angle()

	#Limpa setas de inimigos destruídos
	var to_remove = []
	for enemy in enemy_arrows.keys():
		if not is_instance_valid(enemy):
			enemy_arrows[enemy].queue_free()
			to_remove.append(enemy)

	for enemy in to_remove:
		enemy_arrows.erase(enemy)


func _exit_tree():
	for arrow in enemy_arrows.values():
		arrow.queue_free()
	enemy_arrows.clear()
