extends CharacterBody2D
@export var speed = 800
const  acceleration = 1200.0
const max_speed = 2000.0 
const friction = 100.0
var input = Vector2.ZERO
var currentHealth: int = 0 #vida

@export var dash_speed: float = 1000.0 
@export var dash_duration: float = 0.2 
@export var dash_cooldown: float = 2.0 #tempo de carregamento do dash
var dash_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0

var bullet_path=preload("res://Scenes/bullet.tscn")

func _physics_process(delta): #função que reconhece o clique esquerdo e chama a função atirar
	look_at(get_global_mouse_position())
	input = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	player_movement(input, delta)
	move_and_slide()
	
	# Cooldown do dash
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

# Dash ativo
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	else:
# Iniciar dash se clique direito e cooldown pronto
		if Input.is_action_just_pressed("right_click") and dash_cooldown_timer <= 0:
			is_dashing = true
			dash_timer = dash_duration
			dash_cooldown_timer = dash_cooldown
			dash_direction = Vector2.RIGHT.rotated(rotation)

	if Input.is_action_just_pressed("left_click"):
		fire()
		look_at(get_global_mouse_position())

func get_input(): #Função que reconhece movimentação wasd ou seta
	input.x=int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input.y=int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return input.normalized()
	
func player_movement(direction, delta):
	if is_dashing:
		velocity = dash_direction * dash_speed
	elif direction:
		velocity = velocity.move_toward(input * speed, delta * acceleration)
	else:
		velocity = velocity.move_toward(Vector2(0,0), delta * friction)

func fire():#função para fazer o tiro da nave com o clique esquerdo funcionar
	var bullet=bullet_path.instantiate()
	bullet.dir=rotation
	bullet.global_position=$Node2D.global_position
	bullet.is_enemy_bullet = false
	bullet.configurar_colisao(3, 2)  # Bala do player: está na camada 3, colide com camada 2 (inimigos)
	get_parent().add_child(bullet)
	$AudioStreamPlayer2D.play()
	
func _ready():
	$Hurtbox.connect("area_entered", Callable(self, "_on_Hurtbox_area_entered"))
	Global.player = self

func _on_Hurtbox_area_entered(body): 
	var bullet_owner = body.get_parent()
	if bullet_owner.is_in_group("enemy_bullet"):
		currentHealth -= 1
		bullet_owner.queue_free()
		var hud = get_tree().get_current_scene().get_node("hud")
		hud.update_hearts(currentHealth)
		if currentHealth <= 0:
			die()


func die():
	var hud = get_tree().get_current_scene().get_node("hud")
	hud.get_node("GameOver").show_game_over()
	queue_free()  # remove o player da cena
