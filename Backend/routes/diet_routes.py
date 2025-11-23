"""
Diet API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import date, datetime, timedelta

from Backend.models.schemas import (
    DietPlanRequest,
    DietPlanResponse,
    MealPlan,
    Recipe,
    DietProgress,
    MealType,
)
from Backend.services import DietService
from Backend.utils.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/diet", tags=["Diet"])


@router.post("/plan", response_model=DietPlanResponse)
async def create_diet_plan(
    request: DietPlanRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Generate a personalized meal plan using LLAMA 3.2 AI

    Features:
    - Multi-day meal planning (1-30 days)
    - Calorie and macro optimization
    - Dietary restriction compliance
    - Recipe generation with instructions
    - Shopping list generation
    - AI nutrition recommendations
    - Cultural diversity in meals
    """
    service = DietService(db)

    try:
        plan = await service.create_diet_plan(request)
        return plan
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate diet plan: {str(e)}"
        )


@router.get("/meal-plan/{user_id}/{plan_date}", response_model=MealPlan)
async def get_meal_plan(
    user_id: str,
    plan_date: date,
    db: AsyncSession = Depends(get_db)
):
    """Get meal plan for a specific date"""
    service = DietService(db)

    try:
        meal_plan = await service.get_meal_plan(user_id, plan_date)
        if not meal_plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal plan not found for this date"
            )
        return meal_plan
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch meal plan: {str(e)}"
        )


@router.get("/meal-plans/{user_id}", response_model=List[MealPlan])
async def get_meal_plans(
    user_id: str,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db)
):
    """Get meal plans for a date range"""
    if not start_date:
        start_date = date.today()
    if not end_date:
        end_date = date.today() + timedelta(days=7)

    service = DietService(db)

    try:
        meal_plans = await service.get_meal_plans(user_id, start_date, end_date)
        return meal_plans
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch meal plans: {str(e)}"
        )


@router.post("/log-meal/{user_id}")
async def log_meal(
    user_id: str,
    meal_date: date,
    recipe: Recipe,
    db: AsyncSession = Depends(get_db)
):
    """
    Log a consumed meal

    This will:
    - Update daily nutrition tracking
    - Add calories and macros to daily totals
    - Increment meals logged count
    """
    service = DietService(db)

    try:
        progress = await service.log_meal(user_id, meal_date, recipe)
        return {"message": "Meal logged successfully", "progress": progress}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log meal: {str(e)}"
        )


@router.get("/progress/{user_id}", response_model=List[DietProgress])
async def get_progress(
    user_id: str,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Get nutrition progress for a date range

    Returns daily statistics including:
    - Meals logged
    - Calories consumed
    - Protein, carbs, and fat intake
    - Water consumption
    - Weight tracking
    """
    if not start_date:
        start_date = date.today() - timedelta(days=30)
    if not end_date:
        end_date = date.today()

    service = DietService(db)

    try:
        progress = await service.get_progress(user_id, start_date, end_date)
        return progress
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch progress: {str(e)}"
        )


@router.get("/progress/{user_id}/analysis")
async def analyze_nutrition_progress(
    user_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Get AI-powered nutrition analysis

    Uses LLAMA 3.2 to analyze your nutrition data and provide:
    - Progress summary
    - Strengths and weaknesses
    - Macro balance assessment
    - Personalized recommendations
    - Achievement recognition
    """
    service = DietService(db)

    try:
        analysis = await service.analyze_nutrition_progress(user_id)
        return analysis
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze nutrition progress: {str(e)}"
        )


@router.get("/recipes", response_model=List[Recipe])
async def search_recipes(
    meal_type: Optional[MealType] = None,
    diet_type: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = 20,
    db: AsyncSession = Depends(get_db)
):
    """
    Search recipes in the database

    Filter by:
    - Meal type (breakfast, lunch, dinner, snack)
    - Diet type (vegan, keto, etc.)
    - Keyword search
    """
    service = DietService(db)

    try:
        recipes = await service.search_recipes(meal_type, diet_type, search, limit)
        return recipes
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to search recipes: {str(e)}"
        )


@router.post("/weight/{user_id}")
async def update_weight(
    user_id: str,
    weight: float,
    log_date: date,
    db: AsyncSession = Depends(get_db)
):
    """Update user's weight in progress log"""
    service = DietService(db)

    try:
        await service.update_weight(user_id, weight, log_date)
        return {"message": "Weight updated successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update weight: {str(e)}"
        )
