extends CanvasLayer

# Link to the Panel (the thing that moves)
@onready var panel = $WaveLabel 
# Link to the Label inside the Panel (the thing with text)
@onready var label = $WaveLabel/TextLabel 

func show_wave(wave_num: int):
	# 1. Update the text on the CHILD label
	label.text = "WAVE " + str(wave_num)
	
	# 2. Reset position of the PARENT panel
	panel.position.y = -150 
	
	# 3. Animate the PARENT panel
	var tween = create_tween()
	
	# Slide down
	tween.tween_property(panel, "position:y", 50.0, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	tween.tween_interval(2.0)
	
	# Slide up
	tween.tween_property(panel, "position:y", -150.0, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await tween.finished
