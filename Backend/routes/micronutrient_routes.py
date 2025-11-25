"""
Micronutrient API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from datetime import date, timedelta

from Backend.models.schemas import (
    MicronutrientGoals,
    MicronutrientAnalysis,
    MicronutrientRequest,
)
from Backend.services.micronutrient_service import MicronutrientService
from Backend.utils.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/micronutrients", tags=["Micronutrients"])


@router.get("/goals/{user_id}", response_model=MicronutrientGoals)
async def get_micronutrient_goals(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Get personalized micronutrient goals based on user profile

    Goals are automatically adjusted based on:
    - Age
    - Gender
    - Activity level
    - Health conditions

    Returns RDA (Recommended Daily Allowance) values for vitamins and minerals.
    """
    service = MicronutrientService(db)

    try:
        goals = await service.get_micronutrient_goals(user_id)
        return goals
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get micronutrient goals: {str(e)}"
        )


@router.post("/analyze", response_model=MicronutrientAnalysis)
async def analyze_micronutrients(
    request: MicronutrientRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Comprehensive micronutrient analysis

    Analyzes vitamin and mineral intake over a specified period and provides:
    - Average daily intake for all micronutrients
    - Comparison with RDA goals
    - Deficiency detection with severity levels
    - Food source recommendations
    - AI-powered personalized advice
    - Supplementation suggestions
    - Visual data for charts and graphs

    Features:
    - Tracks 13 vitamins (A, C, D, E, K, B-complex)
    - Tracks 12 minerals (Calcium, Iron, Magnesium, etc.)
    - Detects deficiencies and excesses
    - Provides health impact information
    - Suggests dietary adjustments
    """
    service = MicronutrientService(db)

    try:
        analysis = await service.analyze_micronutrients(
            user_id=request.user_id,
            start_date=request.start_date,
            end_date=request.end_date,
            include_ai_analysis=request.include_ai_analysis
        )
        return analysis
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze micronutrients: {str(e)}"
        )


@router.get("/analyze/{user_id}", response_model=MicronutrientAnalysis)
async def get_recent_micronutrient_analysis(
    user_id: str,
    days: int = 7,
    include_ai: bool = True,
    db: AsyncSession = Depends(get_db)
):
    """
    Get micronutrient analysis for the last N days

    Quick endpoint for getting recent analysis without specifying dates.
    Defaults to last 7 days.

    Parameters:
    - days: Number of days to analyze (default: 7, max: 90)
    - include_ai: Include AI recommendations (default: true)
    """
    if days > 90:
        days = 90

    end_date = date.today()
    start_date = end_date - timedelta(days=days)

    service = MicronutrientService(db)

    try:
        analysis = await service.analyze_micronutrients(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date,
            include_ai_analysis=include_ai
        )
        return analysis
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze micronutrients: {str(e)}"
        )


@router.get("/deficiencies/{user_id}")
async def get_deficiencies_quick_check(
    user_id: str,
    days: int = 14,
    db: AsyncSession = Depends(get_db)
):
    """
    Quick deficiency check

    Returns only the deficiencies detected in the last N days.
    Useful for notifications and alerts.

    Response format:
    {
      "has_deficiencies": true,
      "critical_count": 2,
      "moderate_count": 1,
      "deficiencies": [...]
    }
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days)

    service = MicronutrientService(db)

    try:
        analysis = await service.analyze_micronutrients(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date,
            include_ai_analysis=False  # Skip AI for quick check
        )

        critical = [d for d in analysis.deficiencies if d.severity == "high"]
        moderate = [d for d in analysis.deficiencies if d.severity == "moderate"]

        return {
            "has_deficiencies": len(analysis.deficiencies) > 0,
            "critical_count": len(critical),
            "moderate_count": len(moderate),
            "deficiencies": analysis.deficiencies,
            "period": f"Last {days} days"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check deficiencies: {str(e)}"
        )


@router.get("/summary/{user_id}")
async def get_micronutrient_summary(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Daily micronutrient summary

    Quick overview of today's micronutrient intake vs goals.
    Perfect for dashboard widgets.
    """
    today = date.today()

    service = MicronutrientService(db)

    try:
        analysis = await service.analyze_micronutrients(
            user_id=user_id,
            start_date=today,
            end_date=today,
            include_ai_analysis=False
        )

        return {
            "date": today,
            "vitamin_coverage": analysis.vitamin_completion_percentages,
            "mineral_coverage": analysis.mineral_completion_percentages,
            "deficiency_count": len(analysis.deficiencies),
            "adequacy_count": len(analysis.adequacies),
            "status": "good" if len(analysis.deficiencies) == 0 else "needs_attention"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get micronutrient summary: {str(e)}"
        )
