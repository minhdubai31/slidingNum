"""Prepare the CC0 chess-piece field recording; no synthesized scratch sound.

Source: https://licensing.routenote.com/sound-effect/board-game-wood-piece-slide
Author: Jeff Final Boss. Decode the original MP3 with decode_wood_audio.gd first.
"""
from pathlib import Path
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfiltfilt

ROOT = Path(__file__).resolve().parents[1]
rate, original = wavfile.read(ROOT / "tmp/wood-original.wav")
samples = original.astype(np.float64) / 32768.0
if samples.ndim > 1:
    samples = samples.mean(axis=1)

# Remove rumble and sharp scraping harmonics, retaining the soft wooden friction.
filtered = sosfiltfilt(butter(2, [85, 1900], btype="bandpass", fs=rate, output="sos"), samples)
active = np.flatnonzero(np.abs(filtered) > max(0.001, np.max(np.abs(filtered)) * 0.015))
if len(active):
    filtered = filtered[max(0, active[0] - int(rate * 0.008)):min(len(filtered), active[-1] + int(rate * 0.015))]

def write(name, data, peak):
    data = data.copy()
    fade_in = min(int(rate * 0.012), len(data) // 4)
    fade_out = min(int(rate * 0.045), len(data) // 3)
    data[:fade_in] *= np.sin(np.linspace(0, np.pi / 2, fade_in)) ** 2
    data[-fade_out:] *= np.cos(np.linspace(0, np.pi / 2, fade_out)) ** 2
    data *= peak / max(0.0001, np.max(np.abs(data)))
    wavfile.write(ROOT / "assets/audio" / name, rate, np.round(data * 32767).astype(np.int16))
    print(f"{name}: {len(data) / rate:.3f}s, peak {np.max(np.abs(data)):.3f}")

write("wood-slide-soft.wav", filtered, 0.30)
# A tiny rounded contact from the same wooden recording, softer than UI clicks.
energy = np.convolve(filtered ** 2, np.ones(int(rate * 0.025)), mode="same")
center = int(np.argmax(energy))
contact = filtered[max(0, center - int(rate * 0.018)):center + int(rate * 0.075)]
contact = sosfiltfilt(butter(2, 1400, fs=rate, output="sos"), contact)
write("wood-place-soft.wav", contact, 0.23)
