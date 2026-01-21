extends Node

func _ready():
	Global.node_creation_parent = self
	
func _exit_tree():
	Global.node_creation_parent = null
	


func _on_pause_pressed() -> void:
	get_tree().paused = true 


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_exitbutton_pressed() -> void:
	var sfx = $ButtonManager/exit_button/SFX_button3
	sfx.play()  # play the quit sound effect
	
	await sfx.finished
	get_tree().quit()
