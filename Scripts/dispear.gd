extends CPUParticles2D

@onready var timer = get_node("Timer")

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = 1.0
	timer.start()
	emitting = true

func _on_timer_timeout():
	queue_free()
