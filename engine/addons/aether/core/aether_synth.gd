class_name AetherSynth
extends RefCounted
## Sonidos generados por código (sin archivos): ambiente, latido, golpes,
## susurros, gritos, estática, caja de música… Devuelven AudioStreamWAV listos
## para AudioStreamPlayer o AudioStreamPlayer3D.
##   var s := AetherSynth.make("latido")

const RATE := 22050
static var _cache := {}

## Nombres disponibles: drone, latido, paso, portazo, golpes, susurro, grito,
## estatica, caja_musica, recoger, aliento, viento, crujido, campana, risa, vidrio, tintineo, golpe_madera
static func make(kind: String) -> AudioStreamWAV:
	if not _cache.has(kind):
		_cache[kind] = _build(kind)
	return _cache[kind]

static func _build(kind: String) -> AudioStreamWAV:
	match kind:
		"drone": return _drone()
		"latido": return _heart()
		"paso": return _step()
		"portazo": return _slam()
		"golpes": return _knocks()
		"susurro": return _whisper()
		"grito": return _scream()
		"estatica": return _static()
		"caja_musica": return _musicbox()
		"recoger": return _chime()
		"aliento": return _breath()
		"viento": return _wind()
		"crujido": return _creak()
		"campana": return _bell()
		"risa": return _laugh()
		"vidrio": return _glass_break()
		"tintineo": return _clink()
		"golpe_madera": return _wood_hit()
	return _chime()

static func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

static func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * RATE))
	return b

static func _normalize(b: PackedFloat32Array, peak := 0.9) -> void:
	var m := 0.0001
	for v in b:
		m = maxf(m, absf(v))
	var k := peak / m
	for i in b.size():
		b[i] *= k

static func _drone() -> AudioStreamWAV:
	var sec := 8.0
	var b := _buf(sec)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var lfo := 0.5 + 0.5 * sin(TAU * t / sec)
		var v := sin(TAU * 41.0 * t) * 0.5 + sin(TAU * 41.0 * 1.5 * t + sin(TAU * 0.25 * t)) * 0.18 * lfo
		v += sin(TAU * 82.4 * t) * 0.12 + sin(TAU * 61.5 * t) * 0.1 * (1.0 - lfo)
		lp += (randf() * 2.0 - 1.0 - lp) * 0.02
		v += lp * 0.9
		b[i] = v
	_normalize(b, 0.6)
	return _wav(b, true)

static func _heart() -> AudioStreamWAV:
	var b := _buf(1.0)
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for st in [0.0, 0.22]:
			var d: float = t - st
			if d >= 0.0:
				v += sin(TAU * (52.0 - d * 40.0) * d) * exp(-d * 18.0) * (1.0 if st == 0.0 else 0.7)
		b[i] = v
	_normalize(b, 0.95)
	return _wav(b, true)

static func _step() -> AudioStreamWAV:
	var b := _buf(0.18)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (randf() * 2.0 - 1.0 - lp) * 0.25
		b[i] = (lp * 0.8 + sin(TAU * 90.0 * t) * 0.6) * exp(-t * 32.0)
	_normalize(b, 0.7)
	return _wav(b)

static func _slam() -> AudioStreamWAV:
	var b := _buf(1.4)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (randf() * 2.0 - 1.0 - lp) * 0.12
		var v := sin(TAU * (60.0 - t * 20.0) * t) * exp(-t * 6.0) + lp * exp(-t * 9.0) * 1.4
		v += sin(TAU * 140.0 * t) * exp(-t * 14.0) * 0.4
		b[i] = v
	_normalize(b, 0.98)
	return _wav(b)

static func _knocks() -> AudioStreamWAV:
	var b := _buf(1.6)
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for st in [0.0, 0.32, 0.64]:
			var d: float = t - st
			if d >= 0.0:
				v += (sin(TAU * 170.0 * d) + sin(TAU * 310.0 * d) * 0.4) * exp(-d * 30.0)
				v += (randf() * 2.0 - 1.0) * exp(-d * 120.0) * 0.6
		b[i] = v
	_normalize(b, 0.95)
	return _wav(b)

static func _whisper() -> AudioStreamWAV:
	var sec := 2.4
	var b := _buf(sec)
	var hp := 0.0
	var prev := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf() * 2.0 - 1.0
		hp = 0.92 * (hp + n - prev)
		prev = n
		lp += (hp - lp) * 0.35
		var syl := maxf(0.0, sin(TAU * 3.3 * t + sin(TAU * 0.7 * t) * 2.0))
		var env := sin(PI * t / sec)
		b[i] = lp * syl * syl * env
	_normalize(b, 0.8)
	return _wav(b)

static func _scream() -> AudioStreamWAV:
	var sec := 1.6
	var b := _buf(sec)
	var ph := 0.0
	var ph2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := lerpf(980.0, 520.0, t / sec) + sin(TAU * 7.0 * t) * 35.0
		ph += f / RATE
		ph2 += f * 1.49 / RATE
		var saw := fmod(ph, 1.0) * 2.0 - 1.0
		var saw2 := fmod(ph2, 1.0) * 2.0 - 1.0
		var env := minf(1.0, t * 30.0) * exp(-t * 1.3)
		b[i] = (saw * 0.5 + saw2 * 0.3 + (randf() * 2.0 - 1.0) * 0.45) * env
	_normalize(b, 0.95)
	return _wav(b)

static func _static() -> AudioStreamWAV:
	var b := _buf(3.0)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (randf() * 2.0 - 1.0 - lp) * 0.6
		var crack := (randf() * 2.0 - 1.0) * 3.0 if randf() < 0.0015 else 0.0
		b[i] = lp * (0.6 + 0.4 * sin(TAU * 0.9 * t)) + crack
	_normalize(b, 0.6)
	return _wav(b, true)

static func _tone(b: PackedFloat32Array, start: float, freq: float, dur: float, amp: float) -> void:
	var s := int(start * RATE)
	var n := int(dur * RATE)
	for j in n:
		var idx := s + j
		if idx >= b.size():
			return
		var d := float(j) / RATE
		b[idx] += (sin(TAU * freq * d) + sin(TAU * freq * 2.76 * d) * 0.25 * exp(-d * 8.0)) * exp(-d * 3.5) * amp

static func _musicbox() -> AudioStreamWAV:
	# Nana desafinada (melodía propia).
	var notes := [76, 79, 81, 79, 76, 74, 76, 0, 72, 74, 76, 74, 71, 69, 71, 0]
	var step := 0.42
	var b := _buf(notes.size() * step + 1.5)
	for k in notes.size():
		var m: int = notes[k]
		if m == 0:
			continue
		var f := 440.0 * pow(2.0, (m - 69) / 12.0) * (1.0 + randf_range(-0.006, 0.006))
		_tone(b, k * step, f, 1.4, 0.5)
	_normalize(b, 0.7)
	return _wav(b, true)

static func _chime() -> AudioStreamWAV:
	var b := _buf(2.2)
	_tone(b, 0.0, 523.25, 2.0, 0.5)
	_tone(b, 0.12, 659.25, 2.0, 0.4)
	_tone(b, 0.24, 783.99, 2.0, 0.35)
	_normalize(b, 0.7)
	return _wav(b)

static func _bell() -> AudioStreamWAV:
	var b := _buf(4.0)
	_tone(b, 0.0, 196.0, 4.0, 0.6)
	_tone(b, 0.0, 196.0 * 2.4, 3.0, 0.25)
	_normalize(b, 0.8)
	return _wav(b)

static func _breath() -> AudioStreamWAV:
	var sec := 2.2
	var b := _buf(sec)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (randf() * 2.0 - 1.0 - lp) * 0.08
		var env := pow(maxf(0.0, sin(PI * t / 1.0)), 2.0) if t < 1.0 else pow(maxf(0.0, sin(PI * (t - 1.1) / 1.1)), 2.0) * 0.8
		b[i] = lp * env
	_normalize(b, 0.7)
	return _wav(b)

static func _wind() -> AudioStreamWAV:
	var sec := 6.0
	var b := _buf(sec)
	var lp := 0.0
	var lp2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := 0.01 + 0.02 * (0.5 + 0.5 * sin(TAU * t / sec * 2.0))
		lp += (randf() * 2.0 - 1.0 - lp) * k
		lp2 += (lp - lp2) * 0.05
		b[i] = lp2
	_normalize(b, 0.5)
	return _wav(b, true)

static func _creak() -> AudioStreamWAV:
	var sec := 1.3
	var b := _buf(sec)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 140.0 + sin(TAU * 1.3 * t) * 60.0 + randf() * 30.0
		ph += f / RATE
		var pulse := 1.0 if fmod(ph, 1.0) < 0.08 else 0.0
		b[i] = pulse * sin(PI * t / sec)
	_normalize(b, 0.5)
	return _wav(b)

static func _laugh() -> AudioStreamWAV:
	var sec := 1.8
	var b := _buf(sec)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 330.0 + sin(TAU * 0.5 * t) * 40.0
		ph += f / RATE
		var hh := maxf(0.0, sin(TAU * 5.0 * t))
		var tri := absf(fmod(ph, 1.0) * 2.0 - 1.0) * 2.0 - 1.0
		b[i] = (tri * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * hh * hh * exp(-t * 1.2)
	_normalize(b, 0.7)
	return _wav(b)


## Vidrio que se rompe: golpe seco y muchos fragmentos que tintinean y caen.
static func _glass_break() -> AudioStreamWAV:
	var b := _buf(1.3)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := randf() * 2.0 - 1.0
		lp += (n - lp) * 0.6
		b[i] = (n - lp) * exp(-t * 18.0) * 1.2 + sin(TAU * 180.0 * t) * exp(-t * 40.0) * 0.6
	for k in 46:
		var t0 := randf() * 0.9 * randf() + 0.01
		var f := randf_range(2600.0, 7800.0)
		var amp := randf_range(0.08, 0.35) * (1.0 - t0)
		var d := randf_range(18.0, 60.0)
		var s0 := int(t0 * RATE)
		for i in range(s0, mini(b.size(), s0 + int(0.25 * RATE))):
			var t := float(i - s0) / RATE
			b[i] += sin(TAU * f * t) * amp * exp(-t * d) + sin(TAU * f * 1.51 * t) * amp * 0.5 * exp(-t * d * 1.4)
	_normalize(b, 0.95)
	return _wav(b)

## Botella que choca con otra sin romperse.
static func _clink() -> AudioStreamWAV:
	var b := _buf(0.5)
	var f := 3100.0
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * f * t) + sin(TAU * f * 2.37 * t) * 0.5 + sin(TAU * f * 0.61 * t) * 0.3) * exp(-t * 11.0)
	_normalize(b, 0.6)
	return _wav(b)

## Mueble de madera que cae o golpea el suelo.
static func _wood_hit() -> AudioStreamWAV:
	var b := _buf(0.6)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (randf() * 2.0 - 1.0 - lp) * 0.18
		b[i] = lp * exp(-t * 22.0) * 1.3 + sin(TAU * (120.0 - t * 40.0) * t) * exp(-t * 14.0) + sin(TAU * 310.0 * t) * exp(-t * 30.0) * 0.4
	_normalize(b, 0.85)
	return _wav(b)
