extends Area2D

@export var damage := 9999
@export var lifetime := 0.25

func _ready() -> void:
	# Wait one frame so overlaps are updated, then apply damage
	await get_tree().process_frame

	for b in get_overlapping_bodies():
		if not b.is_in_group("Enemy"):
			continue

		if b.has_method("take_damage"):
			b.call("take_damage", damage)
		elif "health" in b:
			b.health -= damage

	await get_tree().create_timer(lifetime).timeout
	queue_free()
