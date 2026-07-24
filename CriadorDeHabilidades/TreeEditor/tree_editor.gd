extends Control

@export var node_scene: PackedScene
@onready var graph_edit: GraphEdit = $GraphEdit
@onready var popup_menu: PopupMenu = $PopupMenu
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var name_edit: LineEdit = $MarginContainer/NameEdit

var click_position:Vector2 = Vector2.ZERO

func _ready() -> void:
	popup_menu.add_item("Add new node", 0)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Verifica se a tecla foi Delete ou Backspace
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			var selected_nodes: Array[StringName] = []
			
			# Varre a tela para ver quais nós estão selecionados pelo usuário
			for child in graph_edit.get_children():
				if child is CharacteristicNode and child.selected:
					selected_nodes.append(child.name)
			
			# Se tiver alguém selecionado, manda deletar e "consome" o input
			if not selected_nodes.is_empty():
				_on_delete_nodes_request(selected_nodes)
				get_viewport().set_input_as_handled()

func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	open_popup(at_position)

func _on_popup_menu_window_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		call_deferred("reopen_popup")

func _on_popup_menu_id_pressed(_id: int) -> void:
	create_new_node()
	
func open_popup(pos_local: Vector2) -> void:
	click_position = (pos_local + graph_edit.scroll_offset) / graph_edit.zoom
	popup_menu.position = get_viewport().get_mouse_position()
	popup_menu.popup()

func reopen_popup() -> void:
	var mouse_pos = graph_edit.get_local_mouse_position()
	open_popup(mouse_pos)

func create_new_node() -> void:
	var new_node:CharacteristicNode = node_scene.instantiate()
	
	new_node.name = "Node_" + str(Time.get_ticks_msec())
	
	new_node.title = "novo nodo"
	new_node.position_offset = click_position
	graph_edit.add_child(new_node)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func save_tree(file_path: String) -> void:
	var tree_data: TreeData = TreeData.new()
	
	for child in graph_edit.get_children():
		if child is CharacteristicNode:
			var node_data = NodeData.new()
			
			node_data.node_name = child.name
			node_data.position_offset = child.position_offset
			node_data.characteristic = child.data.duplicate()
			
			node_data.characteristic.resource_path = ""
			node_data.resource_path = ""
			tree_data.nodes.append(node_data)
	
	tree_data.connections = graph_edit.get_connection_list()
	tree_data.name = name_edit.text
	tree_data.take_over_path(file_path)
	
	
	var error := ResourceSaver.save(tree_data, file_path)
	
	if error == OK:
		print("Tree saved succesfully at: %s" % file_path)
	else:
		print("Error saving skill tree: %s" % error)

func load_tree(path: String) -> void:
	var tree_data: TreeData = ResourceLoader.load(path)
	if not tree_data:
		print("Error loading tree from: %s" % path)
		return
	
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is CharacteristicNode:
			graph_edit.remove_child(child)
			child.queue_free()
	
	for node_data in tree_data.nodes:
		var new_node: CharacteristicNode = node_scene.instantiate()
		
		new_node.name = node_data.node_name
		new_node.position_offset = node_data.position_offset
		
		if node_data.characteristic:
			new_node.data = node_data.characteristic.duplicate()
		
		
		graph_edit.add_child(new_node)
	
	for connection in tree_data.connections:
		graph_edit.connect_node(connection["from_node"], connection["from_port"], connection["to_node"], connection["to_port"])
	
	name_edit.text = tree_data.name
	
	
	print("Tree succesfully loaded from %s" % path)
	
func _on_save_button_pressed() -> void:
	save_file_dialog.popup_centered()
	
func _on_load_button_pressed() -> void:
	load_file_dialog.popup_centered()

func _on_save_file_selected(path: String) -> void:
	save_tree(path)

func _on_load_file_selected(path: String) -> void:
	load_tree(path)

func organize_tree_by_cost() -> void:
	var x_spacing: float = 400.0 # Horizontal (Andares)
	var y_spacing: float = 400 # Vertical (Distância entre os Nós)
	
	var floor_nodes: Dictionary = {}
	var connections = graph_edit.get_connection_list()
	
	for child in graph_edit.get_children():
		if child is CharacteristicNode:
			var floor_lvl: int = child.data.tree_floor
			if not floor_nodes.has(floor_lvl):
				floor_nodes[floor_lvl] = []
			floor_nodes[floor_lvl].append(child)
			
	var floors: Array = floor_nodes.keys()
	floors.sort()
	
	var node_y_positions: Dictionary = {}

	# --- MAPEAMENTO DE IRMÃOS NO EDITOR ---
	var parent_to_children: Dictionary = {}
	for conn in connections:
		var p_name = conn["from_node"]
		var c_name = conn["to_node"]
		if not parent_to_children.has(p_name):
			parent_to_children[p_name] = []

		var c_node = graph_edit.get_node_or_null(NodePath(c_name))
		if c_node and not parent_to_children[p_name].has(c_node):
			parent_to_children[p_name].append(c_node)

	for p_name in parent_to_children:
		parent_to_children[p_name].sort_custom(func(a, b): return a.position_offset.y < b.position_offset.y)
	# --------------------------------------------
	
	for floor_lvl in floors:
		var nodes_in_this_floor: Array = floor_nodes[floor_lvl]
		
		var ideal_ys = {}
		var roots = []
		var max_connected_y = -999999.0 # Rastreador da borda inferior

		for node in nodes_in_this_floor:
			var sum_y = 0.0
			var count = 0
			for conn in connections:
				if conn["to_node"] == node.name:
					var p_name = conn["from_node"]
					if node_y_positions.has(p_name):
						var p_y = node_y_positions[p_name]
						
						var siblings = parent_to_children.get(p_name, [])
						var c_idx = siblings.find(node)
						var sib_count = siblings.size()
						var offset = 0.0

						if sib_count > 1 and c_idx != -1:
							offset = (c_idx - (sib_count - 1) / 2.0) * y_spacing

						sum_y += (p_y + offset)
						count += 1
			if count > 0:
				var calc_y = sum_y / count
				ideal_ys[node] = calc_y
				if calc_y > max_connected_y: max_connected_y = calc_y
			else:
				roots.append(node)
				
		roots.sort_custom(func(a, b): return a.position_offset.y < b.position_offset.y)
		
		# --- JOGA OS NÓS SOLTOS PARA A BORDA ---
		if max_connected_y == -999999.0: max_connected_y = 0.0 
		
		var edge_y = max_connected_y + (y_spacing * 1.5)
		for i in range(roots.size()):
			ideal_ys[roots[i]] = edge_y
			edge_y += y_spacing * 1.5
		# ---------------------------------------------
			
		nodes_in_this_floor.sort_custom(func(a, b): return ideal_ys[a] < ideal_ys[b])
		
		var blocks: Array = []
		for node in nodes_in_this_floor:
			blocks.append({"nodes": [node], "y": ideal_ys[node]})
			
		var merged = true
		while merged:
			merged = false
			for i in range(blocks.size() - 1):
				var b1 = blocks[i]
				var b2 = blocks[i+1]
				var min_dist = (b1["nodes"].size() * y_spacing + b2["nodes"].size() * y_spacing) / 2.0
				if b2["y"] - b1["y"] < min_dist:
					var total_size = b1["nodes"].size() + b2["nodes"].size()
					var new_y = ((b1["y"] * b1["nodes"].size()) + (b2["y"] * b2["nodes"].size())) / float(total_size)
					blocks[i] = {"nodes": b1["nodes"] + b2["nodes"], "y": new_y}
					blocks.remove_at(i+1)
					merged = true
					break
					
		for block in blocks:
			var block_nodes = block["nodes"]
			var start_y = block["y"] - ((block_nodes.size() - 1) * y_spacing / 2.0)
			
			for i in range(block_nodes.size()):
				var node = block_nodes[i]
				var final_y = start_y + (i * y_spacing)
				node.position_offset = Vector2(floor_lvl * x_spacing, final_y)
				node_y_positions[node.name] = final_y
			
func _on_delete_nodes_request(nodes_to_delete: Array[StringName]) -> void:
	for node_name in nodes_to_delete:
		for connection in graph_edit.get_connection_list():
			if connection["from_node"] == node_name or connection["to_node"] == node_name:
				graph_edit.disconnect_node(connection["from_node"], connection["from_port"], connection["to_node"], connection["to_port"])
	
		var node = graph_edit.get_node_or_null(NodePath(node_name))
		if node:
			node.queue_free()
		else: push_error("deu merda, pai")
	
