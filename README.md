# AI Yoga Planner - High-Performance Yoga Planning & Real-Time Pose Guidance

A comprehensive AI-powered yoga planning and guidance system featuring a FastAPI backend integrated with Kimi 2 and LLAMA 3.2, paired with a beautiful iOS mobile interface built with SwiftUI.

## 🌟 Features

### AI-Powered Intelligence
- **Kimi 2 Integration**: Intelligent yoga session planning and conversational AI
- **LLAMA 3.2 Integration**: Real-time pose analysis and corrections
- **Personalized Plans**: Customized yoga sessions based on user profile, goals, and health conditions
- **Smart Recommendations**: AI-driven pose sequences optimized for specific focus areas

### Real-Time Pose Guidance
- **Live Pose Detection**: Real-time analysis using device camera
- **Instant Feedback**: WebSocket-based real-time corrections and guidance
- **Accuracy Scoring**: AI-powered assessment of pose alignment
- **Visual Overlays**: In-app guidance and correction suggestions

### Mobile Features
- **SwiftUI Interface**: Modern, responsive iOS application
- **Session Tracking**: Monitor progress with detailed statistics
- **Chat Assistant**: Interactive AI yoga tutor for questions and guidance
- **Profile Management**: Personalized experience levels and goals
- **Session History**: Track completed sessions and progress
- **Authentication**: Gmail and Hotmail/Outlook sign-in support

## 🏗️ Architecture

```
IOSDevelopment/
├── backend/                    # FastAPI Backend
│   ├── main.py                # Main API with AI integration
│   ├── requirements.txt       # Python dependencies
│   ├── .env.example          # Environment configuration
│   ├── Dockerfile            # Docker configuration
│   ├── docker-compose.yml    # Docker Compose setup
│   └── README.md             # Backend documentation
│
└── Sources/                   # iOS Application
    ├── LoginApp.swift        # App entry point
    │
    ├── Models/               # Data models
    │   ├── User.swift       # User authentication
    │   └── YogaModels.swift # Yoga-specific models
    │
    ├── Services/            # API & WebSocket services
    │   ├── YogaAPIService.swift
    │   └── WebSocketService.swift
    │
    ├── ViewModels/          # Business logic
    │   ├── AuthenticationViewModel.swift
    │   ├── YogaViewModel.swift
    │   └── ChatViewModel.swift
    │
    └── Views/               # SwiftUI views
        ├── LoginView.swift
        ├── ContentView.swift
        ├── YogaHomeView.swift
        ├── YogaSessionView.swift
        ├── PoseGuidanceView.swift
        └── ChatView.swift
```

## 🚀 Quick Start

### Prerequisites

- **Backend**: Python 3.9+, pip
- **iOS**: macOS with Xcode 15+, iOS 17.0+ SDK
- **AI APIs**: Kimi 2 and LLAMA 3.2 API keys

### Backend Setup

```bash
# Navigate to backend
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run server
python main.py
```

API will be available at:
- Swagger UI: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

### iOS App Setup

```bash
# Open in Xcode
open IOSDevelopment.xcodeproj
```

1. Configure backend URL in `Sources/Services/YogaAPIService.swift`:
```swift
private let baseURL = "http://localhost:8000/api/v1"
```

2. Add camera permission to Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for real-time pose detection and guidance</string>
```

3. Build and Run (`Cmd + R`)

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)

## 📱 Usage

### 1. Authentication
- Sign in with Gmail or Hotmail/Outlook
- Complete authentication flow

### 2. Create Profile
- Enter personal information
- Select experience level (Beginner/Intermediate/Advanced)
- Choose yoga goals

### 3. Generate Yoga Plan
- Select duration (15, 30, 45, or 60 minutes)
- Choose difficulty and session type
- Pick focus areas (Flexibility, Strength, Balance, Relaxation)
- Tap "Generate AI Plan"

### 4. Start Session
- Review AI-generated plan with personalized poses
- Follow pose instructions and timing
- Use real-time pose guidance with camera
- Get instant AI feedback and corrections

### 5. Chat with AI Assistant
- Ask questions about yoga poses and techniques
- Get personalized guidance and tips
- Learn about breathing exercises and flexibility

## 🔧 API Endpoints

### REST API

```
POST   /api/v1/user/profile          - Create/update user profile
POST   /api/v1/yoga/plan             - Generate personalized yoga session
POST   /api/v1/pose/analyze          - Analyze pose from image
POST   /api/v1/chat                  - Chat with AI yoga agent
GET    /api/v1/poses/library         - Get yoga pose library
GET    /api/v1/session/history/:id   - Get session history
GET    /health                       - Health check
```

### WebSocket

```
WS     /ws/pose-guidance/:session/:user  - Real-time pose guidance
```

## 🤖 AI Model Integration

### Kimi 2
**Purpose**: Intelligent session planning and conversational AI

**Features**:
- Personalized yoga session generation
- Context-aware pose sequencing
- Natural language understanding for chat
- Goal-oriented recommendations

**Configuration**: Set `KIMI_API_KEY` and `KIMI_API_ENDPOINT` in `.env`

### LLAMA 3.2
**Purpose**: Real-time pose analysis and corrections

**Features**:
- Computer vision integration
- Pose accuracy assessment
- Intelligent correction generation
- Real-time feedback processing

**Configuration**: Set `LLAMA_API_KEY` and `LLAMA_API_ENDPOINT` in `.env`

## 🐳 Docker Deployment

```bash
cd backend

# Build and run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

## 📊 Tech Stack

### Backend
- **FastAPI**: High-performance web framework
- **Uvicorn**: ASGI server
- **WebSockets**: Real-time communication
- **Pydantic**: Data validation
- **Python 3.11**: Core language

### iOS
- **SwiftUI**: Modern UI framework
- **Combine**: Reactive programming
- **AVFoundation**: Camera integration
- **URLSession**: Network requests

### AI/ML
- **Kimi 2**: Session planning and chat
- **LLAMA 3.2**: Pose analysis and corrections
- **Computer Vision**: Pose detection (future integration)

## 🎨 Screenshots

(Screenshots would go here in a real project)

## 🧪 Testing

### Backend
```bash
# Run tests
pytest

# Test specific endpoint
curl -X POST http://localhost:8000/api/v1/yoga/plan \
  -H "Content-Type: application/json" \
  -d @test_data.json
```

### iOS
- Use Xcode Test Navigator
- Test on iOS Simulator and physical devices
- Verify camera permissions and WebSocket connections

## 🔐 Security

- API key protection via environment variables
- HTTPS in production
- Input validation with Pydantic
- CORS configuration
- Rate limiting (recommended for production)

## 📈 Performance

### Backend
- Async/await for all I/O operations
- WebSocket for real-time communication
- Efficient image processing
- Connection pooling

### iOS
- SwiftUI for efficient rendering
- Lazy loading for lists
- Image caching
- Background processing for API calls

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- **Kimi 2**: Advanced AI for intelligent planning
- **LLAMA 3.2**: Powerful pose analysis capabilities
- **FastAPI**: High-performance web framework
- **SwiftUI**: Modern iOS development
- **The Yoga Community**: Inspiration and guidance

## 📚 Documentation

- [Complete Setup Guide](SETUP_GUIDE.md)
- [Backend Documentation](backend/README.md)
- [API Documentation](http://localhost:8000/docs)

## 🐛 Troubleshooting

### Backend Issues

**Port already in use**:
```bash
lsof -ti:8000 | xargs kill -9
```

**Module not found**:
```bash
pip install -r requirements.txt --force-reinstall
```

### iOS Issues

**Cannot connect to backend**:
- Ensure backend is running
- Check firewall settings
- Use correct IP for physical devices

**Camera not working**:
- Check Info.plist permissions
- Grant camera access in Settings
- Test on physical device

**Build errors**:
- Clean build folder: `Cmd + Shift + K`
- Delete derived data
- Restart Xcode

## 📧 Support

- Open an issue on GitHub
- Check [SETUP_GUIDE.md](SETUP_GUIDE.md)
- Review API docs at `/docs`

---

## 🔮 Future Enhancements

- [ ] Video pose analysis
- [ ] Multi-user sessions
- [ ] Social features and challenges
- [ ] Apple Watch integration
- [ ] Offline mode support
- [ ] Progress analytics dashboard
- [ ] Custom workout creation
- [ ] Health app integration
- [ ] Voice-guided sessions
- [ ] AR pose overlays

---

**Built with ❤️ for the yoga community**

Namaste 🙏
