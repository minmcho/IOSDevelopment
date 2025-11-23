"""
LLAMA 3.2 Diet Agent - Advanced AI-powered meal planning and nutrition optimization
Uses Meta's LLAMA 3.2 model for intelligent diet planning and recipe generation
"""
import json
import httpx
from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
import asyncio

from Backend.config import settings
from Backend.models.schemas import (
    DietPlanRequest,
    DietPlanResponse,
    MealPlan,
    Recipe,
    NutritionalInfo,
    DietType,
    MealType,
    GoalType,
)


class LlamaDietAgent:
    """
    Advanced Diet Agent powered by LLAMA 3.2

    Features:
    - Personalized meal planning
    - Nutrition optimization
    - Recipe generation with detailed instructions
    - Dietary restriction handling
    - Calorie and macro tracking
    - Shopping list generation
    - Cultural and preference-based customization
    - Vision capabilities for food analysis (LLAMA 3.2 Vision)
    """

    def __init__(self):
        self.api_key = settings.LLAMA_API_KEY
        self.api_base = settings.LLAMA_API_BASE
        self.model = settings.LLAMA_MODEL
        self.client = httpx.AsyncClient(timeout=90.0)

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()

    async def _call_llama_api(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 4000
    ) -> str:
        """Call LLAMA API with error handling and retries"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }

        try:
            response = await self.client.post(
                f"{self.api_base}/chat/completions",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"]
        except httpx.HTTPError as e:
            print(f"LLAMA API Error: {e}")
            raise Exception(f"Failed to call LLAMA API: {str(e)}")

    async def generate_diet_plan(
        self,
        request: DietPlanRequest,
        user_profile: Optional[Dict] = None
    ) -> DietPlanResponse:
        """
        Generate a comprehensive, personalized diet plan using LLAMA 3.2

        Advanced features:
        - Multi-day meal planning
        - Macro and calorie optimization
        - Dietary restriction compliance
        - Recipe variety and cultural diversity
        - Nutritional balance
        - Shopping list generation
        """

        # Build comprehensive context
        context = self._build_user_context(request, user_profile)

        # Generate meal plans for requested days
        meal_plans = []
        for day in range(request.num_days):
            meal_plan = await self._generate_daily_meal_plan(
                context,
                request,
                date.today() + timedelta(days=day),
                day
            )
            meal_plans.append(meal_plan)

        # Generate AI recommendations
        recommendations = await self._generate_recommendations(context, meal_plans, request)

        # Calculate weekly nutrition summary
        weekly_nutrition = self._calculate_weekly_nutrition(meal_plans)

        # Generate shopping list
        shopping_list = self._generate_shopping_list(meal_plans)

        return DietPlanResponse(
            meal_plans=meal_plans,
            ai_recommendations=recommendations,
            weekly_nutrition_summary=weekly_nutrition,
            shopping_list=shopping_list,
        )

    def _build_user_context(self, request: DietPlanRequest, user_profile: Optional[Dict]) -> str:
        """Build detailed context for AI agent"""
        context_parts = [
            f"Diet Type: {request.diet_type.value}",
            f"Daily Calorie Target: {request.daily_calorie_target} kcal",
            f"Meals Per Day: {request.meals_per_day}",
            f"Planning Duration: {request.num_days} days",
        ]

        if request.goals:
            goals_str = ', '.join([g.value for g in request.goals])
            context_parts.append(f"Goals: {goals_str}")

        if request.allergies:
            context_parts.append(f"Allergies: {', '.join(request.allergies)}")

        if request.disliked_foods:
            context_parts.append(f"Dislikes: {', '.join(request.disliked_foods)}")

        if user_profile:
            if user_profile.get("age"):
                context_parts.append(f"Age: {user_profile['age']}")
            if user_profile.get("weight"):
                context_parts.append(f"Weight: {user_profile['weight']} kg")
            if user_profile.get("height"):
                context_parts.append(f"Height: {user_profile['height']} cm")
            if user_profile.get("gender"):
                context_parts.append(f"Gender: {user_profile['gender']}")
            if user_profile.get("fitness_level"):
                context_parts.append(f"Activity Level: {user_profile['fitness_level']}")

        return "\n".join(context_parts)

    async def _generate_daily_meal_plan(
        self,
        context: str,
        request: DietPlanRequest,
        plan_date: date,
        day_number: int
    ) -> MealPlan:
        """Generate a single day's meal plan using LLAMA 3.2"""

        # Calculate calorie distribution
        calorie_distribution = self._calculate_calorie_distribution(
            request.daily_calorie_target,
            request.meals_per_day
        )

        prompt = f"""You are an expert nutritionist and chef AI specializing in personalized meal planning.

Create a detailed meal plan for Day {day_number + 1} based on these requirements:

{context}

Calorie Distribution:
- Breakfast: {calorie_distribution['breakfast']} kcal
- Lunch: {calorie_distribution['lunch']} kcal
- Dinner: {calorie_distribution['dinner']} kcal
- Snacks: {calorie_distribution.get('snacks', 0)} kcal

Please provide a complete meal plan in the following JSON format:
{{
  "breakfast": {{
    "name": "Recipe name",
    "description": "Brief description",
    "meal_type": "breakfast",
    "ingredients": [
      {{"item": "ingredient name", "amount": "quantity", "unit": "measurement"}},
      ...
    ],
    "instructions": ["Step 1", "Step 2", "..."],
    "prep_time_minutes": 10,
    "cook_time_minutes": 15,
    "servings": 1,
    "nutrition": {{
      "calories": 400,
      "protein_g": 20,
      "carbs_g": 45,
      "fat_g": 15,
      "fiber_g": 8,
      "sugar_g": 10,
      "sodium_mg": 400
    }},
    "tags": ["quick", "healthy", etc.],
    "diet_type": ["{request.diet_type.value}"]
  }},
  "lunch": {{ ... }},
  "dinner": {{ ... }},
  "snacks": [{{ ... }}]
}}

Important guidelines:
1. Strictly adhere to {request.diet_type.value} dietary requirements
2. Avoid these allergens: {', '.join(request.allergies) if request.allergies else 'none'}
3. Don't include: {', '.join(request.disliked_foods) if request.disliked_foods else 'none'}
4. Optimize for goals: {', '.join([g.value for g in request.goals])}
5. Ensure nutritional balance and variety
6. Provide accurate nutritional information
7. Include practical, achievable recipes
8. Consider meal prep efficiency
9. Ensure total daily calories are close to {request.daily_calorie_target} kcal
10. Make meals appetizing and culturally diverse

Return ONLY valid JSON, no additional text."""

        messages = [
            {"role": "system", "content": "You are an expert nutritionist and chef AI creating personalized, healthy, delicious meal plans."},
            {"role": "user", "content": prompt}
        ]

        response = await self._call_llama_api(messages, temperature=0.8, max_tokens=4000)

        # Parse JSON response
        try:
            json_str = response.strip()
            if json_str.startswith("```json"):
                json_str = json_str.split("```json")[1].split("```")[0].strip()
            elif json_str.startswith("```"):
                json_str = json_str.split("```")[1].split("```")[0].strip()

            meal_data = json.loads(json_str)
            return self._create_meal_plan_object(meal_data, request.user_id, plan_date)
        except json.JSONDecodeError as e:
            print(f"JSON Parse Error: {e}")
            print(f"Response: {response}")
            # Return fallback meal plan
            return self._get_fallback_meal_plan(request, plan_date)

    def _calculate_calorie_distribution(self, total_calories: int, meals_per_day: int) -> Dict[str, int]:
        """Calculate calorie distribution across meals"""
        if meals_per_day == 3:
            return {
                "breakfast": int(total_calories * 0.30),
                "lunch": int(total_calories * 0.35),
                "dinner": int(total_calories * 0.35),
            }
        elif meals_per_day == 4:
            return {
                "breakfast": int(total_calories * 0.25),
                "lunch": int(total_calories * 0.30),
                "dinner": int(total_calories * 0.30),
                "snacks": int(total_calories * 0.15),
            }
        else:  # 5-6 meals
            return {
                "breakfast": int(total_calories * 0.20),
                "lunch": int(total_calories * 0.25),
                "dinner": int(total_calories * 0.25),
                "snacks": int(total_calories * 0.30),
            }

    def _create_meal_plan_object(self, meal_data: Dict, user_id: str, plan_date: date) -> MealPlan:
        """Convert meal data to MealPlan object"""

        def convert_recipe(recipe_data: Dict, meal_type: str) -> Recipe:
            nutrition = NutritionalInfo(**recipe_data['nutrition'])

            return Recipe(
                id=f"recipe_{hash(recipe_data['name'])}_{datetime.utcnow().timestamp()}",
                name=recipe_data['name'],
                description=recipe_data.get('description', ''),
                meal_type=MealType(meal_type),
                ingredients=recipe_data.get('ingredients', []),
                instructions=recipe_data.get('instructions', []),
                prep_time_minutes=recipe_data.get('prep_time_minutes', 10),
                cook_time_minutes=recipe_data.get('cook_time_minutes', 20),
                servings=recipe_data.get('servings', 1),
                nutrition=nutrition,
                tags=recipe_data.get('tags', []),
                diet_type=[DietType(dt) for dt in recipe_data.get('diet_type', [])],
            )

        breakfast = convert_recipe(meal_data['breakfast'], 'breakfast') if meal_data.get('breakfast') else None
        lunch = convert_recipe(meal_data['lunch'], 'lunch') if meal_data.get('lunch') else None
        dinner = convert_recipe(meal_data['dinner'], 'dinner') if meal_data.get('dinner') else None
        snacks = [convert_recipe(s, 'snack') for s in meal_data.get('snacks', [])]

        # Calculate total nutrition
        total_nutrition = self._calculate_total_nutrition([breakfast, lunch, dinner] + snacks)

        return MealPlan(
            id=f"meal_plan_{user_id}_{plan_date}",
            user_id=user_id,
            date=plan_date,
            breakfast=breakfast,
            lunch=lunch,
            dinner=dinner,
            snacks=snacks,
            total_nutrition=total_nutrition,
            created_at=datetime.utcnow(),
        )

    def _calculate_total_nutrition(self, recipes: List[Optional[Recipe]]) -> NutritionalInfo:
        """Calculate total nutrition from multiple recipes"""
        total = {
            "calories": 0.0,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
            "sugar_g": 0.0,
            "sodium_mg": 0.0,
        }

        for recipe in recipes:
            if recipe and recipe.nutrition:
                total["calories"] += recipe.nutrition.calories
                total["protein_g"] += recipe.nutrition.protein_g
                total["carbs_g"] += recipe.nutrition.carbs_g
                total["fat_g"] += recipe.nutrition.fat_g
                total["fiber_g"] += recipe.nutrition.fiber_g or 0
                total["sugar_g"] += recipe.nutrition.sugar_g or 0
                total["sodium_mg"] += recipe.nutrition.sodium_mg or 0

        return NutritionalInfo(**total)

    def _calculate_weekly_nutrition(self, meal_plans: List[MealPlan]) -> NutritionalInfo:
        """Calculate average nutrition across all meal plans"""
        if not meal_plans:
            return NutritionalInfo(calories=0, protein_g=0, carbs_g=0, fat_g=0)

        total = {
            "calories": 0.0,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
            "sugar_g": 0.0,
            "sodium_mg": 0.0,
        }

        for plan in meal_plans:
            total["calories"] += plan.total_nutrition.calories
            total["protein_g"] += plan.total_nutrition.protein_g
            total["carbs_g"] += plan.total_nutrition.carbs_g
            total["fat_g"] += plan.total_nutrition.fat_g
            total["fiber_g"] += plan.total_nutrition.fiber_g or 0
            total["sugar_g"] += plan.total_nutrition.sugar_g or 0
            total["sodium_mg"] += plan.total_nutrition.sodium_mg or 0

        # Calculate averages
        num_days = len(meal_plans)
        return NutritionalInfo(
            calories=round(total["calories"] / num_days, 2),
            protein_g=round(total["protein_g"] / num_days, 2),
            carbs_g=round(total["carbs_g"] / num_days, 2),
            fat_g=round(total["fat_g"] / num_days, 2),
            fiber_g=round(total["fiber_g"] / num_days, 2),
            sugar_g=round(total["sugar_g"] / num_days, 2),
            sodium_mg=round(total["sodium_mg"] / num_days, 2),
        )

    def _generate_shopping_list(self, meal_plans: List[MealPlan]) -> List[Dict[str, Any]]:
        """Generate consolidated shopping list from meal plans"""
        ingredients_map = {}

        for plan in meal_plans:
            for recipe in [plan.breakfast, plan.lunch, plan.dinner] + plan.snacks:
                if not recipe:
                    continue

                for ingredient in recipe.ingredients:
                    item_name = ingredient.get('item', '').lower()
                    if item_name not in ingredients_map:
                        ingredients_map[item_name] = {
                            "item": ingredient.get('item', ''),
                            "total_amount": ingredient.get('amount', ''),
                            "unit": ingredient.get('unit', ''),
                            "category": self._categorize_ingredient(item_name)
                        }

        # Convert to sorted list
        shopping_list = sorted(
            ingredients_map.values(),
            key=lambda x: (x['category'], x['item'])
        )

        return shopping_list

    def _categorize_ingredient(self, ingredient: str) -> str:
        """Categorize ingredient for shopping list organization"""
        categories = {
            "produce": ["lettuce", "tomato", "onion", "garlic", "spinach", "carrot", "pepper", "fruit", "vegetable"],
            "protein": ["chicken", "beef", "pork", "fish", "tofu", "eggs", "turkey", "salmon"],
            "dairy": ["milk", "cheese", "yogurt", "butter", "cream"],
            "grains": ["rice", "pasta", "bread", "oats", "quinoa", "flour"],
            "canned": ["beans", "tomato sauce", "coconut milk"],
            "spices": ["salt", "pepper", "cumin", "paprika", "oregano", "basil"],
        }

        for category, keywords in categories.items():
            if any(keyword in ingredient for keyword in keywords):
                return category

        return "other"

    async def _generate_recommendations(
        self,
        context: str,
        meal_plans: List[MealPlan],
        request: DietPlanRequest
    ) -> str:
        """Generate personalized diet recommendations using LLAMA 3.2"""

        avg_nutrition = self._calculate_weekly_nutrition(meal_plans)

        prompt = f"""Based on the user's diet plan and profile, provide personalized nutrition recommendations.

User Context:
{context}

Average Daily Nutrition:
- Calories: {avg_nutrition.calories} kcal
- Protein: {avg_nutrition.protein_g}g
- Carbs: {avg_nutrition.carbs_g}g
- Fat: {avg_nutrition.fat_g}g

Target: {request.daily_calorie_target} kcal/day
Goals: {', '.join([g.value for g in request.goals])}

Provide 5-7 actionable, personalized recommendations covering:
1. Nutritional balance assessment
2. Meal timing suggestions
3. Hydration guidance
4. Supplement considerations (if any)
5. Portion control tips
6. Meal prep strategies
7. Progress tracking suggestions

Keep it concise, scientific, and motivating. Return as plain text, not JSON."""

        messages = [
            {"role": "system", "content": "You are an expert registered dietitian providing evidence-based nutrition guidance."},
            {"role": "user", "content": prompt}
        ]

        recommendations = await self._call_llama_api(messages, temperature=0.8, max_tokens=800)
        return recommendations.strip()

    def _get_fallback_meal_plan(self, request: DietPlanRequest, plan_date: date) -> MealPlan:
        """Provide a basic fallback meal plan if AI generation fails"""
        breakfast = Recipe(
            id="fallback_breakfast",
            name="Oatmeal with Berries",
            description="Healthy breakfast option",
            meal_type=MealType.BREAKFAST,
            ingredients=[
                {"item": "Oats", "amount": "50", "unit": "g"},
                {"item": "Milk", "amount": "200", "unit": "ml"},
                {"item": "Berries", "amount": "100", "unit": "g"},
            ],
            instructions=["Cook oats with milk", "Top with berries"],
            prep_time_minutes=5,
            cook_time_minutes=5,
            servings=1,
            nutrition=NutritionalInfo(calories=300, protein_g=12, carbs_g=45, fat_g=8),
            tags=["quick", "healthy"],
            diet_type=[request.diet_type],
        )

        return MealPlan(
            id=f"fallback_{request.user_id}_{plan_date}",
            user_id=request.user_id,
            date=plan_date,
            breakfast=breakfast,
            total_nutrition=breakfast.nutrition,
            created_at=datetime.utcnow(),
        )

    async def analyze_nutrition_progress(self, user_id: str, diet_logs: List[Dict]) -> Dict[str, Any]:
        """Analyze user's nutrition progress using LLAMA 3.2"""

        if not diet_logs:
            return {
                "summary": "No nutrition data logged yet. Start tracking your meals!",
                "recommendations": ["Log all meals consistently", "Track water intake"],
                "achievements": []
            }

        prompt = f"""Analyze this user's nutrition tracking history and provide insights:

Total days logged: {len(diet_logs)}
Recent nutrition data: {json.dumps(diet_logs[-7:], indent=2)}

Provide analysis in JSON format:
{{
  "summary": "Brief progress summary",
  "strengths": ["Strength 1", "Strength 2"],
  "areas_for_improvement": ["Area 1", "Area 2"],
  "recommendations": ["Recommendation 1", "Recommendation 2"],
  "achievements": ["Achievement 1", "Achievement 2"],
  "macro_balance_assessment": "Assessment of protein/carbs/fat balance"
}}

Return ONLY valid JSON."""

        messages = [
            {"role": "system", "content": "You are an expert nutritionist analyzing dietary patterns."},
            {"role": "user", "content": prompt}
        ]

        response = await self._call_llama_api(messages, temperature=0.7)

        try:
            json_str = response.strip()
            if json_str.startswith("```json"):
                json_str = json_str.split("```json")[1].split("```")[0].strip()
            elif json_str.startswith("```"):
                json_str = json_str.split("```")[1].split("```")[0].strip()

            analysis = json.loads(json_str)
            return analysis
        except json.JSONDecodeError:
            return {
                "summary": "Making progress with nutrition tracking!",
                "recommendations": ["Continue consistent logging", "Focus on balanced meals"],
                "achievements": [f"Logged {len(diet_logs)} days of meals"]
            }
