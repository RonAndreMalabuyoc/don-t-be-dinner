extends CanvasLayer

@onready var panel = $WaveLabel
@onready var label = $WaveLabel/TextLabel  # <--- Make sure this matches your new node name!

func show_wave(wave_num: int):
	# This line puts the ACTUAL wave number into the text
	label.text = "WAVE " + str(wave_num)
	
	# Reset position off-screen
	panel.position.y = -150
	
	# Animation
	var tween = create_tween()
	tween.tween_property(panel, "position:y", 50.0, 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(2.0)
	tween.tween_property(panel, "position:y", -150.0, 0.5).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
