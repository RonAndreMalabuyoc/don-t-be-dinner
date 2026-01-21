extends HBoxContainer

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

const HP_PER_HEART := 10

func _ready():
	await get_tree().process_frame
	if Global.playerbody:
		Global.playerbody.health_changed.connect(update_hearts)
		update_hearts(Global.playerbody.current_health, Global.playerbody.max_health)

func update_hearts(current_hp: int, max_hp: int):
	var total_hearts_count = int(max_hp / HP_PER_HEART)
	var full_hearts_count = int(current_hp / HP_PER_HEART)

	
	
	
	# 2. Clear old icons
	for child in get_children():
		child.queue_free()
	
	# 3. Draw Hearts
	for i in range(total_hearts_count):
		var icon = TextureRect.new()
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# If index is less than the number of full hearts we have, draw Full.
		# Example: 20 HP / 10 = 2 Full Hearts.
		# i=0 (Full), i=1 (Full), i=2 (Empty).
		if i < full_hearts_count:
			icon.texture = heart_full
		else:
			icon.texture = heart_empty
			
		add_child(icon)
