# Yoga & Diet AI Agent Backend

Advanced AI-powered wellness platform backend combining yoga and diet planning.

## Features

### 🧘 Yoga Planning (KIMI 2)
- **AI-Powered Session Generation**: Personalized yoga sessions using Moonshot AI's KIMI 2 model
- **Multiple Yoga Styles**: Hatha, Vinyasa, Ashtanga, Bikram, Yin, Restorative, Power, Kundalini
- **Difficulty Levels**: Beginner to Expert with adaptive progression
- **Comprehensive Sessions**: Includes warm-up, main sequence, and cool-down
- **Progress Tracking**: Track sessions, minutes practiced, calories burned, and poses mastered
- **Pose Library**: Extensive library with instructions, benefits, and precautions
- **AI Analysis**: Progress analysis and personalized recommendations

### 🍽️ Diet Planning (LLAMA 3.2)
- **AI Meal Planning**: Generate 1-30 day meal plans using Meta's LLAMA 3.2
- **Diet Types**: Balanced, Vegan, Vegetarian, Keto, Paleo, Mediterranean, Low-Carb, High-Protein
- **Nutrition Optimization**: Calorie and macro (protein/carbs/fat) optimization
- **Recipe Generation**: Detailed recipes with ingredients and step-by-step instructions
- **Dietary Restrictions**: Support for allergies and food preferences
- **Shopping Lists**: Auto-generated categorized shopping lists
- **Progress Tracking**: Daily nutrition logging and weight tracking
- **AI Analysis**: Nutrition pattern analysis and recommendations

### 📊 Analytics
- **Comprehensive Tracking**: Combined yoga and diet progress
- **Trend Analysis**: Identify patterns and improvements
- **Dashboard**: Today's stats, weekly summaries, and streaks
- **AI Insights**: Actionable recommendations based on your data

## Technology Stack

- **FastAPI**: Modern, fast web framework
- **SQLAlchemy**: ORM with async support
- **SQLite**: Lightweight database (easily upgradeable to PostgreSQL)
- **KIMI 2 API**: Moonshot AI for yoga planning
- **LLAMA 3.2 API**: Meta AI for diet planning
- **Pydantic**: Data validation
- **httpx**: Async HTTP client

## Setup

### Prerequisites

- Python 3.9+
- pip

### Installation

1. Install dependencies:
```bash
cd Backend
pip install -r requirements.txt
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env and add your API keys
```

3. Required API Keys:

**KIMI 2 (Moonshot AI)**:
- Sign up at https://platform.moonshot.cn/
- Get your API key
- Add to `.env`: `KIMI_API_KEY=your_key_here`

**LLAMA 3.2**:
- Option 1: Together AI (https://api.together.xyz/)
- Option 2: Groq (https://groq.com/)
- Option 3: Replicate (https://replicate.com/)
- Add to `.env`: `LLAMA_API_KEY=your_key_here`

### Running

```bash
# Development
python main.py

# Or with uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API will be available at: http://localhost:8000

Interactive docs: http://localhost:8000/docs

## API Endpoints

### Yoga

- `POST /api/yoga/plan` - Generate AI yoga session
- `GET /api/yoga/sessions/{user_id}` - Get user's sessions
- `POST /api/yoga/sessions/{session_id}/complete` - Complete session
- `GET /api/yoga/progress/{user_id}` - Get progress
- `GET /api/yoga/progress/{user_id}/analysis` - AI progress analysis
- `GET /api/yoga/poses` - Browse pose library

### Diet

- `POST /api/diet/plan` - Generate AI meal plan
- `GET /api/diet/meal-plan/{user_id}/{date}` - Get meal plan for date
- `GET /api/diet/meal-plans/{user_id}` - Get meal plans (date range)
- `POST /api/diet/log-meal/{user_id}` - Log consumed meal
- `GET /api/diet/progress/{user_id}` - Get nutrition progress
- `GET /api/diet/progress/{user_id}/analysis` - AI nutrition analysis
- `GET /api/diet/recipes` - Search recipes
- `POST /api/diet/weight/{user_id}` - Update weight

### Analytics

- `POST /api/analytics/comprehensive` - Get comprehensive analytics
- `GET /api/analytics/dashboard/{user_id}` - Get dashboard summary

## Project Structure

```
Backend/
├── agents/              # AI agents
│   ├── kimi_yoga_agent.py
│   └── llama_diet_agent.py
├── config/              # Configuration
│   └── settings.py
├── models/              # Data models
│   ├── database.py      # SQLAlchemy models
│   └── schemas.py       # Pydantic schemas
├── routes/              # API routes
│   ├── yoga_routes.py
│   ├── diet_routes.py
│   └── analytics_routes.py
├── services/            # Business logic
│   ├── yoga_service.py
│   └── diet_service.py
├── utils/               # Utilities
│   └── database.py
├── main.py              # Application entry
├── requirements.txt
└── .env.example
```

## Advanced Features

### KIMI 2 Yoga Agent

- **Context-Aware**: Analyzes user profile, fitness level, goals
- **Sequence Optimization**: Creates flowing, balanced pose sequences
- **Safety First**: Includes precautions and modifications
- **Goal-Oriented**: Adapts to specific goals (flexibility, strength, stress relief)
- **Progress Adaptation**: Recommends level progression

### LLAMA 3.2 Diet Agent

- **Nutrition Science**: Evidence-based meal planning
- **Cultural Diversity**: Recipes from various cuisines
- **Meal Prep Efficiency**: Considers prep time and complexity
- **Macro Balance**: Optimizes protein/carbs/fat ratios
- **Vision Capable**: Future support for food image analysis

### Analytics Engine

- **Streak Tracking**: Yoga and nutrition consistency
- **Trend Detection**: Identify improvements and plateaus
- **Correlation Analysis**: Link yoga practice with nutrition
- **Achievement System**: Milestone recognition

## Database Schema

- **users**: User profiles and preferences
- **yoga_sessions**: Generated and completed yoga sessions
- **yoga_progress**: Daily yoga tracking
- **yoga_poses**: Pose library
- **meal_plans**: Generated meal plans
- **diet_progress**: Daily nutrition tracking
- **recipes**: Recipe database

## Security Considerations

- API keys stored in environment variables
- Input validation with Pydantic
- SQL injection prevention via SQLAlchemy ORM
- CORS configuration for production
- JWT support ready (implement as needed)

## Scaling

- **Database**: Migrate to PostgreSQL for production
- **Caching**: Add Redis for API response caching
- **Queue**: Celery for async AI generation
- **Deployment**: Docker + Kubernetes ready
- **Monitoring**: Add Sentry for error tracking

## License

Proprietary - All rights reserved

## Support

For issues or questions, please contact the development team.
