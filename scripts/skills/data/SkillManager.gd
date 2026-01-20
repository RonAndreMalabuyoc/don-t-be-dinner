extends Node

# ───────── CONFIG ─────────
@export var starting_skill_points := 10

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

# ───────── READY ─────────
func _ready():
	skill_points = starting_skill_points
	_load_skills()

# ───────── LOAD SKILLS ─────────
func _load_skills():
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
		var skill = load(path)
		if skill:
			all_skills[skill.id] = skill
			print("Loaded skill:", skill.id)
		else:
			push_error("FAILED TO LOAD: " + path)

	print("ALL SKILLS LOADED:", all_skills.keys())

# ───────── SKILL LOGIC ─────────
func can_unlock(skill_id: String) -> bool:
	if not all_skills.has(skill_id):
		return false

	if has_skill(skill_id):
		return false

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

func unlock_skill(skill_id: String) -> bool:
	if not all_skills.has(skill_id):
		print("Skill not found:", skill_id)
		return false

	if has_skill(skill_id):
		print("Already unlocked:", skill_id)
		return false

	var skill = all_skills[skill_id]

	if skill_points < skill.cost:
		print("Not enough skill points")
		return false

	skill_points -= skill.cost
	unlocked_skills.append(skill_id)

	apply_skill_effect(skill_id)

	print("Unlocked skill:", skill_id)
	return true

func add_skill_points(amount: int):
	skill_points += amount
	print("Skill points:", skill_points)

# ───────── APPLY EXISTING SKILLS (PLAYER SPAWN) ─────────
func apply_existing_skills_to_player():
	for skill_id in unlocked_skills:
		apply_skill_effect(skill_id)

# ───────── APPLY SKILL EFFECTS ─────────
# In skillmanager.gd

func apply_skill_effect(skill_id: String) -> void:
	if not all_skills.has(skill_id):
		return

	match skill_id:
		"extra_heart":
			if Global.playerbody:
				Global.playerbody.max_health += 1
				Global.playerbody.current_health += 1

		"post_wave_heal":
			post_wave_heal_active = true

		"dash_mastery":
			dash_mastery_active = true
			if Global.playerbody:
				Global.playerbody.apply_dash_mastery() # ADDED THIS

		"swift_feet":
			swift_feet_active = true
			if Global.playerbody:
				Global.playerbody.apply_swift_feet()

		"double_jump":
			double_jump_active = true
			if Global.playerbody:
				Global.playerbody.apply_double_jump()

		"sharp_blows":
			sharp_blows_active = true
			if Global.playerbody:
				Global.playerbody.apply_sharp_blows() # ADDED THIS

		"quick_recovery":
			quick_recovery_active = true
			if Global.playerbody:
				Global.playerbody.apply_quick_recovery() # ADDED THIS
