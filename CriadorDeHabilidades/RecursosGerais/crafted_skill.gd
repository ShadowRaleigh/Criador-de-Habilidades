class_name CraftedSkill extends Resource

var selected_nodes: Array[NodeData] = []

# Variáveis finais da habilidade
var total_cost: float = 0.0
var combined_types: Array[int] = []
var min_allowed_tier: int = 1
var max_allowed_tier: int = 5

# Status de validação
var is_valid: bool = true
var error_message: String = ""

func toggle_node(node_data: NodeData) -> bool:
	if selected_nodes.has(node_data):
		selected_nodes.erase(node_data)
		calculate_totals()
		return false
	else:
		selected_nodes.append(node_data)
		calculate_totals()
		return true

func calculate_totals() -> void:
	total_cost = 0.0
	combined_types.clear()
	min_allowed_tier = 1
	max_allowed_tier = 5
	is_valid = true
	error_message = ""

	if selected_nodes.is_empty():
		return

	# Inicia com valores extremos para a lógica de interseção funcionar
	var current_min = 1
	var current_max = 5

	for data in selected_nodes:
		var char_data = data.characteristic
		total_cost += char_data.cost_multiplier
		
		# Adiciona o tipo à mistura se ele já não estiver lá
		if not combined_types.has(char_data.type):
			combined_types.append(char_data.type)
			
		# Interseção de Tiers (Pega o maior mínimo e o menor máximo)
		if char_data.min_tier > current_min:
			current_min = char_data.min_tier
		if char_data.max_tier < current_max:
			current_max = char_data.max_tier

	min_allowed_tier = current_min
	max_allowed_tier = current_max

	# Se a interseção for impossível (ex: exigiu min 4 e max 2 ao mesmo tempo)
	if min_allowed_tier > max_allowed_tier:
		is_valid = false
		error_message = "Erro: Conflito de Tiers entre os nós escolhidos!"
		
# Função que será chamada pela UI para checar se o Tier que o jogador digitou é válido
func validate_desired_tier(desired_tier: int) -> void:
	if not is_valid and error_message == "Erro: Conflito de Tiers entre os nós escolhidos!":
		return # Já está quebrado por natureza
		
	if desired_tier < min_allowed_tier or desired_tier > max_allowed_tier:
		is_valid = false
		error_message = "Erro: O Tier " + str(desired_tier) + " está fora do limite permitido (" + str(min_allowed_tier) + " a " + str(max_allowed_tier) + ")."
	else:
		is_valid = true
		error_message = "Habilidade Válida!"
