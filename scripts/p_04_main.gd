extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InventoryTests.new().run_all()
	var db := ItemDatabase.new()
	print("load: ", db.load_from_directory("res://data/"), " chest is piece: ", db.get_item(&"chest_00") is BuildingPieceData)
