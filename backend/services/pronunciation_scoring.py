import random

# Simplified phoneme map (demo-friendly)
PHONEMES = {
    "butterfly": ["b", "uh", "t", "er", "f", "l", "ai"]
}

def score_pronunciation(audio, sr, target_word):
    phonemes = PHONEMES.get(target_word, [])
    results = []

    for ph in phonemes:
        confidence = round(random.uniform(0.6, 0.95), 2)

        results.append({
            "phoneme": ph,
            "expected": ph,
            "confidence": confidence
        })

    return results
 
