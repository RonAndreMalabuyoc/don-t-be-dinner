extends Node

# ───────── CONFIG ─────────
@export var starting_skill_points := 20

# ───────── STATE ─────────
var skill_points := 0
var unlocked_skills: Array[String] = []
var all_skills: Dictionary = {}

# ───────── SKILL FLAGS ─────────
var dash_mastery_active := false
var swift_feet_active := false
var double_jump_active := false
var sharp_blows_active := false
var quick_recovery_active := false
var post_wave_heal_active := false
var health_boost_active := false  # Max HP +1 (3 -> 4)
var wave_recovery_active := false # Heal +1 Heart per wave

# ───────── READY ─────────
func _ready():
	skill_points = starting_skill_points
	_load_skills()

# ───────── LOAD SKILLS ─────────
func _load_skills():
	# Make sure these paths are correct!
	var skill_files = [
		"res://scripts/skills/data/extra_heart.tres",
		"res://scripts/skills/data/post_wave_heal.tres",
		"res://scripts/skills/data/dash_mastery.tres",
		"res://scripts/skills/data/swift_feet.tres",
		"res://scripts/skills/data/double_jump.tres",
		"res://scripts/skills/data/sharp_blows.tres",
		"res://scripts/skills/data/quick_recovery.tres"
	]

	for path in skill_files:
		if ResourceLoader.exists(path):
			var skill = load(path)
			if skill and "id" in skill:
				all_skills[skill.id] = skill
				print("Loaded skill:", skill.id)
		else:
			print("ERROR: File not found -> ", path)

	print("ALL SKILLS LOADED:", all_skills.keys())

# ───────── SKILL CHECK LOGIC ─────────
func can_unlock(skill_id: String) -> bool:
	if not all_skills.has(skill_id): return false
	if has_skill(skill_id): return false

	var skill = all_skills[skill_id]

	# Check prerequisites
	for prereq in skill.prerequisites:
		if not has_skill(prereq):
			return false

	# Check cost
	if skill_points < skill.cost:
		return false

	return true

func has_skill(skill_id: String) -> bool:
	return skill_id in unlocked_skills

# ───────── UNLOCK LOGIC (FIXED) ─────────
func unlock_skill(skill_id: String) -> bool:
	# 1. Check if Skill Exists
	if not all_skills.has(skill_id):
		print("Skill ID not found:", skill_id)
		return false

	# 2. Check if Already Unlocked
	if has_skill(skill_id):
		print("Already unlocked:", skill_id)
		return false

	var skill = all_skills[skill_id]

	# 3. Check Prerequisites (THIS WAS MISSING)
	for prereq in skill.prerequisites:
		if not has_skill(prereq):
			print("Locked! You need prerequisite:", prereq)
			return false

	# 4. Check Cost
	if skill_points < skill.cost:
		print("Not enough points! Have:", skill_points, " Need:", skill.cost)
		return false

	# 5. Success: Deduct Points & Save
	skill_points -= skill.cost
	unlocked_skills.append(skill_id)
	
	print("Unlocked:", skill_id, " | Remaining Points:", skill_points)

	# 6. Apply Effect
	apply_skill_effect(skill_id)
	return true

func add_skill_points(amount: int):
	skill_points += amount

# ───────── APPLY EXISTING SKILLS (ON SPAWN) ─────────
func apply_existing_skills_to_player():
	for skill_id in unlocked_skills:
		apply_skill_effect(skill_id)

# ───────── APPLY EFFECTS (THE IMPORTANT PART) ─────────
func apply_skill_effect(skill_id: String) -> void:
	print("Applying Effect for: ", skill_id)
	
	match skill_id:
		"extra_heart":
			health_boost_active = true
			if Global.playerbody:
				Global.playerbody.update_max_health()
				
		"post_wave_heal":
			wave_recovery_active = true
			print("Wave Recovery Active")

		"dash_mastery":
			dash_mastery_active = true
			if Global.playerbody: Global.playerbody.apply_dash_mastery()

		"swift_feet":
			swift_feet_active = true
			if Global.playerbody: Global.playerbody.apply_swift_feet()

		"double_jump":
			double_jump_active = true
			if Global.playerbody: Global.playerbody.apply_double_jump()

		"sharp_blows":
			sharp_blows_active = true
			if Global.playerbody: Global.playerbody.apply_sharp_blows()

		"quick_recovery":
			quick_recovery_active = true
			if Global.playerbody: Global.playerbody.apply_quick_recovery()
