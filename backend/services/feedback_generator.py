def generate_feedback(phoneme_scores):
    feedback = []

    for p in phoneme_scores:
        if p["confidence"] < 0.75:
            tip = f"Try slowing down when saying the '{p['phoneme']}' sound."
        else:
            tip = f"Nice job on the '{p['phoneme']}' sound!"

        feedback.append({
            "phoneme": p["phoneme"],
            "expected": p["expected"],
            "confidence": p["confidence"],
            "tip": tip
        })

    return feedback
 
