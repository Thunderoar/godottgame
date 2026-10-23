@tool
class_name AssetCatalog
extends Resource
## Dictionary keys are stable semantic IDs, never file-order indices.
@export var version := 1
@export var entries: Dictionary = {}
