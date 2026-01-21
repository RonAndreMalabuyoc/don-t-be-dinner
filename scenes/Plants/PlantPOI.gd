extends StaticBody2D

func take_damage(amount: float):
	Global.take_damage(amount)
	# Visual feedback
	var tw = create_tween()
	tw.tween_property($Sprite2D, "modulate", Color.RED, 0.1)
	tw.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
