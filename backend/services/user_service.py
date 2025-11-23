"""
User service containing business logic for user management.
"""

from sqlalchemy.orm import Session
from backend.db.models import User
from backend.schemas.user import UserUpdate
from typing import Optional, List


class UserService:
    """Service class for user management operations."""

    def get_user_by_id(self, db: Session, user_id: int) -> Optional[User]:
        """
        Get user by ID.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            User object if found, None otherwise
        """
        return db.query(User).filter(User.id == user_id).first()

    def get_user_by_email(self, db: Session, email: str) -> Optional[User]:
        """
        Get user by email.

        Args:
            db: Database session
            email: User email

        Returns:
            User object if found, None otherwise
        """
        return db.query(User).filter(User.email == email).first()

    def get_users(
        self,
        db: Session,
        skip: int = 0,
        limit: int = 100,
        active_only: bool = False
    ) -> List[User]:
        """
        Get list of users.

        Args:
            db: Database session
            skip: Number of records to skip
            limit: Maximum number of records to return
            active_only: If True, return only active users

        Returns:
            List of user objects
        """
        query = db.query(User)

        if active_only:
            query = query.filter(User.is_active == True)

        return query.offset(skip).limit(limit).all()

    def update_user(
        self,
        db: Session,
        user_id: int,
        user_update: UserUpdate
    ) -> Optional[User]:
        """
        Update user information.

        Args:
            db: Database session
            user_id: User ID
            user_update: User update data

        Returns:
            Updated user object if found, None otherwise

        Raises:
            ValueError: If email already exists for another user
        """
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            return None

        # Check if email is being changed and if it already exists
        if user_update.email and user_update.email != user.email:
            existing_user = db.query(User).filter(
                User.email == user_update.email,
                User.id != user_id
            ).first()

            if existing_user:
                raise ValueError("Email already exists for another user")

            user.email = user_update.email
            user.is_verified = False  # Reset verification on email change

        if user_update.full_name is not None:
            user.full_name = user_update.full_name

        db.commit()
        db.refresh(user)

        return user

    def deactivate_user(self, db: Session, user_id: int) -> bool:
        """
        Deactivate a user account.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            True if user was deactivated, False otherwise
        """
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            return False

        user.is_active = False
        db.commit()

        return True

    def activate_user(self, db: Session, user_id: int) -> bool:
        """
        Activate a user account.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            True if user was activated, False otherwise
        """
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            return False

        user.is_active = True
        db.commit()

        return True

    def verify_user_email(self, db: Session, user_id: int) -> bool:
        """
        Mark user email as verified.

        Args:
            db: Database session
            user_id: User ID

        Returns:
            True if user was verified, False otherwise
        """
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            return False

        user.is_verified = True
        db.commit()

        return True

    def delete_user(self, db: Session, user_id: int) -> bool:
        """
        Delete a user account (hard delete).

        Args:
            db: Database session
            user_id: User ID

        Returns:
            True if user was deleted, False otherwise
        """
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            return False

        db.delete(user)
        db.commit()

        return True


# Create singleton instance
user_service = UserService()
