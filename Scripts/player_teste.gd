extends CharacterBody2D
#Variáveis
@export var speed = 800
const acceleration = 1200.0
const max_speed = 3000.0
const friction = 1000.0
var input = Vector2.ZERO
var current_xp := 0
var xp_to_next_level := 100
var level := 1
@export var max_health := 100
var current_health := max_health
@export var dash_speed: float = 1000.0 
@export var dash_duration: float = 0.2 
@export var dash_cooldown: float = 2.0
var dash_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0
#variaveis de debuff
var debuff_multiplier := 1.0
var debuff_timer := 0.0


var is_invincible: bool = false
var bullet_path = preload("res://Scenes/bullet.tscn")
signal health_changed(current, max)
@export var base_damage := 35

func _ready():
	Global.player = self
	$Hurtbox.connect("area_entered", Callable(self, "_on_Hurtbox_area_entered"))
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta):
	look_at(get_global_mouse_position())
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player_movement(input, delta)
	move_and_slide()
	
	if debuff_timer > 0:
		debuff_timer -= delta
	else:
		debuff_multiplier = 1.0  # remove o debuff
	# Dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			is_invincible = false
	else:
		if Input.is_action_just_pressed("right_click") and dash_cooldown_timer <= 0:
			is_dashing = true
			dash_timer = dash_duration
			dash_cooldown_timer = dash_cooldown
			is_invincible = true
			dash_direction = Vector2.RIGHT.rotated(rotation)

	if Input.is_action_just_pressed("left_click"):#Atira pelo clique esquerdo
		fire()
		look_at(get_global_mouse_position())

func get_input():
	input.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return input.normalized()
	
func player_movement(direction: Vector2, delta: float):
	if is_dashing:
		velocity = dash_direction * dash_speed
	elif direction != Vector2.ZERO:
		velocity += direction.normalized() * acceleration * delta
		var alignment = velocity.normalized().dot(direction.normalized())
		var braking_factor = clamp(1.0 - alignment, 0.0, 1.0)
		var extra_friction = friction * 3.0 * braking_factor
		velocity += direction.normalized() * acceleration * debuff_multiplier * delta
	if velocity.length() > max_speed * debuff_multiplier:
		velocity = velocity.normalized() * max_speed * debuff_multiplier
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func fire():
	var bullet = bullet_path.instantiate()
	bullet.damage = base_damage
	bullet.dir = rotation
	bullet.global_position = $Node2D.global_position
	bullet.is_enemy_bullet = false
	bullet.add_to_group("player_bullet")
	bullet.configurar_colisao(3, 2)

	# Adiciona a herança de velocidade da nave
	if "velocity_inherited" in bullet:
		bullet.velocity_inherited = velocity

	get_parent().add_child(bullet)
	$AudioStreamPlayer2D.play()
	
func _on_Hurtbox_area_entered(body):#Ativa quando o player é atingido por balas inimigas
	if is_invincible:
		print("Dano ignorado: invencível!")
		return
	if body.is_in_group("enemy_bullet"):
		print("Acertado por bala inimiga!")
		take_damage(30)
		body.queue_free()

func take_damage(amount: int):#Função que processa o dano
	current_health -= amount
	current_health = max(current_health, 0)
	print("Player tomou dano! Vida restante:", current_health)
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0:
		die()
		
func gain_xp(amount: int):
	current_xp += amount
	print("XP atual: ", current_xp)
	if current_xp >= xp_to_next_level:
		level_up()

func level_up():
	current_xp -= xp_to_next_level
	level += 1
	xp_to_next_level += 50
	print("Subiu para o nível ", level)
	get_tree().paused = true
	var upgrade_menu = get_tree().get_current_scene().get_node("hud/TelaUpgrade")
	upgrade_menu.show()

func die():
	var hud = get_tree().get_current_scene().get_node("hud")
	if Global.score >= 30:
		hud.get_node("Victory").show_victory()
	else:
		hud.get_node("GameOver").show_game_over()
	queue_free()


func _on_xp_magnet_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_orb"):
		area.start_attraction(self)


func _on_tela_upgrade_upgrade_selected(upgrade_name: Variant) -> void:
	match upgrade_name:
		"Mais Dano":
			base_damage += 15
			print("Upgrade: Mais Dano. Novo dano:", base_damage)
		
		"Mais Vida":
			max_health += 20
			current_health += 20
			emit_signal("health_changed", current_health, max_health)
			print("Upgrade: Mais Vida")
		
		"Mais XP":
			xp_to_next_level = max(20, xp_to_next_level - 20)
			print("Upgrade: Mais XP (xp_to_next_level agora é %d)" % xp_to_next_level)
	var upgrade_menu = get_tree().get_current_scene().get_node("hud/TelaUpgrade")
	upgrade_menu.hide()
	get_tree().paused = false

func apply_debuff(multiplier: float, duration: float): #aplica debuff de velocidade
	debuff_multiplier = multiplier
	debuff_timer = duration
	print("Debuff aplicado! Velocidade reduzida em", multiplier)
