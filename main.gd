extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func update_health():
	$CanvasLayer/ProgressBar.value = $player.health
func _ready():
	$player.connect("attacked", self, "update_health")
	$CanvasLayer/ProgressBar.value = $player.health
