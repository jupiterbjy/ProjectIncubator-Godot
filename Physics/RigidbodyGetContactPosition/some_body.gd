extends RigidBody3D
## Demonstration of CollisionShape-Aware contact coordination access


# --- Signals ---

## Signal for showing message on UI
signal contact_report(msg: String)


# --- Referneces ---

# prob better not using PackedVector3Array here, locality barely matters
## Dict[RID, Dict[int, Array[Vector3]]] typed contacts mapping.
## {RID: {CollisionShape3D: local-coordination-contacts}}
var _contacts: Dictionary[RID, Dictionary]


# --- Drivers ---

## Populates contact mapping for use in _on_body_shape_entered signal.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:

	self._contacts.clear()

	for idx: int in range(state.get_contact_count()):

		# for each contact idx get/add dict associated with collider's RID
		var coll_shape_to_contacts_map: Dictionary = self._contacts.get_or_add(
			state.get_contact_collider(idx), {}
		)

		# from that dict get/add array associated with CollisionShape3D
		var contact_points: Array = coll_shape_to_contacts_map.get_or_add(
			self.shape_owner_get_owner(
				self.shape_find_owner(state.get_contact_local_shape(idx))
			),
			[],
		)

		# add points to array
		contact_points.append(self.to_local(state.get_contact_local_position(idx)))


## Process contact data for given body_rid.
func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:

	var msg_parts: Array[String] = []

	for collided_shape: CollisionShape3D in self._contacts[body_rid]:
		msg_parts.append("\nCollisionShape3D '%s' got hit at:" % collided_shape.name)

		for point: Vector3 in self._contacts[body_rid][collided_shape]:
			msg_parts.append("  └ %v" % point)

	self.contact_report.emit("\n".join(msg_parts).lstrip("\n"))
