extends Control
@onready var bg_music = $bg_music

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bg_music.play()  # play background music


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

	
func _on_quit_pressed() -> void:
	var sfx = $Button_manager/Quit/SFX_button2
	sfx.play()  # play the quit sound effect
	
	await sfx.finished
	
	get_tree().quit()   # exits the game


func _on_play_pressed() -> void:
	var sfx = $Button_manager/Play/SFX_button
	sfx.play()
	get_tree().change_scene_to_file("res://scenes/MAIN.tscn")
