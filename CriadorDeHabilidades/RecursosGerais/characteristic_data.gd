class_name CharacteristicData extends Resource

enum characteritstic_types {OFENSIVO, SUPORTE, TATICO}
@export var type: characteritstic_types
@export var name: String
@export_multiline() var description: String
@export var material_cost: String
@export var cost_multiplier: float
@export_range(1, 5) var min_tier: int = 1:
	set(value):
		if value > max_tier:
			min_tier = max_tier
		else: min_tier = value
@export_range(1, 5) var max_tier: int = 5: 
	set(value):
		if value < min_tier:
			max_tier = min_tier
		else: max_tier = value
@export var tree_floor:int
