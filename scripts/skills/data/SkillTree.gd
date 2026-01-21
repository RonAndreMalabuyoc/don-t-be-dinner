extends Control

@onready var toggle_button := $ToggleButton
@onready var skills_node: Control = $SkillArea/Skills 
@onready var connections: Node2D = $SkillArea/SkillConnections

const NODE_W := 160
const NODE_H := 48
const GAP_X := 20   # Horizontal space between neighbor branches
const GAP_Y := 100  # Vertical space between tiers

var is_open := false

func _ready():
	skills_node.visible = false
	connections.visible = false
	
	# --- FIX START: PREVENT SPACEBAR FROM TOGGLING THE BUTTON ---
	toggle_button.focus_mode = Control.FOCUS_NONE
	# --- FIX END ---
	
	toggle_button.toggled.connect(_on_toggle_toggled)
	
	# Wait one frame to ensure SkillManager is ready
	await get_tree().process_frame 
	_update_ui()

func _on_toggle_toggled(button_pressed: bool):
	is_open = button_pressed
	skills_node.visible = is_open
	connections.visible = is_open
	if is_open:
		connections.queue_redraw()

func _update_ui():
	# 1. Clear old buttons
	for c in skills_node.get_children():
		c.queue_free()

	# 2. Build Hierarchy
	var children_map = _build_tree_hierarchy()
	var positions = {}

	# 3. Find Roots (Skills with no parents)
	var roots = []
	for skill in SkillManager.all_skills.values():
		if skill.prerequisites.is_empty():
			roots.append(skill.id)

	# 4. Calculate Positions
	var current_x = 0.0
	for root_id in roots:
		var tree_width = _calculate_node_position(root_id, children_map, 0, current_x, positions)
		current_x += tree_width + GAP_X

	# 5. Center on Screen
	var total_width = current_x - GAP_X
	var start_offset_x = (size.x - total_width) / 2
	
	# 6. Create Buttons
	for skill_id in positions:
		var skill = SkillManager.all_skills[skill_id]

		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.name = skill_id
		btn.text = "%s\n%d pts" % [skill.name, skill.cost]
		btn.size = Vector2(NODE_W, NODE_H)
		btn.position = positions[skill_id] + Vector2(start_offset_x, 50)

		btn.pressed.connect(_on_skill_pressed.bind(skill_id))

		# Color logic
		if SkillManager.has_skill(skill_id):
			btn.modulate = Color.GREEN
		elif SkillManager.can_unlock(skill_id):
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)

		skills_node.add_child(btn)


func _build_tree_hierarchy() -> Dictionary:
	var children = {}
	for skill_id in SkillManager.all_skills.keys():
		children[skill_id] = []
	for skill in SkillManager.all_skills.values():
		for prereq in skill.prerequisites:
			if children.has(prereq):
				children[prereq].append(skill.id)
	return children

func _calculate_node_position(skill_id: String, children_map: Dictionary, depth: int, start_x: float, result_positions: Dictionary) -> float:
	var my_children = children_map.get(skill_id, [])
	
	if my_children.is_empty():
		result_positions[skill_id] = Vector2(start_x, depth * GAP_Y)
		return NODE_W

	var total_w = 0.0
	var cursor_x = start_x
	var first_center = 0.0
	var last_center = 0.0

	for i in range(my_children.size()):
		var child_id = my_children[i]
		var w = _calculate_node_position(child_id, children_map, depth + 1, cursor_x, result_positions)
		
		if i == 0: first_center = result_positions[child_id].x
		if i == my_children.size() - 1: last_center = result_positions[child_id].x
		
		cursor_x += w + GAP_X
		total_w += w + GAP_X

	total_w -= GAP_X
	var my_x = (first_center + last_center) / 2.0
	result_positions[skill_id] = Vector2(my_x, depth * GAP_Y)
	
	return max(total_w, NODE_W)
	
func _on_skill_pressed(skill_id: String) -> void:
	# Already unlocked
	if SkillManager.has_skill(skill_id):
		return
	
	# Can't unlock yet
	if not SkillManager.can_unlock(skill_id):
		return
	
	# Unlock in SkillManager
	SkillManager.unlock_skill(skill_id)
	
	# APPLY EFFECTS IMMEDIATELY
	if skill_id == "health_boost":
		if Global.playerbody:
			Global.playerbody.update_max_health()
	
	_update_ui()
