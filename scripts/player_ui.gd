extends CanvasLayer

signal health_changed(current_hp)
@export var heart_full: Texture2D
@export var heart_empty: Texture2D

@onready var hearts_container := $Hearts

var max_hp := 0

func set_max_health(hp: int):
	max_hp = hp
	clear_hearts()

	for i in hp:
		var heart = TextureRect.new()
		heart.texture = heart_full
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		hearts_container.add_child(heart)

func update_health(current_hp: int):
	for i in hearts_container.get_child_count():
		var heart = hearts_container.get_child(i) as TextureRect
		if i < current_hp:
			heart.texture = heart_full
		else:
			heart.texture = heart_empty

func clear_hearts():
	for c in hearts_container.get_children():
		c.queue_free()
