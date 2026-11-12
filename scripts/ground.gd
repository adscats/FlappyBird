extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_deathzone_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()

func set_speed_scale(speed_scale: float) -> void:
	if animation_player:
		animation_player.speed_scale = speed_scale
