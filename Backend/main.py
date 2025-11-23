"""
Yoga & Diet AI Agent Backend
Powered by KIMI 2 and LLAMA 3.2
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from Backend.config import settings
from Backend.utils.database import init_db
from Backend.routes import yoga_router, diet_router, analytics_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    print("🚀 Starting Yoga & Diet AI Backend...")
    print(f"📊 Using KIMI 2 for Yoga Planning")
    print(f"🍽️  Using LLAMA 3.2 for Diet Planning")
    await init_db()
    print("✅ Database initialized")
    yield
    # Shutdown
    print("👋 Shutting down...")


# Create FastAPI app
app = FastAPI(
    title="Yoga & Diet AI Agent API",
    description="""
    Advanced AI-powered wellness platform combining yoga and diet planning.

    ## Features

    ### Yoga Planning (KIMI 2)
    - Personalized yoga session generation
    - Multiple yoga styles (Hatha, Vinyasa, Ashtanga, etc.)
    - Difficulty adaptation (Beginner to Expert)
    - Progress tracking and analytics
    - AI-powered recommendations
    - Pose library with detailed instructions

    ### Diet Planning (LLAMA 3.2)
    - Multi-day meal planning
    - Nutrition optimization
    - Dietary restriction support
    - Recipe generation with instructions
    - Shopping list generation
    - Macro and calorie tracking
    - AI nutrition analysis

    ### Analytics
    - Comprehensive progress tracking
    - Trend analysis
    - Goal monitoring
    - AI-powered insights
    - Dashboard summaries
    """,
    version="1.0.0",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(yoga_router)
app.include_router(diet_router)
app.include_router(analytics_router)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Yoga & Diet AI Agent API",
        "version": "1.0.0",
        "features": {
            "yoga": {
                "agent": "KIMI 2",
                "capabilities": [
                    "Personalized session generation",
                    "Progress tracking",
                    "Pose library",
                    "AI recommendations"
                ]
            },
            "diet": {
                "agent": "LLAMA 3.2",
                "capabilities": [
                    "Meal planning",
                    "Nutrition tracking",
                    "Recipe generation",
                    "Shopping lists"
                ]
            },
            "analytics": {
                "capabilities": [
                    "Comprehensive tracking",
                    "Trend analysis",
                    "AI insights"
                ]
            }
        },
        "docs": "/docs",
        "endpoints": {
            "yoga": "/api/yoga",
            "diet": "/api/diet",
            "analytics": "/api/analytics"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "services": {
            "api": "online",
            "kimi_agent": settings.ENABLE_YOGA_AGENT,
            "llama_agent": settings.ENABLE_DIET_AGENT,
            "analytics": settings.ENABLE_ANALYTICS,
        }
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.API_DEBUG,
    )
