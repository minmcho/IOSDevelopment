"""
User management API endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
from backend.db.database import get_db
from backend.schemas.user import UserProfile, UserUpdate
from backend.schemas.auth import MessageResponse
from backend.services.user_service import user_service
from backend.routers.dependencies import get_current_user
from backend.db.models import User


router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserProfile)
def get_my_profile(current_user: User = Depends(get_current_user)):
    """
    Get current user's profile.

    Args:
        current_user: Current authenticated user

    Returns:
        User profile
    """
    return current_user


@router.put("/me", response_model=UserProfile)
def update_my_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update current user's profile.

    Args:
        user_update: Profile update data
        current_user: Current authenticated user
        db: Database session

    Returns:
        Updated user profile

    Raises:
        HTTPException: If email already exists
    """
    try:
        updated_user = user_service.update_user(db, current_user.id, user_update)
        return updated_user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.delete("/me", response_model=MessageResponse)
def delete_my_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete current user's account.

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success message
    """
    user_service.delete_user(db, current_user.id)
    return MessageResponse(message="Account deleted successfully")


@router.get("/{user_id}", response_model=UserProfile)
def get_user(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user by ID.

    Args:
        user_id: User ID to retrieve
        current_user: Current authenticated user
        db: Database session

    Returns:
        User profile

    Raises:
        HTTPException: If user not found
    """
    user = user_service.get_user_by_id(db, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user


@router.get("/", response_model=List[UserProfile])
def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    active_only: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List all users (paginated).

    Args:
        skip: Number of records to skip
        limit: Maximum number of records to return
        active_only: Filter for active users only
        current_user: Current authenticated user
        db: Database session

    Returns:
        List of user profiles
    """
    users = user_service.get_users(db, skip=skip, limit=limit, active_only=active_only)
    return users
