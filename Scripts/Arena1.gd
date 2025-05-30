extends Node2D

var enemy_1=preload("res://Scenes/inimigo_1.tscn")
var enemy_2=preload("res://Scenes/inimigo_2.tscn")
var enemy_3=preload("res://Scenes/inimigo_3.tscn")

func _ready():
	Global.node_creation_parent = self

func _exit_tree():
	Global.node_creation_parent = self

func _on_spawner_inimigo_timeout():
	var enemy_postion = Vector2(randf_range(-2800,2800), randf_range(-2800, 2800))
	while enemy_postion.x<2700 and enemy_postion.x>-2700 and enemy_postion.y < 2700 and enemy_postion.y>-2700:
		enemy_postion = Vector2(randf_range(-2800,2800), randf_range(-2800, 2800))
	Global.instance_node(enemy_1, enemy_postion, self)
	Global.instance_node(enemy_2, enemy_postion, self)
	Global.instance_node(enemy_3, enemy_postion, self)
