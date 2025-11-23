"""
Yoga API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import date, datetime, timedelta

from Backend.models.schemas import (
    YogaPlanRequest,
    YogaPlanResponse,
    YogaSession,
    YogaProgress,
    YogaPose,
    YogaLevel,
)
from Backend.services import YogaService
from Backend.utils.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/yoga", tags=["Yoga"])


@router.post("/plan", response_model=YogaPlanResponse)
async def create_yoga_plan(
    request: YogaPlanRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Generate a personalized yoga session plan using KIMI 2 AI

    Features:
    - Personalized to user's level and goals
    - Style-specific sequences (Hatha, Vinyasa, etc.)
    - Warm-up and cool-down included
    - Detailed pose instructions
    - Calorie estimation
    - AI recommendations
    """
    service = YogaService(db)

    try:
        plan = await service.create_yoga_plan(request)
        return plan
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate yoga plan: {str(e)}"
        )


@router.get("/sessions/{user_id}", response_model=List[YogaSession])
async def get_user_sessions(
    user_id: str,
    limit: int = 10,
    completed_only: bool = False,
    db: AsyncSession = Depends(get_db)
):
    """Get user's yoga sessions"""
    service = YogaService(db)

    try:
        sessions = await service.get_user_sessions(user_id, limit, completed_only)
        return sessions
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch sessions: {str(e)}"
        )


@router.post("/sessions/{session_id}/complete")
async def complete_session(
    session_id: str,
    user_id: str,
    notes: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Mark a yoga session as completed

    This will:
    - Update session status
    - Update daily progress tracking
    - Add poses to mastered list
    - Update calorie burn tracking
    """
    service = YogaService(db)

    try:
        session = await service.complete_session(session_id, user_id, notes)
        return {"message": "Session completed successfully", "session": session}
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete session: {str(e)}"
        )


@router.get("/progress/{user_id}", response_model=List[YogaProgress])
async def get_progress(
    user_id: str,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Get yoga progress for a date range

    Returns daily statistics including:
    - Sessions completed
    - Total minutes practiced
    - Calories burned
    - Poses mastered
    - Flexibility score
    """
    if not start_date:
        start_date = date.today() - timedelta(days=30)
    if not end_date:
        end_date = date.today()

    service = YogaService(db)

    try:
        progress = await service.get_progress(user_id, start_date, end_date)
        return progress
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch progress: {str(e)}"
        )


@router.get("/progress/{user_id}/analysis")
async def analyze_progress(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Get AI-powered progress analysis

    Uses KIMI 2 to analyze your yoga journey and provide:
    - Progress summary
    - Strengths and areas for improvement
    - Personalized recommendations
    - Achievement recognition
    - Level progression readiness
    """
    service = YogaService(db)

    try:
        analysis = await service.analyze_progress(user_id)
        return analysis
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze progress: {str(e)}"
        )


@router.get("/poses", response_model=List[YogaPose])
async def get_pose_library(
    difficulty: Optional[YogaLevel] = None,
    search: Optional[str] = None,
    limit: int = 50,
    db: AsyncSession = Depends(get_db)
):
    """
    Browse the yoga pose library

    Search and filter poses by:
    - Difficulty level
    - Name or Sanskrit name
    - Benefits
    """
    service = YogaService(db)

    try:
        poses = await service.get_pose_library(difficulty, search, limit)
        return poses
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch poses: {str(e)}"
        )
