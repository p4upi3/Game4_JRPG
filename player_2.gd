extends Node2D

@onready var character_body_2d: CharacterBody2D = $CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var arrow: Sprite2D = $CharacterBody2D/Arrow
@onready var progress_bar: ProgressBar = $CharacterBody2D/ProgressBar

var max_health: float = 10

func _ready() -> void:
	animated_sprite_2d.play("idle")

var health: float = 10:
	set(value):
		health = value
		_update_progress_bar()
		animated_sprite_2d.play("hurt")

func _update_progress_bar():
	progress_bar.value = (health/max_health) * 100

func focus():
	arrow.show()

func unfocus():
	arrow.hide()

func take_damage(value):
	health -= value
