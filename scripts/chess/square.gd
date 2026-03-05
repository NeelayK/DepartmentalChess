extends Area2D
class_name Square

var coord: Vector2i

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var overlay: Sprite2D = $Overlay

## Shared retro overlay material
func setup(x: int, y: int, size: int) -> void:
	coord = Vector2i(x, y)

	overlay.visible = false
	overlay.centered = true

	# Base square sprite
	sprite.texture = preload("res://assets/white_pixel.png")
	sprite.centered = false
	sprite.scale = Vector2(size, size)

	# Overlay scale (piece-sized)
	overlay.scale = Vector2(size / 64.0, size / 64.0)

	# Collision
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision.shape = shape
	collision.position = Vector2(size / 2, size / 2)
	overlay.position = Vector2(size / 2, size / 2)

	var tex_size := overlay.texture.get_size()
	var target_pixel_size: float = get_parent().square_size * 0.65

	var final_scale: float = target_pixel_size / tex_size.x
	overlay.scale = Vector2(final_scale, final_scale)


func set_color(color: Color) -> void:
	sprite.modulate = color

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		get_parent().on_square_pressed(coord)

#endregion


#region Overlay API (IMPORTANT)
func show_piece_overlay(piece_texture: Texture2D) -> void:
	if piece_texture == null:
		return

	overlay.texture = piece_texture
	
	# Ensure the scale math we fixed earlier is applied here too
	var target_size = get_parent().square_size * 0.85
	overlay.scale = Vector2.ONE * (target_size / piece_texture.get_size().x)
	
	overlay.visible = true

func hide_overlay() -> void:
	overlay.visible = false
	overlay.texture = null
#endregion
