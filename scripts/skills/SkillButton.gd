extends Control
class_name SkillButton

@export var skill_id: String
@onready var button := $Button

func _ready():
	button.pressed.connect(_on_pressed)
	_update_state()

func _on_pressed():
	print("Trying to unlock:", skill_id)

	if SkillManager.unlock_skill(skill_id):
		print("Unlocked:", skill_id)
		SkillManager.apply_skill_effect(skill_id)
		_update_state()

func _update_state():
	if SkillManager.has_skill(skill_id):
		button.disabled = true
