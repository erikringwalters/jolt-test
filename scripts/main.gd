extends Node3D

const Y_OFFSET = 10
const CUBE_SIZE = 0.9

func _ready():
	spawn_cubes(10)

func _physics_process(delta: float) -> void:
	print("fps", Engine.get_frames_per_second())

func spawn_cubes(axis_amount:int):
	for i in axis_amount:
		for j in axis_amount:
			for k in axis_amount:
				var cube = RigidBody3D.new()
				add_child(cube);
				var cube_collider = CollisionShape3D.new()
				cube_collider.shape = BoxShape3D.new()
				cube_collider.shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
				cube.add_child(cube_collider)
				var cube_mesh = MeshInstance3D.new()
				cube_mesh.mesh = BoxMesh.new()
				cube_mesh.mesh.size = cube_collider.shape.size
				cube.add_child(cube_mesh)
				
				cube.global_transform.origin = Vector3(i + CUBE_SIZE/2 - axis_amount/2, j + Y_OFFSET, k)
				
