def generate_exercises(phoneme_scores):
    exercises = []

    for p in phoneme_scores:
        if p["confidence"] < 0.75:
            exercises.append(
                f"Repeat the '{p['phoneme']}' sound slowly 3 times."
            )

    if not exercises:
        exercises.append("Try a harder word next level!")

    return exercises
 
