extends Node

# ───────── CONFIG ─────────
@export var starting_skill_points := 10

# ───────── STATE ─────────
var skill_points := 0
var unlocked_skills: Array[String] = []

var all_skills: Dictionary = {}

# skill flags
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
func has_skill(skill_id: String) -> bool:
	return skill_id in unlocked_skills

func unlock_skill(skill_id: String) -> bool:
	print("Trying to unlock:", skill_id)

	if not all_skills.has(skill_id):
		print("Skill not found:", skill_id)
		return false

	if has_skill(skill_id):
		print("Already unlocked:", skill_id)
		return false

	var skill = all_skills[skill_id]

	if skill_points < skill.cost:
		print("Not enough points")
		return false

	skill_points -= skill.cost
	unlocked_skills.append(skill_id)
	
	apply_skill_effect(skill_id)

	print("Unlocked:", skill_id)
	return true

func add_skill_points(amount: int):
	skill_points += amount
	print("Skill points:", skill_points)

# ───────── APPLY EFFECTS ─────────
func apply_skill_effect(skill_id: String) -> void:
	if not all_skills.has(skill_id):
		return

	var skill = all_skills[skill_id]

	match skill.id:

		"extra_heart":
			if Global.playerbody:
				Global.playerbody.max_health += 1
				Global.playerbody.current_health += 1
				print("Extra Heart applied! Max Health:", Global.playerbody.max_health)

		"post_wave_heal":
			if not post_wave_heal_active:
				post_wave_heal_active = true
				print("Post-Wave Heal activated")

		"dash_mastery":
			if not dash_mastery_active:
				dash_mastery_active = true
				print("Dash Mastery applied!")

		"swift_feet":
			if not swift_feet_active:
				swift_feet_active = true
				if Global.playerbody:
					Global.playerbody.apply_swift_feet()
				print("Swift Feet applied!")

		"double_jump":
			if not double_jump_active:
				double_jump_active = true
				if Global.playerbody:
					Global.playerbody.apply_double_jump()
				print("Double Jump applied!")

		"sharp_blows":
			if not sharp_blows_active:
				sharp_blows_active = true
				print("Sharp Blows applied!")

		"quick_recovery":
			if not quick_recovery_active:
				quick_recovery_active = true
				print("Quick Recovery applied!")
