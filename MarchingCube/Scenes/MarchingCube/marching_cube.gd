class_name MarchingCube extends Node3D
## Godot marching cube implementation for Cube.
## Multithreading is not implemented.


@export_group("Generation")

## Division
@export var width: int = 10

## Chunk's position
@export var chunk_pos: Vector3

## Noise generator
@export var noise: FastNoiseLite

## isovalue or threshold, deciding which value to be boundary of solid & empty
@export var threshold: float = 0.0

## Smoothness of generated mesh. 0.0 gives blocky feeling
@export_range(0.0, 1.0) var smoothness: float = 1.0


@export_group("Visual")

## Marker used for visualizing vertices
@export var vert_marker: PackedScene

## Decide whether to apply flat shading or not
@export var flat_shading: bool = false


# --- Onready ---

@onready var _offset_node: Node3D = $Offset

@onready var _marker_root: Node3D = $Offset/MarkerRoot
@onready var _mesh_instance: MeshInstance3D = $Offset/MeshInstance
@onready var _collision_shape: CollisionShape3D = $Offset/StaticBody3D/CollisionShape3D

## Cache verts counts per edge
@onready var _w_verts: int = self.width + 1

## Cache squared verts count for indexing
@onready var _sq_w_verts: int = self._w_verts ** 2


# --- Noise ---

## Offset to noise since noise's 0,0,0 is always 1.
static var _NOISE_OFFSET: Vector3 = Vector3(0, 0, -10000)

## Multiplier to noise since step is too small
static var _NOISE_MULTIPLIER: float = 50.0

## Return noise in range of -1.0~1.0. Redefine this yourself to change shape!
## We're giving it int values because we'll just gonna scale entire thing down
## via 1/width to delegate float calculation to engine.
func sample_noise(pos: Vector3) -> float:
	# for 3D noise just use this
	# return self.noise.get_noise_3d(x, y, z)

	# else for 2D noise we want bottom to be filled, top is open so lerp this
	# we'll give 0.0 for Y as I'm lazy to change back to NoiseTexture2D.
	var height: float = self.noise.get_noise_3d(pos.x, 0.0, pos.z)
	var height_weight: float = pos.y / self.width

	height = lerpf(-1.0, height / (height_weight + 1e-5) - 0.5, height_weight)
	return clampf(height, -1.0, 1.0)


# --- Tables ---

# NOTE: it's better to fold these long bastards!

## Triangulation table - cube idx to crossed edges that form triangle
static var _CUBE_TO_TRI_EDGES_TABLE: Array[Array] = [
	[],
	[0, 8, 3],
	[0, 1, 9],
	[1, 8, 3, 9, 8, 1],
	[1, 2, 10],
	[0, 8, 3, 1, 2, 10],
	[9, 2, 10, 0, 2, 9],
	[2, 8, 3, 2, 10, 8, 10, 9, 8],
	[3, 11, 2],
	[0, 11, 2, 8, 11, 0],
	[1, 9, 0, 2, 3, 11],
	[1, 11, 2, 1, 9, 11, 9, 8, 11],
	[3, 10, 1, 11, 10, 3],
	[0, 10, 1, 0, 8, 10, 8, 11, 10],
	[3, 9, 0, 3, 11, 9, 11, 10, 9],
	[9, 8, 10, 10, 8, 11],
	[4, 7, 8],
	[4, 3, 0, 7, 3, 4],
	[0, 1, 9, 8, 4, 7],
	[4, 1, 9, 4, 7, 1, 7, 3, 1],
	[1, 2, 10, 8, 4, 7],
	[3, 4, 7, 3, 0, 4, 1, 2, 10],
	[9, 2, 10, 9, 0, 2, 8, 4, 7],
	[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],
	[8, 4, 7, 3, 11, 2],
	[11, 4, 7, 11, 2, 4, 2, 0, 4],
	[9, 0, 1, 8, 4, 7, 2, 3, 11],
	[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],
	[3, 10, 1, 3, 11, 10, 7, 8, 4],
	[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],
	[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
	[4, 7, 11, 4, 11, 9, 9, 11, 10],
	[9, 5, 4],
	[9, 5, 4, 0, 8, 3],
	[0, 5, 4, 1, 5, 0],
	[8, 5, 4, 8, 3, 5, 3, 1, 5],
	[1, 2, 10, 9, 5, 4],
	[3, 0, 8, 1, 2, 10, 4, 9, 5],
	[5, 2, 10, 5, 4, 2, 4, 0, 2],
	[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],
	[9, 5, 4, 2, 3, 11],
	[0, 11, 2, 0, 8, 11, 4, 9, 5],
	[0, 5, 4, 0, 1, 5, 2, 3, 11],
	[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
	[10, 3, 11, 10, 1, 3, 9, 5, 4],
	[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
	[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],
	[5, 4, 8, 5, 8, 10, 10, 8, 11],
	[9, 7, 8, 5, 7, 9],
	[9, 3, 0, 9, 5, 3, 5, 7, 3],
	[0, 7, 8, 0, 1, 7, 1, 5, 7],
	[1, 5, 3, 3, 5, 7],
	[9, 7, 8, 9, 5, 7, 10, 1, 2],
	[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],
	[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],
	[2, 10, 5, 2, 5, 3, 3, 5, 7],
	[7, 9, 5, 7, 8, 9, 3, 11, 2],
	[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],
	[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
	[11, 2, 1, 11, 1, 7, 7, 1, 5],
	[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
	[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],
	[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
	[11, 10, 5, 7, 11, 5],
	[10, 6, 5],
	[0, 8, 3, 5, 10, 6],
	[9, 0, 1, 5, 10, 6],
	[1, 8, 3, 1, 9, 8, 5, 10, 6],
	[1, 6, 5, 2, 6, 1],
	[1, 6, 5, 1, 2, 6, 3, 0, 8],
	[9, 6, 5, 9, 0, 6, 0, 2, 6],
	[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],
	[2, 3, 11, 10, 6, 5],
	[11, 0, 8, 11, 2, 0, 10, 6, 5],
	[0, 1, 9, 2, 3, 11, 5, 10, 6],
	[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],
	[6, 3, 11, 6, 5, 3, 5, 1, 3],
	[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],
	[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
	[6, 5, 9, 6, 9, 11, 11, 9, 8],
	[5, 10, 6, 4, 7, 8],
	[4, 3, 0, 4, 7, 3, 6, 5, 10],
	[1, 9, 0, 5, 10, 6, 8, 4, 7],
	[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],
	[6, 1, 2, 6, 5, 1, 4, 7, 8],
	[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],
	[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
	[7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9],
	[3, 11, 2, 7, 8, 4, 10, 6, 5],
	[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],
	[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
	[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],
	[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
	[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],
	[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
	[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],
	[10, 4, 9, 6, 4, 10],
	[4, 10, 6, 4, 9, 10, 0, 8, 3],
	[10, 0, 1, 10, 6, 0, 6, 4, 0],
	[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],
	[1, 4, 9, 1, 2, 4, 2, 6, 4],
	[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],
	[0, 2, 4, 4, 2, 6],
	[8, 3, 2, 8, 2, 4, 4, 2, 6],
	[10, 4, 9, 10, 6, 4, 11, 2, 3],
	[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
	[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],
	[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
	[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],
	[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
	[3, 11, 6, 3, 6, 0, 0, 6, 4],
	[6, 4, 8, 11, 6, 8],
	[7, 10, 6, 7, 8, 10, 8, 9, 10],
	[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],
	[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
	[10, 6, 7, 10, 7, 1, 1, 7, 3],
	[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
	[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],
	[7, 8, 0, 7, 0, 6, 6, 0, 2],
	[7, 3, 2, 6, 7, 2],
	[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],
	[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
	[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],
	[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
	[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],
	[0, 9, 1, 11, 6, 7],
	[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],
	[7, 11, 6],
	[7, 6, 11],
	[3, 0, 8, 11, 7, 6],
	[0, 1, 9, 11, 7, 6],
	[8, 1, 9, 8, 3, 1, 11, 7, 6],
	[10, 1, 2, 6, 11, 7],
	[1, 2, 10, 3, 0, 8, 6, 11, 7],
	[2, 9, 0, 2, 10, 9, 6, 11, 7],
	[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],
	[7, 2, 3, 6, 2, 7],
	[7, 0, 8, 7, 6, 0, 6, 2, 0],
	[2, 7, 6, 2, 3, 7, 0, 1, 9],
	[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
	[10, 7, 6, 10, 1, 7, 1, 3, 7],
	[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
	[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],
	[7, 6, 10, 7, 10, 8, 8, 10, 9],
	[6, 8, 4, 11, 8, 6],
	[3, 6, 11, 3, 0, 6, 0, 4, 6],
	[8, 6, 11, 8, 4, 6, 9, 0, 1],
	[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
	[6, 8, 4, 6, 11, 8, 2, 10, 1],
	[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
	[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],
	[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
	[8, 2, 3, 8, 4, 2, 4, 6, 2],
	[0, 4, 2, 4, 6, 2],
	[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
	[1, 9, 4, 1, 4, 2, 2, 4, 6],
	[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],
	[10, 1, 0, 10, 0, 6, 6, 0, 4],
	[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],
	[10, 9, 4, 6, 10, 4],
	[4, 9, 5, 7, 6, 11],
	[0, 8, 3, 4, 9, 5, 11, 7, 6],
	[5, 0, 1, 5, 4, 0, 7, 6, 11],
	[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
	[9, 5, 4, 10, 1, 2, 7, 6, 11],
	[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
	[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],
	[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
	[7, 2, 3, 7, 6, 2, 5, 4, 9],
	[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],
	[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
	[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],
	[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
	[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],
	[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
	[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],
	[6, 9, 5, 6, 11, 9, 11, 8, 9],
	[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],
	[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
	[6, 11, 3, 6, 3, 5, 5, 3, 1],
	[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
	[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],
	[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
	[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],
	[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],
	[9, 5, 6, 9, 6, 0, 0, 6, 2],
	[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],
	[1, 5, 6, 2, 1, 6],
	[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],
	[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
	[0, 3, 8, 5, 6, 10],
	[10, 5, 6],
	[11, 5, 10, 7, 5, 11],
	[11, 5, 10, 11, 7, 5, 8, 3, 0],
	[5, 11, 7, 5, 10, 11, 1, 9, 0],
	[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],
	[11, 1, 2, 11, 7, 1, 7, 5, 1],
	[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],
	[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
	[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],
	[2, 5, 10, 2, 3, 5, 3, 7, 5],
	[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],
	[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
	[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],
	[1, 3, 5, 3, 7, 5],
	[0, 8, 7, 0, 7, 1, 1, 7, 5],
	[9, 0, 3, 9, 3, 5, 5, 3, 7],
	[9, 8, 7, 5, 9, 7],
	[5, 8, 4, 5, 10, 8, 10, 11, 8],
	[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],
	[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
	[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],
	[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
	[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],
	[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
	[9, 4, 5, 2, 11, 3],
	[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],
	[5, 10, 2, 5, 2, 4, 4, 2, 0],
	[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],
	[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
	[8, 4, 5, 8, 5, 3, 3, 5, 1],
	[0, 4, 5, 1, 0, 5],
	[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],
	[9, 4, 5],
	[4, 11, 7, 4, 9, 11, 9, 10, 11],
	[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
	[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],
	[3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4],
	[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],
	[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
	[11, 7, 4, 11, 4, 2, 2, 4, 0],
	[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
	[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],
	[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
	[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],
	[1, 10, 2, 8, 7, 4],
	[4, 9, 1, 4, 1, 7, 7, 1, 3],
	[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],
	[4, 0, 3, 7, 4, 3],
	[4, 8, 7],
	[9, 10, 8, 10, 11, 8],
	[3, 0, 9, 3, 9, 11, 11, 9, 10],
	[0, 1, 10, 0, 10, 8, 8, 10, 11],
	[3, 1, 10, 11, 3, 10],
	[1, 2, 11, 1, 11, 9, 9, 11, 8],
	[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],
	[0, 2, 11, 8, 0, 11],
	[3, 2, 11],
	[2, 3, 8, 2, 8, 10, 10, 8, 9],
	[9, 10, 2, 0, 9, 2],
	[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
	[1, 10, 2],
	[1, 3, 8, 9, 1, 8],
	[0, 9, 1],
	[0, 3, 8],
	[]
]

## Edge's vert a, b index in cube
static var _EDGE_TO_VERT_TABLE: Array[Array] = [
	[0, 1],
	[1, 2],
	[2, 3],
	[3, 0],
	[4, 5],
	[5, 6],
	[6, 7],
	[7, 4],
	[0, 4],
	[1, 5],
	[2, 6],
	[3, 7],
]

## Relative offset from Cube's 0th vert
static var _VERT_OFFSET_TABLE: Array[Vector3i] = [
	Vector3i.ZERO,
	Vector3i(1, 0, 0),
	Vector3i(1, 0, 1),
	Vector3i(0, 0, 1),
	Vector3i(0, 1, 0),
	Vector3i(1, 1, 0),
	Vector3i(1, 1, 1),
	Vector3i(0, 1, 1),
]


## Get vert at given index relative to 0th vert position
func _get_vert(zero_vert: Vector3i, idx: int) -> Vector3i:
	return zero_vert + self._VERT_OFFSET_TABLE[idx]


# --- Height Grid ---
# NOTE: This are kept to allow fast update without regenerating whole grid

## 1-dim height array that is accessed via 3D array.
## Has size of width + 1, height + 1, width + 1.
var _heights: Array[float]


## Get height value at given coordinate
func _get_height(pos: Vector3i) -> float:
	return self._heights[self._sq_w_verts * pos.x + self._w_verts * pos.y + pos.z]


# --- Vertice Position Markers ---
# NOTE: This are kept to allow fast update without regenerating whole grid

## 1-dim marker array that is accessed via 3D array.
## Has size of width + 1, height + 1, width + 1.
var _markers: Array[MeshInstance3D]


## Get marker at given coordinate
func _get_marker(pos: Vector3i) -> MeshInstance3D:
	return self._markers[self._sq_w_verts * pos.x + self._w_verts * pos.y + pos.z]


# --- Utility Function ---

## Interpolates verts' position within chunk
func _interpolate(iso_level: float, vert_a: Vector3i, vert_b: Vector3i) -> Vector3:
	var a_height: float = self._get_height(vert_a)
	var b_height: float = self._get_height(vert_b)

	# check if div by zero, if so return half
	if b_height == a_height:
		return (Vector3(vert_a) + Vector3(vert_b)) / 2.0

	# eles interpolate
	var factor: float = (iso_level - a_height) / (b_height - a_height)
	return Vector3(vert_a) + factor * Vector3(vert_b - vert_a)


# --- Marching Cube Implementations

## Generates cube index of cube that starts with given vertex.
func _get_cube_idx(vert_zero: Vector3i) -> int:
	var cube_idx: int = 0

	# for each cube vert ... god I wish I had enumerate here
	for idx: int in range(8):

		# mark current edge's bit if height is above threshold
		if (self._get_height(self._get_vert(vert_zero, idx)) > self.threshold):
			cube_idx |= 1 << idx

	return cube_idx


## Generate actual vertex pos from given cube index.
func _generate_mesh_vertices(vert_zero: Vector3i, vert_arr: Array[Vector3]):
	# iso_level = height threshold in this implementation.
	# iso = greek 'isos', meaning 'equal'. So equal level!

	# get cube idx
	var cube_idx: int = self._get_cube_idx(vert_zero)

	# Get Array of crossed edges' indices for cube_idx. Triangulation step.
	var tri_edges: Array = self._CUBE_TO_TRI_EDGES_TABLE[cube_idx]

	# for each crossed edge idx in cube
	for edge_idx: int in tri_edges:

		# lookup the cube verts that forms the edge
		var idx_a: int = self._EDGE_TO_VERT_TABLE[edge_idx][0];
		var idx_b: int = self._EDGE_TO_VERT_TABLE[edge_idx][1];

		# interpolate vertices for smooth mesh
		var vert_smooth: Vector3 = self._interpolate(
			self.threshold,
			self._get_vert(vert_zero, idx_a),
			self._get_vert(vert_zero, idx_b),
		)

		# or divide half for blockiness
		var vert_hard: Vector3 = (
			Vector3(vert_zero)
			+ (self._VERT_OFFSET_TABLE[idx_a] + self._VERT_OFFSET_TABLE[idx_b]) / 2.0
		)

		# mix those. more fine control > optimization here!
		var vert_mixed: Vector3 = lerp(vert_hard, vert_smooth, self.smoothness)

		# append to vert array
		vert_arr.append(vert_mixed)


## Generate mesh from existing heights
func regenerate_mesh() -> void:

	# setup surf tool
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# smooth group will smooth ALL in same group. EVEN IF we didn't merge vertices. I luv ya!
	var smooth_group: int = -1 if self.flat_shading else 0

	# added vertex counter & array
	# kinda afriad of fragmentation here
	var vert_idx: int = 0
	var verts: Array[Vector3]

	for x in range(self.width):
		for y in range(self.width):
			for z in range(self.width):
				self._generate_mesh_vertices(Vector3i(x, y, z), verts)

	# somehow surfacetool still can automatically smooth non-merged vertices.
	# I assume it merges verts for us, so just mindlessly append vert
	for vert: Vector3 in verts:

		# surf_tool.set_uv(Vector2(vert.x, vert.z))
		# we do uv using triplaner shader now, not needed nor seemingly possible

		surf_tool.set_smooth_group(smooth_group)
		surf_tool.add_index(vert_idx)
		surf_tool.add_vertex(vert)

		vert_idx += 1

	# gen normal & commit
	surf_tool.generate_normals()
	var _mesh: ArrayMesh = surf_tool.commit()

	# set mesh & collision shape
	self._mesh_instance.mesh = _mesh
	self._collision_shape.shape = _mesh.create_trimesh_shape()


## Set noise & update marker. Does not regenerate mesh.
func _resample_noise() -> void:
	# premultiply with vert count so we can save calculations
	var vert_offset: Vector3 = self.chunk_pos * self._w_verts + self._NOISE_OFFSET

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				var flat_idx = x_flat_idx + y_flat_idx + z

				# we're dividing by vert width to make sure UV 1:1 match width
				var height: float = self.sample_noise(
					(Vector3(x, y, z) / self.width + vert_offset) * self._NOISE_MULTIPLIER
				)

				self._heights[flat_idx] = height

				self._markers[flat_idx].set_height(height)
				self._markers[flat_idx].visible = height < self.threshold


# --- Grid management ---
# Convenient helper methods that repopulate grid's arrays.
# For actual in-game usage, these are probably not needed.

## Creates new grid filled with 1.0.
func _recreate_grid() -> void:

	# destroy
	for node: Node3D in self._markers:
		node.queue_free()

	self._markers.clear()
	self._heights.clear()

	# recreate
	var flat_size: int = self._w_verts ** 3

	self._markers.resize(flat_size)
	self._heights.resize(flat_size)
	self._heights.fill(1.0)

	# generate markers
	self._create_markers()


## Creates debug markers
func _create_markers() -> void:

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				# instance vert marker
				var instance: Node3D = self.vert_marker.instantiate()

				self._marker_root.add_child(instance)
				instance.position = Vector3(x, y, z)

				self._markers[x_flat_idx + y_flat_idx + z] = instance


# --- Generation Wrappers ---
# Convenient helper methods that sets parameter & regenerate mesh as needed.
# For actual in-game usage, most of is probably not needed.

## Dump all mesh, verts, markers and regenerate from scratch.
## Since this is expensive call when:
## - initializing
## - width change
func regenerate_all() -> void:

	self._recreate_grid()
	self._resample_noise()
	self.regenerate_mesh()

	# update scale since size width might have changed.
	self._offset_node.scale = Vector3.ONE / self.width


## Convenience wrapper for setting noise seed. Regenerate noise & mesh.
func set_seed(new_seed: int) -> void:
	self.noise.seed = new_seed
	self._resample_noise()
	self.regenerate_mesh()


## Convenience setup func for setting threshold. Updates mesh.
## Set threshold (or iso level) only. Only shows verts that's below threshold.
## Height above 0 will be empty while belows become solid.
func set_threshold(new_threshold: float) -> void:
	self.threshold = new_threshold

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				var flat_idx: int = x_flat_idx + y_flat_idx + z
				self._markers[flat_idx].visible = self._heights[flat_idx] < self.threshold

	# we only need to regenerate mesh, right?
	# ...right?
	self.regenerate_mesh()
	# yeah I think it was, good job old me


## Convenient setup func for setting width.
## Regenerates entire grid from scratch.
func set_width(new_width: float) -> void:
	self.width = int(new_width)

	self._w_verts = self.width + 1
	self._sq_w_verts = self._w_verts ** 2

	self.regenerate_all()


## Convenience function for changing chunk position.
## Regenerates noise and mesh.
func set_chunk_pos(new_chunk_pos: Vector3) -> void:
	self.chunk_pos = new_chunk_pos
	self._resample_noise()
	self.regenerate_mesh()


## Convenience function for changing blending factor.
func set_blending_factor(factor: float) -> void:
	var mat: ShaderMaterial = self._mesh_instance.get_active_material(0)
	mat.set_shader_parameter("BlendFactor", factor)
