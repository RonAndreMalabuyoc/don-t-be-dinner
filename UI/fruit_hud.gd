extends CanvasLayer

@onready var slot0_icon := get_node_or_null("Panel/Slots/Slot0/Icon") as TextureRect
@onready var slot0_status := get_node_or_null("Panel/Slots/Slot0/Status") as Label
@onready var slot1_icon := get_node_or_null("Panel/Slots/Slot1/Icon") as TextureRect
@onready var slot1_status := get_node_or_null("Panel/Slots/Slot1/Status") as Label

@export var icon_map := {
	"pomegranate": preload("res://assets/Fruit_Icons/pomegranate.png"),
	"orange": preload("res://assets/Fruit_Icons/orange.png"),
	"banana": preload("res://assets/Fruit_Icons/banana.png"),
	"coconut": preload("res://assets/Fruit_Icons/coconut.png"),
}

func _ready() -> void:
	print("FruitHUD READY path:", get_path())
	print("slot0_icon:", slot0_icon)
	print("slot0_status:", slot0_status)
	print("slot1_icon:", slot1_icon)
	print("slot1_status:", slot1_status)

	if slot0_icon == null or slot0_status == null or slot1_icon == null or slot1_status == null:
		print("FruitHUD ERROR: One or more UI nodes not found. Check node names/paths.")
		print("Children of FruitHUD:")
		for c in get_children():
			print(" - ", c.name)

func update_fruit_ui(fruit_slots: Array, active_slot: int) -> void:
	_update_slot(0, slot0_icon, slot0_status, fruit_slots, active_slot)
	_update_slot(1, slot1_icon, slot1_status, fruit_slots, active_slot)

func _update_slot(index: int, icon: TextureRect, status: Label, fruit_slots: Array, active_slot: int) -> void:
	# Hard guard so you never crash again
	if icon == null or status == null:
		return

	if index >= fruit_slots.size():
		icon.texture = null
		icon.modulate.a = 0.25
		status.text = "EMPTY"
		return

	var id := str(fruit_slots[index].get("id", "")).strip_edges().to_lower()
	icon.texture = icon_map.get(id, null)

	var is_equipped := (index == active_slot)
	icon.modulate.a = 1.0 if is_equipped else 0.6
	status.text = "EQUIPPED" if is_equipped else "RESERVE"
