extends Node2D

@onready var skills_container: Control = $"../Skills"

func _process(_delta):
	# Forces redraw if buttons move or screen resizes
	if visible:
		queue_redraw()

func _draw():
	if not skills_container.visible:
		return
		
	for skill in SkillManager.all_skills.values():
		# Get the child button
		var child_node = skills_container.get_node_or_null(skill.id)
		if not child_node: continue
			
		for prereq_id in skill.prerequisites:
			var parent_node = skills_container.get_node_or_null(prereq_id)
			if not parent_node: continue
			
			# CALCULATE POSITIONS USING GLOBAL COORDINATES
			# This fixes the "floating line" bug by ignoring local offsets
			
			# Parent Bottom-Center
			var start_global = parent_node.global_position + Vector2(parent_node.size.x / 2, parent_node.size.y)
			# Child Top-Center
			var end_global = child_node.global_position + Vector2(child_node.size.x / 2, 0)
			
			# Convert global back to local drawing space
			var start_pos = to_local(start_global)
			var end_pos = to_local(end_global)
			
			# Color Logic
			var color = Color.GRAY
			var width = 2.0
			
			if SkillManager.has_skill(skill.id) and SkillManager.has_skill(prereq_id):
				color = Color.GOLD
				width = 4.0
			elif SkillManager.has_skill(prereq_id):
				color = Color.WHITE
				
			draw_line(start_pos, end_pos, color, width, true)
