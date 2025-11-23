"""
User-related Pydantic schemas.
"""

from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional
from datetime import datetime
from backend.schemas.auth import AuthProvider


class UserUpdate(BaseModel):
    """Schema for user profile update."""
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None


class UserProfile(BaseModel):
    """Schema for user profile."""
    id: int
    email: EmailStr
    full_name: Optional[str]
    auth_provider: AuthProvider
    is_active: bool
    is_verified: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
