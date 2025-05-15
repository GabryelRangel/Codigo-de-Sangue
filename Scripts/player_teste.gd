extends CharacterBody2D
@export var speed = 800
const  acceleration = 1200.0
const max_speed = 2000.0 
const friction = 100.0
var input = Vector2.ZERO
var bullet_path=preload("res://Scenes/bullet.tscn")

func _physics_process(delta): #função que reconhece o clique esquerdo e chama a função atirar
	look_at(get_global_mouse_position())
	input = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	player_movement(input, delta)
	move_and_slide()
	if Input.is_action_just_pressed("left_click"):
		fire()
		look_at(get_global_mouse_position())

func get_input(): #Função que reconhece movimentação wasd ou seta
	input.x=int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input.y=int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	return input.normalized()
	
func player_movement(direction,delta):
	if direction: velocity = velocity.move_toward(input * speed , delta * acceleration)
	else: velocity = velocity.move_toward(Vector2(0,0), delta * friction)
		
func fire():#função para fazer o tiro da nave com o clique esquerdo funcionar
	var bullet=bullet_path.instantiate()
	bullet.dir=rotation
	bullet.pos=$Node2D.global_position
	bullet.rota=global_rotation
	get_parent().add_child(bullet)
	$AudioStreamPlayer2D.play() #chama o aúdio pro tiro. remover caso se tornar problemático
