extends CanvasLayer

signal upgrade_selected(upgrade_name: String)

var all_upgrades := [
	"Escudo de Energia",
	"Kit Médico",
	"Pacote de Veterano",
	"Sede de Sangue",
	"Última resistência",
	"Caminho da Ganância",
	"Instinto de Sobrevivência",
	"Capa Sorrateira",
	"Sorte de Principiante",
	"Balas Perfurantes"
]

var upgrade_descricoes := {
	"Escudo de Energia": "Cria um escudo envolta de SH4RK que absorve até 100 de dano.",
	"Kit Médico": "Aumenta sua vida máxima em 20 HP e recupera vida.",
	"Pacote de Veterano": "Ganha 20% mais experiência.",
	"Sede de Sangue": "Aumenta o dano das suas armas em 25%.",
	"Última Resistência": "Aumenta o dano em 30% quando o SH4RK está com a vida baixa.",
	"Caminho da Ganância": "Aumenta o alcance de coleta de orbes de XP e HP.",
	"Instinto de Sobrevivência": "Reduz o tempo de recarga do dash em 20%.",
	"Capa Sorrateira": "Fica invisível e invencível por 2s ao tomar dano.",
	"Sorte de Principiante": "Aumenta a chance de inimigos droparem orbes de vida.",
	"Balas Perfurantes": "As balas de SH4RK atravessam até 2 inimigos."
}

func _ready():
	hide()

func mostrar_opcoes_upgrade():
	randomize()

	var upgrades = all_upgrades.duplicate()
	upgrades.shuffle()
	var selecionados = upgrades.slice(0, 3)

	var botoes = [
		$Panel/VBoxContainer/Caixa1/Upgrade1,
		$Panel/VBoxContainer/Caixa2/Upgrade2,
		$Panel/VBoxContainer/Caixa3/Upgrade3
	]

	var descricoes = [
		$Panel/VBoxContainer/Caixa1/Desc1,
		$Panel/VBoxContainer/Caixa2/Desc2,
		$Panel/VBoxContainer/Caixa3/Desc3
	]

	for i in range(3):
		var nome_upgrade = selecionados[i]
		botoes[i].text = nome_upgrade
		descricoes[i].text = upgrade_descricoes.get(nome_upgrade, "Sem descrição disponível.")

		# Desconecta qualquer conexão anterior
		for connection in botoes[i].get_signal_connection_list("pressed"):
			botoes[i].disconnect("pressed", connection["callable"])

		# Conecta o botão ao upgrade escolhido
		botoes[i].pressed.connect(func(): _on_upgrade_chosen(nome_upgrade))

	show()
	get_tree().paused = true

func _on_upgrade_chosen(upgrade_name):
	emit_signal("upgrade_selected", upgrade_name)
	hide()
	get_tree().paused = false
