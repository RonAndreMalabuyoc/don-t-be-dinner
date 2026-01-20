extends Control

@onready var skill_grid := $SkillGrid
@onready var toggle_button := $ToggleButton
@onready var connections = $SkillConnections
@export var skill_button_scene: PackedScene

var is_open := false
var connection_lines: Array = []


func _ready():
	visible = true
	skill_grid.visible = false
	connections.visible = false
	
	await get_tree().process_frame
	_update_ui()
	toggle_button.pressed.connect(func():
		is_open = !is_open
		_set_tree_visibility(is_open)
)


	# Start CLOSED visually, but keep toggle visible
	is_open = false


	print("SkillTree ready")
	print("skill_grid:", skill_grid)
	print("toggle_button:", toggle_button)
	_set_tree_visibility(false)

		
func _on_toggle_toggled(button_pressed: bool):
	print("TOGGLE CLICKED:", button_pressed)
	is_open = button_pressed
	print("Toggle toggled:", is_open)
	_set_tree_visibility(is_open)

func _set_tree_visibility(open: bool):
	skill_grid.visible = open
	connections.visible = open
	
func _update_ui():
	print("SKILLS FOUND:", SkillManager.all_skills.keys())
	# Clear previous buttons
	
	for child in skill_grid.get_children():
		child.queue_free()

	for skill_id in SkillManager.all_skills.keys():
		print("Adding button for", skill_id)  # <-- debug
		var btn = Button.new()
		btn.text = skill_id
		skill_grid.add_child(btn)
		var skill = SkillManager.all_skills[skill_id]

		btn.name = skill_id
		btn.text = skill.name
		btn.disabled = not SkillManager.can_unlock(skill_id)
		btn.tooltip_text = skill.description

		btn.pressed.connect(func(id=skill_id):
			if SkillManager.unlock_skill(id):
				_update_ui()
			$SkillConnections.update_lines()
		)


	# Update overlay lines
	$SkillConnections.update_lines()
	

	# Update lines after creating buttons
	if connections:
		
		connections.update_lines()
