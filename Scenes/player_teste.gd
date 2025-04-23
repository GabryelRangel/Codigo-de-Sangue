extends CharacterBody2D
@export var speed = 400

var bullet_path=preload("res://Scenes/bullet.tscn")

func get_input(): #Função que reconhece movimentação wasd ou seta
	look_at(get_global_mouse_position())
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed #afeta velocidade da nave



func _physics_process(_delta): #função que reconhece o clique esquerdo e chama a função atirar
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("left_click"):
		fire()
	
	get_input()
	move_and_slide()

func fire():#função para fazer o tiro da nave com o clique esquerdo funcionar
	var bullet=bullet_path.instantiate()
	bullet.dir=rotation
	bullet.pos=$Node2D.global_position
	bullet.rota=global_rotation
	get_parent().add_child(bullet)
	$AudioStreamPlayer2D.play() #chama o aúdio pro tiro. remover caso se tornar problemático
