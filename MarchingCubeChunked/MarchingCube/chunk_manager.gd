class_name ChunkManager extends Node3D
## Manages marching cube chunks


# --- Signals ---

signal generation_done(elapsed_sec: float)


# --- Exports ---

@export var chunks_dimension: Vector3i = Vector3i(4, 2, 4)


# --- Attributes ---

@onready var chunks_count: int = (
	self.chunks_dimension.x * self.chunks_dimension.y * self.chunks_dimension.z
)

const chunk_scene: PackedScene = preload(
	"res://MarchingCube/marching_cube.tscn"
)


# --- Chunk Table ---

## Keeps chunks with Vector3i key, MarchingCube as value.
var _lookup_table: Dictionary = {}


## Find chunk with given position. Returns null if non exists.
func get_chunk(pos: Vector3) -> MarchingCube:
	var key: Vector3i = floor(pos)
	return self._lookup_table.get(key)


## Add chunk with given position, remove previous entry if any
func add_chunk(chunk: MarchingCube) -> void:
	var key: Vector3i = floor(chunk.global_position)

	var existing: MarchingCube = self._lookup_table.get(key)
	if existing:
		existing.queue_free()

	self._lookup_table[key] = chunk


# --- Counter ---

var _pending_count: int = 0
var _start_time: float

## Increase counter. This is used to track number of chunks via call_deferred().
## also starts recording time when pending is empty.
func _pending_count_up():
	if self._pending_count == 0:
		self._start_time = Time.get_unix_time_from_system()

	self._pending_count += 1


## Decrease counter. This is used to track number of chunks via call_deferred().
## also emits generation_done when pending is empty with total elapsed time.
func _pending_count_down():
	self._pending_count -= 1

	if self._pending_count == 0:
		self.generation_done.emit(Time.get_unix_time_from_system() - self._start_time)


# --- Thread Manager ---

@export var max_threads: int = 4

var semaphore: Semaphore = Semaphore.new()
var mutex: Mutex = Mutex.new()
var thread_pool: Array[Thread] = []

const THREAD_SENTINEL: String = ""

## Pending chunks or sentinels since null is also returned when arr is empty.
var pending_chunks: Array = []


## Prep initial threading required data like semaphore.
func _thread_init() -> void:
	for _idx in range(self.max_threads):
		self.thread_pool.append(Thread.new())
		self.thread_pool[_idx].start(
			self._generate_mesh_threaded.bind(_idx)
		)


## Stop threads gracefully
func _thread_stop() -> void:
	mutex.lock()

	# clear pending jobs and put enough sentinels in arr just in case
	self.pending_chunks.clear()

	for _idx in range(self.max_threads * 2):
		self.pending_chunks.append(THREAD_SENTINEL)
		self.semaphore.post()

	mutex.unlock()

	# wait for threads
	for thread: Thread in self.thread_pool:
		if thread.is_started():
			thread.wait_to_finish()

	self.thread_pool.clear()


## update thread runners count. This will discard ALL CHUNKS. Generate again afterward.
func set_thread_count(count: int) -> void:
	if count == self.max_threads:
		return

	print("[ChunkManager] Setting thread count (%s -> %s)" % [self.max_threads, count])

	self._thread_stop()
	self.max_threads = count

	# clear chunks
	#for chunk: MarchingCube in self._lookup_table.values():
		#chunk.queue_free()
		#self.remove_child(chunk)

	self.pending_chunks.clear()
	# self._lookup_table.clear()

	# start new threads
	self._thread_init()


## Clear pending generations
func clear_pending() -> void:
	self.mutex.lock()
	self.pending_chunks.clear()
	self.mutex.unlock()


## Thread safe runner for mesh generation.
## Send null in array and post semaphore to terminate gracefully.
func _generate_mesh_threaded(thread_idx: int) -> void:
	print("[Thread %s] Started" % thread_idx)

	while true:
		self.semaphore.wait()
		self.mutex.lock()

		# front pop ain't nice...but can't help
		var item = self.pending_chunks.pop_front()

		self.mutex.unlock()

		# if array's empty, then just go back to waiting room
		if item == null:
			continue

		# if it's not chunk it's sentinel
		if item is not MarchingCube:
			print("[Thread %s] Stop" % thread_idx)
			return

		var chunk := item as MarchingCube
		chunk.debug_set_generating.call_deferred()

		#if chunk.is_sampled:
			#print("[Thread %s] Updating %s" % [thread_idx, chunk.pos])
		if not chunk.is_sampled:
			#print("[Thread %s] Generating %s" % [thread_idx, chunk.pos])
			chunk.resample_density()

		chunk.regenerate_mesh()
		chunk.debug_unset_generating.call_deferred()

		self._pending_count_down.call_deferred()
		# print("[Thread %s] Processing %s done" % [thread_idx, chunk.pos])


## Only generate chunks. Set chunk amount at `chunk_dimensions` export beforehand.
## Does not sample & create mesh. Call `regenerate_all` instead.
func generate_chunk(seed_: int, method: StringName, frequency: float = 0.1) -> void:

	print("[ChunkManager] Generation requested")

	var offset := (Vector3(self.chunks_dimension) / 2).floor()

	for x in range(self.chunks_dimension.x):
		for y in range(self.chunks_dimension.y):
			for z in range(self.chunks_dimension.z):

				var chunk: MarchingCube = self.chunk_scene.instantiate()
				chunk.pos = Vector3(x, y, z) - offset

				# set but not update yet, we'll do it at last moment
				chunk.set_noise_seed(seed_, false)
				chunk.set_noise_frequency(frequency, false)
				chunk.sampler = method

				# add chunk and set position etc
				# TODO: add seed here
				self.add_child(chunk)

				self.add_chunk(chunk)
				#self.pending_chunks.append(chunk)


## Generate/Regenerate all chunks. Create chunk nodes automatically when nonexisting.
func regenerate_all(seed_: int, method: StringName, frequency: float = 0.1) -> void:

	# check if not generated, if so generate
	if self._lookup_table.is_empty():
		self.generate_chunk(seed_, method, frequency)

	print("[ChunkManager] Regenerate requested w/ seed: %d | method: %s" % [seed_, method])

	self.clear_pending()

	for chunk: MarchingCube in self._lookup_table.values():

		# set but not update yet, we'll do it at last moment
		chunk.set_noise_seed(seed_, false)
		chunk.set_noise_frequency(frequency, false)
		chunk.sampler = method

		# clear mesh & add to queue
		chunk.clear_mesh()
		self.pending_chunks.append(chunk)

	# allow thread to run for all chunks
	for _n in range(self.chunks_count):
		self._pending_count_up()
		self.semaphore.post()


func update_chunk(chunk: MarchingCube):

	var updated: bool = false

	self.mutex.lock()

	# check if it exists already in queue and only add if not already done
	if chunk not in self.pending_chunks:
		self.pending_chunks.append(chunk)
		updated = true

	self.mutex.unlock()

	if updated:
		self.semaphore.post()


# --- Handlers ---

func _enter_tree() -> void:
	self._thread_init.call_deferred()


func _exit_tree() -> void:
	self._thread_stop()
