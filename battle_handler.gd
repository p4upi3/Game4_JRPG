extends Node

@onready var player_group = $"../player_group"
@onready var enemy_group = $"../enemy_group"
@onready var choices = $"../CanvasLayer/Choices"
@onready var slash_button = $"../CanvasLayer/Choices/Slash"
@onready var dodge_button = $"../CanvasLayer/Choices/Dodge"
@onready var battle_text: Label = $"../CanvasLayer/BattleText"

var player_actions = []
var player_index = 0
var target_index = 0

var choosing_target = false
var battle_running = false
var battle_over = false


func _ready():
	enemy_group.set_process(false)
	choices.hide()

	player_group.players = get_alive_members(player_group.get_children())
	enemy_group.enemies = get_alive_members(enemy_group.get_children())

	if player_group.players.is_empty():
		end_battle(false)
	elif enemy_group.enemies.is_empty():
		end_battle(true)
	else:
		begin_player_turn()


func _process(_delta):
	if battle_over or not choosing_target:
		return

	if Input.is_action_just_pressed("ui_up"):
		move_target(-1)
	elif Input.is_action_just_pressed("ui_down"):
		move_target(1)
	elif Input.is_action_just_pressed("ui_accept"):
		confirm_target()


# PLAYER TURN

func begin_player_turn():
	if check_battle_end():
		return

	battle_running = true
	choosing_target = false
	player_actions.clear()
	player_index = 0

	skip_defeated_players()

	if player_index >= player_group.players.size():
		execute_player_actions()
		return

	focus_current_player()
	show_commands()

	log_message("Player Turn: choose an action for each party member.")


func show_commands():
	choices.show()
	slash_button.show()
	dodge_button.show()
	slash_button.grab_focus()


func _on_slash_pressed():
	if battle_over or not battle_running or choosing_target:
		return

	if get_alive_members(enemy_group.get_children()).is_empty():
		check_battle_end()
		return

	choices.hide()
	choosing_target = true
	target_index = 0

	focus_enemy_target()
	log_message("Choose an enemy to attack.")


func _on_dodge_pressed():
	if battle_over or not battle_running or choosing_target:
		return

	var actor = player_group.players[player_index]

	player_actions.append({
		"actor": actor,
		"command": "dodge"
	})

	log_message(actor.name + " chose Dodge.")
	advance_player()


# CHOOSE ENEMY

func move_target(direction):
	var enemies = get_alive_members(enemy_group.get_children())

	if enemies.is_empty():
		return

	target_index = clampi(target_index + direction, 0, enemies.size() - 1)
	focus_enemy_target()


func confirm_target():
	var enemies = get_alive_members(enemy_group.get_children())

	if enemies.is_empty():
		check_battle_end()
		return

	var actor = player_group.players[player_index]
	var target = enemies[target_index]

	player_actions.append({
		"actor": actor,
		"command": "slash",
		"target": target
	})

	choosing_target = false
	log_message(actor.name + " selected Slash.")

	advance_player()


func advance_player():
	choices.hide()
	choosing_target = false
	player_index += 1

	skip_defeated_players()

	if player_index >= player_group.players.size():
		execute_player_actions()
	else:
		focus_current_player()
		show_commands()


func skip_defeated_players():
	while player_index < player_group.players.size():
		var player = player_group.players[player_index]

		if player.health > 0:
			break

		player_index += 1

# WHO TO FOCUs ON

func focus_current_player():
	for player in player_group.players:
		player.unfocus()

	if player_index < player_group.players.size():
		player_group.players[player_index].focus()


func focus_enemy_target():
	var enemies = get_alive_members(enemy_group.get_children())

	for enemy in enemy_group.enemies:
		enemy.unfocus()

	if not enemies.is_empty():
		target_index = clampi(target_index, 0, enemies.size() - 1)
		enemies[target_index].focus()


# PLAYER ACTIONS

func execute_player_actions():
	choices.hide()
	choosing_target = false

	log_message("Executing player actions...")

	for action in player_actions:
		if check_battle_end():
			return

		var actor = action["actor"]

		if not is_instance_valid(actor) or actor.health <= 0:
			continue

		if action["command"] == "dodge":
			actor.set_meta("dodging", true)
			log_message(actor.name + " is ready to dodge.")

		elif action["command"] == "slash":
			var target = action["target"]

			if not is_instance_valid(target) or target.health <= 0:
				target = get_first_alive_enemy()

			if target == null:
				break

			var damage = randi_range(1, 2)
			target.take_damage(damage)

			log_message(actor.name + " used Slash on " + target.name + " for " + str(damage) + " damage.")

			await get_tree().create_timer(0.7).timeout

	if check_battle_end():
		return

	await run_enemy_turn()


# ENEMY TURN

func run_enemy_turn():
	log_message("Enemy Turn!")

	var enemies = get_alive_members(enemy_group.get_children())

	for enemy in enemies:
		if check_battle_end():
			return

		if enemy.health <= 0:
			continue

		var targets = get_alive_members(player_group.get_children())

		if targets.is_empty():
			check_battle_end()
			return

		var enemy_actor: Variant = enemy
		var result = enemy_actor.perform_turn(targets)

		log_message(result.get("message", enemy.name + " acted."))

		await get_tree().create_timer(0.7).timeout

	if check_battle_end():
		return

	begin_player_turn()


# WIN OR LOSS

func check_battle_end():
	player_group.players = get_alive_members(player_group.get_children())
	enemy_group.enemies = get_alive_members(enemy_group.get_children())

	if player_group.players.is_empty():
		end_battle(false)
		return true

	if enemy_group.enemies.is_empty():
		end_battle(true)
		return true

	return false


func end_battle(player_won):
	battle_over = true
	battle_running = false
	choosing_target = false
	choices.hide()

	for member in player_group.get_children() + enemy_group.get_children():
		if is_instance_valid(member):
			member.unfocus()

	if player_won:
		log_message("Victory! All enemies have been defeated.")
	else:
		log_message("Defeat... Your party has been wiped out.")


func get_alive_members(members):
	var alive = []

	for member in members:
		if is_instance_valid(member) and member.health > 0:
			alive.append(member)

	return alive

func get_first_alive_enemy():
	var enemies = get_alive_members(enemy_group.get_children())

	if enemies.is_empty():
		return null

	return enemies[0]


func log_message(message):
	if is_instance_valid(battle_text):
		battle_text.text = message

	print(message)
