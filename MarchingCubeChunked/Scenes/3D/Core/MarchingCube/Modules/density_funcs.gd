class_name DensityFuncs extends Node
## Density functions that samples the density from given coordinate.
## Here, negative means SOLID while positive means OPEN.
## Do note some marching cube tutorials use those in reverse, watchout for sign.


# --- Funcs ---

## const multiplier for scaling noise
## ... but without const because const implementation is bs rn
static var _pos_multiplier: Vector3 = Vector3(1.0, 1.0, 1.0)


## Density function with 3D Noise. Creates Tunnels.
static func sample_3d_density(noise: Noise, pos: Vector3) -> float:
	var _density: float = noise.get_noise_3dv(pos)
	return _density


## Density function with 3D Noise. Creates Tunnels.
static func sample_3d_inverted_density(noise: Noise, pos: Vector3) -> float:
	return -sample_3d_density(noise, pos)


## Density function with 2D Noise. Creates 2D map.
static func sample_2d_density(noise: Noise, pos: Vector3) -> float:
	# since y val sign change at y=0, this creates plane.
	var _density: float = pos.y

	var height_weight: float = (1.0 - abs(pos.y * 2))

	# add noise
	var noise_val = noise.get_noise_2d(pos.x, pos.z) * 0.5;

	return _density + noise_val * height_weight


static var radius := 0.2


## Density function with Sphere shape with center at 0, 0, 0.
static func sample_sphere_density(_noise: Noise, pos: Vector3) -> float:
	var _density: float = pos.distance_squared_to(Vector3.ZERO) - DensityFuncs.radius
	return _density


## normalize -0.5~0.5 range into 0~1 range
static func _normalize_pos(val: Vector3) -> Vector3:
	return val + Vector3(0.5, 0.5, 0.5)


## Moon surface density func
static func sample_moon_density(noise: Noise, pos: Vector3) -> float:

	var is_ocean: int = pos.y > 0.0
	var base_surface = pos.y

	# cut circle shape around center
	var distance = Vector3.ZERO.distance_squared_to(Vector3(pos.x, 0.0, pos.z))
	if distance < 4.0:
		return base_surface

	var height: float = base_surface - (noise.get_noise_3dv(pos)) * is_ocean

	# blend slowly
	if distance < 16.0:
		return lerpf(base_surface, height, (distance - 4.0) / 12.0)

	return height


## Plaetu density func
static func sample_plaetu_density(noise: Noise, pos: Vector3) -> float:
	var floored_pos = Vector3(pos.x, pos.y - fmod(pos.y, 0.1), pos.z)

	var base_surface = floored_pos.y

	return base_surface - noise.get_noise_3dv(floored_pos)



## Density function types
enum FUNC_TYPE {NOISE_3D, NOISE_3D_INV, NOISE_2D, SPHERE}

static var _FUNCS: Array[Callable] = [
	Callable(self, "sample_3d_density"),
	Callable(self, "sample_3d_inverted_density"),
	Callable(self, "sample_2d_density"),
	Callable(self, "sample_sphere_density"),
]


## Return noise in range of -1.0~1.0 with designated func_type.
## Expects position of -0.5~0.5 range, no restriction for offset_pos.
static func sample_density(noise: Noise, pos: Vector3) -> float:
	# return self._FUNCS[type].call(noise, pos, offset_pos)
	return DensityFuncs.sample_moon_density(noise, pos * DensityFuncs._pos_multiplier)
	# return DensityFuncs.sample_plaetu_density(noise, pos)
