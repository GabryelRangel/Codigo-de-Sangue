extends Node2D
extends Node2D

@onready var music_player = $AudioStreamPlayer
var fade_in_time := 2.0  # segundos para o fade in
var delay := 1.5         # segundos de atraso antes de começar

var enemy_1 = preload("res://Scenes/inimigo_1.tscn")
var enemy_2 = preload("res://Scenes/inimigo_2.tscn")
var enemy_3 = preload("res://Scenes/inimigo_3.tscn")
var enemy_4 = preload("res://Scenes/inimigo_4.tscn")
var enemy_5 = preload("res://Scenes/inimigo_5.tscn")

var current_wave := 1
var total_waves := 5
var enemies_remaining := 0
@onready var spawner = $Spawner_Inimigo  # Ajuste se o nome for diferente

func _ready():
    Global.node_creation_parent = self
    music_player.volume_db = -80  # começa silencioso
    await get_tree().create_timer(delay).timeout
    music_player.play()
    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", 0, fade_in_time)
    start_wave()

func start_wave():
	var hud = get_tree().get_current_scene().get_node("hud")
	if hud:
		hud.update_wave(current_wave)

	print("Iniciando wave ", current_wave)
	# resto do código...

	enemies_remaining = 0

	var enemy_count = 5 + current_wave * 2  # Aumenta o número de inimigos por wave
	for i in range(enemy_count):
		var enemy_scene
		if current_wave < 2:
			enemy_scene = enemy_1
		elif current_wave < 3:
			enemy_scene = [enemy_1, enemy_2].pick_random()
		elif current_wave < 4:
			enemy_scene = [enemy_1, enemy_2, enemy_3].pick_random()
		else:
			enemy_scene = [enemy_1, enemy_2, enemy_3, enemy_4, enemy_5].pick_random()

		var pos = gerar_posicao_longe_do_player()
		var enemy = Global.instance_node(enemy_scene, pos, self)
		enemies_remaining += 1

		# Conecta ao sinal de morte
		if enemy.has_signal("tree_exited"):
			enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_remaining -= 1
	print("Inimigos restantes:", enemies_remaining)
	if enemies_remaining <= 0:
		if current_wave >= total_waves:
			get_tree().paused = true
			get_node("hud/Victory").show_victory()
		else:
			current_wave += 1
			call_deferred("_start_next_wave_with_delay")

func gerar_posicao_longe_do_player() -> Vector2:
	var pos = Vector2.ZERO
	var player_pos = Global.player.global_position
	while true:
		pos = Vector2(randf_range(-2800, 2800), randf_range(-2800, 2800))
		if pos.distance_to(player_pos) > 600:
			break
	return pos

func _start_next_wave_with_delay():
	$WaveDelayTimer.start(2.0)

func _on_spawner_inimigo_timeout() -> void:
	pass # Replace with function body.

func _on_wave_delay_timer_timeout():
	start_wave()
