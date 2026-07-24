class_name CharacteristicNode extends GraphNode

var data: CharacteristicData = CharacteristicData.new()

@onready var name_edit: LineEdit = $NameEdit
@onready var description_edit: TextEdit = $DescriptionEdit
@onready var type_button: OptionButton = $TypeButton
@onready var material_edit: TextEdit = $MaterialEdit
@onready var cost_box: SpinBox = $CostBox
@onready var min_tier_box: SpinBox = $HBoxContainer/MinTierBox
@onready var max_tier_box: SpinBox = $HBoxContainer/MaxTierBox
@onready var floor_box: SpinBox = $FloorBox


func _ready() -> void:
	type_button.clear()
	for type_key in data.characteritstic_types.keys():
		type_button.add_item(type_key)
		
	update_ui()

func update_ui() -> void:
	title = data.name
	name_edit.text = data.name
	description_edit.text = data.description
	
	type_button.selected = data.type
	material_edit.text = data.material_cost
	cost_box.value = data.cost_multiplier
	
	min_tier_box.value = data.min_tier
	max_tier_box.value = data.max_tier
	floor_box.value = data.tree_floor
	

func _on_name_changed(new_text: String) -> void:
	data.name = new_text
	title = new_text

func _on_description_changed() -> void:
	data.description = description_edit.text

func _on_type_selected(index: int) -> void:
	data.type = index as CharacteristicData.characteritstic_types

func _on_material_cost_changed() -> void:
	data.material_cost = material_edit.text
	
func _on_cost_changed(value: float) -> void:
	data.cost_multiplier = float(value)

func _on_min_tier_changed(value: float) -> void:
	data.min_tier = int(value)
	min_tier_box.set_value_no_signal(data.min_tier)

func _on_max_tier_changed(value: float) -> void:
	data.max_tier = int(value)
	max_tier_box.set_value_no_signal(data.max_tier)

func _on_floor_changed(value: float) -> void:
	data.tree_floor = int(value)
