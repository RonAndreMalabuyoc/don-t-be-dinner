extends Control

@onready var skill_list := $SkillList
@onready var toggle_button := $"../ToggleButton" # adjust path if different
@export var skill_button_scene: PackedScene # assign your SkillButton scene

var is_open := true

func _ready():
	toggle_button.pressed.connect(_on_toggle_pressed)
	_update_ui()

func _on_toggle_pressed():
	is_open = !is_open
	# Collapse/expand the panel
	visible = is_open

func _update_ui():
	# Clear previous buttons
	for child in skill_list.get_children():
		child.queue_free()

	for skill_id in SkillManager.all_skills.keys():
		var skill = SkillManager.all_skills[skill_id]
		var btn = skill_button_scene.instantiate() as Button
		var status = "Unlocked" if SkillManager.has_skill(skill_id) else "Locked"
		btn.text = "%s | Cost: %d | %s" % [skill.name, skill.cost, status]
		btn.pressed.connect(func(id=skill_id):
			_try_unlock_skill(id)
		)
		skill_list.add_child(btn)

func _try_unlock_skill(skill_id: String):
	print("Trying to unlock:", skill_id)
	if SkillManager.unlock_skill(skill_id):
		_update_ui() # refresh the UI
	else:
		print("Cannot unlock skill:", skill_id)
		
	if SkillManager.unlock_skill(skill_id):
		_update_ui()
		
	if skill_id == "swift_feet" and Global.playerbody:
		Global.playerbody.apply_swift_feet()
		
	if skill_id == "double_jump" and Global.playerbody:
		Global.playerbody.apply_double_jump()
	
	if skill_id == "sharp_blows" and Global.playerbody:
		Global.playerbody.apply_sharp_blows()
	
	if skill_id == "quick_recovery" and Global.playerbody:
		Global.playerbody.apply_quick_recovery()
	
	else:
		print("Cannot unlock skill:", skill_id)
