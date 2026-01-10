"""
Responsible AI Ethics for SpeakBright - UPDATED
Aligns with articulation therapy best practices
No harming, judging, excluding or exploiting children
"""

# Confidence thresholds (adjusted per your description)
CONFIDENCE_FLOOR = 0.50  # Below this, give ONLY neutral encouragement
HIGH_CONFIDENCE_THRESHOLD = 0.75  # Above this, can give specific corrective feedback

# Responsible AI Principles - exactly as you described
PRINCIPLES = {
    "no_harsh_feedback": "We never use words like 'wrong' or 'bad'",
    "encourage_effort": "We celebrate trying, not just perfection", 
    "explain_gently": "We show HOW to improve, not what's 'wrong'",
    "privacy_first": "Audio is deleted immediately after processing",
    "progress_based": "We compare to the child's own progress, not others",
    "accent_neutral": "We don't penalize regional accents or dialects",
    "age_appropriate": "All language is child-friendly and encouraging",
    "no_red_marks": "No red marks, penalties, or repeated failure screens",
    "focus_on_improvement": "Target improvement and effort, not absolute perfection"
}

def is_feedback_safe(confidence: float) -> bool:
    """
    Determine if we can give specific corrective feedback
    
    Per your requirements:
    - Low confidence = neutral encouragement ONLY
    - High confidence = gentle articulation guidance
    """
    return confidence >= CONFIDENCE_FLOOR


def should_give_corrective_feedback(confidence: float) -> bool:
    """
    Only give specific articulation tips if confidence is high enough
    Otherwise, just encourage and try again
    
    This prevents misleading feedback when the AI isn't confident
    """
    return confidence >= HIGH_CONFIDENCE_THRESHOLD


def get_encouragement_level(confidence: float) -> str:
    """
    Determine what type of encouragement to give
    
    Categories align with your feedback structure:
    - excellent: Strong praise (85%+)
    - good: Positive reinforcement (75-85%)
    - try_again: Gentle encouragement to practice (60-75%)
    - neutral: General encouragement only (<60%)
    """
    if confidence >= 0.85:
        return "excellent"
    elif confidence >= 0.75:
        return "good"
    elif confidence >= 0.60:
        return "try_again"
    else:
        return "neutral"


def is_dialect_variation(phoneme: str, detected: str) -> bool:
    """
    Check if detected pronunciation is an acceptable dialect variation
    
    Per your requirement: "No penalties for accents or dialects"
    
    Common acceptable variations based on linguistics research:
    - "th" → "d" or "t" in some dialects (e.g., African American Vernacular English)
    - "r" variations (many regional differences)
    - "-ing" → "-in" (common informal speech)
    """
    dialect_variations = {
        "th": ["d", "t"],
        "r": ["w", "ah"],
        "ing": ["in"],
    }
    
    phoneme_lower = phoneme.lower()
    if phoneme_lower in dialect_variations:
        return detected.lower() in dialect_variations[phoneme_lower]
    
    return False


def ensure_child_safety(feedback: dict) -> dict:
    """
    Final safety check on all feedback before sending to child
    
    Per your principles:
    - Remove any harsh language
    - Ensure encouraging tone
    - Replace negative words with positive alternatives
    
    This is the LAST LINE OF DEFENSE before content reaches children
    """
    # Banned words/phrases that should NEVER appear in child feedback
    banned_replacements = {
        "wrong": "let's practice",
        "bad": "needs practice",
        "incorrect": "let's try",
        "failed": "learning",
        "poor": "developing",
        "terrible": "growing",
        "error": "learning opportunity",
        "mistake": "practice opportunity",
        "can't": "learning to",
        "unable": "working on"
    }
    
    # Check all text fields recursively
    for key, value in feedback.items():
        if isinstance(value, str):
            value_lower = value.lower()
            for banned, replacement in banned_replacements.items():
                if banned in value_lower:
                    # Case-insensitive replacement
                    import re
                    pattern = re.compile(re.escape(banned), re.IGNORECASE)
                    feedback[key] = pattern.sub(replacement, value)
                    print(f"[SAFETY] Replaced '{banned}' with '{replacement}' in feedback")
        
        elif isinstance(value, dict):
            feedback[key] = ensure_child_safety(value)
        
        elif isinstance(value, list):
            feedback[key] = [
                ensure_child_safety(item) if isinstance(item, dict) else item 
                for item in value
            ]
    
    return feedback


def validate_no_harsh_language(text: str) -> bool:
    """
    Validate that text contains no harsh language
    Returns True if safe, False if contains banned words
    """
    banned_words = ["wrong", "bad", "incorrect", "failed", "poor", "terrible", 
                    "error", "mistake", "penalty", "punishment"]
    
    text_lower = text.lower()
    for word in banned_words:
        if word in text_lower:
            return False
    
    return True


# Privacy compliance - exactly as you specified
PRIVACY_RULES = {
    "audio_retention": "0 seconds - immediate deletion",
    "score_retention_days": 90,
    "pii_stored": False,
    "coppa_compliant": True,
    "gdpr_data_minimization": True,
    "what_we_store": "Only abstract scores for progress tracking",
    "what_we_delete": "Audio is processed temporarily and deleted immediately"
}


def log_privacy_compliance(action: str):
    """
    Log privacy-compliant actions for audit trail
    Critical for COPPA & GDPR compliance
    """
    from datetime import datetime
    timestamp = datetime.now().isoformat()
    print(f"[PRIVACY - {timestamp}] {action}")


def get_privacy_statement() -> str:
    """
    Get privacy statement to show parents/users
    Transparency is key for trust
    """
    return """
🔒 Your Child's Privacy is Protected:
• Audio recordings are NEVER stored
• Only abstract practice scores are saved
• No personal information is collected
• COPPA & GDPR compliant
• Full transparency in how we use data
    """.strip()


# Therapy approach principles - aligned with articulation therapy
THERAPY_APPROACH = {
    "focus": "Articulation therapy (speech sound production)",
    "method": "Evidence-based speech therapy techniques",
    "progression": "Isolation → Syllable → Word → Sentence",
    "individualized": "Exercises adapt to each child's needs",
    "compare_to_self": "Progress measured against child's own baseline, NOT absolute standards",
    "practice_philosophy": "5-10 minutes sessions, focused on FUN and positive reinforcement"
}


def get_therapy_explanation() -> dict:
    """
    Get explanation of our therapy approach for parents/educators
    """
    return {
        "what_is_articulation_therapy": (
            "Articulation therapy focuses on improving the clarity and accuracy "
            "of speech sounds. It targets mispronunciation or difficulty in "
            "producing specific speech sounds."
        ),
        "how_it_works": (
            "Children learn to coordinate their articulators (lips, tongue, jaw) "
            "through structured practice. We start with sounds in isolation, "
            "then move to syllables, words, and finally sentences."
        ),
        "our_approach": THERAPY_APPROACH,
        "what_makes_us_different": (
            "We use AI to provide immediate, gentle feedback while maintaining "
            "all the principles of professional speech therapy. Your child's "
            "progress is compared only to their own previous attempts, never "
            "to other children or arbitrary standards."
        )
    }


# Reward system psychology - as you specified
REWARD_PRINCIPLES = {
    "personal_progress": "Scoring based on personal progress, not fixed standard",
    "compare_to_self": "Based on what the child did before, not absolute standards",
    "celebrate_effort": "Reward trying and practicing, not just perfection",
    "no_penalties": "No penalties for accents, dialects, or natural variation",
    "positive_reinforcement": "Every session ends with encouragement and celebration",
    "growth_mindset": "Emphasize learning and improvement over innate ability"
}


def calculate_personal_progress_score(
    current_confidence: float,
    previous_average: float
) -> tuple[str, str]:
    """
    Calculate progress relative to child's own baseline
    
    Per your requirement: "Progress measured against child's own baseline"
    
    Returns (status, message) tuple
    """
    if previous_average is None:
        return ("first_attempt", "Great job trying something new! 🌟")
    
    improvement = current_confidence - previous_average
    
    if improvement >= 0.10:
        return ("great_improvement", "Wow! You've improved so much! 🎉")
    elif improvement >= 0.05:
        return ("good_improvement", "You're getting better! Keep it up! ⭐")
    elif improvement >= 0:
        return ("slight_improvement", "Nice work! You're making progress! 💪")
    elif improvement >= -0.05:
        return ("consistent", "You're staying strong! Great job! 👏")
    else:
        # Even if slight regression, stay positive
        return ("keep_practicing", "Keep practicing! You've got this! 🌈")


# Testing/validation
if __name__ == "__main__":
    print("Responsible AI Ethics Module - SpeakBright")
    print("=" * 60)
    print("\nPrinciples:")
    for key, value in PRINCIPLES.items():
        print(f"  ✓ {key}: {value}")
    
    print("\nPrivacy Rules:")
    for key, value in PRIVACY_RULES.items():
        print(f"  🔒 {key}: {value}")
    
    print("\nTherapy Approach:")
    for key, value in THERAPY_APPROACH.items():
        print(f"  📚 {key}: {value}")
    
    # Test safety check
    print("\n" + "=" * 60)
    print("Testing safety checks...")
    
    test_feedback = {
        "message": "Wrong sound detected",
        "tip": "Your pronunciation is bad"
    }
    
    print(f"Before: {test_feedback}")
    safe_feedback = ensure_child_safety(test_feedback)
    print(f"After: {safe_feedback}")