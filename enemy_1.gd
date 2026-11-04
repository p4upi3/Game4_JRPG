extends Node2D

@onready var character_body_2d: CharacterBody2D = $CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var arrow: Sprite2D = $CharacterBody2D/Arrow
@onready var progress_bar: ProgressBar = $CharacterBody2D/ProgressBar

var max_health: float = 5
var is_hurt: bool = false

func _ready() -> void:
	animated_sprite_2d.play("idle")

func get_health():
	return health

func _physics_process(delta):
	if not is_hurt:
		animated_sprite_2d.play("idle")

var health: float = 5:
	set(value):
		health = value
		_update_progress_bar()

func _update_progress_bar():
	progress_bar.value = (health/max_health) * 100

func take_damage(value):
	is_hurt = true
	health -= value
	animated_sprite_2d.play("hurt")
	if health <= 0:
		animated_sprite_2d.play("die")

# Shows/hides arrow above enemy, indicating which
# enemy the player chooses to attack
func focus():
	arrow.show()

func unfocus():
	arrow.hide()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hurt":
		is_hurt = false
