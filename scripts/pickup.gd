extends Area2D
class_name Pickup

@export var item_id : StringName = &"stone_00"
@export var amount : int = 1


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("handle_pickup"):
			var result = body.handle_pickup(item_id,amount)
			amount = result["remaining"]
			if amount <= 0:
				queue_free()
	
