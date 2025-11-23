"""
JWT token service for handling token generation and validation.
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from backend.schemas.auth import TokenData
import os


class JWTService:
    """Service class for JWT operations."""

    def __init__(self):
        self.secret_key = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
        self.algorithm = "HS256"
        self.access_token_expire_minutes = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
        self.refresh_token_expire_days = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))

    def create_access_token(
        self,
        user_id: int,
        email: str,
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """
        Create an access token.

        Args:
            user_id: User ID
            email: User email
            expires_delta: Custom expiration time

        Returns:
            Encoded JWT token
        """
        to_encode = {
            "user_id": user_id,
            "email": email,
            "type": "access"
        }

        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)

        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)

        return encoded_jwt

    def verify_token(self, token: str) -> Optional[TokenData]:
        """
        Verify and decode a JWT token.

        Args:
            token: JWT token to verify

        Returns:
            TokenData if token is valid, None otherwise
        """
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            user_id: int = payload.get("user_id")
            email: str = payload.get("email")
            exp: int = payload.get("exp")

            if user_id is None or email is None:
                return None

            return TokenData(user_id=user_id, email=email, exp=exp)
        except JWTError:
            return None

    def get_access_token_expire_seconds(self) -> int:
        """
        Get access token expiration time in seconds.

        Returns:
            Expiration time in seconds
        """
        return self.access_token_expire_minutes * 60


# Create singleton instance
jwt_service = JWTService()
