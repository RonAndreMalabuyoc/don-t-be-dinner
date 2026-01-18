extends Resource
class_name SkillData

@export var id: String
@export var name: String
@export var description: String
@export var cost: int

# category is ONLY for UI grouping later
@export_enum("Survivability", "Mobility", "Offense", "Utility")
var category: String

# effect identifiers (used later)
@export var effect_type: String
@export var effect_value: float
