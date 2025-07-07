extends CharacterBody2D
#Variáveis
@export var speed = 800
const acceleration = 400.0  # Reduzido para impulsos menores
const max_speed = 3000.0
const friction = 50.0  # MUITO baixo para deslizar
var input = Vector2.ZERO
var current_xp := 0
var xp_to_next_level := 100
var level := 1
@export var max_health := 100
var current_health := max_health
@export var dash_speed: float = 1000.0 
@export var dash_duration: float = 0.5 
@export var dash_cooldown: float = 2.0
var dash_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0
#variaveis de debuff
var debuff_multiplier := 1.0
var debuff_timer := 0.0
var shield_hp := 0  # HP do powerup de escudo (0 = sem escudo)
@export var base_speed = 300  # Impulso base menor
@export var accel_speed = 800  # Impulso com Shift
@onready var propulsor = $Propulsor  # o AnimatedSprite2D
var acelerando := false
var thruster_estado := "desligado" # Pode ser: "desligado", "ligando", "ativo"

var is_invincible: bool = false
var bullet_path = preload("res://Scenes/bullet.tscn")
signal health_changed(current, max)
@export var base_damage := 35

# Adicione essas variáveis para o efeito de piscar
@export var blink_interval: float = 0.1  # Intervalo entre piscadas
var blink_timer: float = 0.0
var player_visible: bool = true

func _ready():
	Global.player = self
	$Hurtbox.connect("area_entered", Callable(self, "_on_Hurtbox_area_entered"))
	# Remove ou comente esta linha se já está conectada no editor:
	# propulsor.animation_finished.connect(Callable(self, "_on_propulsor_animation_finished"))
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta):
	look_at(get_global_mouse_position())
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Detecta se começou ou parou de acelerar com Shift
	var shift_pressed = Input.is_action_pressed("ui_shift")

	if shift_pressed and not acelerando:
		acelerando = true
		start_thruster()
	elif not shift_pressed and acelerando:
		acelerando = false
		stop_thruster()

	player_movement(input, delta)
	move_and_slide()
	
	# Gerencia o efeito de piscar durante invencibilidade
	if is_invincible:
		blink_timer += delta
		if blink_timer >= blink_interval:
			player_visible = !player_visible
			modulate.a = 0.3 if not player_visible else 1.0  # Semi-transparente ou opaco
			blink_timer = 0.0
	else:
		# Restaura visibilidade normal quando não está invencível
		modulate.a = 1.0
		player_visible = true
	
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
			# Restaura visibilidade normal quando sai da invencibilidade
			modulate.a = 1.0
			visible = true
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

func get_input() -> Vector2:
	var dir = Vector2.ZERO
	dir.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	dir.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return dir.normalized() if dir.length() > 0 else Vector2.ZERO
	
func player_movement(direction: Vector2, delta: float):
	if is_dashing:
		velocity = dash_direction * dash_speed
	elif direction != Vector2.ZERO:
		var impulse_strength = base_speed
		
		# Se está acelerando (Shift pressionado), usa impulso maior
		if acelerando:
			impulse_strength = accel_speed
		
		# Aplica impulso na direção do movimento (ao invés de acelerar continuamente)
		velocity += direction.normalized() * impulse_strength * delta
		
		# Limita pela velocidade máxima
		var max_vel = max_speed * debuff_multiplier
		if velocity.length() > max_vel:
			velocity = velocity.normalized() * max_vel
	else:
		# Atrito MUITO baixo quando não há input - a nave continua deslizando
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# Limita a velocidade máxima global
	if velocity.length() > max_speed * debuff_multiplier:
		velocity = velocity.normalized() * max_speed * debuff_multiplier

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
		take_damage(body.damage)
		body.queue_free()

func take_damage(amount: int):
	if shield_hp > 0:
		shield_hp -= amount
		if shield_hp <= 0:
			shield_hp = 0
			if has_node("VisualEscudo"):
				get_node("VisualEscudo").queue_free()
		return  # Dano absorvido pelo escudo, não tira vida

	if amount > 0:
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
	upgrade_menu.mostrar_opcoes_upgrade()


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
		"Escudo Sangrento":
			activate_shield(100)
		
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

func start_thruster():
	if thruster_estado != "desligado":
		return  # já ligando ou ativo

	thruster_estado = "ligando"
	propulsor.visible = true
	propulsor.play("ligando")
	print("Tocando 'ligando'")

func stop_thruster():
	# Se está no meio da animação "ligando", apenas marca para parar
	if thruster_estado == "ligando":
		acelerando = false  # Garante que pare quando a animação terminar
		return
	
	thruster_estado = "desligado"
	if propulsor.is_playing():
		propulsor.stop()
	propulsor.visible = false
	print("Propulsor desligado")

func _on_propulsor_animation_finished():
	print("Animação terminou. Estado atual:", thruster_estado, "Acelerando:", acelerando)
	
	# Se terminou a animação "ligando" e ainda está acelerando, muda para "ativo"
	if thruster_estado == "ligando" and acelerando:
		print("Mudando para 'ativo'")
		thruster_estado = "ativo"
		propulsor.play("ativo")
	# Se terminou qualquer animação e não está mais acelerando, para tudo
	elif not acelerando:
		print("Não está mais acelerando, parando")
		stop_thruster()
#Upgrades abaixo
func activate_shield(amount: int):
	print("Escudo")
	if not has_node("VisualEscudo"):
		print("Escudo 2")
		var escudo = preload("res://Scenes/PowerUps/VisualEscudo.tscn").instantiate()
		escudo.name = "VisualEscudo"
		add_child(escudo)
		escudo.position = Vector2.ZERO
		escudo.max_hp = amount
