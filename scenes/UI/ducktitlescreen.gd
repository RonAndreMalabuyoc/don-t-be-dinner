extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

# Bounce pattern for each frame (like a ball)
var bounce_pattern = [0, 15, 30, 45, 30, 15]  # Height for each frame
var base_y = 300
var x_increment = 20

func _ready():
	animated_sprite.play("default")
	position = Vector2(100, base_y)

func _physics_process(_delta):  # Uses physics frame rate (smoother)
	# Update position based on current frame
	var frame = animated_sprite.frame
	
	# Move horizontally and bounce vertically
	position.x = 100 + (frame * x_increment)
	position.y = base_y - bounce_pattern[frame]
