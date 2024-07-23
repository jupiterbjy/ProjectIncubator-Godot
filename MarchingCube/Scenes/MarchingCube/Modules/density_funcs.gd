class_name DensityFuncs extends Node
## Density functions that samples the density from given coordinate.
## Here, negative means SOLID while positive means OPEN.
## Do note some marching cube tutorials use those in reverse, watchout for sign.


# --- Funcs ---

## Sphere Radius
@export var radius: float = 0.2

## Density function with 3D Noise. Creates Tunnels.
func sample_3d_density(noise: Noise, pos: Vector3, offset_pos: Vector3) -> float:
	var _density: float = noise.get_noise_3dv(pos + offset_pos)
	return _density


## Density function with 3D Noise. Creates Tunnels.
func sample_3d_inverted_density(noise: Noise, pos: Vector3, offset_pos: Vector3) -> float:
	return -sample_3d_density(noise, pos, offset_pos)


## Density function with 2D Noise. Creates 2D map.
func sample_2d_density(noise: Noise, pos: Vector3, offset_pos: Vector3) -> float:
	# since y val sign change at y=0, this creates plane.
	var _density: float = pos.y
	
	var height_weight: float = (1.0 - abs(pos.y * 2))
	
	# add noise
	var noise_val = noise.get_noise_2d(pos.x + offset_pos.x, pos.z + offset_pos.z) * 0.5;
	
	return _density + noise_val * height_weight


## Density function with Sphere shape with center at 0, 0, 0.
func sample_sphere_density(noise: Noise, pos: Vector3, _offset_pos: Vector3) -> float:
	var _density: float = pos.distance_squared_to(Vector3.ZERO) - self.radius
	return _density



## Density function types
enum FUNC_TYPE {NOISE_3D, NOISE_3D_INV, NOISE_2D, SPHERE}

var _FUNCS: Array[Callable] = [
	Callable(self, "sample_3d_density"),
	Callable(self, "sample_3d_inverted_density"),
	Callable(self, "sample_2d_density"),
	Callable(self, "sample_sphere_density"),
]

## Return noise in range of -1.0~1.0 with designated func_type.
## Expects position of -0.5~0.5 range, no restriction for offset_pos.
func sample_density(noise: Noise, pos: Vector3, offset_pos: Vector3, type: FUNC_TYPE) -> float:
	return self._FUNCS[type].call(noise, pos, offset_pos)
