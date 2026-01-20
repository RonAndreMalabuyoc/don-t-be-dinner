extends Node2D
var connection_lines: Array = []
@onready var skill_grid := $"../SkillGrid"

func _draw():
	for c in connection_lines:
		draw_line(c.from, c.to, Color.WHITE, 2.0)
		
func update_lines():
	
	# Remove old lines
	for child in get_children():
		child.queue_free()

	for skill_id in SkillManager.all_skills.keys():
		var skill = SkillManager.all_skills[skill_id]

		for prereq_id in skill.prerequisites:
			var prereq_btn = skill_grid.get_node(prereq_id)
			var skill_btn = skill_grid.get_node(skill_id)

			if prereq_btn and skill_btn:
				var line = Line2D.new()
				line.width = 3

				# Color by branch
				if skill.category == "Mobility":
					line.default_color = Color(0,0.7,1)
				elif skill.category == "Offense":
					line.default_color = Color(1,0,0)
				elif skill.category == "Survivability":
					line.default_color = Color(0,1,0)
				else:
					line.default_color = Color(1,1,1)


				# Positions relative to overlay
				var start_pos = prereq_btn.global_position - global_position
				var end_pos   = skill_btn.global_position - global_position

				# Optional elbow curve
				var mid = Vector2(start_pos.x, end_pos.y)
				line.points = [start_pos, mid, end_pos]

				add_child(line)
