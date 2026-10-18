extends SceneTree

func _init() -> void:
	var source := AudioStreamMP3.new()
	source.data = FileAccess.get_file_as_bytes("res://assets/audio/source/wood-piece-original.mp3")
	var playback := source.instantiate_playback()
	playback.start()
	var rate: int = int(AudioServer.get_mix_rate())
	var frames: PackedVector2Array = playback.mix_audio(1.0, int(ceil(source.get_length() * rate)))
	var bytes := PackedByteArray()
	bytes.resize(frames.size() * 2)
	for i in range(frames.size()):
		var sample: float = (frames[i].x + frames[i].y) * 0.5
		bytes.encode_s16(i * 2, clampi(int(sample * 32767.0), -32768, 32767))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = rate
	wave.data = bytes
	var error: Error = wave.save_to_wav("res://tmp/wood-original.wav")
	print("Decoded wood slide: %.3f s, %d Hz, result %d" % [source.get_length(), rate, error])
	quit(error)
