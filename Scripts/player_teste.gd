extends CharacterBody2D
#Variáveis

@export var speed = 800
const acceleration = 400.0  # Reduzido para impulsos menores
const max_speed = 3000.0
const friction = 20.0  # Atrito ainda mais baixo para desacelerar menos
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
@export var base_speed = 600  # Impulso base maior (era 300)
@export var accel_speed = 1200  # Impulso com Shift maior (era 800)
@onready var propulsor = $Propulsor  # o AnimatedSprite2D
var acelerando := false
var thruster_estado := "desligado" # Pode ser: "desligado", "ligando", "ativo"
#Variaveis de powerup
var max_bullet_pierce := 0  # Quantos inimigos as balas podem atravessar
var bonus_drop_vida := 0.0  # Começa sem bônus
var tem_furia_upgrade := false
var tem_camuflagem_temporal := false
var camuflagem_em_cooldown := false
@export var duracao_camuflagem := 2.0
@export var cooldown_camuflagem := 10.0

var is_invincible: bool = false
var bullet_path = preload("res://Scenes/bullet.tscn")
signal health_changed(current, max)
@export var base_damage := 35

# Adicione essas variáveis para o efeito de piscar
@export var blink_interval: float = 0.1  # Intervalo entre piscadas
var blink_timer: float = 0.0
var player_visible: bool = true

# Variáveis para dano por velocidade
@export var velocity_damage_threshold: float = 800.0  # Velocidade mínima para causar dano
@export var velocity_damage_multiplier: float = 0.02  # Multiplicador do dano por velocidade
var collision_cooldown: float = 0.0
@export var collision_cooldown_duration: float = 0.5  # Cooldown entre colisões
# Variáveis para controle vetorial avançado
@export var max_directional_multiplier: float = 3.0  # Multiplicador máximo para mudanças de direção
@export var min_velocity_for_vectorial: float = 200.0  # Velocidade mínima para ativar controle vetorial
var previous_velocity: Vector2 = Vector2.ZERO  # Para detectar colisões melhor

# Variáveis para efeito de piscar ao tomar dano
var damage_flash_timer: float = 0.0
@export var damage_flash_duration: float = 0.15  # Duração menor (era 0.3)
@export var damage_flash_interval: float = 0.075  # Intervalo maior (era 0.05)
var is_damage_flashing: bool = false

func _ready():
	var cursor_image = load("res://Assets/cursor_1.png")
	Input.set_custom_mouse_cursor(cursor_image)
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
	
	# Armazena velocidade antes do move_and_slide para detectar colisões
	previous_velocity = velocity
	
	move_and_slide()
	
	# Verifica colisão com StaticBody2D após move_and_slide
	check_collision_damage()
	
	# Gerencia cooldown de colisão
	if collision_cooldown > 0:
		collision_cooldown -= delta
	
	# Gerencia o efeito de piscar durante invencibilidade
	if is_invincible:
		blink_timer += delta
		if blink_timer >= blink_interval:
			player_visible = !player_visible
			modulate.a = 0.3 if not player_visible else 1.0  # Semi-transparente ou opaco
			blink_timer = 0.0
	elif is_damage_flashing:
		# Efeito de piscar ao tomar dano
		damage_flash_timer += delta
		blink_timer += delta
		
		if blink_timer >= damage_flash_interval:
			player_visible = !player_visible
			if player_visible:
				modulate = Color(1, 1, 1, 1)  # Cor normal
			else:
				modulate = Color(2, 2, 2, 1)  # Mais branco/brilhante
			blink_timer = 0.0
			# Remove o print para evitar spam
			
		if damage_flash_timer >= damage_flash_duration:
			damage_flash_timer = 0.0
			is_damage_flashing = false
			modulate = Color(1, 1, 1, 1)  # Restaura cor normal
			# Remove o print para evitar spam
	else:
		# Restaura visibilidade normal quando não está invencível nem piscando
		modulate.a = 1.0
		modulate = Color(1, 1, 1, 1)
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
		var base_impulse = base_speed
		
		# Se está acelerando (Shift pressionado), usa impulso maior
		if acelerando:
			base_impulse = accel_speed
		
		# Controle vetorial: calcula multiplicador baseado na direção
		var directional_multiplier = 1.0
		var current_speed = velocity.length()
		
		# Só aplica controle vetorial se a nave já está se movendo com velocidade significativa
		if current_speed > min_velocity_for_vectorial:
			# Normaliza a direção atual da velocidade
			var current_direction = velocity.normalized()
			var input_direction = direction.normalized()
			
			# Calcula o ângulo entre a direção atual e o input (dot product = cos do ângulo)
			var dot_product = current_direction.dot(input_direction)
			
			# dot_product vai de 1 (mesma direção) a -1 (direção oposta)
			# Converte para multiplicador: quanto mais oposta, maior o multiplicador
			# dot = 1 (0°) -> multiplier = 1.0 (sem bonus)
			# dot = 0 (90°) -> multiplier = 2.0 (bonus médio)  
			# dot = -1 (180°) -> multiplier = 3.0 (bonus máximo)
			directional_multiplier = 1.0 + (1.0 - dot_product) * (max_directional_multiplier - 1.0) / 2.0
			
			# Debug para ver o sistema funcionando
			if current_speed > 500:  # Só mostra debug em velocidades altas
				var angle_degrees = rad_to_deg(acos(clamp(dot_product, -1.0, 1.0)))
				print("Velocidade: ", int(current_speed), " Ângulo: ", int(angle_degrees), "° Multiplicador: ", "%.2f" % directional_multiplier)
		
		# Aplica impulso com multiplicador direcional
		var final_impulse = base_impulse * directional_multiplier
		velocity += direction.normalized() * final_impulse * delta
		
		# Limita pela velocidade máxima
		var max_vel = max_speed * debuff_multiplier
		if velocity.length() > max_vel:
			velocity = velocity.normalized() * max_vel
	else:
		# Atrito quando não há input - a nave continua deslizando
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# Limita a velocidade máxima global
	if velocity.length() > max_speed * debuff_multiplier:
		velocity = velocity.normalized() * max_speed * debuff_multiplier

func fire():
	var bullet = bullet_path.instantiate()

	var dano_final = base_damage
	if tem_furia_upgrade and current_health <= max_health * 0.3:
		dano_final *= 1.3  # +30% de dano

	bullet.damage = dano_final
	bullet.dir = rotation
	bullet.global_position = $Node2D.global_position
	bullet.is_enemy_bullet = false
	bullet.add_to_group("player_bullet")
	bullet.configurar_colisao(3, 2)
	if "pierce" in bullet:
		bullet.pierce = max_bullet_pierce
		
	# Adiciona a herança de velocidade da nave
	if "velocity_inherited" in bullet:
		bullet.velocity_inherited = velocity

	get_parent().add_child(bullet)
	$AudioStreamPlayer2D.play()

	
func _on_Hurtbox_area_entered(body):#Ativa quando o player é atingido por balas inimigas
	if is_invincible:
		print("Dano ignorado: invencível!")
		return
	
	# Ignora balas do próprio player silenciosamente
	if body.is_in_group("player_bullet"):
		return
	
	print("Hurtbox atingido!")
	print("Algo entrou:", body.name, " Grupos do pai:", body.get_groups())
	
	if body.is_in_group("enemy_bullet"):
		print("Acertado por bala inimiga!")
		take_damage(body.damage)
		body.queue_free()
	elif body.is_in_group("enemy") and collision_cooldown <= 0:
		# Dano por colisão com inimigo baseado na velocidade
		var current_velocity = velocity.length()
		if current_velocity > velocity_damage_threshold:
			var damage_to_player = int(current_velocity * velocity_damage_multiplier)
			var damage_to_enemy = int(current_velocity * velocity_damage_multiplier * 0.5)  # Inimigo toma menos dano
			
			print("Colisão de alta velocidade! Velocidade: ", current_velocity)
			print("Dano ao player: ", damage_to_player, " Dano ao inimigo: ", damage_to_enemy)
			
			# Aplica dano ao player
			take_damage(damage_to_player)
			
			# Aplica dano ao inimigo se ele tem a função
			if body.has_method("take_damage"):
				body.take_damage(damage_to_enemy)
			
			collision_cooldown = collision_cooldown_duration

func take_damage(amount: int):
	print("take_damage chamado com amount:", amount)
	
	if shield_hp > 0:
		shield_hp -= amount
		print("Escudo absorveu dano. HP do escudo:", shield_hp)
		if shield_hp <= 0:
			shield_hp = 0
			if has_node("VisualEscudo"):
				get_node("VisualEscudo").queue_free()
		# Mesmo com escudo, mostra o efeito de piscar
		is_damage_flashing = true
		damage_flash_timer = 0.0
		blink_timer = 0.0
		print("Ativando efeito de piscar (escudo)")
		return  # Dano absorvido pelo escudo, não tira vida

	if amount > 0:
		if tem_camuflagem_temporal and not camuflagem_em_cooldown:
			camuflagem_em_cooldown = true
			ativar_camuflagem_temporal()

		current_health -= amount
		current_health = max(current_health, 0)
		print("Player tomou dano! Vida restante:", current_health)
		emit_signal("health_changed", current_health, max_health)
		
		# Ativa o efeito de piscar ao tomar dano
		is_damage_flashing = true
		damage_flash_timer = 0.0
		blink_timer = 0.0
		print("Ativando efeito de piscar (vida)")
		
		if current_health <= 0:
			die()

func gain_xp(amount: int):
	current_xp += amount
	print("XP atual: ", current_xp)
	if current_xp >= xp_to_next_level:
		level_up()

func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	emit_signal("health_changed", current_health, max_health)


func level_up():
	current_xp -= xp_to_next_level
	level += 1
	xp_to_next_level += 50
	# Aumenta vida máxima e cura totalmente
	max_health += 10
	# Aumenta dano base
	base_damage += 5
	print("Subiu para o nível ", level)
	get_tree().paused = true
	var upgrade_menu = get_tree().get_current_scene().get_node("hud/TelaUpgrade")
	upgrade_menu.mostrar_opcoes_upgrade()

func die():
	var hud = get_tree().get_current_scene().get_node("hud")
	hud.get_node("GameOver").show_game_over()
	queue_free()

func _on_xp_magnet_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_orb") or area.is_in_group("hp_orb"):
		area.start_attraction(self)


func _on_tela_upgrade_upgrade_selected(upgrade_name: Variant) -> void:
	var player = Global.player
	var upgrade_menu = get_tree().get_current_scene().get_node("hud/TelaUpgrade")
	match upgrade_name:
		"Balas Perfurantes":
			player.max_bullet_pierce = 2
			upgrade_menu.all_upgrades.erase("Balas Perfurantes")
			print("Upgrade único: Balas Perfurantes ativado (atravessa até 2 inimigos).")

		"Escudo de Energia":
			activate_shield(100)
		
		"Sorte de Principiante":
			if player.bonus_drop_vida < 0.3:
				player.bonus_drop_vida += 0.2
				# Garante que o bônus não passe de 30%
				if player.bonus_drop_vida > 0.3:
					player.bonus_drop_vida = 0.3
				print("Upgrade: Sorte de Sobrevivente. Chance de drop aumentada para %.0f%%" % (player.bonus_drop_vida * 100.0))
				# Se atingiu o máximo, remove o upgrade da lista
				if player.bonus_drop_vida >= 0.3:
					var tela_upgrade = get_tree().get_current_scene().get_node("hud/TelaUpgrade")
					tela_upgrade.all_upgrades.erase("Sorte de Principiante")
				else:
					print("Chance de drop de vida já está no máximo!")

		"Resistência Final":
			tem_furia_upgrade = true
			upgrade_menu.all_upgrades.erase("Resistência Final")
		"Caminho da Ganância":
			upgrade_menu.all_upgrades.erase("Caminho da Ganância")
			if has_node("XpMagnet"):
				var magnet = get_node("XpMagnet")
				if magnet.has_node("CollisionShape2D"):
					var shape = magnet.get_node("CollisionShape2D").shape
					if shape is CircleShape2D:
						shape.radius *= 1.5  # Aumenta 50% o raio
		"Capa Sorrateira":
			tem_camuflagem_temporal = true
			upgrade_menu.all_upgrades.erase("Capa Sorrateira")

		"Instinto de Sobrevivência":
			dash_cooldown *= 0.8  # Reduz o cooldown em 20%
			upgrade_menu.all_upgrades.erase("Instinto de Sobrevivência")
			print("Upgrade único: Redução de Cooldown aplicado. Novo cooldown:", dash_cooldown)
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
	if not has_node("VisualEscudo"):
		var escudo = preload("res://Scenes/PowerUps/VisualEscudo.tscn").instantiate()
		escudo.name = "VisualEscudo"
		add_child(escudo)
		escudo.position = Vector2.ZERO
		escudo.max_hp = amount

func check_collision_damage():
	# Verifica se houve colisão e se a velocidade é alta o suficiente
	if get_slide_collision_count() > 0 and collision_cooldown <= 0:
		# Use a velocidade anterior (antes do slide) para detecção mais precisa
		var current_velocity = previous_velocity.length()
		
		# Só faz debug se a velocidade for significativa
		if current_velocity > 50:  # Evita spam de debug
			print("Colisão detectada! Velocidade:", current_velocity, "Threshold:", velocity_damage_threshold)
		
		if current_velocity > velocity_damage_threshold:
			var damage_to_player = int(current_velocity * velocity_damage_multiplier)
			
			# Pega informações da colisão para debug
			var collision = get_slide_collision(0)
			if collision:
				print("Colidiu com:", collision.get_collider().name if collision.get_collider() else "Desconhecido")
				print("Posição da colisão:", collision.get_position())
				print("Normal da colisão:", collision.get_normal())
			
			print("Colisão de alta velocidade com parede! Velocidade: ", current_velocity)
			print("Dano ao player: ", damage_to_player)
			
			# Aplica dano ao player
			take_damage(damage_to_player)
			
			collision_cooldown = collision_cooldown_duration
			
			# Reduz velocidade após colisão para simular impacto
			velocity = velocity * 0.3  # Reduz velocidade para 30% após colisão
			
func ativar_camuflagem_temporal():
	modulate.a = 0.2  # Deixa quase invisível
	is_invincible = true

	await get_tree().create_timer(duracao_camuflagem).timeout

	modulate.a = 1.0  # Restaura visibilidade
	is_invincible = false

	await get_tree().create_timer(cooldown_camuflagem).timeout
	camuflagem_em_cooldown = false
	print("Camuflagem pronta para uso novamente.")
