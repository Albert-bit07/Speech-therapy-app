CONFIDENCE_FLOOR = 0.6

def is_feedback_safe(confidence):
    return confidence >= CONFIDENCE_FLOOR
 
