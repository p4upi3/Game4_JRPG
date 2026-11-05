extends Node2D

@onready var character_body_2d: CharacterBody2D = $CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var arrow: Sprite2D = $CharacterBody2D/Arrow
@onready var progress_bar: ProgressBar = $CharacterBody2D/ProgressBar

var max_health: float = 10

var is_hurt: bool = false

func _ready() -> void:
	animated_sprite_2d.play("idle")

var health: float = 10:
	set(value):
		health = value
		_update_progress_bar()

func get_health():
	return health
	
func get_max_health():
	return max_health

func heal(value):
	health += value
	_update_progress_bar()

func _update_progress_bar():
	progress_bar.value = (health/max_health) * 100

func focus():
	arrow.show()

func unfocus():
	arrow.hide()

func take_damage(value):
	health -= value
	is_hurt = true
	if health <= 0.0:
			animated_sprite_2d.play("die")
			unfocus()
	else:
		animated_sprite_2d.play("hurt")

func is_alive() -> bool:
	return health > 0.0

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hurt":
		is_hurt = false

		if is_alive():
			animated_sprite_2d.play("idle")
