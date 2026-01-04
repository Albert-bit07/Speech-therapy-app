"""
Child-friendly feedback generator for speech therapy
Uses encouraging language and gentle articulation guidance
"""
from services.ethics import (
    should_give_corrective_feedback,
    get_encouragement_level,
    ensure_child_safety
)

# General encouragement phrases (when we can't give specific feedback)
GENERAL_ENCOURAGEMENT = [
    "Nice try! I love how hard you're working! 🌟",
    "Great effort! Let's keep going together! 💪",
    "You're learning—that's so cool! 🎉",
    "Every try helps your voice get stronger! 🦸",
    "Wow, you're doing awesome! Keep it up! ⭐",
    "I can see you trying really hard! That's amazing! 🌈"
]

# Encouragement when a sound needs practice
PRACTICE_ENCOURAGEMENT = {
    "gentle_start": [
        "That was a great start! Let's practice one sound together. 🎯",
        "Nice job! We can help that sound sound even clearer. ✨",
        "You're so close! Let's try that sound one more time. 🎪"
    ],
    "specific_sound": {
        "r": "Almost there! Let's make the 'r' sound a little stronger. 🦁",
        "s": "Great try! Let's help the 's' sound sound even clearer. 🐍",
        "th": "Nice work! Let's practice the 'th' sound together. 👅",
        "l": "Good job! Let's make the 'l' sound a bit clearer. 🎵",
        "f": "Awesome effort! Let's work on the 'f' sound. 🌬️",
        "default": "Let's practice that sound together! You've got this! 💫"
    }
}

# Articulation guidance - Explainable & Gentle
ARTICULATION_TIPS = {
    "r": {
        "visual_cue": "🛝",
        "tip": "Try curling your tongue back like a little slide!",
        "alternative": "Let your tongue hide a bit inside your mouth.",
        "mouth_position": "tongue_back"
    },
    "s": {
        "visual_cue": "🐍",
        "tip": "Smile a little and push the air forward like a snake!",
        "alternative": "Let the air flow straight out.",
        "mouth_position": "teeth_together"
    },
    "th": {
        "visual_cue": "👅",
        "tip": "Gently peek your tongue between your teeth!",
        "alternative": "Let your tongue say hello!",
        "mouth_position": "tongue_between_teeth"
    },
    "l": {
        "visual_cue": "🎵",
        "tip": "Touch the top of your mouth with your tongue tip!",
        "alternative": "Your tongue wants to touch the ceiling!",
        "mouth_position": "tongue_to_roof"
    },
    "f": {
        "visual_cue": "🌬️",
        "tip": "Gently bite your bottom lip and blow air!",
        "alternative": "Your top teeth touch your bottom lip softly.",
        "mouth_position": "teeth_on_lip"
    },
    "v": {
        "visual_cue": "🐝",
        "tip": "Just like 'f' but make your voice buzz like a bee!",
        "alternative": "Your voice box makes a humming sound!",
        "mouth_position": "teeth_on_lip"
    }
}

def get_encouragement_message(confidence: float, phoneme: str = None) -> str:
    """
    Generate age-appropriate encouragement based on performance
    """
    level = get_encouragement_level(confidence)
    
    if level == "excellent":
        return f"Fantastic! Your '{phoneme}' sound is so clear! 🌟"
    elif level == "good":
        return f"Great job on the '{phoneme}' sound! You're doing awesome! 🎉"
    elif level == "try_again" and phoneme:
        return PRACTICE_ENCOURAGEMENT["specific_sound"].get(
            phoneme,
            PRACTICE_ENCOURAGEMENT["specific_sound"]["default"]
        )
    else:
        import random
        return random.choice(GENERAL_ENCOURAGEMENT)

def generate_feedback(phoneme_scores: list) -> list:
    """
    Generate child-friendly feedback for each phoneme
    No harsh language - focus on encouragement and gentle guidance
    """
    feedback = []
    
    for p in phoneme_scores:
        phoneme = p["phoneme"]
        confidence = p["confidence"]
        
        # Determine feedback type based on confidence
        if should_give_corrective_feedback(confidence):
            # High confidence - we can give specific articulation tips
            tip_data = ARTICULATION_TIPS.get(phoneme, {})
            tip = tip_data.get("tip", "Let's practice this sound together!")
            visual_cue = tip_data.get("visual_cue", "🎯")
            mouth_position = tip_data.get("mouth_position", "default")
        else:
            # Low confidence - just encourage, no specifics
            tip = get_encouragement_message(confidence, phoneme)
            visual_cue = "✨"
            mouth_position = "neutral"
        
        feedback.append({
            "phoneme": phoneme,
            "expected": p["expected"],
            "confidence": round(confidence, 2),
            "tip": tip,
            "visual_cue": visual_cue,
            "mouth_position": mouth_position,
            "needs_practice": confidence < 0.75,
            "encouragement": get_encouragement_message(confidence, phoneme)
        })
    
    # Final safety check - remove any harsh language
    feedback = [ensure_child_safety(f) for f in feedback]
    
    return feedback

def generate_overall_encouragement(overall_score: int) -> str:
    """
    Generate overall encouraging message based on session performance
    """
    if overall_score >= 85:
        return "Wow! You're a superstar! Your voice is getting so strong! 🌟✨"
    elif overall_score >= 75:
        return "Great work today! You're making amazing progress! 🎉💪"
    elif overall_score >= 60:
        return "Nice job practicing! Every try makes you better! 🌈⭐"
    else:
        return "I love seeing you try! You're learning so much! Keep going! 🚀💫"

def get_celebration_message(improved_phonemes: list) -> str:
    """
    Celebrate specific improvements
    """
    if not improved_phonemes:
        return "Keep practicing—you're doing great! 🌟"
    
    if len(improved_phonemes) == 1:
        return f"Your '{improved_phonemes[0]}' sound got even better! Amazing! 🎉"
    else:
        phoneme_list = "', '".join(improved_phonemes[:-1])
        return f"Your '{phoneme_list}' and '{improved_phonemes[-1]}' sounds improved! Wow! 🌈✨"