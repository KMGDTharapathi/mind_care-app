import wave
import struct
import math

def write_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'wb') as wf:
        wf.setnchannels(1)  # mono
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)
        for s in samples:
            wf.writeframes(struct.pack('<h', int(s * 32767)))

def generate_tone(freq, duration, sample_rate=44100, volume=0.3, fade_out=True):
    """Generate a sine wave tone."""
    n = int(sample_rate * duration)
    samples = []
    for i in range(n):
        t = i / sample_rate
        sample = volume * math.sin(2 * math.pi * freq * t)
        if fade_out:
            # Apply exponential fade out
            fade = math.exp(-5 * t / duration)
            sample *= fade
        samples.append(sample)
    return samples

def generate_chime():
    """Generate a gentle two-tone chime for step transitions."""
    # First tone: C5 (523.25 Hz)
    tone1 = generate_tone(523.25, 0.4, volume=0.4)
    # Small gap
    gap = [0.0] * int(44100 * 0.1)
    # Second tone: E5 (659.25 Hz)
    tone2 = generate_tone(659.25, 0.5, volume=0.35)
    return tone1 + gap + tone2

def generate_finish_chime():
    """Generate a three-tone ascending chime for meditation completion."""
    tones = [
        (523.25, 0.35),  # C5
        (659.25, 0.35),  # E5
        (783.99, 0.5),   # G5
    ]
    samples = []
    for i, (freq, dur) in enumerate(tones):
        samples.extend(generate_tone(freq, dur, volume=0.4 if i < 2 else 0.35))
        if i < len(tones) - 1:
            samples.extend([0.0] * int(44100 * 0.08))
    return samples

# Generate the files
chime_samples = generate_chime()
finish_samples = generate_finish_chime()

write_wav('assets/audio/step_chime.wav', chime_samples)
write_wav('assets/audio/finish_chime.wav', finish_samples)

print('Generated step_chime.wav ({:.2f}s)'.format(len(chime_samples)/44100))
print('Generated finish_chime.wav ({:.2f}s)'.format(len(finish_samples)/44100))