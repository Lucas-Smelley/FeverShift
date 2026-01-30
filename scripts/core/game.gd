extends Node2D

@onready var player: CharacterBody2D = $player
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	camera.set_player(player)
