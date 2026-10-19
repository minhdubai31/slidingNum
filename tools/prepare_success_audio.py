"""Make a short success cadence from Kenney's CC0 confirmation_001.wav.
No new instrument synthesis; soft fades and three rising copies of the source.
Run: python3 tools/prepare_success_audio.py
"""
from array import array
from pathlib import Path
import math
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]

def build():
    with wave.open(str(ROOT / 'assets/audio/confirmation_001.wav'), 'rb') as stream:
        assert stream.getsampwidth() == 2 and stream.getnchannels() == 1
        rate = stream.getframerate()
        source = array('h', stream.readframes(stream.getnframes()))
    if sys.byteorder != 'little':
        source.byteswap()
    result = [0.0] * int(rate * 1.0)
    for offset, pitch, gain in [(0, .90, .65), (.19, 1.0, .72), (.39, 1.15, .82)]:
        length = int((len(source) - 1) / pitch)
        for i in range(length):
            position = i * pitch
            j = int(position)
            v = source[j] + (source[j + 1] - source[j]) * (position - j)
            fade = min(1, i / (rate * .006), (length - 1 - i) / (rate * .025))
            result[int(offset * rate) + i] += v * gain * fade
    gain = .50 * 32767 / max(1, max(map(abs, result)))
    pcm = array('h', [round(v * gain) for v in result])
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(ROOT / 'assets/audio/success-soft.wav'), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(rate)
        stream.writeframes(pcm.tobytes())

if __name__ == '__main__':
    build()
