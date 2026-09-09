extends RefCounted
## Tiny sound helper: cached wavs, fire-and-forget 2D/3D players.

static var _cache := {}

static func stream(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		var s: AudioStreamWAV = load("res://assets/audio/%s.wav" % name)
		_cache[name] = s
	return _cache[name]

static func play(parent: Node, name: String, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p

static func play_at(parent: Node, name: String, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0, max_dist: float = 18.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.max_distance = max_dist
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
	return p
