# Yoga & Diet AI Agent Platform

A comprehensive wellness platform combining AI-powered yoga planning and diet management. Built with SwiftUI for iOS and FastAPI for the backend, powered by **KIMI 2** for yoga planning and **LLAMA 3.2** for diet planning.

## 🌟 Features

### 🧘 AI Yoga Planner (KIMI 2)
- **Personalized Session Generation**: AI-powered yoga sessions tailored to your level, style, and goals
- **Multiple Yoga Styles**: Hatha, Vinyasa, Ashtanga, Bikram, Yin, Restorative, Power, Kundalini
- **Adaptive Difficulty**: Beginner to Expert levels with smart progression
- **Complete Sessions**: Warm-up, main sequence, and cool-down included
- **Pose Library**: Extensive database with instructions, benefits, and precautions
- **Progress Tracking**: Track sessions, minutes, calories, poses mastered, and streaks
- **AI Analysis**: Get insights and recommendations based on your practice history

### 🍽️ AI Diet Planner (LLAMA 3.2)
- **Smart Meal Planning**: Generate 1-30 day personalized meal plans
- **Diet Types**: Balanced, Vegan, Vegetarian, Keto, Paleo, Mediterranean, Low-Carb, High-Protein
- **Nutrition Optimization**: Automatic calorie and macro (protein/carbs/fat) balancing
- **Recipe Generation**: AI-created recipes with detailed instructions
- **Dietary Restrictions**: Full support for allergies and food preferences
- **Shopping Lists**: Auto-generated, categorized shopping lists
- **Progress Tracking**: Daily nutrition logging, macro tracking, and weight monitoring
- **AI Nutrition Analysis**: Get personalized recommendations and insights

### 📊 Analytics & Insights
- **Dashboard**: Unified view of yoga and diet progress
- **Streaks**: Track consistency in both yoga practice and nutrition
- **Trends**: Visualize your progress over time
- **AI Insights**: Actionable recommendations based on your data
- **Goal Tracking**: Monitor progress toward fitness and nutrition goals

### 🔐 Authentication
- Email/Password authentication
- Gmail OAuth integration (ready for implementation)
- Hotmail/Outlook OAuth integration (ready for implementation)
- Secure user profile management

## 📱 iOS App Features

- **Modern SwiftUI Interface**: Clean, intuitive design with smooth animations
- **Tab Navigation**: Easy access to Dashboard, Yoga, Diet, and Profile
- **Offline Support**: View downloaded plans without internet
- **Real-time Sync**: Automatic synchronization with backend
- **Dark Mode**: Full dark mode support
- **Accessibility**: VoiceOver and Dynamic Type support

## 🏗️ Architecture

### Backend
- **Framework**: FastAPI (Python)
- **Database**: SQLAlchemy with SQLite (upgradeable to PostgreSQL)
- **AI Integration**:
  - KIMI 2 API (Moonshot AI) for yoga
  - LLAMA 3.2 API (Together AI/Groq/Replicate) for diet
- **API Documentation**: Auto-generated with OpenAPI/Swagger

### iOS
- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession with async/await
- **State Management**: Combine + @Published properties
- **Minimum iOS**: 15.0+

## 🚀 Getting Started

### Backend Setup

1. **Navigate to backend directory**:
```bash
cd Backend
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

3. **Configure environment**:
```bash
cp .env.example .env
```

4. **Add API keys to `.env`**:
```
KIMI_API_KEY=your_kimi_api_key_here
LLAMA_API_KEY=your_llama_api_key_here
```

Get API keys from:
- KIMI 2: https://platform.moonshot.cn/
- LLAMA 3.2: https://api.together.xyz/ (or Groq, Replicate)

5. **Run the server**:
```bash
python main.py
```

Backend will be available at: http://localhost:8000
API docs: http://localhost:8000/docs

### iOS Setup

1. **Open Xcode project**

2. **Update API endpoint**:
   - Open `Sources/Services/APIClient.swift`
   - Change `baseURL` to your backend URL:
   ```swift
   private let baseURL = "http://localhost:8000"  // or your production URL
   ```

3. **Build and run**:
   - Select target device/simulator
   - Press Cmd+R to build and run

## 📂 Project Structure

```
IOSDevelopment/
├── Backend/                      # Python FastAPI backend
│   ├── agents/                   # AI agents
│   │   ├── kimi_yoga_agent.py   # KIMI 2 yoga planner
│   │   └── llama_diet_agent.py  # LLAMA 3.2 diet planner
│   ├── config/                   # Configuration
│   ├── models/                   # Database & Pydantic models
│   ├── routes/                   # API endpoints
│   │   ├── yoga_routes.py
│   │   ├── diet_routes.py
│   │   └── analytics_routes.py
│   ├── services/                 # Business logic
│   │   ├── yoga_service.py
│   │   └── diet_service.py
│   ├── utils/                    # Database utilities
│   ├── main.py                   # FastAPI app
│   ├── requirements.txt
│   └── README.md
│
└── Sources/                      # iOS SwiftUI app
    ├── Models/                   # Data models
    │   ├── User.swift
    │   ├── YogaModels.swift
    │   └── DietModels.swift
    ├── ViewModels/               # Business logic
    │   ├── AuthenticationViewModel.swift
    │   ├── YogaViewModel.swift
    │   ├── DietViewModel.swift
    │   └── DashboardViewModel.swift
    ├── Views/                    # UI components
    │   ├── LoginView.swift
    │   ├── DashboardView.swift
    │   ├── YogaPlannerView.swift
    │   ├── DietPlannerView.swift
    │   └── ContentView.swift
    ├── Services/                 # API client
    │   └── APIClient.swift
    └── LoginApp.swift            # App entry point
```

## 🔑 Key Technologies

### AI Models
- **KIMI 2 (Moonshot AI)**: 32k context window, excellent for structured yoga session generation
- **LLAMA 3.2 (Meta)**: 90B parameter vision-instruct model for comprehensive meal planning

### Backend Stack
- FastAPI 0.104+
- SQLAlchemy 2.0+ (async)
- Pydantic 2.5+ (validation)
- httpx (async HTTP client)
- uvicorn (ASGI server)

### iOS Stack
- SwiftUI (declarative UI)
- Combine (reactive programming)
- URLSession (networking)
- Swift 5.7+

## 📖 API Documentation

### Yoga Endpoints
- `POST /api/yoga/plan` - Generate AI yoga session
- `GET /api/yoga/sessions/{user_id}` - Get user sessions
- `POST /api/yoga/sessions/{session_id}/complete` - Mark session complete
- `GET /api/yoga/progress/{user_id}` - Get progress data
- `GET /api/yoga/progress/{user_id}/analysis` - AI progress analysis
- `GET /api/yoga/poses` - Browse pose library

### Diet Endpoints
- `POST /api/diet/plan` - Generate AI meal plan
- `GET /api/diet/meal-plan/{user_id}/{date}` - Get meal plan
- `GET /api/diet/meal-plans/{user_id}` - Get meal plans (range)
- `POST /api/diet/log-meal/{user_id}` - Log meal
- `GET /api/diet/progress/{user_id}` - Get nutrition progress
- `GET /api/diet/progress/{user_id}/analysis` - AI nutrition analysis
- `GET /api/diet/recipes` - Search recipes
- `POST /api/diet/weight/{user_id}` - Update weight

### Analytics Endpoints
- `POST /api/analytics/comprehensive` - Comprehensive analytics
- `GET /api/analytics/dashboard/{user_id}` - Dashboard summary

Full API documentation available at: http://localhost:8000/docs

## 🎯 Usage Examples

### Generate Yoga Plan
```swift
let request = YogaPlanRequest(
    userId: "user123",
    level: .intermediate,
    style: .vinyasa,
    durationMinutes: 45,
    focusAreas: ["flexibility", "core strength"],
    goals: [.stressRelief, .flexibility],
    avoidPoses: []
)

await yogaViewModel.generateYogaPlan(userId: userId)
```

### Generate Diet Plan
```swift
let request = DietPlanRequest(
    userId: "user123",
    dietType: .mediterranean,
    dailyCalorieTarget: 2000,
    numDays: 7,
    mealsPerDay: 3,
    allergies: ["peanuts"],
    dislikedFoods: ["mushrooms"],
    goals: [.weightLoss, .generalHealth]
)

await dietViewModel.generateDietPlan(userId: userId)
```

## 🔒 Security

- API keys stored in environment variables
- Input validation with Pydantic
- SQL injection prevention via ORM
- CORS configuration for production
- Secure password hashing (ready for implementation)
- JWT authentication (ready for implementation)

## 🚢 Deployment

### Backend
- **Docker**: Containerized deployment ready
- **Cloud**: AWS, Google Cloud, Azure compatible
- **Database**: Upgrade to PostgreSQL for production
- **Caching**: Redis integration ready

### iOS
- **TestFlight**: Beta distribution
- **App Store**: Production deployment
- **Configuration**: Environment-specific settings

## 📈 Roadmap

### Phase 1 (Completed) ✅
- AI yoga session generation with KIMI 2
- AI meal planning with LLAMA 3.2
- Progress tracking for both yoga and diet
- iOS app with SwiftUI
- Backend API with FastAPI

### Phase 2 (Planned)
- Real-time sync and offline support
- Social features (share sessions, recipes)
- Video tutorials for yoga poses
- Barcode scanning for nutrition tracking
- Integration with Apple Health
- Push notifications for reminders

### Phase 3 (Future)
- Community features
- Instructor marketplace
- Meal prep service integration
- Wearable device integration
- Advanced AI personalization
- Multi-language support

## 🤝 Contributing

This is a proprietary project. For collaboration opportunities, please contact the development team.

## 📄 License

Proprietary - All rights reserved

## 🙏 Acknowledgments

- **Moonshot AI** for KIMI 2 API
- **Meta AI** for LLAMA 3.2
- **FastAPI** team for excellent framework
- **Apple** for SwiftUI

## 📞 Support

For questions or issues:
- Check the `/docs` endpoint for API documentation
- Review the Backend README for backend-specific details
- Contact: [Your contact information]

---

Built with ❤️ using KIMI 2 and LLAMA 3.2
