# for Pau: right now the battle handler/action
# queue is in enemy_group, and it counts if the
# amount of actions taken by the players is equal
# to the amount of enemies. In the battle handler,
# find a way that it instead counts if all players
# have acted. In other words, if the amount
# of actions taken is the same as amount of players,
# it ends the players' phase and launches their attacks.
# same goes for the enemies. -Kandice

extends Node2D

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0

signal next_player
@onready var choice = $"../CanvasLayer/Choices"

func _ready() -> void:
	enemies = get_children()
	show_choice()
	_start_choosing()

func _process(delta: float) -> void:
	if not choice.visible:
		# Choose enemy after choosing action (press up or down)
		if Input.is_action_just_pressed("ui_up"):
			if index > 0:
				index -= 1
				switch_focus(index, index+1)
			
		if Input.is_action_just_pressed("ui_down"):
			if index < enemies.size() - 1:
				index += 1
				switch_focus(index, index-1)
		
		# Choose action using left/right arrows, then enter
		if Input.is_action_just_pressed("ui_accept"):
			action_queue.push_back(index)
			emit_signal("next_player")
			
		# If amount of actions is equal to amount of enemies, start phase
		# after choosing player inputs
		if action_queue.size() == enemies.size() and not is_battling:
			is_battling = true
			_action(action_queue)

# Takes all actions and distributes them to whichever
# enemies are chosen... for now only has slash
func _action(stack):
	for i in stack:
		enemies[i].take_damage(1)
		
		# If enemy dies, unfocus and remove them from
		# array so you can't choose them anymore. If
		# the enemy dies but you still have actions queued
		# up, they go to the next enemy
		if enemies[i].get_health() <= 0:
			enemies[i].unfocus()
			enemies.remove_at(i)
		await get_tree().create_timer(1).timeout
	action_queue.clear()
	is_battling = false
	show_choice()

func switch_focus(x,y):
	enemies[x].focus()
	enemies[y].unfocus()

func show_choice():
	choice.show()
	choice.find_child("Slash").grab_focus()

func _reset_focus():
	index = 0
	for enemy in enemies:
		enemy.unfocus()

func _start_choosing():
	_reset_focus()
	enemies[0].focus()

func _on_slash_pressed() -> void:
	choice.hide()
	_start_choosing()
