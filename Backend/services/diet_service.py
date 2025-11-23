"""
Diet Service - Business logic for meal planning and nutrition tracking
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from Backend.agents import LlamaDietAgent
from Backend.models.database import MealPlanDB, DietProgressDB, RecipeDB, User
from Backend.models.schemas import (
    DietPlanRequest,
    DietPlanResponse,
    MealPlan,
    Recipe,
    DietProgress,
    NutritionalInfo,
    MealType,
)


class DietService:
    """
    Diet Service with advanced features:
    - AI-powered meal planning
    - Nutrition tracking
    - Recipe management
    - Shopping list generation
    - Progress analytics
    """

    def __init__(self, db: AsyncSession):
        self.db = db
        self.agent = LlamaDietAgent()

    async def create_diet_plan(
        self,
        request: DietPlanRequest,
        user_profile: Optional[Dict] = None
    ) -> DietPlanResponse:
        """Create a personalized diet plan using AI"""

        # Get user profile if not provided
        if not user_profile:
            user_profile = await self._get_user_profile(request.user_id)

        # Generate plan using LLAMA agent
        async with self.agent as agent:
            plan_response = await agent.generate_diet_plan(request, user_profile)

        # Save meal plans to database
        for meal_plan in plan_response.meal_plans:
            await self._save_meal_plan(meal_plan)

        return plan_response

    async def _get_user_profile(self, user_id: str) -> Dict:
        """Fetch user profile from database"""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            return {}

        return {
            "age": user.age,
            "weight": user.weight,
            "height": user.height,
            "gender": user.gender,
            "fitness_level": user.fitness_level,
            "goals": user.goals,
            "dietary_restrictions": user.dietary_restrictions,
            "preferred_diet_type": user.preferred_diet_type,
        }

    async def _save_meal_plan(self, meal_plan: MealPlan) -> None:
        """Save meal plan to database"""
        db_meal_plan = MealPlanDB(
            id=meal_plan.id,
            user_id=meal_plan.user_id,
            date=meal_plan.date,
            breakfast=meal_plan.breakfast.dict() if meal_plan.breakfast else None,
            lunch=meal_plan.lunch.dict() if meal_plan.lunch else None,
            dinner=meal_plan.dinner.dict() if meal_plan.dinner else None,
            snacks=[s.dict() for s in meal_plan.snacks],
            total_nutrition=meal_plan.total_nutrition.dict(),
            created_at=meal_plan.created_at,
            ai_notes=meal_plan.ai_notes,
        )

        self.db.add(db_meal_plan)
        await self.db.commit()

    async def get_meal_plan(self, user_id: str, plan_date: date) -> Optional[MealPlan]:
        """Get meal plan for a specific date"""
        result = await self.db.execute(
            select(MealPlanDB).where(
                MealPlanDB.user_id == user_id,
                MealPlanDB.date == plan_date
            )
        )
        db_plan = result.scalar_one_or_none()

        if not db_plan:
            return None

        return self._db_to_schema(db_plan)

    async def get_meal_plans(
        self,
        user_id: str,
        start_date: date,
        end_date: date
    ) -> List[MealPlan]:
        """Get meal plans for a date range"""
        result = await self.db.execute(
            select(MealPlanDB).where(
                MealPlanDB.user_id == user_id,
                MealPlanDB.date >= start_date,
                MealPlanDB.date <= end_date
            ).order_by(MealPlanDB.date)
        )

        db_plans = result.scalars().all()

        return [self._db_to_schema(p) for p in db_plans]

    def _db_to_schema(self, db_plan: MealPlanDB) -> MealPlan:
        """Convert database model to schema"""
        return MealPlan(
            id=db_plan.id,
            user_id=db_plan.user_id,
            date=db_plan.date,
            breakfast=Recipe(**db_plan.breakfast) if db_plan.breakfast else None,
            lunch=Recipe(**db_plan.lunch) if db_plan.lunch else None,
            dinner=Recipe(**db_plan.dinner) if db_plan.dinner else None,
            snacks=[Recipe(**s) for s in db_plan.snacks] if db_plan.snacks else [],
            total_nutrition=NutritionalInfo(**db_plan.total_nutrition),
            created_at=db_plan.created_at,
            ai_notes=db_plan.ai_notes,
        )

    async def log_meal(
        self,
        user_id: str,
        meal_date: date,
        recipe: Recipe
    ) -> DietProgress:
        """Log a consumed meal and update progress"""

        # Update or create progress record
        result = await self.db.execute(
            select(DietProgressDB).where(
                DietProgressDB.user_id == user_id,
                DietProgressDB.date == meal_date
            )
        )
        progress = result.scalar_one_or_none()

        if progress:
            # Update existing
            progress.meals_logged += 1
            progress.calories_consumed += recipe.nutrition.calories
            progress.protein_g += recipe.nutrition.protein_g
            progress.carbs_g += recipe.nutrition.carbs_g
            progress.fat_g += recipe.nutrition.fat_g
        else:
            # Create new
            progress = DietProgressDB(
                user_id=user_id,
                date=meal_date,
                meals_logged=1,
                calories_consumed=recipe.nutrition.calories,
                protein_g=recipe.nutrition.protein_g,
                carbs_g=recipe.nutrition.carbs_g,
                fat_g=recipe.nutrition.fat_g,
            )
            self.db.add(progress)

        await self.db.commit()

        return DietProgress(
            user_id=progress.user_id,
            date=progress.date,
            meals_logged=progress.meals_logged,
            calories_consumed=progress.calories_consumed,
            protein_g=progress.protein_g,
            carbs_g=progress.carbs_g,
            fat_g=progress.fat_g,
            water_ml=progress.water_ml,
            weight=progress.weight,
            notes=progress.notes,
        )

    async def get_progress(
        self,
        user_id: str,
        start_date: date,
        end_date: date
    ) -> List[DietProgress]:
        """Get diet progress for a date range"""
        result = await self.db.execute(
            select(DietProgressDB).where(
                DietProgressDB.user_id == user_id,
                DietProgressDB.date >= start_date,
                DietProgressDB.date <= end_date
            ).order_by(DietProgressDB.date)
        )

        progress_records = result.scalars().all()

        return [
            DietProgress(
                user_id=p.user_id,
                date=p.date,
                meals_logged=p.meals_logged,
                calories_consumed=p.calories_consumed,
                protein_g=p.protein_g,
                carbs_g=p.carbs_g,
                fat_g=p.fat_g,
                water_ml=p.water_ml,
                weight=p.weight,
                notes=p.notes,
            )
            for p in progress_records
        ]

    async def analyze_nutrition_progress(self, user_id: str) -> Dict[str, Any]:
        """Get AI-powered nutrition progress analysis"""
        progress = await self.get_progress(
            user_id,
            date.today() - timedelta(days=30),
            date.today()
        )

        progress_data = [
            {
                "date": p.date.isoformat(),
                "calories": p.calories_consumed,
                "protein": p.protein_g,
                "carbs": p.carbs_g,
                "fat": p.fat_g,
                "meals_logged": p.meals_logged,
            }
            for p in progress
        ]

        async with self.agent as agent:
            analysis = await agent.analyze_nutrition_progress(user_id, progress_data)

        return analysis

    async def search_recipes(
        self,
        meal_type: Optional[MealType] = None,
        diet_type: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 20
    ) -> List[Recipe]:
        """Search recipes in the database"""
        query = select(RecipeDB)

        if meal_type:
            query = query.where(RecipeDB.meal_type == meal_type.value)

        if diet_type:
            query = query.where(RecipeDB.diet_type.contains([diet_type]))

        if search:
            query = query.where(RecipeDB.name.ilike(f"%{search}%"))

        query = query.limit(limit)

        result = await self.db.execute(query)
        db_recipes = result.scalars().all()

        return [
            Recipe(
                id=r.id,
                name=r.name,
                description=r.description,
                meal_type=MealType(r.meal_type),
                ingredients=r.ingredients,
                instructions=r.instructions,
                prep_time_minutes=r.prep_time_minutes,
                cook_time_minutes=r.cook_time_minutes,
                servings=r.servings,
                nutrition=NutritionalInfo(**r.nutrition),
                tags=r.tags or [],
                diet_type=r.diet_type or [],
                image_url=r.image_url,
            )
            for r in db_recipes
        ]

    async def update_weight(self, user_id: str, weight: float, log_date: date) -> None:
        """Update user's weight in progress log"""
        result = await self.db.execute(
            select(DietProgressDB).where(
                DietProgressDB.user_id == user_id,
                DietProgressDB.date == log_date
            )
        )
        progress = result.scalar_one_or_none()

        if progress:
            progress.weight = weight
        else:
            progress = DietProgressDB(
                user_id=user_id,
                date=log_date,
                weight=weight,
                meals_logged=0,
                calories_consumed=0,
                protein_g=0,
                carbs_g=0,
                fat_g=0,
            )
            self.db.add(progress)

        await self.db.commit()
