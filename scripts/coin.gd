extends Area2D

@onready var gamemanager = %gamemanager
@onready var animation_player = $AnimationPlayer


func _on_body_entered(body: Node2D) -> void:
	gamemanager.add_point()
	animation_player.play("pickup")
