extends Control

# We changed the path to find "SettingsMenu" inside "MainUI"
@onready var menu = $CanvasLayer/MainUI/SettingsMenu

func _ready():
	# Hide the menu when the game starts
	menu.visible = false

# This function is for your "SettingsButton"
func _on_settings_button_pressed():
	get_tree().paused = true
	menu.visible = true

# This function is for the "PlayButton" inside the menu
func _on_play_button_pressed():
	get_tree().paused = false
	menu.visible = false

# This function is for the "ExitButton"
func _on_exit_button_pressed():
	get_tree().quit()

func _on_volume_slider_value_changed(value):
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	
func _input(event):
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is mapped to ESC by default
		_on_settings_button_pressed() # Triggers the same pause logic
