class_name DemocraticEmitter extends GPUParticles3D
## Written by jupiterbjy@gmail.com
##
## This simple subclass allows 'Truely Free' emitting by simply
## grouping GPUParticles3D.emit_particle() calls.
## Make sure to increase 'Amount' high enough (4096 in this example)

## Min # of particles to be emitted per emit_once call.
@export var single_emit_min: int = 128

## Max # of particles to be emitted per emit_once call.
@export var single_emit_max: int = 256


## Emit particle group single time
func emit_once() -> void:
	for _idx in range(randi_range(single_emit_min, single_emit_max)):
		# whatever I put in doesn't matter much for my draw pass
		self.emit_particle(Transform3D.IDENTITY, Vector3.ZERO, Color.RED, Color.RED, 0)
