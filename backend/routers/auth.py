"""
Authentication API endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.db.database import get_db
from backend.schemas.auth import (
    UserCreate,
    UserLogin,
    UserResponse,
    TokenResponse,
    TokenRefreshRequest,
    OAuthLoginRequest,
    MessageResponse,
    PasswordChange
)
from backend.services.auth_service import auth_service
from backend.services.jwt_service import jwt_service
from backend.services.user_service import user_service
from backend.routers.dependencies import get_current_user
from backend.db.models import User


router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user with email and password.

    Args:
        user_data: User registration data
        db: Database session

    Returns:
        Created user object

    Raises:
        HTTPException: If user already exists
    """
    try:
        user = auth_service.create_user(db, user_data)
        return user
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/login", response_model=TokenResponse)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """
    Login with email and password.

    Args:
        credentials: Login credentials
        db: Database session

    Returns:
        Access and refresh tokens

    Raises:
        HTTPException: If credentials are invalid
    """
    user = auth_service.authenticate_user(db, credentials.email, credentials.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )

    # Create tokens
    access_token = jwt_service.create_access_token(user.id, user.email)
    refresh_token = auth_service.create_refresh_token(db, user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=jwt_service.get_access_token_expire_seconds()
    )


@router.post("/oauth/login", response_model=TokenResponse)
def oauth_login(oauth_data: OAuthLoginRequest, db: Session = Depends(get_db)):
    """
    Login or register with OAuth provider (Gmail or Hotmail).

    Note: This endpoint expects the client to have already validated the OAuth token
    with the provider and sends the verified token here.

    In production, you should validate the ID token with the OAuth provider's API:
    - For Gmail: Use Google's tokeninfo endpoint or google-auth library
    - For Hotmail: Use Microsoft Graph API or MSAL library

    Args:
        oauth_data: OAuth login data with ID token
        db: Database session

    Returns:
        Access and refresh tokens

    Raises:
        HTTPException: If OAuth token is invalid
    """
    # TODO: Implement actual OAuth token verification
    # For now, this is a placeholder that accepts any token
    # In production, you MUST verify the ID token with the provider

    # Example for Gmail:
    # from google.oauth2 import id_token
    # from google.auth.transport import requests
    # idinfo = id_token.verify_oauth2_token(oauth_data.id_token, requests.Request(), GOOGLE_CLIENT_ID)
    # email = idinfo['email']
    # provider_id = idinfo['sub']
    # full_name = idinfo.get('name')

    # For demonstration purposes only - REMOVE IN PRODUCTION
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="OAuth login requires proper token validation. Please implement OAuth verification for production use."
    )

    # Uncomment and modify this code after implementing OAuth verification:
    # user = auth_service.authenticate_oauth_user(
    #     db, oauth_data, email, provider_id, full_name
    # )
    #
    # access_token = jwt_service.create_access_token(user.id, user.email)
    # refresh_token = auth_service.create_refresh_token(db, user.id)
    #
    # return TokenResponse(
    #     access_token=access_token,
    #     refresh_token=refresh_token,
    #     expires_in=jwt_service.get_access_token_expire_seconds()
    # )


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(token_data: TokenRefreshRequest, db: Session = Depends(get_db)):
    """
    Refresh access token using refresh token.

    Args:
        token_data: Refresh token data
        db: Database session

    Returns:
        New access and refresh tokens

    Raises:
        HTTPException: If refresh token is invalid
    """
    user_id = auth_service.validate_refresh_token(db, token_data.refresh_token)

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )

    user = user_service.get_user_by_id(db, user_id)

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )

    # Revoke old refresh token
    auth_service.revoke_refresh_token(db, token_data.refresh_token)

    # Create new tokens
    access_token = jwt_service.create_access_token(user.id, user.email)
    refresh_token = auth_service.create_refresh_token(db, user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=jwt_service.get_access_token_expire_seconds()
    )


@router.post("/logout", response_model=MessageResponse)
def logout(
    token_data: TokenRefreshRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout user by revoking refresh token.

    Args:
        token_data: Refresh token to revoke
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success message
    """
    auth_service.revoke_refresh_token(db, token_data.refresh_token)

    return MessageResponse(message="Successfully logged out")


@router.post("/change-password", response_model=MessageResponse)
def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Change user password.

    Args:
        password_data: Current and new password
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success message

    Raises:
        HTTPException: If current password is incorrect
    """
    success = auth_service.change_password(
        db,
        current_user.id,
        password_data.current_password,
        password_data.new_password
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    return MessageResponse(message="Password changed successfully")


@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """
    Get current authenticated user information.

    Args:
        current_user: Current authenticated user

    Returns:
        User information
    """
    return current_user
