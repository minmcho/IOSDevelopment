# AI Yoga Planner Backend

High-performance FastAPI backend for yoga planning and real-time pose guidance using Kimi 2 and LLAMA 3.2.

## Features

- 🤖 AI-powered yoga session planning using Kimi 2
- 📸 Real-time pose detection and correction using LLAMA 3.2
- 💬 Interactive chat agent for yoga guidance
- 🔄 WebSocket support for real-time feedback
- 📊 Personalized recommendations based on user profile
- 🎯 Multi-level difficulty support (beginner, intermediate, advanced)

## Setup

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your API keys
```

### 3. Run the Server

```bash
# Development
python main.py

# Or using uvicorn directly
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Access API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

### REST Endpoints

- `POST /api/v1/user/profile` - Create/update user profile
- `POST /api/v1/yoga/plan` - Generate personalized yoga session
- `POST /api/v1/pose/analyze` - Analyze pose from image
- `POST /api/v1/chat` - Chat with AI yoga agent
- `GET /api/v1/poses/library` - Get pose library
- `GET /api/v1/session/history/{user_id}` - Get session history

### WebSocket Endpoints

- `WS /ws/pose-guidance/{session_id}/{user_id}` - Real-time pose guidance

## AI Model Integration

### Kimi 2
Used for intelligent yoga session planning and conversational AI.

```python
# Configure in main.py
ai_agent.kimi_endpoint = "your_kimi_endpoint"
```

### LLAMA 3.2
Used for real-time pose analysis and corrections.

```python
# Configure in main.py
ai_agent.llama_endpoint = "your_llama_endpoint"
```

## Example Usage

### Create Yoga Plan

```python
import requests

response = requests.post("http://localhost:8000/api/v1/yoga/plan", json={
    "session": {
        "user_id": "user123",
        "duration_minutes": 30,
        "difficulty": "beginner",
        "focus_areas": ["flexibility", "relaxation"],
        "session_type": "morning"
    },
    "user_profile": {
        "user_id": "user123",
        "name": "John Doe",
        "email": "john@example.com",
        "experience_level": "beginner",
        "goals": ["flexibility", "stress relief"]
    }
})

plan = response.json()
print(f"Session ID: {plan['session_id']}")
print(f"Poses: {len(plan['poses'])}")
```

### WebSocket Real-Time Guidance

```python
import asyncio
import websockets
import json

async def pose_guidance():
    uri = "ws://localhost:8000/ws/pose-guidance/session123/user123"
    async with websockets.connect(uri) as websocket:
        # Send pose frame
        await websocket.send(json.dumps({
            "type": "pose_frame",
            "pose_name": "Downward Dog",
            "image": "base64_encoded_image_data"
        }))

        # Receive feedback
        feedback = await websocket.recv()
        print(f"Feedback: {feedback}")

asyncio.run(pose_guidance())
```

## Performance Optimization

- Async/await for all I/O operations
- WebSocket for real-time communication
- Efficient image processing
- Caching for frequently accessed data

## Security

- CORS middleware configured
- API key authentication (implement as needed)
- Input validation with Pydantic
- Rate limiting (configure as needed)

## Deployment

### Docker

```bash
docker build -t yoga-planner-api .
docker run -p 8000:8000 yoga-planner-api
```

### Production

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## License

MIT
