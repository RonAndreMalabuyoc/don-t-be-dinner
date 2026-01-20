extends Camera2D

func _ready():
	limit_left = -254
	limit_right = 2321
	limit_top = -773


	# Soft stop polish (recommended)
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
