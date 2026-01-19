extends Node2D

@onready var anim := get_node_or_null("Anim") as AnimatedSprite2D

func _ready() -> void:
	if anim == null:
		push_error("BananaExplosion: Missing AnimatedSprite2D child named 'Anim'")
		queue_free()
		return

	anim.play("explode")
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	queue_free()
