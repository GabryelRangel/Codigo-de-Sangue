extends CanvasLayer

signal upgrade_selected(upgrade_name: String)

var all_upgrades := [
	"Escudo de Energia",
	"Mais Vida",
	"Mais XP",
	"Mais Dano",
	"Fúria",
	"Magnetismo Melhorado",
	"Redução de Cooldown",
	"Camuflagem Temporal",
	"Sorte de Sobrevivente"
]

func _ready():
	hide()

func mostrar_opcoes_upgrade():
	randomize()

	var upgrades = all_upgrades.duplicate()
	upgrades.shuffle()
	var selecionados = upgrades.slice(0, 3)

	var botoes = [
		$VBoxContainer/Upgrade1,
		$VBoxContainer/Upgrade2,
		$VBoxContainer/Upgrade3
	]

	for i in range(3):
		botoes[i].text = selecionados[i]

		# Desconecta todos os Callables conectados ao "pressed"
		for connection in botoes[i].get_signal_connection_list("pressed"):
			botoes[i].disconnect("pressed", connection["callable"])

		# Conecta um novo callback com a opção sorteada
		var upgrade_nome = selecionados[i]  # Captura corretamente o valor para cada botão
		botoes[i].pressed.connect(func(): _on_upgrade_chosen(upgrade_nome))

	show()
	get_tree().paused = true

func _on_upgrade_chosen(upgrade_name):
	emit_signal("upgrade_selected", upgrade_name)
	hide()
	get_tree().paused = false
