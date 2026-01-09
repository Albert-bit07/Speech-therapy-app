"""
Child-friendly feedback generator for speech therapy - UPDATED
Uses your exact phrasing and encouraging language
"""
from services.ethics import (
    should_give_corrective_feedback,
    get_encouragement_level,
    ensure_child_safety,
    validate_no_harsh_language
)
import random

# General encouragement phrases - EXACTLY as you specified
GENERAL_ENCOURAGEMENT = [
    "Nice try! I love how hard you're working! 🌟",
    "Great effort! Let's keep going together! 💪",
    "You're learning—that's so cool! 🎉",
    "Every try helps your voice get stronger! 🦸",
]

# Additional supportive phrases
ADDITIONAL_ENCOURAGEMENT = [
    "Wow, you're doing awesome! Keep it up! ⭐",
    "I can see you trying really hard! That's amazing! 🌈",
    "You're being so brave! I'm proud of you! 🌟",
    "Keep going! You're learning something new! 🚀"
]

# When a sound needs practice - EXACTLY your phrases
PRACTICE_ENCOURAGEMENT = {
    "gentle_start": [
        "That was a great start! Let's practice one sound together. 🎯",
        "Nice job! We can help that sound sound even clearer. ✨",
    ],
    "specific_sound": {
        "r": "Almost there! Let's make the 'r' sound a little stronger. 🦁",
        "s": "Nice job! We can help the 's' sound sound even clearer. 🐍",
        "th": "That was a great start! Let's practice the 'th' sound together. 👅",
        "l": "Great job! Let's make the 'l' sound a bit clearer. 🎵",
        "f": "Nice try! Let's work on the 'f' sound together. 🌬️",
        "v": "Good effort! Let's practice the 'v' sound. 🐝",
        "default": "Let's practice that sound together! You've got this! 💫"
    }
}

# Articulation Guidance - EXACTLY your phrases with explanations
ARTICULATION_TIPS = {
    "r": {
        "visual_cue": "🛝",
        "tip": "Try curling your tongue back like a little slide! 🛝",
        "alternative": "Let your tongue hide a bit inside your mouth.",
        "mouth_position": "tongue_back",
        "explanation": "The R sound needs your tongue to curl back"
    },
    "s": {
        "visual_cue": "🐍",
        "tip": "Smile a little and push the air forward like a snake! 🐍",
        "alternative": "Let the air flow straight out.",
        "mouth_position": "teeth_together",
        "explanation": "The S sound is made by pushing air through your teeth"
    },
    "th": {
        "visual_cue": "👅",
        "tip": "Gently peek your tongue between your teeth! 👅",
        "alternative": "Let your tongue say hello!",
        "mouth_position": "tongue_between_teeth",
        "explanation": "The TH sound needs your tongue to peek out"
    },
    "l": {
        "visual_cue": "🎵",
        "tip": "Touch the top of your mouth with your tongue tip! 🎵",
        "alternative": "Your tongue wants to touch the ceiling!",
        "mouth_position": "tongue_to_roof",
        "explanation": "The L sound is made by touching the roof of your mouth"
    },
    "f": {
        "visual_cue": "🌬️",
        "tip": "Gently bite your bottom lip and blow air! 🌬️",
        "alternative": "Your top teeth touch your bottom lip softly.",
        "mouth_position": "teeth_on_lip",
        "explanation": "The F sound is made by blowing air over your lip"
    },
    "v": {
        "visual_cue": "🐝",
        "tip": "Just like 'f' but make your voice buzz like a bee! 🐝",
        "alternative": "Your voice box makes a humming sound!",
        "mouth_position": "teeth_on_lip",
        "explanation": "The V sound is like F, but your voice buzzes"
    },
    # Add more sounds as needed
    "b": {
        "visual_cue": "💥",
        "tip": "Put your lips together and pop them open!",
        "alternative": "Make a little explosion with your lips!",
        "mouth_position": "lips_together",
        "explanation": "The B sound starts with closed lips"
    },
    "p": {
        "visual_cue": "🎈",
        "tip": "Close your lips and blow out air!",
        "alternative": "Pop your lips like a bubble!",
        "mouth_position": "lips_together",
        "explanation": "The P sound is a quiet lip pop"
    }
}


def get_encouragement_message(confidence: float, phoneme: str = None) -> str:
    """
    Generate age-appropriate encouragement based on performance
    Uses your exact phrasing structure
    """
    level = get_encouragement_level(confidence)
    
    if level == "excellent":
        # Strong praise for high performance
        if phoneme:
            return f"Fantastic! Your '{phoneme}' sound is so clear! 🌟"
        return random.choice([
            "Amazing work! You're a superstar! ⭐",
            "Perfect! You nailed it! 🎯",
            "Wow! That was excellent! 🎉"
        ])
    
    elif level == "good":
        # Positive reinforcement
        if phoneme:
            return f"Great job on the '{phoneme}' sound! You're doing awesome! 🎉"
        return random.choice([
            "Really good work! Keep it up! 💪",
            "You're doing so well! Proud of you! 🌟",
            "Nice job! You're making progress! ⭐"
        ])
    
    elif level == "try_again" and phoneme:
        # Gentle guidance for sounds that need practice
        return PRACTICE_ENCOURAGEMENT["specific_sound"].get(
            phoneme,
            PRACTICE_ENCOURAGEMENT["specific_sound"]["default"]
        )
    
    else:
        # Neutral encouragement - no specifics, just support
        return random.choice(GENERAL_ENCOURAGEMENT + ADDITIONAL_ENCOURAGEMENT)


def generate_feedback(phoneme_scores: list) -> list:
    """
    Generate child-friendly feedback for each phoneme
    
    Per your requirements:
    - AI gives corrective feedback ONLY if confidence is high
    - Low confidence = neutral encouragement only
    - No harsh language
    - Focus on encouragement and gentle guidance
    """
    feedback = []
    
    for p in phoneme_scores:
        phoneme = p["phoneme"]
        confidence = p["confidence"]
        
        # Determine feedback type based on confidence level
        if should_give_corrective_feedback(confidence):
            # HIGH confidence - we can give specific articulation tips
            tip_data = ARTICULATION_TIPS.get(phoneme, {})
            tip = tip_data.get("tip", "Let's practice this sound together!")
            visual_cue = tip_data.get("visual_cue", "🎯")
            mouth_position = tip_data.get("mouth_position", "neutral")
            explanation = tip_data.get("explanation", "")
        else:
            # LOW confidence - ONLY neutral encouragement, no specifics
            tip = get_encouragement_message(confidence)
            visual_cue = "✨"
            mouth_position = "neutral"
            explanation = "Keep practicing! You're doing great!"
        
        # Build feedback object
        feedback_item = {
            "phoneme": phoneme,
            "expected": p["expected"],
            "confidence": round(confidence, 2),
            "tip": tip,
            "visual_cue": visual_cue,
            "mouth_position": mouth_position,
            "needs_practice": confidence < 0.75,
            "encouragement": get_encouragement_message(confidence, phoneme),
            "show_specific_guidance": should_give_corrective_feedback(confidence)
        }
        
        # Add explanation only for high-confidence corrections
        if should_give_corrective_feedback(confidence) and phoneme in ARTICULATION_TIPS:
            feedback_item["explanation"] = ARTICULATION_TIPS[phoneme].get("explanation", "")
        
        feedback.append(feedback_item)
    
    # Final safety check - remove any harsh language that slipped through
    feedback = [ensure_child_safety(f) for f in feedback]
    
    # Validate all feedback is child-safe
    for f in feedback:
        for key, value in f.items():
            if isinstance(value, str):
                if not validate_no_harsh_language(value):
                    print(f"[WARNING] Potentially harsh language detected in: {value}")
    
    return feedback


def generate_overall_encouragement(overall_score: int) -> str:
    """
    Generate overall encouraging message based on session performance
    Always positive, never discouraging
    """
    if overall_score >= 85:
        return "Wow! You're a superstar! Your voice is getting so strong! 🌟✨"
    elif overall_score >= 75:
        return "Great work today! You're making amazing progress! 🎉💪"
    elif overall_score >= 60:
        return "Nice job practicing! Every try makes you better! 🌈⭐"
    else:
        # Even for lower scores, stay VERY positive
        return "I love seeing you try! You're learning so much! Keep going! 🚀💫"


def get_celebration_message(improved_phonemes: list) -> str:
    """
    Celebrate specific improvements
    Per your requirement: "Reward system based on personal progress"
    """
    if not improved_phonemes:
        return "Keep practicing—you're doing great! 🌟"
    
    if len(improved_phonemes) == 1:
        return f"Your '{improved_phonemes[0]}' sound got even better! Amazing! 🎉"
    elif len(improved_phonemes) == 2:
        return f"Your '{improved_phonemes[0]}' and '{improved_phonemes[1]}' sounds improved! Wow! 🌈✨"
    else:
        phoneme_list = "', '".join(improved_phonemes[:-1])
        return f"Your '{phoneme_list}' and '{improved_phonemes[-1]}' sounds improved! You're on fire! 🔥🎊"


def generate_session_summary(
    overall_score: int,
    improved_phonemes: list,
    total_sessions: int,
    is_first_session: bool = False
) -> dict:
    """
    Generate encouraging session summary
    Focuses on growth and effort, not just score
    """
    if is_first_session:
        return {
            "title": "Welcome to SpeakBright! 🌟",
            "message": "You did amazing for your first try! Every practice makes you stronger!",
            "next_steps": "Keep coming back to practice. You're going to do great things!",
            "encouragement": generate_overall_encouragement(overall_score)
        }
    
    celebration = get_celebration_message(improved_phonemes) if improved_phonemes else None
    
    return {
        "title": f"Session #{total_sessions} Complete! 🎉",
        "message": generate_overall_encouragement(overall_score),
        "celebration": celebration,
        "next_steps": "Keep practicing! The more you try, the better you get!",
        "sessions_completed": total_sessions,
        "growth_message": "Look how much you've practiced! That's amazing! 💪"
    }


# Testing
if __name__ == "__main__":
    print("Feedback Generator - Child-Friendly Edition")
    print("=" * 60)
    
    # Test with different confidence levels
    test_scores = [
        {"phoneme": "r", "expected": "r", "confidence": 0.55},  # Low - neutral only
        {"phoneme": "s", "expected": "s", "confidence": 0.85},  # High - specific tips
        {"phoneme": "th", "expected": "th", "confidence": 0.92}, # Excellent
    ]
    
    feedback = generate_feedback(test_scores)
    
    for f in feedback:
        print(f"\nPhoneme: {f['phoneme']}")
        print(f"Confidence: {f['confidence']}")
        print(f"Tip: {f['tip']}")
        print(f"Encouragement: {f['encouragement']}")
        print(f"Show specific guidance: {f['show_specific_guidance']}")