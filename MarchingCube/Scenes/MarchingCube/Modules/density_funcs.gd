class_name DensityFuncs extends Node
## Density functions that samples the density from given coordinate.
## Here, negative means SOLID while positive means OPEN.
## Do note some marching cube tutorials use those in reverse, watchout for sign.


## Offset to noise since simplex noise's 0,0,0 is always 1.
static var _NOISE_OFFSET: Vector3 = Vector3(0, 0, -10000)

## Multiplier to noise in case step is too small.
static var _NOISE_MULTIPLIER: float = 50.0

## Density function types
enum FUNC_TYPE {NOISE_3D, NOISE_2D, SPHERE}

@export var func_type: FUNC_TYPE

## 3D Noise
@export var noise_3d: NoiseTexture3D

## 2D Noise
@export var noise_2d: NoiseTexture2D

## Sphere Radius
@export var radius: float = 0.2


# --- Funcs ---

## Density function with Sphere shape with center at 0, 0, 0.
func sample_sphere_density(pos: Vector3) -> float:
	var _density: float = pos.distance_squared_to(Vector3.ZERO) - self.radius
	return _density


## Density function with 3D Noise. Creates Tunnels.
func sample_3d_density(pos: Vector3) -> float:
	var _density: float = self.noise_3d.get_noise_3dv(pos)
	return _density


## Density function with 2D Noise. Creates 2D map.
func sample_2d_density(pos: Vector3) -> float:
	# since y val sign change at y=0, this creates plane.
	var _density: float = pos.y
	
	# add noise
	_density += self.noise_2d.get_noise_2d(pos.x, pos.z);
	
	return _density


static var _FUNCS: Array[Callable] = [
	Callable(self, "sample_")
]

## Return noise in range of -1.0~1.0 with designated func_type.
func sample_density(pos: Vector3) -> float:
	
