"""
Analytics API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
from datetime import date, timedelta

from Backend.models.schemas import AnalyticsRequest, AnalyticsResponse
from Backend.services import YogaService, DietService
from Backend.utils.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])


@router.post("/comprehensive", response_model=AnalyticsResponse)
async def get_comprehensive_analytics(
    request: AnalyticsRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Get comprehensive analytics across yoga and diet

    Combines data from:
    - Yoga sessions and progress
    - Meal plans and nutrition tracking
    - AI-powered insights
    - Trend analysis
    - Goal progress
    """
    yoga_service = YogaService(db)
    diet_service = DietService(db)

    try:
        # Gather yoga analytics
        yoga_analytics = {}
        if "yoga" in request.metrics:
            yoga_progress = await yoga_service.get_progress(
                request.user_id,
                request.start_date,
                request.end_date
            )
            yoga_analytics = _analyze_yoga_data(yoga_progress)

        # Gather diet analytics
        diet_analytics = {}
        if "diet" in request.metrics:
            diet_progress = await diet_service.get_progress(
                request.user_id,
                request.start_date,
                request.end_date
            )
            diet_analytics = _analyze_diet_data(diet_progress)

        # Generate insights
        insights = _generate_insights(yoga_analytics, diet_analytics)

        # Calculate trends
        trends = _calculate_trends(yoga_analytics, diet_analytics)

        # Generate AI summary
        ai_summary = await _generate_ai_summary(
            request,
            yoga_analytics,
            diet_analytics,
            yoga_service,
            diet_service
        )

        return AnalyticsResponse(
            user_id=request.user_id,
            period=f"{request.start_date} to {request.end_date}",
            yoga_analytics=yoga_analytics,
            diet_analytics=diet_analytics,
            insights=insights,
            trends=trends,
            ai_summary=ai_summary,
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate analytics: {str(e)}"
        )


@router.get("/dashboard/{user_id}")
async def get_dashboard_summary(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Get dashboard summary for today and current week

    Returns quick stats for:
    - Today's activity
    - This week's progress
    - Current streaks
    - Quick recommendations
    """
    yoga_service = YogaService(db)
    diet_service = DietService(db)

    try:
        today = date.today()
        week_start = today - timedelta(days=today.weekday())

        # Today's stats
        today_yoga = await yoga_service.get_progress(user_id, today, today)
        today_diet = await diet_service.get_progress(user_id, today, today)

        # Week's stats
        week_yoga = await yoga_service.get_progress(user_id, week_start, today)
        week_diet = await diet_service.get_progress(user_id, week_start, today)

        # Calculate streaks
        streak_days = await _calculate_streak(user_id, yoga_service, diet_service)

        return {
            "today": {
                "yoga": {
                    "sessions": today_yoga[0].sessions_completed if today_yoga else 0,
                    "minutes": today_yoga[0].total_minutes if today_yoga else 0,
                    "calories_burned": today_yoga[0].calories_burned if today_yoga else 0,
                },
                "diet": {
                    "meals_logged": today_diet[0].meals_logged if today_diet else 0,
                    "calories": today_diet[0].calories_consumed if today_diet else 0,
                }
            },
            "this_week": {
                "yoga": {
                    "total_sessions": sum(p.sessions_completed for p in week_yoga),
                    "total_minutes": sum(p.total_minutes for p in week_yoga),
                    "total_calories_burned": sum(p.calories_burned for p in week_yoga),
                },
                "diet": {
                    "total_meals": sum(p.meals_logged for p in week_diet),
                    "avg_calories": sum(p.calories_consumed for p in week_diet) / len(week_diet) if week_diet else 0,
                }
            },
            "streaks": streak_days,
            "date": today.isoformat(),
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate dashboard: {str(e)}"
        )


def _analyze_yoga_data(progress_list) -> Dict[str, Any]:
    """Analyze yoga progress data"""
    if not progress_list:
        return {}

    return {
        "total_sessions": sum(p.sessions_completed for p in progress_list),
        "total_minutes": sum(p.total_minutes for p in progress_list),
        "total_calories_burned": sum(p.calories_burned for p in progress_list),
        "avg_session_duration": sum(p.total_minutes for p in progress_list) / len(progress_list) if progress_list else 0,
        "days_active": len([p for p in progress_list if p.sessions_completed > 0]),
        "consistency_rate": len([p for p in progress_list if p.sessions_completed > 0]) / len(progress_list) * 100 if progress_list else 0,
    }


def _analyze_diet_data(progress_list) -> Dict[str, Any]:
    """Analyze diet progress data"""
    if not progress_list:
        return {}

    return {
        "total_meals_logged": sum(p.meals_logged for p in progress_list),
        "avg_daily_calories": sum(p.calories_consumed for p in progress_list) / len(progress_list) if progress_list else 0,
        "avg_protein": sum(p.protein_g for p in progress_list) / len(progress_list) if progress_list else 0,
        "avg_carbs": sum(p.carbs_g for p in progress_list) / len(progress_list) if progress_list else 0,
        "avg_fat": sum(p.fat_g for p in progress_list) / len(progress_list) if progress_list else 0,
        "days_tracked": len([p for p in progress_list if p.meals_logged > 0]),
        "tracking_consistency": len([p for p in progress_list if p.meals_logged > 0]) / len(progress_list) * 100 if progress_list else 0,
    }


def _generate_insights(yoga_data: Dict, diet_data: Dict) -> list:
    """Generate actionable insights from data"""
    insights = []

    # Yoga insights
    if yoga_data:
        if yoga_data.get("consistency_rate", 0) >= 80:
            insights.append("Excellent yoga consistency! You're building a strong practice habit.")
        elif yoga_data.get("consistency_rate", 0) < 50:
            insights.append("Try to increase yoga practice consistency for better results.")

        if yoga_data.get("avg_session_duration", 0) < 20:
            insights.append("Consider extending session duration to 30+ minutes for deeper benefits.")

    # Diet insights
    if diet_data:
        if diet_data.get("tracking_consistency", 0) >= 80:
            insights.append("Great job tracking your nutrition consistently!")
        elif diet_data.get("tracking_consistency", 0) < 50:
            insights.append("Track meals more consistently to better understand your nutrition patterns.")

        protein_ratio = diet_data.get("avg_protein", 0) * 4 / diet_data.get("avg_daily_calories", 1) if diet_data.get("avg_daily_calories", 0) > 0 else 0
        if protein_ratio < 0.15:
            insights.append("Consider increasing protein intake for better muscle recovery and satiety.")

    # Combined insights
    if yoga_data and diet_data:
        if yoga_data.get("days_active", 0) > 0 and diet_data.get("days_tracked", 0) > 0:
            insights.append("Combining yoga practice with nutrition tracking - a holistic approach to wellness!")

    return insights


def _calculate_trends(yoga_data: Dict, diet_data: Dict) -> Dict[str, str]:
    """Calculate trends from data"""
    trends = {}

    if yoga_data.get("total_sessions", 0) > 0:
        trends["yoga_activity"] = "active"
        trends["yoga_consistency"] = "improving" if yoga_data.get("consistency_rate", 0) > 60 else "needs attention"

    if diet_data.get("total_meals_logged", 0) > 0:
        trends["nutrition_tracking"] = "active"
        trends["calorie_trend"] = "stable"  # Would need historical comparison

    return trends


async def _generate_ai_summary(
    request: AnalyticsRequest,
    yoga_data: Dict,
    diet_data: Dict,
    yoga_service: YogaService,
    diet_service: DietService
) -> str:
    """Generate AI-powered summary"""
    summary_parts = []

    if yoga_data:
        summary_parts.append(f"Yoga: {yoga_data.get('total_sessions', 0)} sessions, {yoga_data.get('total_minutes', 0)} minutes practiced")

    if diet_data:
        summary_parts.append(f"Nutrition: {diet_data.get('total_meals_logged', 0)} meals logged, averaging {diet_data.get('avg_daily_calories', 0):.0f} calories/day")

    if not summary_parts:
        return "Start your wellness journey by tracking yoga sessions and meals!"

    return "Period summary: " + ". ".join(summary_parts) + ". Continue your great progress!"


async def _calculate_streak(user_id: str, yoga_service: YogaService, diet_service: DietService) -> Dict[str, int]:
    """Calculate current streaks"""
    today = date.today()
    streak_yoga = 0
    streak_diet = 0

    # Check backwards from today
    for i in range(30):  # Check up to 30 days back
        check_date = today - timedelta(days=i)

        yoga_progress = await yoga_service.get_progress(user_id, check_date, check_date)
        diet_progress = await diet_service.get_progress(user_id, check_date, check_date)

        if yoga_progress and yoga_progress[0].sessions_completed > 0:
            streak_yoga += 1
        else:
            if i > 0:  # Don't break on first day
                break

    for i in range(30):
        check_date = today - timedelta(days=i)

        diet_progress = await diet_service.get_progress(user_id, check_date, check_date)

        if diet_progress and diet_progress[0].meals_logged > 0:
            streak_diet += 1
        else:
            if i > 0:
                break

    return {
        "yoga_streak_days": streak_yoga,
        "diet_streak_days": streak_diet,
        "total_active_days": max(streak_yoga, streak_diet)
    }
