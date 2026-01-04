"""
Articulation therapy exercise generator
Based on evidence-based speech therapy techniques
"""

# Articulation exercises by phoneme
ARTICULATION_EXERCISES = {
    "r": [
        {
            "level": "isolation",
            "exercise": "Say 'rrrrr' like a lion roaring! Hold it for 3 seconds. 🦁",
            "repetitions": 5
        },
        {
            "level": "syllable",
            "exercise": "Practice: 'ray, ray, ray' - Say it slowly 3 times!",
            "repetitions": 3
        },
        {
            "level": "word",
            "exercise": "Try these words: 'red', 'run', 'rain' - Take your time!",
            "repetitions": 2
        }
    ],
    "s": [
        {
            "level": "isolation",
            "exercise": "Make a snake sound: 'sssss' - Let the air flow! 🐍",
            "repetitions": 5
        },
        {
            "level": "syllable",
            "exercise": "Practice: 'see, see, see' - Smile and say it!",
            "repetitions": 3
        },
        {
            "level": "word",
            "exercise": "Try: 'sun', 'sit', 'sea' - One at a time!",
            "repetitions": 2
        }
    ],
    "th": [
        {
            "level": "isolation",
            "exercise": "Stick your tongue out gently and say 'thhhh'! 👅",
            "repetitions": 5
        },
        {
            "level": "syllable",
            "exercise": "Practice: 'tha, tha, tha' - Tongue peeks out!",
            "repetitions": 3
        },
        {
            "level": "word",
            "exercise": "Try: 'think', 'thank', 'three' - Go slow!",
            "repetitions": 2
        }
    ],
    "l": [
        {
            "level": "isolation",
            "exercise": "Touch the roof of your mouth and say 'llll'! 🎵",
            "repetitions": 5
        },
        {
            "level": "syllable",
            "exercise": "Practice: 'la, la, la' - Tongue up high!",
            "repetitions": 3
        },
        {
            "level": "word",
            "exercise": "Try: 'like', 'let', 'look' - Nice and slow!",
            "repetitions": 2
        }
    ],
    "f": [
        {
            "level": "isolation",
            "exercise": "Gently bite your lip and blow: 'ffff'! 🌬️",
            "repetitions": 5
        },
        {
            "level": "syllable",
            "exercise": "Practice: 'fay, fay, fay' - Feel the air!",
            "repetitions": 3
        },
        {
            "level": "word",
            "exercise": "Try: 'fun', 'find', 'fall' - Take your time!",
            "repetitions": 2
        }
    ]
}

# Breathing and relaxation exercises
BREATHING_EXERCISES = [
    "Take a deep breath in... and blow it out slowly like a candle! 🕯️",
    "Breathe in through your nose, out through your mouth. Nice and easy! 🌬️",
    "Pretend to blow bubbles - take a big breath and blow gently! 🫧"
]

# Coordination exercises
COORDINATION_EXERCISES = [
    "Open your mouth wide like a lion, then close it. Do this 3 times! 🦁",
    "Stick your tongue out, then pull it back in. Try it 5 times! 👅",
    "Smile big, then make a fish face. Back and forth 3 times! 🐠"
]

def generate_exercises(phoneme_scores: list, difficulty_level: str = "beginner") -> list:
    """
    Generate personalized articulation exercises based on performance
    Focuses on sounds that need the most practice
    """
    exercises = []
    
    # Find phonemes that need practice (confidence < 0.75)
    needs_practice = [
        p for p in phoneme_scores 
        if p["confidence"] < 0.75
    ]
    
    # Sort by confidence (lowest first = needs most practice)
    needs_practice.sort(key=lambda x: x["confidence"])
    
    # Add warm-up breathing exercise
    import random
    exercises.append({
        "type": "warmup",
        "title": "Let's Warm Up! 🌟",
        "instruction": random.choice(BREATHING_EXERCISES)
    })
    
    # Generate exercises for each phoneme that needs practice
    for p in needs_practice[:3]:  # Focus on top 3 that need practice
        phoneme = p["phoneme"]
        
        if phoneme in ARTICULATION_EXERCISES:
            phoneme_exercises = ARTICULATION_EXERCISES[phoneme]
            
            # Start with isolation, then syllable, then word level
            for ex in phoneme_exercises:
                exercises.append({
                    "type": "articulation",
                    "phoneme": phoneme,
                    "level": ex["level"],
                    "title": f"Practice the '{phoneme}' sound",
                    "instruction": ex["exercise"],
                    "repetitions": ex["repetitions"]
                })
    
    # Add coordination exercise
    exercises.append({
        "type": "coordination",
        "title": "Mouth Movement Practice! 💪",
        "instruction": random.choice(COORDINATION_EXERCISES)
    })
    
    # If no specific practice needed, give encouragement and challenge
    if not needs_practice:
        exercises = [
            {
                "type": "celebration",
                "title": "You're Amazing! 🌟",
                "instruction": "All your sounds are clear! Try a harder word next level!"
            },
            {
                "type": "challenge",
                "title": "Ready for More? 🚀",
                "instruction": "Try saying your word in a silly sentence!"
            }
        ]
    
    return exercises

def generate_practice_schedule(phoneme: str, sessions_per_week: int = 3) -> dict:
    """
    Generate a weekly practice schedule for a specific phoneme
    Based on speech therapy best practices
    """
    schedule = {
        "phoneme": phoneme,
        "sessions_per_week": sessions_per_week,
        "duration_per_session": "5-10 minutes",
        "weekly_plan": []
    }
    
    if phoneme in ARTICULATION_EXERCISES:
        exercises = ARTICULATION_EXERCISES[phoneme]
        
        for day in range(1, sessions_per_week + 1):
            schedule["weekly_plan"].append({
                "day": day,
                "focus": exercises[min(day - 1, len(exercises) - 1)]["level"],
                "exercises": [ex["exercise"] for ex in exercises]
            })
    
    return schedule

def get_home_practice_tips(phoneme: str) -> list:
    """
    Tips for parents to help at home
    """
    general_tips = [
        "Practice during fun activities like playtime! 🎮",
        "Keep sessions short (5-10 minutes) and positive! ⏰",
        "Praise effort, not just perfection! 🌟",
        "Make silly faces in the mirror together! 🪞",
        "Turn practice into a game with rewards! 🎁"
    ]
    
    phoneme_specific = {
        "r": "Practice 'r' words during car rides - 'red car', 'race', 'road'!",
        "s": "Find 's' words at the store - 'soap', 'salt', 'sandwich'!",
        "th": "Say 'th' words before meals - 'three spoons', 'thank you'!",
        "l": "Sing songs with lots of 'l' sounds - 'la la la'!",
        "f": "Blow bubbles or feathers while practicing 'f' sounds!"
    }
    
    tips = general_tips.copy()
    if phoneme in phoneme_specific:
        tips.insert(0, phoneme_specific[phoneme])
    
    return tips