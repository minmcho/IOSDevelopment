"""
Authentication-related Pydantic schemas for request/response validation.
"""

from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional
from datetime import datetime
from enum import Enum


class AuthProvider(str, Enum):
    """Authentication provider types."""
    EMAIL = "email"
    GMAIL = "gmail"
    HOTMAIL = "hotmail"


class UserBase(BaseModel):
    """Base user schema."""
    email: EmailStr
    full_name: Optional[str] = None


class UserCreate(UserBase):
    """Schema for user creation with email/password."""
    password: str = Field(..., min_length=6, description="Password must be at least 6 characters")
    auth_provider: AuthProvider = AuthProvider.EMAIL


class UserLogin(BaseModel):
    """Schema for email/password login."""
    email: EmailStr
    password: str


class OAuthLoginRequest(BaseModel):
    """Schema for OAuth login requests."""
    id_token: str = Field(..., description="OAuth ID token from provider")
    auth_provider: AuthProvider = Field(..., description="OAuth provider (gmail or hotmail)")


class UserResponse(UserBase):
    """Schema for user response."""
    id: int
    auth_provider: AuthProvider
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    """Schema for token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Access token expiration in seconds")


class TokenRefreshRequest(BaseModel):
    """Schema for token refresh request."""
    refresh_token: str


class TokenData(BaseModel):
    """Schema for token payload data."""
    user_id: int
    email: str
    exp: Optional[int] = None


class MessageResponse(BaseModel):
    """Generic message response schema."""
    message: str
    detail: Optional[str] = None


class PasswordResetRequest(BaseModel):
    """Schema for password reset request."""
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Schema for password reset confirmation."""
    token: str
    new_password: str = Field(..., min_length=6)


class PasswordChange(BaseModel):
    """Schema for password change."""
    current_password: str
    new_password: str = Field(..., min_length=6)
