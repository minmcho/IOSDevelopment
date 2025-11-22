# AI Yoga Planner - Complete Setup Guide

This guide will walk you through setting up the entire AI Yoga Planner system from scratch.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [iOS App Setup](#ios-app-setup)
4. [AI Model Configuration](#ai-model-configuration)
5. [Testing](#testing)
6. [Deployment](#deployment)

## Prerequisites

### System Requirements

#### For Backend Development
- **Operating System**: macOS, Linux, or Windows
- **Python**: Version 3.9 or higher
- **pip**: Latest version
- **Virtual Environment**: venv or conda

#### For iOS Development
- **Operating System**: macOS (required for iOS development)
- **Xcode**: Version 15.0 or higher
- **iOS SDK**: iOS 17.0 or higher
- **Swift**: Version 5.9 or higher
- **Device**: iPhone running iOS 17+ or iOS Simulator

### Account Requirements
- **Kimi 2 API**: Sign up at [Kimi AI website] and obtain API key
- **LLAMA 3.2 API**: Access through your preferred provider (HuggingFace, Replicate, etc.)
- **Apple Developer Account**: For testing on physical devices (optional for simulator)

## Backend Setup

### Step 1: Clone and Navigate

```bash
cd /path/to/IOSDevelopment
cd backend
```

### Step 2: Create Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### Step 3: Install Dependencies

```bash
# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables

```bash
# Copy example environment file
cp .env.example .env
```

Edit `.env` file with your credentials:

```bash
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# AI Model API Keys
KIMI_API_KEY=your_actual_kimi_api_key_here
KIMI_API_ENDPOINT=https://api.kimi.ai/v1  # Replace with actual endpoint

LLAMA_API_KEY=your_actual_llama_api_key_here
LLAMA_API_ENDPOINT=https://api.llama.ai/v1  # Replace with actual endpoint

# Security
SECRET_KEY=generate_a_secure_random_key_here
ALGORITHM=HS256

# CORS - Add your iOS app URL
ALLOWED_ORIGINS=http://localhost:3000
```

### Step 5: Generate Secret Key

```bash
# Generate a secure secret key
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Copy the output and paste it as your `SECRET_KEY` in `.env`

### Step 6: Test Backend

```bash
# Run the server
python main.py

# Or using uvicorn directly with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

### Step 7: Verify API

Open your browser and navigate to:
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

You should see the Swagger UI documentation and a health status response.

## iOS App Setup

### Step 1: Open Project in Xcode

```bash
cd /path/to/IOSDevelopment
open -a Xcode .
```

Or:
- Open Xcode
- File → Open → Select `IOSDevelopment` folder

### Step 2: Configure Project Settings

1. **Select your development team**:
   - Click on project name in navigator
   - Select target
   - Go to "Signing & Capabilities"
   - Choose your development team

2. **Update bundle identifier**:
   - Change to unique identifier (e.g., `com.yourname.yogaplanner`)

### Step 3: Add Camera Permissions

1. **Locate Info.plist** or create it if it doesn't exist

2. **Add camera permission**:
   - Right-click Info.plist → Open As → Source Code
   - Add:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for real-time yoga pose detection and guidance. We analyze your poses to provide instant feedback and corrections.</string>
```

### Step 4: Configure Backend URL

Edit `Sources/Services/YogaAPIService.swift`:

```swift
class YogaAPIService: ObservableObject {
    // For iOS Simulator (backend on same machine)
    private let baseURL = "http://localhost:8000/api/v1"
    private let wsBaseURL = "ws://localhost:8000/ws"

    // For Physical Device (replace with your computer's IP)
    // private let baseURL = "http://192.168.1.XXX:8000/api/v1"
    // private let wsBaseURL = "ws://192.168.1.XXX:8000/ws"
}
```

To find your computer's IP address:
```bash
# On macOS
ipconfig getifaddr en0

# On Linux
hostname -I | awk '{print $1}'

# On Windows
ipconfig
```

### Step 5: Build and Run

1. **Select Target Device**:
   - Choose iPhone simulator (e.g., iPhone 15 Pro)
   - Or connect physical device and select it

2. **Build**:
   - Press `Cmd + B` to build
   - Fix any build errors

3. **Run**:
   - Press `Cmd + R` to run
   - App should launch in simulator/device

### Step 6: First Launch Setup

1. **Sign In**:
   - Use Gmail or Hotmail login
   - Complete authentication

2. **Create Profile**:
   - Tap "Get Started"
   - Enter your information
   - Select experience level
   - Choose goals

3. **Test Connection**:
   - Generate a yoga plan
   - Verify backend communication

## AI Model Configuration

### Kimi 2 Setup

1. **Obtain API Key**:
   - Visit Kimi AI platform
   - Create account/login
   - Generate API key
   - Copy key to `.env` file

2. **Configure Endpoint**:
   Edit `backend/main.py`:

```python
class AIYogaAgent:
    def __init__(self):
        self.kimi_endpoint = os.getenv('KIMI_API_ENDPOINT')
        self.kimi_key = os.getenv('KIMI_API_KEY')
```

3. **Test Integration**:
```python
# Add test function in main.py
async def test_kimi():
    # Your test code here
    pass
```

### LLAMA 3.2 Setup

1. **Choose Provider**:
   - **HuggingFace**: https://huggingface.co
   - **Replicate**: https://replicate.com
   - **Together AI**: https://together.ai
   - **Self-hosted**: Run locally with Ollama

2. **For HuggingFace**:
```python
# Install transformers
pip install transformers torch

# In main.py
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.2-8B")
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.2-8B")
```

3. **For Replicate**:
```bash
pip install replicate
```

```python
import replicate

response = replicate.run(
    "meta/llama-3.2-8b",
    input={"prompt": "Your prompt here"}
)
```

4. **For Self-Hosted (Ollama)**:
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull LLAMA 3.2
ollama pull llama3.2

# Run server
ollama serve
```

```python
# In main.py
import requests

response = requests.post(
    "http://localhost:11434/api/generate",
    json={"model": "llama3.2", "prompt": "Your prompt"}
)
```

## Testing

### Backend Testing

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test user profile creation
curl -X POST http://localhost:8000/api/v1/user/profile \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test123",
    "name": "Test User",
    "email": "test@example.com",
    "experience_level": "beginner",
    "goals": ["flexibility", "stress relief"]
  }'

# Test yoga plan generation
curl -X POST http://localhost:8000/api/v1/yoga/plan \
  -H "Content-Type: application/json" \
  -d '{
    "session": {
      "user_id": "test123",
      "duration_minutes": 30,
      "difficulty": "beginner",
      "focus_areas": ["flexibility"],
      "session_type": "morning"
    },
    "user_profile": {
      "user_id": "test123",
      "name": "Test User",
      "email": "test@example.com",
      "experience_level": "beginner",
      "goals": ["flexibility"]
    }
  }'
```

### iOS App Testing

1. **Manual Testing**:
   - Test authentication flow
   - Create user profile
   - Generate yoga plan
   - Start yoga session
   - Test pose guidance with camera
   - Test chat feature

2. **Debug Logging**:
```swift
// Add in YogaAPIService.swift
print("API Request: \(request)")
print("API Response: \(response)")
```

3. **Network Debugging**:
   - Use Charles Proxy or Proxyman
   - Monitor API calls
   - Verify request/response data

## Deployment

### Backend Deployment (Docker)

1. **Build Docker Image**:
```bash
cd backend
docker build -t yoga-planner-api .
```

2. **Run with Docker Compose**:
```bash
docker-compose up -d
```

3. **Verify**:
```bash
docker-compose ps
docker-compose logs api
```

### Backend Deployment (Cloud)

#### AWS EC2

```bash
# SSH to EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install dependencies
sudo apt update
sudo apt install python3-pip python3-venv

# Clone repository
git clone your-repo-url
cd backend

# Setup and run
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

#### Heroku

```bash
# Install Heroku CLI
# Create Procfile
echo "web: uvicorn main:app --host 0.0.0.0 --port \$PORT" > Procfile

# Deploy
heroku create yoga-planner-api
git push heroku main
```

### iOS App Deployment

1. **Archive Build**:
   - Product → Archive
   - Wait for archive to complete

2. **Upload to App Store Connect**:
   - Distribute App → App Store Connect
   - Upload
   - Submit for review

3. **TestFlight**:
   - Add internal/external testers
   - Distribute beta builds

## Troubleshooting

### Common Issues

#### Backend

**Issue**: "Module not found"
```bash
# Solution
pip install -r requirements.txt --force-reinstall
```

**Issue**: "Port 8000 already in use"
```bash
# Solution - Find and kill process
lsof -ti:8000 | xargs kill -9
# Or use different port
uvicorn main:app --port 8001
```

**Issue**: "CORS error"
```python
# Solution - Update CORS in main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### iOS

**Issue**: "Cannot connect to localhost"
```swift
// Solution - Use computer's IP for physical device
private let baseURL = "http://YOUR_IP_HERE:8000/api/v1"
```

**Issue**: "Camera permission denied"
```
// Solution
1. Delete app
2. Check Info.plist has camera description
3. Reinstall and grant permission
```

**Issue**: "Build failed"
```
// Solution
1. Clean build folder (Cmd + Shift + K)
2. Delete derived data
3. Restart Xcode
4. Update pods if using CocoaPods
```

## Next Steps

1. ✅ Complete setup
2. ✅ Test all features
3. 📝 Customize UI/UX
4. 🔧 Add custom poses
5. 🚀 Deploy to production
6. 📊 Monitor usage
7. 🎯 Gather user feedback
8. 🔄 Iterate and improve

## Support

- **Documentation**: Check README.md
- **API Docs**: http://localhost:8000/docs
- **Issues**: Open GitHub issue
- **Community**: Join discussions

---

**Happy coding! 🧘‍♀️**
