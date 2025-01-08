@tool
class_name SubViewportPopup extends PopupBase
## Viewport popup displaying demo 3D scene


# --- References ---

## Scene ref for named scene constructor
const _SCENE: PackedScene = preload("uid://dbxb8pdr13idc")


# --- Utilities ---

## Instantiate scene and automatically add self as child to given parent
static func create_instance(parent: Node) -> SubViewportPopup:
	var instance: SubViewportPopup = _SCENE.instantiate()
	parent.add_child(instance)
	return instance
