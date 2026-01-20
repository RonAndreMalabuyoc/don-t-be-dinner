extends Area2D

@export var speed: float = 1200.0
@export var blast_radius: float = 260.0

@export var explosion_scene: PackedScene = preload("res://scenes/Bullets/BananaExplosion.tscn")

var direction: Vector2 = Vector2.RIGHT
var _exploded := false

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	print("BANANA body hit:", body.name)
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	print("BANANA area hit:", area.name)
	_hit(area)


func _hit(hit: Node) -> void:
	if _exploded:
		return

	var enemy := _resolve_enemy(hit)
	if enemy == null:
		return

	_exploded = true

	# 1) Spawn explosion animation at impact point
	_spawn_explosion_fx()

	# 2) Do your AoE kill logic
	_explode_kill_aoe()

	# 3) Remove the banana projectile
	queue_free()

func _spawn_explosion_fx() -> void:
	if explosion_scene == null:
		return

	var fx: Node2D = explosion_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position

func _resolve_enemy(n: Node) -> Node:
	if n.is_in_group("Enemy"):
		return n

	var p := n.get_parent()
	var steps := 0
	while p != null and steps < 6:
		if p.is_in_group("Enemy"):
			return p
		p = p.get_parent()
		steps += 1

	return null

func _explode_kill_aoe() -> void:
	for e in get_tree().get_nodes_in_group("Enemy"):
		if not (e is Node2D):
			continue

		var e2d := e as Node2D
		var d: float = (e2d.global_position - global_position).length()

		if d <= blast_radius:
			_kill_enemy(e)

func _kill_enemy(enemy: Node) -> void:
	if enemy.has_method("die"):
		enemy.call("die")
	elif enemy.has_method("take_damage"):
		enemy.call("take_damage", 999999)
	else:
		enemy.queue_free()
