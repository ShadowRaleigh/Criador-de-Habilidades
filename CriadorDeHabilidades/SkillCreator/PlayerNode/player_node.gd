class_name PlayerNode extends PanelContainer

signal node_clicked(node: PlayerNode)

var node_data: NodeData
var is_selected: bool = false

@onready var button: Button = $Button
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var material_cost_label: Label = $VBoxContainer/MaterialCostLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var min_tier_label: Label = $VBoxContainer/HBoxContainer/MinTierLabel
@onready var max_tier_label: Label = $VBoxContainer/HBoxContainer/MaxTierLabel

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func setup(data: NodeData) -> void:
	node_data = data
	var char_data = data.characteristic # Atalho para facilitar a leitura
	
	name_label.text = char_data.name
	
	# Esconde a descrição se estiver vazia, ou preenche se tiver texto
	if char_data.description == "":
		description_label.hide()
	else:
		description_label.text = char_data.description
		description_label.show()
	
	var type_str = CharacteristicData.characteritstic_types.keys()[char_data.type]
	type_label.text = "Tipo: " + type_str
	
	# Mesma lógica para o custo material
	if char_data.material_cost == "":
		material_cost_label.hide()
	else:
		material_cost_label.text = "Material: " + char_data.material_cost
		material_cost_label.show()
	
	# Usa o snapped para forçar 3 casas decimais no máximo
	var rounded_cost = snapped(char_data.cost_multiplier, 0.001)
	
	cost_label.text = "Fator de Custo: " + str(rounded_cost)
	min_tier_label.text = "Min Tier: " + str(char_data.min_tier)
	max_tier_label.text = "Max Tier: " + str(char_data.max_tier)

func _on_button_pressed() -> void:
	node_clicked.emit(self)

func set_selection_visual(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		modulate = Color(0.5, 1.5, 0.5) 
	else:
		modulate = Color(1.0, 1.0, 1.0)
