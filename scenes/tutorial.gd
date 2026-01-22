extends CanvasLayer

# This 'onready' variable creates a shortcut to the child node that CAN fade
@onready var content_box = $Content 

func _ready():
	# We check the content_box, not the CanvasLayer itself
	content_box.modulate.a = 1.0
	get_tree().create_timer(5.0).timeout.connect(_fade_out)

func _input(event):
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("shoot"):
		_fade_out()

func _fade_out():
	var tween = create_tween()
	# FADE the content_box, then DELETE the whole CanvasLayer
	tween.tween_property(content_box, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
