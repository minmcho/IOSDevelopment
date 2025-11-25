"""
Micronutrient Service - Business logic for micronutrient tracking and analysis
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from Backend.agents import LlamaDietAgent
from Backend.models.database import MealPlanDB, DietProgressDB, User
from Backend.models.schemas import (
    Micronutrients,
    Vitamins,
    Minerals,
    MicronutrientGoals,
    MicronutrientDeficiency,
    MicronutrientAnalysis,
    MicronutrientRequest,
)


class MicronutrientService:
    """
    Micronutrient Service with advanced features:
    - Detailed vitamin and mineral tracking
    - RDA (Recommended Daily Allowance) comparison
    - Deficiency detection
    - AI-powered recommendations
    - Supplementation suggestions
    """

    def __init__(self, db: AsyncSession):
        self.db = db
        self.agent = LlamaDietAgent()

    async def get_micronutrient_goals(self, user_id: str) -> MicronutrientGoals:
        """Get personalized micronutrient goals based on user profile"""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            # Return default goals
            return MicronutrientGoals(
                user_id=user_id,
                age=30,
                gender="male"
            )

        age = user.age or 30
        gender = user.gender or "male"

        # Adjust goals based on age and gender
        goals = MicronutrientGoals(
            user_id=user_id,
            age=age,
            gender=gender
        )

        # Age-specific adjustments
        if age < 18:
            goals.calcium_mg = 1300  # Growing bones
        elif age > 50:
            if gender == "female":
                goals.calcium_mg = 1200
                goals.vitamin_d_mcg = 20  # Postmenopausal
                goals.iron_mg = 8  # Postmenopausal
            else:
                goals.vitamin_d_mcg = 20
                goals.calcium_mg = 1200

        # Gender-specific adjustments
        if gender == "female" and age <= 50:
            goals.iron_mg = 18  # Menstruating women
            goals.folate_mcg = 400  # Childbearing age
            goals.vitamin_a_mcg = 700

        return goals

    async def analyze_micronutrients(
        self,
        user_id: str,
        start_date: date,
        end_date: date,
        include_ai_analysis: bool = True
    ) -> MicronutrientAnalysis:
        """
        Comprehensive micronutrient analysis for a date range
        """

        # Get user profile
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        # Get meal plans for the period
        meal_plans_result = await self.db.execute(
            select(MealPlanDB).where(
                MealPlanDB.user_id == user_id,
                MealPlanDB.date >= start_date,
                MealPlanDB.date <= end_date
            )
        )
        meal_plans = meal_plans_result.scalars().all()

        # Calculate average micronutrient intake
        avg_vitamins, avg_minerals = self._calculate_average_micronutrients(meal_plans)

        # Get personalized goals
        goals = await self.get_micronutrient_goals(user_id)

        # Detect deficiencies and excesses
        deficiencies = self._detect_deficiencies(avg_vitamins, avg_minerals, goals)
        adequacies = self._detect_adequacies(avg_vitamins, avg_minerals, goals)
        excesses = self._detect_excesses(avg_vitamins, avg_minerals, goals)

        # Calculate completion percentages for charts
        vitamin_percentages = self._calculate_vitamin_percentages(avg_vitamins, goals)
        mineral_percentages = self._calculate_mineral_percentages(avg_minerals, goals)

        # AI analysis
        ai_recommendations = ""
        supplement_suggestions = []
        dietary_adjustments = []

        if include_ai_analysis:
            meal_data = self._prepare_meal_data_for_ai(meal_plans)
            user_profile = {
                "age": user.age if user else 30,
                "gender": user.gender if user else "male",
                "goals": user.goals if user else []
            }

            async with self.agent as agent:
                ai_analysis = await agent.analyze_micronutrients(
                    user_id,
                    meal_data,
                    user_profile
                )

            ai_recommendations = ai_analysis.get("summary", "")
            supplement_suggestions = [
                d.get("supplement_advice", "")
                for d in ai_analysis.get("deficiencies", [])
                if d.get("supplement_advice")
            ]
            dietary_adjustments = ai_analysis.get("recommendations", [])

        period = f"{start_date} to {end_date}"

        return MicronutrientAnalysis(
            user_id=user_id,
            period=period,
            start_date=start_date,
            end_date=end_date,
            avg_vitamins=avg_vitamins,
            avg_minerals=avg_minerals,
            goals=goals,
            deficiencies=deficiencies,
            adequacies=adequacies,
            excesses=excesses,
            ai_recommendations=ai_recommendations,
            supplement_suggestions=supplement_suggestions,
            dietary_adjustments=dietary_adjustments,
            vitamin_completion_percentages=vitamin_percentages,
            mineral_completion_percentages=mineral_percentages
        )

    def _calculate_average_micronutrients(self, meal_plans: List[MealPlanDB]) -> tuple[Vitamins, Minerals]:
        """Calculate average daily micronutrient intake"""
        if not meal_plans:
            return Vitamins(), Minerals()

        total_vitamins = {
            "vitamin_a_mcg": 0.0,
            "vitamin_c_mg": 0.0,
            "vitamin_d_mcg": 0.0,
            "vitamin_e_mg": 0.0,
            "vitamin_k_mcg": 0.0,
            "vitamin_b1_thiamin_mg": 0.0,
            "vitamin_b2_riboflavin_mg": 0.0,
            "vitamin_b3_niacin_mg": 0.0,
            "vitamin_b6_mg": 0.0,
            "vitamin_b9_folate_mcg": 0.0,
            "vitamin_b12_mcg": 0.0
        }

        total_minerals = {
            "calcium_mg": 0.0,
            "iron_mg": 0.0,
            "magnesium_mg": 0.0,
            "potassium_mg": 0.0,
            "sodium_mg": 0.0,
            "zinc_mg": 0.0,
            "selenium_mcg": 0.0
        }

        for plan in meal_plans:
            # Extract micronutrients from total_nutrition if available
            nutrition = plan.total_nutrition
            if nutrition and nutrition.get("micronutrients"):
                micros = nutrition["micronutrients"]

                # Add vitamins
                if "vitamins" in micros:
                    for key, value in micros["vitamins"].items():
                        if key in total_vitamins and value:
                            total_vitamins[key] += value

                # Add minerals
                if "minerals" in micros:
                    for key, value in micros["minerals"].items():
                        if key in total_minerals and value:
                            total_minerals[key] += value

        # Calculate averages
        num_days = len(meal_plans)
        avg_vitamins = Vitamins(**{k: round(v / num_days, 2) for k, v in total_vitamins.items()})
        avg_minerals = Minerals(**{k: round(v / num_days, 2) for k, v in total_minerals.items()})

        return avg_vitamins, avg_minerals

    def _detect_deficiencies(
        self,
        vitamins: Vitamins,
        minerals: Minerals,
        goals: MicronutrientGoals
    ) -> List[MicronutrientDeficiency]:
        """Detect micronutrient deficiencies"""
        deficiencies = []

        # Vitamin deficiencies
        vitamin_checks = [
            ("Vitamin A", vitamins.vitamin_a_mcg, goals.vitamin_a_mcg,
             ["Night blindness", "Weakened immune system"],
             ["Carrots", "Sweet potatoes", "Spinach"]),
            ("Vitamin C", vitamins.vitamin_c_mg, goals.vitamin_c_mg,
             ["Weakened immunity", "Slow wound healing"],
             ["Citrus fruits", "Bell peppers", "Broccoli"]),
            ("Vitamin D", vitamins.vitamin_d_mcg, goals.vitamin_d_mcg,
             ["Bone weakness", "Muscle pain"],
             ["Fatty fish", "Fortified milk", "Sunlight exposure"]),
            ("Iron", minerals.iron_mg, goals.iron_mg,
             ["Fatigue", "Anemia"],
             ["Red meat", "Beans", "Fortified cereals"]),
            ("Calcium", minerals.calcium_mg, goals.calcium_mg,
             ["Bone loss", "Osteoporosis risk"],
             ["Dairy products", "Leafy greens", "Fortified foods"]),
        ]

        for name, current, target, impacts, sources in vitamin_checks:
            if current and target and current < target * 0.7:  # Less than 70% of RDA
                deficit_pct = ((target - current) / target) * 100
                severity = "high" if deficit_pct > 50 else "moderate" if deficit_pct > 30 else "low"

                deficiencies.append(MicronutrientDeficiency(
                    nutrient_name=name,
                    current_intake=current or 0,
                    recommended_intake=target,
                    deficit_percentage=deficit_pct,
                    health_impacts=impacts,
                    food_sources=sources,
                    severity=severity
                ))

        return deficiencies

    def _detect_adequacies(self, vitamins: Vitamins, minerals: Minerals, goals: MicronutrientGoals) -> List[str]:
        """Detect nutrients meeting RDA goals"""
        adequacies = []

        # Check vitamins
        if vitamins.vitamin_a_mcg and vitamins.vitamin_a_mcg >= goals.vitamin_a_mcg * 0.9:
            adequacies.append("Vitamin A")
        if vitamins.vitamin_c_mg and vitamins.vitamin_c_mg >= goals.vitamin_c_mg * 0.9:
            adequacies.append("Vitamin C")

        # Check minerals
        if minerals.calcium_mg and minerals.calcium_mg >= goals.calcium_mg * 0.9:
            adequacies.append("Calcium")
        if minerals.iron_mg and minerals.iron_mg >= goals.iron_mg * 0.9:
            adequacies.append("Iron")

        return adequacies

    def _detect_excesses(self, vitamins: Vitamins, minerals: Minerals, goals: MicronutrientGoals) -> List[str]:
        """Detect nutrients exceeding safe upper limits"""
        excesses = []

        # Sodium check (upper limit is the goal itself)
        if minerals.sodium_mg and minerals.sodium_mg > goals.sodium_mg * 1.2:
            excesses.append("Sodium (consider reducing salt intake)")

        return excesses

    def _calculate_vitamin_percentages(self, vitamins: Vitamins, goals: MicronutrientGoals) -> Dict[str, float]:
        """Calculate percentage of RDA for each vitamin"""
        return {
            "Vitamin A": min((vitamins.vitamin_a_mcg or 0) / goals.vitamin_a_mcg * 100, 150),
            "Vitamin C": min((vitamins.vitamin_c_mg or 0) / goals.vitamin_c_mg * 100, 150),
            "Vitamin D": min((vitamins.vitamin_d_mcg or 0) / goals.vitamin_d_mcg * 100, 150),
            "Vitamin E": min((vitamins.vitamin_e_mg or 0) / goals.vitamin_e_mg * 100, 150),
            "Vitamin K": min((vitamins.vitamin_k_mcg or 0) / goals.vitamin_k_mcg * 100, 150),
            "Vitamin B12": min((vitamins.vitamin_b12_mcg or 0) / goals.vitamin_b12_mcg * 100, 150),
            "Folate": min((vitamins.vitamin_b9_folate_mcg or 0) / goals.vitamin_b9_mcg * 100, 150),
        }

    def _calculate_mineral_percentages(self, minerals: Minerals, goals: MicronutrientGoals) -> Dict[str, float]:
        """Calculate percentage of RDA for each mineral"""
        return {
            "Calcium": min((minerals.calcium_mg or 0) / goals.calcium_mg * 100, 150),
            "Iron": min((minerals.iron_mg or 0) / goals.iron_mg * 100, 150),
            "Magnesium": min((minerals.magnesium_mg or 0) / goals.magnesium_mg * 100, 150),
            "Potassium": min((minerals.potassium_mg or 0) / goals.potassium_mg * 100, 150),
            "Zinc": min((minerals.zinc_mg or 0) / goals.zinc_mg * 100, 150),
            "Selenium": min((minerals.selenium_mcg or 0) / goals.selenium_mcg * 100, 150),
        }

    def _prepare_meal_data_for_ai(self, meal_plans: List[MealPlanDB]) -> List[Dict]:
        """Prepare meal data for AI analysis"""
        meal_data = []

        for plan in meal_plans:
            meal_data.append({
                "date": plan.date.isoformat(),
                "breakfast": plan.breakfast.get("name") if plan.breakfast else None,
                "lunch": plan.lunch.get("name") if plan.lunch else None,
                "dinner": plan.dinner.get("name") if plan.dinner else None,
                "nutrition": plan.total_nutrition
            })

        return meal_data
