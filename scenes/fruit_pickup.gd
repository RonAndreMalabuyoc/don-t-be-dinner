extends Area2D
class_name FruitPickup

enum FruitType { POMEGRANATE, ORANGE, BANANA, COCONUT }

@export var fruit_type: FruitType = FruitType.POMEGRANATE
@export var pickup_radius: float = 18.0

# Optional: assign a texture per fruit from the editor
@export var icon: Texture2D

signal picked_up(fruit_type: FruitType)

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Apply icon if provided
	if icon != null:
		sprite.texture = icon

	# Ensure collision radius matches export
	var circle := CircleShape2D.new()
	circle.radius = pickup_radius
	shape.shape = circle

	monitoring = true
	monitorable = true

func _on_body_entered(body: Node) -> void:
	# Most reliable: compare to your Global.playerbody (your project already uses this pattern)
	if Global.playerbody != null and body == Global.playerbody:
		emit_signal("picked_up", fruit_type)

		# No powerup yet: just remove the fruit
		queue_free()
