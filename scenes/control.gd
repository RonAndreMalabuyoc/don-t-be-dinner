extends CanvasLayer

@onready var content = $Content # The node containing your text/buttons

func _ready():
	# Start visible
	content.modulate.a = 1.0
	
	# Auto-hide after 5 seconds if no input
	get_tree().create_timer(5.0).timeout.connect(_fade_out)

func _input(event):
	# If player starts moving or shooting, hide the instructions
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("shoot"):
		_fade_out()

func _fade_out():
	# Check if we are already fading to avoid errors
	var tween = create_tween()
	tween.tween_property(content, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free) # Deletes the whole TutorialUI when done
