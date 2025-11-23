"""
Authentication service containing business logic for user authentication.
"""

from sqlalchemy.orm import Session
from backend.db.models import User, RefreshToken, AuthProviderEnum
from backend.schemas.auth import UserCreate, UserLogin, OAuthLoginRequest, AuthProvider
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional, Tuple
import secrets


class AuthService:
    """Service class for authentication operations."""

    def __init__(self):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """
        Verify a plain password against a hashed password.

        Args:
            plain_password: Plain text password
            hashed_password: Hashed password to verify against

        Returns:
            True if password matches, False otherwise
        """
        return self.pwd_context.verify(plain_password, hashed_password)

    def get_password_hash(self, password: str) -> str:
        """
        Hash a password.

        Args:
            password: Plain text password

        Returns:
            Hashed password
        """
        return self.pwd_context.hash(password)

    def authenticate_user(self, db: Session, email: str, password: str) -> Optional[User]:
        """
        Authenticate user with email and password.

        Args:
            db: Database session
            email: User email
            password: User password

        Returns:
            User object if authentication successful, None otherwise
        """
        user = db.query(User).filter(
            User.email == email,
            User.auth_provider == AuthProviderEnum.EMAIL
        ).first()

        if not user:
            return None

        if not user.hashed_password or not self.verify_password(password, user.hashed_password):
            return None

        return user

    def create_user(self, db: Session, user_data: UserCreate) -> User:
        """
        Create a new user.

        Args:
            db: Database session
            user_data: User creation data

        Returns:
            Created user object

        Raises:
            ValueError: If user with email already exists
        """
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise ValueError("User with this email already exists")

        # Create new user
        hashed_password = self.get_password_hash(user_data.password)
        db_user = User(
            email=user_data.email,
            full_name=user_data.full_name,
            hashed_password=hashed_password,
            auth_provider=AuthProviderEnum(user_data.auth_provider.value),
            is_verified=False
        )

        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        return db_user

    def authenticate_oauth_user(
        self,
        db: Session,
        oauth_data: OAuthLoginRequest,
        email: str,
        provider_id: str,
        full_name: Optional[str] = None
    ) -> User:
        """
        Authenticate or create user via OAuth.

        Args:
            db: Database session
            oauth_data: OAuth login request data
            email: User email from OAuth provider
            provider_id: Unique ID from OAuth provider
            full_name: User's full name from OAuth provider

        Returns:
            User object
        """
        # Map schema enum to model enum
        provider_map = {
            AuthProvider.GMAIL: AuthProviderEnum.GMAIL,
            AuthProvider.HOTMAIL: AuthProviderEnum.HOTMAIL
        }
        provider = provider_map.get(oauth_data.auth_provider, AuthProviderEnum.EMAIL)

        # Check if user exists with this provider
        user = db.query(User).filter(
            User.email == email,
            User.auth_provider == provider
        ).first()

        if user:
            # Update provider_id if changed
            if user.provider_id != provider_id:
                user.provider_id = provider_id
                db.commit()
                db.refresh(user)
            return user

        # Create new OAuth user
        new_user = User(
            email=email,
            full_name=full_name,
            auth_provider=provider,
            provider_id=provider_id,
            is_verified=True  # OAuth users are pre-verified
        )

        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return new_user

    def create_refresh_token(self, db: Session, user_id: int, expires_days: int = 30) -> str:
        """
        Create a refresh token for a user.

        Args:
            db: Database session
            user_id: User ID
            expires_days: Number of days until token expires

        Returns:
            Refresh token string
        """
        token = secrets.token_urlsafe(32)
        expires_at = datetime.utcnow() + timedelta(days=expires_days)

        db_token = RefreshToken(
            user_id=user_id,
            token=token,
            expires_at=expires_at
        )

        db.add(db_token)
        db.commit()

        return token

    def validate_refresh_token(self, db: Session, token: str) -> Optional[int]:
        """
        Validate a refresh token and return user ID.

        Args:
            db: Database session
            token: Refresh token to validate

        Returns:
            User ID if token is valid, None otherwise
        """
        db_token = db.query(RefreshToken).filter(
            RefreshToken.token == token,
            RefreshToken.is_revoked == False
        ).first()

        if not db_token:
            return None

        # Check if token is expired
        if db_token.expires_at < datetime.utcnow():
            return None

        return db_token.user_id

    def revoke_refresh_token(self, db: Session, token: str) -> bool:
        """
        Revoke a refresh token.

        Args:
            db: Database session
            token: Refresh token to revoke

        Returns:
            True if token was revoked, False otherwise
        """
        db_token = db.query(RefreshToken).filter(RefreshToken.token == token).first()

        if not db_token:
            return False

        db_token.is_revoked = True
        db.commit()

        return True

    def change_password(
        self,
        db: Session,
        user_id: int,
        current_password: str,
        new_password: str
    ) -> bool:
        """
        Change user password.

        Args:
            db: Database session
            user_id: User ID
            current_password: Current password
            new_password: New password

        Returns:
            True if password changed successfully, False otherwise
        """
        user = db.query(User).filter(User.id == user_id).first()

        if not user or not user.hashed_password:
            return False

        # Verify current password
        if not self.verify_password(current_password, user.hashed_password):
            return False

        # Set new password
        user.hashed_password = self.get_password_hash(new_password)
        db.commit()

        return True


# Create singleton instance
auth_service = AuthService()
