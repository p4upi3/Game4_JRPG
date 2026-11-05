extends Node2D

@onready var character_body_2d: CharacterBody2D = $CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $CharacterBody2D/AnimatedSprite2D
@onready var arrow: Sprite2D = $CharacterBody2D/Arrow
@onready var progress_bar: ProgressBar = $CharacterBody2D/ProgressBar


# -------------------------
# ENEMY STATS
# -------------------------

@export var enemy_name: String = "Skeleton Archer"

@export var max_health: float = 5.0

@export var min_attack_damage: int = 1
@export var max_attack_damage: int = 3

@export_range(0.0, 1.0, 0.05)
var defend_chance: float = 0.30

@export_range(0.0, 1.0, 0.05)
var critical_chance: float = 0.20


var health: float = 5.0
var is_hurt: bool = false
var defending: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	health = max_health
	rng.randomize()

	_update_progress_bar()
	animated_sprite_2d.play("idle")


# -------------------------
# HEALTH
# -------------------------

func get_health() -> float:
	return health


func is_alive() -> bool:
	return health > 0.0


func take_damage(value: float) -> float:
	if not is_alive():
		return 0.0

	# Defend blocks the next incoming attack.
	if defending:
		defending = false
		return 0.0

	is_hurt = true

	var actual_damage: float = maxf(value, 0.0)

	health = maxf(
		health - actual_damage,
		0.0
	)

	_update_progress_bar()

	if health <= 0.0:
		animated_sprite_2d.play("die")
		unfocus()
		
	else:
		animated_sprite_2d.play("hurt")

	return actual_damage


func _update_progress_bar() -> void:
	progress_bar.value = (health / max_health) * 100.0


# -------------------------
# RNG / ENEMY AI
# -------------------------

func choose_command() -> String:
	var roll: float = rng.randf()

	if roll < defend_chance:
		return "defend"

	return "attack"


func choose_target(targets: Array) -> Node:
	var available_targets: Array[Node] = []

	for target in targets:
		if not is_instance_valid(target):
			continue

		if not target is Node:
			continue

		var target_node: Node = target

		# The enemy should only target characters
		# that are capable of receiving damage.
		if not target_node.has_method("take_damage"):
			continue

		# If the target provides get_health(),
		# make sure defeated targets are ignored.
		if target_node.has_method("get_health"):
			var target_health: float = float(
				target_node.call("get_health")
			)

			if target_health <= 0.0:
				continue

		available_targets.append(target_node)

	if available_targets.is_empty():
		return null

	var random_index: int = rng.randi_range(
		0,
		available_targets.size() - 1
	)

	return available_targets[random_index]


func roll_attack_damage() -> Dictionary:
	var damage: int = rng.randi_range(
		min_attack_damage,
		max_attack_damage
	)

	var critical: bool = rng.randf() < critical_chance

	if critical:
		damage *= 2

	return {
		"damage": damage,
		"critical": critical
	}


# -------------------------
# ENEMY COMMANDS
# -------------------------

func attack(target: Node) -> Dictionary:
	if target == null:
		return {
			"command": "attack",
			"success": false,
			"message": enemy_name + " had no valid target."
		}

	# check if dodging
	if target.has_meta("dodging") and target.get_meta("dodging"):
		target.set_meta("dodging", false)

		return {
			"command": "attack",
			"success": true,
			"target": target,
			"damage": 0,
			"critical": false,
			"message": target.name + " dodged " + enemy_name + "'s attack!"
		}
		
	var damage_roll: Dictionary = roll_attack_damage()

	var damage: int = int(damage_roll["damage"])
	var critical: bool = bool(damage_roll["critical"])

	target.call("take_damage", damage)

	var message: String = (
		enemy_name
		+ " attacked "
		+ target.name
		+ " for "
		+ str(damage)
		+ " damage."
	)

	if critical:
		message += " Critical hit!"

	return {
		"command": "attack",
		"success": true,
		"target": target,
		"damage": damage,
		"critical": critical,
		"message": message
	}


func defend() -> Dictionary:
	defending = true

	return {
		"command": "defend",
		"success": true,
		"message": enemy_name + " defended against the next attack."
	}


# The Battle Handler can call this once
# it is this enemy's turn.
func perform_turn(targets: Array) -> Dictionary:
	if not is_alive():
		return {
			"command": "none",
			"success": false,
			"message": enemy_name + " cannot act because it is defeated."
		}

	var command: String = choose_command()

	if command == "defend":
		return defend()

	var target: Node = choose_target(targets)

	return attack(target)


# -------------------------
# TARGET SELECTION
# -------------------------

# Shows the arrow above the enemy when
# the player is selecting this enemy.
func focus() -> void:
	arrow.show()


func unfocus() -> void:
	arrow.hide()


# -------------------------
# ANIMATIONS
# -------------------------

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hurt":
		is_hurt = false

		if is_alive():
			animated_sprite_2d.play("idle")
