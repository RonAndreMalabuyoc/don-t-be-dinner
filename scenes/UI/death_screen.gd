extends CanvasLayer

@onready var restart_btn = $LayoutRoot/ColorRect/VBoxContainer/Restart 
@onready var quit_btn = $LayoutRoot/ColorRect/VBoxContainer/Quit

@onready var time_label = %TimeLabel
@onready var kills_label = %KillsLabel
@onready var wave_label = %WaveLabel

func _ready():
	var minutes = floor(Global.run_time / 60)
	var seconds = int(Global.run_time) % 60
	var time_text = "%02d:%02d" % [minutes, seconds]
	
	# 2. Update the Text
	time_label.text = "Time Alive: " + time_text
	kills_label.text = "Enemies Cooked: " + str(Global.enemies_defeated)
	
	# Assuming you track waves in Global, otherwise remove this line
	wave_label.text = "Wave Reached: " + str(Global.waves_survived)
	
	# 3. Optional: Hide the mouse so it's not annoying, or Show it if you need to click
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
