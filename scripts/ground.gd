extends StaticBody2D

func _on_deathzone_body_entered(body: Node2D) -> void:
	if body is Player:
		print("E")
