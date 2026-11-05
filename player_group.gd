extends Node2D

var players: Array = []
var index: int = 0

func _ready() -> void:
	players = get_children()
	players[0].focus()

func switch_focus(x,y):
	players[x].focus()
	players[y].unfocus()
