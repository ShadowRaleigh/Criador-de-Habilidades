extends Control

#region

@export var player_node_scene: PackedScene
@onready var material_cost_label: Label = $HBoxContainer/SidePanel/VBoxContainer/MaterialCostLabel
@onready var tree_map: Control = $HBoxContainer/MapWindow/TreeMap
@onready var skill_sheet: SkillSheet = $SkillSheet
@onready var tree_selector_list: VBoxContainer = $HBoxContainer/SidePanel/VBoxContainer/ScrollContainer/TreeSelectorList

# Referências do Painel Lateral

@onready var area_shape_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/AreaShapeButton
@onready var sync_type_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/SyncTypeButton
@onready var target_type_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/TargetTypeButton
@onready var speed_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/SpeedButton
@onready var range_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/RangeButton
@onready var duration_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/DurationButton
@onready var uses_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/UsesButton
@onready var recovery_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/RecoveryButton
@onready var defense_button: OptionButton = $HBoxContainer/SidePanel/VBoxContainer/TierBox/DefenseButton
@onready var finish_button: Button = $HBoxContainer/SidePanel/VBoxContainer/FinishButton

@onready var skill_name_edit: LineEdit = $HBoxContainer/SidePanel/VBoxContainer/SkillNameEdit

@onready var cost_factor_label: Label = $HBoxContainer/SidePanel/VBoxContainer/CostFactorLabel
@onready var area_size_label: Label = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/AreaSizeLabel
@onready var area_shape_label: Label = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/AreaShapeLabel
@onready var final_cost_label: Label = $HBoxContainer/SidePanel/VBoxContainer/FinalCostLabel
@onready var types_label: Label = $HBoxContainer/SidePanel/VBoxContainer/TypesLabel
@onready var status_label: Label = $HBoxContainer/SidePanel/VBoxContainer/StatusLabel

@onready var tier_spin_box: SpinBox = $HBoxContainer/SidePanel/VBoxContainer/TierBox/TierSpinBox
@onready var area_size_spin_box: SpinBox = $HBoxContainer/SidePanel/VBoxContainer/GridContainer/AreaSizeSpinBox

var crafted_skill: CraftedSkill = CraftedSkill.new()
var loaded_trees_info: Array[Dictionary] = []
var current_x_offset: float = 50000.0

# --- VARIÁVEIS DE ZOOM E PASTA ---
var first_root_pos: Vector2 = Vector2.ZERO
const TREES_FOLDER_PATH: String = "res://Trees/"
var is_panning: bool = false
var current_zoom: float = 1.0
var base_tree_map_size: Vector2 = Vector2(4000, 4000)
#endregion

func _ready() -> void:
	
	# Adiciona as opções de defesa no menu
	defense_button.add_item("Nenhum")
	defense_button.add_item("Deflexão")
	defense_button.add_item("Reflexos")
	defense_button.add_item("Mental")
	defense_button.add_item("Fortitude")
	
	# Preenche os dropdowns
	sync_type_button.add_item("Simples")
	sync_type_button.add_item("Especial")
	
	target_type_button.add_item("Target")
	target_type_button.add_item("Self")
	target_type_button.add_item("Área")
	
	speed_button.add_item("Lento (-35%)")
	speed_button.add_item("Normal (0%)")
	speed_button.add_item("Rápido (+30%)")
	speed_button.add_item("Instantâneo (+60%)")
	speed_button.selected = 1 # Deixa o Normal como padrão
	
	range_button.add_item("Toque (-15%)")
	range_button.add_item("Curta (0%)")
	range_button.add_item("Média (+15%)")
	range_button.add_item("Longa (+25%)")
	range_button.add_item("Longuíssima (+50%)")
	range_button.selected = 1
	
	duration_button.add_item("Instantânea (-15%)")
	duration_button.add_item("Curta (0%)")
	duration_button.add_item("Média (+25%)")
	duration_button.add_item("Longa (+50%)")
	duration_button.add_item("Concentração (+40%)")
	
	uses_button.add_item("1 Uso (0%)")
	uses_button.add_item("2 Usos (+10%)")
	uses_button.add_item("3 Usos (+20%)")
	uses_button.add_item("4 Usos (+30%)")
	uses_button.add_item("5 Usos (+40%)")
	uses_button.add_item("Escalonável (+30%)")
	uses_button.add_item("Ilimitado (+100%)")
	
	area_shape_button.add_item("Círculo (Raio)")
	area_shape_button.add_item("Quadrilátero (Lado)")
	area_shape_button.add_item("Cone (Comprimento)")
	
	area_size_spin_box.value_changed.connect(_on_tier_changed) # Pode reaproveitar a função do tier que só chama o update
	
	_update_recovery_options(0) # Inicia com as opções de 'Simples'
	
	# Conecta todos os botões para atualizarem a UI quando mudarem
	var all_dropdowns = [sync_type_button, target_type_button, speed_button, range_button, duration_button, uses_button, recovery_button, area_shape_button]
	for btn in all_dropdowns:
		btn.item_selected.connect(_on_any_dropdown_changed)
	
	# Toda vez que o jogador mudar algo, atualizamos o painel
	defense_button.item_selected.connect(_on_defense_selected)
	
	tree_map.draw.connect(_on_tree_map_draw)
	tier_spin_box.value_changed.connect(_on_tier_changed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	
	# Ajusta o tamanho base do painel onde desenhamos para o scroll funcionar bem
	tree_map.custom_minimum_size = base_tree_map_size
	
	# Carrega a lista de árvores ao iniciar
	populate_tree_selector()
	_on_any_dropdown_changed(0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(current_zoom + 0.1, true) # "true" diz para focar no mouse
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(current_zoom - 0.1, true)
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning = event.pressed
	elif event is InputEventMouseMotion and is_panning:
		tree_map.position += event.relative

func set_zoom(new_zoom: float, use_mouse: bool = false) -> void:
	var previous_zoom = current_zoom
	current_zoom = clamp(new_zoom, 0.3, 2.0)
	
	if current_zoom == previous_zoom:
		return

	var map_window = $HBoxContainer/MapWindow
	var zoom_point: Vector2

	# Descobre se o zoom deve ir para o mouse ou para o centro da tela
	if use_mouse:
		zoom_point = map_window.get_local_mouse_position()
	else:
		zoom_point = map_window.size / 2.0

	# A Mágica Matemática: Mantém o ponto sob o mouse no mesmo lugar após o zoom
	var map_point = (zoom_point - tree_map.position) / previous_zoom
	tree_map.scale = Vector2(current_zoom, current_zoom)
	tree_map.position = zoom_point - (map_point * current_zoom)
	
func _update_recovery_options(sync_type: int) -> void:
	recovery_button.clear()
	if sync_type == 0: # Simples
		recovery_button.add_item("Por Descanso Longo (-20%)")
		recovery_button.add_item("Por Descanso Curto (0%)")
		recovery_button.add_item("Por Combate (+50%)")
	else: # Especial
		recovery_button.add_item("Por Sessão (-25%)")
		recovery_button.add_item("Por Descanso Longo (0%)")
		recovery_button.add_item("Por Descanso Curto (+75%)")
	recovery_button.selected = 1 # Seleciona a base (0%)

func populate_tree_selector() -> void:
	var dir = DirAccess.open(TREES_FOLDER_PATH)
	if dir:
		var files = dir.get_files() # O método seguro do Godot 4
		
		for file_name in files:
			# Lê tanto arquivos do Editor (.tres) quanto os exportados (.tres.remap)
			if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
				
				# Tira o .remap do nome para o ResourceLoader conseguir achar o arquivo original
				var clean_name = file_name.replace(".remap", "")
				
				var checkbox := CheckBox.new()
				checkbox.text = clean_name.replace(".tres", "") 
				checkbox.text = checkbox.text.capitalize()
				checkbox.set_meta("file_path", TREES_FOLDER_PATH + clean_name) 
				checkbox.toggled.connect(_on_tree_checkbox_toggled)
				tree_selector_list.add_child(checkbox)
	else:
		print("Erro: Pasta de árvores não encontrada! Verifique o caminho.")

func _on_tree_checkbox_toggled(_toggled_on: bool) -> void:
	reload_all_selected_trees()

func reload_all_selected_trees() -> void:
	for child in tree_map.get_children():
		tree_map.remove_child(child)
		child.queue_free()
		
	loaded_trees_info.clear()
	
	# O reset agora volta para o meio do Mega Canvas
	current_x_offset = 50000.0 
	
	first_root_pos = Vector2.ZERO 
	crafted_skill.selected_nodes.clear()
	crafted_skill.calculate_totals()
	update_ui_panel()
	
	for checkbox in tree_selector_list.get_children():
		if checkbox is CheckBox and checkbox.button_pressed:
			load_tree(checkbox.get_meta("file_path"))
	
	# --- MEGA CANVAS (Adeus, linhas sumindo!) ---
	# Um mapa de 100.000 por 100.000 pixels garante que a borda nunca passe pela tela
	tree_map.custom_minimum_size = Vector2(100000.0, 100000.0)
	tree_map.size = tree_map.custom_minimum_size
	# --------------------------------------------
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if first_root_pos != Vector2.ZERO:
		focus_camera_on(first_root_pos)
	else:
		set_zoom(current_zoom)
		
	tree_map.queue_redraw()
	
func focus_camera_on(target_pos: Vector2) -> void:
	var window_size = $HBoxContainer/MapWindow.size
	# Move o mapa para que a Raiz fique no centro-inferior da tela
	tree_map.position = (window_size / 2.0) - (target_pos * current_zoom)
	# Dá um pequeno ajuste para baixo para a Raiz não ficar no exato meio da tela
	tree_map.position.y += window_size.y * 0.25 
	set_zoom(current_zoom)

func load_tree(path: String) -> void:
	var tree_data: TreeData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not tree_data: return
		
	var prefix: String = "tree_" + str(loaded_trees_info.size()) + "_"
	loaded_trees_info.append({"data": tree_data, "prefix": prefix})
	
	var floor_nodes: Dictionary = {}
	for node_data in tree_data.nodes:
		var floor_lvl = node_data.characteristic.tree_floor
		if not floor_nodes.has(floor_lvl):
			floor_nodes[floor_lvl] = []
		floor_nodes[floor_lvl].append(node_data)
			
	var y_spacing: float = 450.0 
	var x_spacing: float = 380.0 
	
	var floors: Array = floor_nodes.keys()
	floors.sort()
	
	var node_x_positions: Dictionary = {}
	var tree_min_x: float = 999999.0
	var tree_max_x: float = -999999.0

	# --- NOVO: CHÃO UNIVERSAL ---
	# Garante que o Andar 1 de TODAS as árvores comece exatamente na mesma altura
	var BASE_GROUND_Y: float = 50000.0
	# ----------------------------

	var parent_to_children: Dictionary = {}
	for conn in tree_data.connections:
		var parent_name = conn["from_node"]
		var child_name = conn["to_node"]
		if not parent_to_children.has(parent_name):
			parent_to_children[parent_name] = []

		var child_node = null
		for n in tree_data.nodes:
			if n.node_name == child_name:
				child_node = n
				break

		if child_node and not parent_to_children[parent_name].has(child_node):
			parent_to_children[parent_name].append(child_node)

	for p_name in parent_to_children:
		parent_to_children[p_name].sort_custom(func(a, b): return a.position_offset.y < b.position_offset.y)
	
	for floor_lvl in floors:
		var nodes_in_this_floor: Array = floor_nodes[floor_lvl]
		
		var ideal_xs = {}
		var roots = []
		var max_connected_x = -999999.0 

		for node_data in nodes_in_this_floor:
			var sum_x = 0.0
			var count = 0
			for conn in tree_data.connections:
				if conn["to_node"] == node_data.node_name:
					var parent_name = conn["from_node"]
					if node_x_positions.has(parent_name):
						var parent_x = node_x_positions[parent_name]
						
						var siblings = parent_to_children.get(parent_name, [])
						var child_idx = siblings.find(node_data)
						var sib_count = siblings.size()
						var offset = 0.0

						if sib_count > 1 and child_idx != -1:
							offset = (child_idx - (sib_count - 1) / 2.0) * x_spacing
						
						sum_x += (parent_x + offset)
						count += 1
			if count > 0:
				var calc_x = sum_x / count
				ideal_xs[node_data] = calc_x
				if calc_x > max_connected_x: max_connected_x = calc_x
			else:
				roots.append(node_data)
				
		roots.sort_custom(func(a, b): return a.position_offset.y < b.position_offset.y)
		
		if max_connected_x == -999999.0: max_connected_x = current_x_offset
		
		var edge_x = max_connected_x + (x_spacing * 1.5)
		for i in range(roots.size()):
			ideal_xs[roots[i]] = edge_x
			edge_x += x_spacing * 1.5
			
		nodes_in_this_floor.sort_custom(func(a, b): return ideal_xs[a] < ideal_xs[b])
		
		var blocks: Array = []
		for node_data in nodes_in_this_floor:
			blocks.append({"nodes": [node_data], "x": ideal_xs[node_data]})
			
		var merged = true
		while merged:
			merged = false
			for i in range(blocks.size() - 1):
				var b1 = blocks[i]
				var b2 = blocks[i+1]
				var min_dist = (b1["nodes"].size() * x_spacing + b2["nodes"].size() * x_spacing) / 2.0
				if b2["x"] - b1["x"] < min_dist:
					var total_size = b1["nodes"].size() + b2["nodes"].size()
					var new_x = ((b1["x"] * b1["nodes"].size()) + (b2["x"] * b2["nodes"].size())) / float(total_size)
					blocks[i] = {"nodes": b1["nodes"] + b2["nodes"], "x": new_x}
					blocks.remove_at(i+1)
					merged = true
					break
					
		for block in blocks:
			var block_nodes = block["nodes"]
			var start_x = block["x"] - ((block_nodes.size() - 1) * x_spacing / 2.0)
			
			for i in range(block_nodes.size()):
				var node_data = block_nodes[i]
				var final_x = start_x + (i * x_spacing)
				node_x_positions[node_data.node_name] = final_x
				
				if final_x < tree_min_x: tree_min_x = final_x
				if final_x > tree_max_x: tree_max_x = final_x
				
				var new_node: PlayerNode = player_node_scene.instantiate()
				new_node.name = prefix + node_data.node_name 
				
				# NOVO: A posição Y agora depende apenas do Andar e do Chão Universal!
				var pos_y = BASE_GROUND_Y - (floor_lvl * y_spacing)
				
				new_node.position = Vector2(final_x, pos_y)
				
				tree_map.add_child(new_node)
				new_node.setup(node_data)
				new_node.node_clicked.connect(_on_player_node_clicked)
				if crafted_skill.selected_nodes.has(node_data):
					new_node.set_selection_visual(true)

	var node_fixed_width: float = 250.0 
	var total_tree_width = (tree_max_x - tree_min_x) + node_fixed_width

	var tree_title := Label.new()
	tree_title.text = tree_data.name
	if tree_title.text == "": tree_title.text = "Árvore sem Nome"
	tree_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tree_title.add_theme_font_size_override("font_size", 32) 
	tree_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4)) 
	tree_title.custom_minimum_size = Vector2(total_tree_width, 50)
	
	# O título fica logo abaixo do Andar 1
	var root_y = BASE_GROUND_Y - (1 * y_spacing)
	tree_title.position = Vector2(tree_min_x, root_y + 450.0) 
	tree_map.add_child(tree_title)

	if loaded_trees_info.size() == 1:
		var center_x = tree_min_x + (total_tree_width / 2.0)
		first_root_pos = Vector2(center_x, root_y)

	for floor_lvl in floors:
		var floor_label := Label.new()
		floor_label.text = "--------------------  ANDAR " + str(floor_lvl) + "  --------------------"
		floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		floor_label.add_theme_font_size_override("font_size", 64) 
		floor_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.1)) 
		floor_label.custom_minimum_size = Vector2(total_tree_width, 100)
		
		# A marca d'água acompanha o andar universalmente
		var pos_y = BASE_GROUND_Y - (floor_lvl * y_spacing)
		
		floor_label.position = Vector2(tree_min_x, pos_y + 80.0) 
		floor_label.z_index = -1 
		tree_map.add_child(floor_label)

	current_x_offset = tree_max_x + node_fixed_width + 400.0
	tree_map.queue_redraw()
	
func _on_player_node_clicked(node: PlayerNode) -> void:
	var is_now_selected: bool = crafted_skill.toggle_node(node.node_data)
	node.set_selection_visual(is_now_selected)
	
	update_ui_panel()

func calculate_final_cost() -> float:
	var tier = int(tier_spin_box.value)
	var is_especial = (sync_type_button.selected == 1)
	var is_area = (target_type_button.selected == 2)
	
	# 1. Custo Base de Mana
	var custo_base: float = 0.0
	if not is_especial:
		var bases_simples = [8, 20, 40, 65, 80]
		custo_base = bases_simples[clamp(tier - 1, 0, 4)]
	else:
		var bases_especiais = [16, 35, 60, 100, 125]
		custo_base = bases_especiais[clamp(tier - 1, 0, 4)]
		
	# 2. Somando todos os Fatores Aditivamente
	# Fatores de custo são taxas aditivas que multiplicam o valor base
	var fator_total: float = 1.0 + crafted_skill.total_cost 
	
	# Aditivo de Área
	if is_area:
		fator_total += 0.20 # +20% se for AoE
	
	# Velocidade
	var spd = speed_button.selected
	if spd == 0: fator_total -= 0.35
	elif spd == 2: fator_total += 0.30
	elif spd == 3: fator_total += 0.60
	
	# Alcance
	var rng = range_button.selected
	if rng == 0: fator_total -= 0.15
	elif rng == 2: fator_total += 0.15
	elif rng == 3: fator_total += 0.25
	elif rng == 4: fator_total += 0.50
	
	# Duração
	var dur = duration_button.selected
	if dur == 0: fator_total -= 0.15
	elif dur == 2: fator_total += 0.25
	elif dur == 3: fator_total += 0.50
	elif dur == 4: fator_total += 0.40
	
	# Usos
	var uses = uses_button.selected
	if uses >= 1 and uses <= 4: fator_total += (uses * 0.10) 
	elif uses == 5: fator_total += 0.30 
	elif uses == 6: fator_total += 1.00 
	
	# Recuperação
	var rec = recovery_button.selected
	if not is_especial:
		if rec == 0: fator_total -= 0.20
		elif rec == 2: fator_total += 0.50
	else:
		if rec == 0: fator_total -= 0.25
		elif rec == 2: fator_total += 0.75
		
	# Custo final = Base * Fator Total
	return ceil(custo_base * fator_total)

func _on_tree_map_draw() -> void:
	for tree_info in loaded_trees_info:
		var t_data: TreeData = tree_info["data"]
		var prefix: String = tree_info["prefix"]
		
		for conn in t_data.connections:
			var from_node: PlayerNode = tree_map.get_node_or_null(NodePath(prefix + conn["from_node"]))
			var to_node: PlayerNode = tree_map.get_node_or_null(NodePath(prefix + conn["to_node"]))
			
			if from_node and to_node:
				# Como é de baixo para cima: 
				# A linha sai do TOPO do nó pai (from_node - andar mais baixo)...
				var start_pos = from_node.position + Vector2(from_node.size.x / 2.0, 0)
				# ...e vai até a BASE do nó filho (to_node - andar mais alto)
				var end_pos = to_node.position + Vector2(to_node.size.x / 2.0, to_node.size.y)
				
				tree_map.draw_line(start_pos, end_pos, Color.WHITE, 4.0)

func update_ui_panel() -> void:
	if crafted_skill.selected_nodes.is_empty():
		types_label.text = "Tipos: Nenhum"
		material_cost_label.text = "Materiais: Nenhum"
		status_label.text = "Selecione características na árvore."
		status_label.add_theme_color_override("font_color", Color.WHITE)
		finish_button.disabled = true
		return

	var type_strings: Array[String] = []
	var material_strings: Array[String] = [] # <--- Array para os materiais
	
	for type_int in crafted_skill.combined_types:
		type_strings.append(CharacteristicData.characteritstic_types.keys()[type_int])
		
	# Varre os nós selecionados pegando os materiais
	for node in crafted_skill.selected_nodes:
		if node.characteristic.material_cost != "":
			material_strings.append(node.characteristic.material_cost)
	
	types_label.text = "Tipos: " + " / ".join(type_strings)

	
	# Exibe os materiais, ou avisa se não tiver nenhum
	if material_strings.is_empty():
		material_cost_label.text = "Materiais: Nenhum"
	else:
		material_cost_label.text = "Materiais: " + ", ".join(material_strings)
	
	var rounded_total = snapped(crafted_skill.total_cost, 0.001)
	cost_factor_label.text = "Fator de Custo: " + str(rounded_total)
	
	var custo_final_calculado = calculate_final_cost()
	
	# Por enquanto, deixamos um espaço reservado:
	final_cost_label.text = "Custo Final de Mana/Energia: " + str(custo_final_calculado)
	
	# Valida o Tier PRIMEIRO
	crafted_skill.validate_desired_tier(int(tier_spin_box.value))
	
	# AGORA APLICAMOS AS REGRAS DO RPG (Só se o Tier base já estiver válido)
	if crafted_skill.is_valid:
		var tier_atual = int(tier_spin_box.value)
		var is_especial = (sync_type_button.selected == 1)
		
		# Regra 1: Velocidade Ofensiva
		if CharacteristicData.characteritstic_types.OFENSIVO in crafted_skill.combined_types:
			if speed_button.selected > 1: # Rápido ou Instantâneo
				crafted_skill.is_valid = false
				crafted_skill.error_message = "Erro: Habilidades Ofensivas não podem ser mais rápidas que Normal."
		
		# Regra 2: Limite de Efeitos
		var max_efeitos = 1
		if is_especial:
			var limits_esp = [2, 3, 5, 6, 8]
			max_efeitos = limits_esp[clamp(tier_atual - 1, 0, 4)]
		else:
			var limits_simp = [1, 2, 3, 4, 5]
			max_efeitos = limits_simp[clamp(tier_atual - 1, 0, 4)]
			
		if crafted_skill.selected_nodes.size() > max_efeitos:
			crafted_skill.is_valid = false
			crafted_skill.error_message = "Erro: Máximo de " + str(max_efeitos) + " efeitos excedido para este Tier."
			
		# Regra 3: Limite de Tamanho da Área
		if target_type_button.selected == 2: # Se for Área
			var shape = area_shape_button.selected
			var size = int(area_size_spin_box.value)
			var max_allowed = 0
			
			# Tabelas do Documento
			var max_circle = [2, 4, 6, 9, 11]
			var max_square = [3, 7, 11, 16, 18]
			var max_cone = [2, 6, 10, 16, 20]
			
			if shape == 0: max_allowed = max_circle[clamp(tier_atual - 1, 0, 4)]
			elif shape == 1: max_allowed = max_square[clamp(tier_atual - 1, 0, 4)]
			elif shape == 2: max_allowed = max_cone[clamp(tier_atual - 1, 0, 4)]
			
			if size > max_allowed:
				crafted_skill.is_valid = false
				crafted_skill.error_message = "Erro: Área excede o máximo do Tier " + str(tier_atual) + " (" + str(max_allowed) + "m)."

	# Atualiza o visual do Status depois de todas as checagens
	status_label.text = crafted_skill.error_message
	
	if crafted_skill.is_valid:
		status_label.add_theme_color_override("font_color", Color.GREEN)
		finish_button.disabled = false
	else:
		status_label.add_theme_color_override("font_color", Color.RED)
		finish_button.disabled = true

func _on_finish_button_pressed() -> void:
	# 1. Pega o nome da habilidade
	var skill_name = skill_name_edit.text.strip_edges()
	if skill_name == "":
		skill_name = "Habilidade Sem Nome"
		
	# 2. Calcula o custo final em Mana/Energia
	var final_cost = calculate_final_cost()
	
	# 3. Empacota todas as escolhas dos Dropdowns em um dicionário
	var extra_stats: Dictionary = {
		"defesa": defense_button.get_item_text(defense_button.selected),
		"sincronia": sync_type_button.get_item_text(sync_type_button.selected),
		"alvo": target_type_button.get_item_text(target_type_button.selected),
		"velocidade": speed_button.get_item_text(speed_button.selected),
		"alcance": range_button.get_item_text(range_button.selected),
		"duracao": duration_button.get_item_text(duration_button.selected),
		"usos": uses_button.get_item_text(uses_button.selected),
		"recuperacao": recovery_button.get_item_text(recovery_button.selected)
	}
	
	# Se for em área, adicionamos os detalhes da área no dicionário
	if target_type_button.selected == 2:
		extra_stats["area_shape"] = area_shape_button.get_item_text(area_shape_button.selected)
		extra_stats["area_size"] = str(area_size_spin_box.value) + "m"
	
	# 4. Envia TUDO para a ficha
	skill_sheet.build_sheet(skill_name, crafted_skill, int(tier_spin_box.value), final_cost, extra_stats)

func _on_defense_selected(_index: int) -> void:
	update_ui_panel()

func _on_tier_changed(_value: float) -> void:
	update_ui_panel()

func _on_any_dropdown_changed(_index: int) -> void:
	# 1. Regra da Recuperação
	if sync_type_button.selected == 0 and recovery_button.get_item_text(0) != "Por Descanso Longo (-20%)":
		_update_recovery_options(0)
	elif sync_type_button.selected == 1 and recovery_button.get_item_text(0) != "Por Sessão (-25%)":
		_update_recovery_options(1)
		
	# 2. Regra de Habilidades Simples não podem ser em Área
	var is_simples = (sync_type_button.selected == 0)
	target_type_button.set_item_disabled(2, is_simples) # Desabilita a opção "Área"
	
	if is_simples and target_type_button.selected == 2:
		target_type_button.selected = 0 # Força voltar para "Target" se estava em área
		
	# 3. Mostra/Esconde as opções de formato e tamanho
	var is_area = (target_type_button.selected == 2)
	area_shape_label.visible = is_area
	area_shape_button.visible = is_area
	area_size_label.visible = is_area
	area_size_spin_box.visible = is_area
		
	update_ui_panel()
