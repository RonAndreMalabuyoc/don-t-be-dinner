extends Resource

@export var id: String
@export var name: String
@export var description: String
@export var cost: int

@export_enum("Survivability", "Mobility", "Offense", "Utility")
var category: String

# NEW: skill dependencies
@export var prerequisites: Array[String] = []

# effect identifiers
@export var effect_type: String
@export var effect_value: float
