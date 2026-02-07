extends Area2D
class_name Square

var coord: Vector2i
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var overlay: Sprite2D = $Overlay

func setup(x: int, y: int, size: int) -> void:
	coord = Vector2i(x, y)
	overlay.visible = false
	# sprite
	sprite.texture = preload("res://assets/white_pixel.png")
	sprite.centered = false
	sprite.scale = Vector2(size, size)
	overlay.scale = Vector2(size/30, size/30)

	# collision
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision.shape = shape
	collision.position = Vector2(size/2,size/2)
	overlay.position = Vector2(size/2,size/2)

func set_color(color: Color) -> void:
	sprite.modulate = color

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		get_parent().on_square_pressed(coord)
		
func show_overlay(Color) -> void:
	overlay.modulate = Color 
	overlay.visible = true

func hide_overlay() -> void:
	overlay.visible = false
