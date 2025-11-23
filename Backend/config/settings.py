"""
Configuration settings for Yoga & Diet AI Agent Backend
"""
import os
from typing import Optional
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    """Application settings"""

    # API Configuration
    API_HOST: str = os.getenv("API_HOST", "0.0.0.0")
    API_PORT: int = int(os.getenv("API_PORT", "8000"))
    API_DEBUG: bool = os.getenv("API_DEBUG", "True").lower() == "true"

    # KIMI 2 Configuration (Moonshot AI)
    KIMI_API_KEY: Optional[str] = os.getenv("KIMI_API_KEY")
    KIMI_API_BASE: str = os.getenv("KIMI_API_BASE", "https://api.moonshot.cn/v1")
    KIMI_MODEL: str = os.getenv("KIMI_MODEL", "moonshot-v1-32k")

    # LLAMA 3.2 Configuration
    LLAMA_API_KEY: Optional[str] = os.getenv("LLAMA_API_KEY")
    LLAMA_API_BASE: str = os.getenv("LLAMA_API_BASE", "https://api.together.xyz/v1")
    LLAMA_MODEL: str = os.getenv("LLAMA_MODEL", "meta-llama/Llama-3.2-90B-Vision-Instruct")

    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./yoga_diet.db")

    # JWT Configuration
    JWT_SECRET: str = os.getenv("JWT_SECRET", "change_this_secret_key_in_production")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRATION_HOURS: int = int(os.getenv("JWT_EXPIRATION_HOURS", "24"))

    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # Feature Flags
    ENABLE_YOGA_AGENT: bool = os.getenv("ENABLE_YOGA_AGENT", "True").lower() == "true"
    ENABLE_DIET_AGENT: bool = os.getenv("ENABLE_DIET_AGENT", "True").lower() == "true"
    ENABLE_ANALYTICS: bool = os.getenv("ENABLE_ANALYTICS", "True").lower() == "true"
    ENABLE_NOTIFICATIONS: bool = os.getenv("ENABLE_NOTIFICATIONS", "True").lower() == "true"

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
