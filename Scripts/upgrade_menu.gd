extends CanvasLayer

signal upgrade_selected(upgrade_name: String)

func _ready():
	hide()
	$VBoxContainer/Upgrade1.pressed.connect(func(): _on_upgrade_chosen("Mais Dano"))
	$VBoxContainer/Upgrade2.pressed.connect(func(): _on_upgrade_chosen("Mais Vida"))
	$VBoxContainer/Upgrade3.pressed.connect(func(): _on_upgrade_chosen("Mais XP"))

func _on_upgrade_chosen(upgrade_name):
	emit_signal("upgrade_selected", upgrade_name)
	hide()
	get_tree().paused = false


func _on_upgrade_1_pressed() -> void:
	emit_signal("upgrade_selected", "Mais Dano")


func _on_upgrade_2_pressed() -> void:
	emit_signal("upgrade_selected", "Mais Vida")


func _on_upgrade_3_pressed() -> void:
	emit_signal("upgrade_selected", "Mais XP")
