extends CanvasLayer

@onready var restart_btn = $LayoutRoot/ColorRect/VBoxContainer/Restart 
@onready var quit_btn = $LayoutRoot/ColorRect/VBoxContainer/Quit

func _ready():
	# Safety check: ensure the node exists before trying to use it
	if restart_btn:
		restart_btn.grab_focus()
	else:
		# This will print to the console instead of crashing the game
		print("ERROR: Could not find a node named 'Restart' inside VBoxContainer")
	
	if quit_btn:
		quit_btn.grab_focus()
	else:
		# This will print to the console instead of crashing the game
		print("ERROR: Could not find a node named 'Quit' inside VBoxContainer")

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free() # This removes the death screen from the Root

func _on_quit_pressed():
	print("Quitting...")
	get_tree().quit()
