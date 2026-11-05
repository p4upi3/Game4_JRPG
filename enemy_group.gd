extends Node2D

var enemies: Array = []
var index: int = 0

@onready var choice = $"../CanvasLayer/Choices"

func _ready() -> void:
	enemies = get_children()
	show_choice()
	_start_choosing()

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
