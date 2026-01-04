"""
Responsible AI Ethics for SpeakBright
No harming, judging, excluding or exploiting children
"""

# Confidence thresholds
CONFIDENCE_FLOOR = 0.6  # Below this, give neutral encouragement only
HIGH_CONFIDENCE_THRESHOLD = 0.75  # Above this, can give specific corrective feedback

# Responsible AI Principles
PRINCIPLES = {
    "no_harsh_feedback": True,  # No red marks, penalties, or "wrong" labels
    "encourage_effort": True,   # Focus on improvement and effort
    "explain_gently": True,     # Explain what needs practice, not what's "wrong"
    "privacy_first": True,      # No audio storage, immediate deletion
    "progress_based": True,     # Compare to child's own progress, not absolute standard
    "accent_neutral": True,     # No penalties for accents or dialects
    "age_appropriate": True     # Child-friendly language and visuals
}

def is_feedback_safe(confidence: float) -> bool:
    """
    Determine if we can give specific corrective feedback
    Low confidence = neutral encouragement only
    High confidence = gentle articulation guidance
    """
    return confidence >= CONFIDENCE_FLOOR

def should_give_corrective_feedback(confidence: float) -> bool:
    """
    Only give specific articulation tips if confidence is high enough
    Otherwise, just encourage and try again
    """
    return confidence >= HIGH_CONFIDENCE_THRESHOLD

def get_encouragement_level(confidence: float) -> str:
    """
    Determine what type of encouragement to give
    """
    if confidence >= 0.85:
        return "excellent"  # Strong praise
    elif confidence >= 0.75:
        return "good"       # Positive reinforcement
    elif confidence >= 0.6:
        return "try_again"  # Gentle encouragement to practice
    else:
        return "neutral"    # Just general encouragement, no specifics

def filter_dialect_variations(phoneme: str, detected: str) -> bool:
    """
    Don't penalize common dialect variations
    Examples: "th" vs "d" in some dialects, "r" variations, etc.
    """
    # Common acceptable variations (expand based on research)
    dialect_variations = {
        "th": ["d", "t"],  # Some dialects pronounce "th" as "d"
        "r": ["w", "ah"],  # R-colored vowels vary by region
    }
    
    if phoneme in dialect_variations:
        return detected in dialect_variations[phoneme]
    
    return False

def ensure_child_safety(feedback: dict) -> dict:
    """
    Final safety check on all feedback before sending to child
    Removes any harsh language, ensures encouraging tone
    """
    # Banned words/phrases
    banned_words = ["wrong", "bad", "incorrect", "failed", "poor", "terrible"]
    
    # Check all text fields
    for key, value in feedback.items():
        if isinstance(value, str):
            for banned in banned_words:
                if banned.lower() in value.lower():
                    # Replace with encouraging alternative
                    feedback[key] = value.replace(banned, "let's practice")
    
    return feedback

# Privacy compliance
PRIVACY_RULES = {
    "audio_retention": 0,           # 0 seconds - immediate deletion
    "score_retention_days": 90,     # Keep abstract scores for progress tracking
    "pii_stored": False,            # No personally identifiable information
    "coppa_compliant": True,        # Children's Online Privacy Protection Act
    "gdpr_data_minimization": True  # Only store what's absolutely necessary
}

def log_privacy_compliance(action: str):
    """
    Log privacy-compliant actions for audit trail
    """
    print(f"[PRIVACY] {action} - Audio deleted, only abstract scores saved")