"""
Pydantic schemas for request/response models
"""
from datetime import datetime, date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, validator
from enum import Enum


# Enums
class YogaLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    EXPERT = "expert"


class YogaStyle(str, Enum):
    HATHA = "hatha"
    VINYASA = "vinyasa"
    ASHTANGA = "ashtanga"
    BIKRAM = "bikram"
    YIN = "yin"
    RESTORATIVE = "restorative"
    POWER = "power"
    KUNDALINI = "kundalini"


class DietType(str, Enum):
    BALANCED = "balanced"
    VEGAN = "vegan"
    VEGETARIAN = "vegetarian"
    KETO = "keto"
    PALEO = "paleo"
    MEDITERRANEAN = "mediterranean"
    LOW_CARB = "low_carb"
    HIGH_PROTEIN = "high_protein"


class GoalType(str, Enum):
    WEIGHT_LOSS = "weight_loss"
    MUSCLE_GAIN = "muscle_gain"
    FLEXIBILITY = "flexibility"
    STRESS_RELIEF = "stress_relief"
    GENERAL_HEALTH = "general_health"
    ATHLETIC_PERFORMANCE = "athletic_performance"


class MealType(str, Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"


# User Schemas
class UserProfile(BaseModel):
    user_id: str
    email: str
    name: str
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    gender: Optional[str] = None
    fitness_level: Optional[YogaLevel] = None
    goals: List[GoalType] = []
    dietary_restrictions: List[str] = []
    preferred_diet_type: Optional[DietType] = None


# Yoga Schemas
class YogaPose(BaseModel):
    id: str
    name: str
    sanskrit_name: Optional[str] = None
    description: str
    benefits: List[str]
    difficulty: YogaLevel
    duration_seconds: int
    instructions: List[str]
    precautions: List[str] = []
    image_url: Optional[str] = None
    video_url: Optional[str] = None


class YogaSession(BaseModel):
    id: str
    user_id: str
    title: str
    style: YogaStyle
    level: YogaLevel
    duration_minutes: int
    poses: List[YogaPose]
    warm_up: List[YogaPose] = []
    cool_down: List[YogaPose] = []
    created_at: datetime
    completed: bool = False
    completed_at: Optional[datetime] = None
    notes: Optional[str] = None


class YogaPlanRequest(BaseModel):
    user_id: str
    level: YogaLevel
    style: YogaStyle
    duration_minutes: int = Field(ge=10, le=120, default=30)
    focus_areas: List[str] = []
    goals: List[GoalType] = []
    avoid_poses: List[str] = []


class YogaPlanResponse(BaseModel):
    session: YogaSession
    ai_recommendations: str
    estimated_calories_burned: float
    benefits: List[str]


# Diet Schemas

# Micronutrient Models
class Vitamins(BaseModel):
    """Vitamin content in recommended daily values"""
    vitamin_a_mcg: Optional[float] = None  # Micrograms
    vitamin_c_mg: Optional[float] = None   # Milligrams
    vitamin_d_mcg: Optional[float] = None
    vitamin_e_mg: Optional[float] = None
    vitamin_k_mcg: Optional[float] = None
    vitamin_b1_thiamin_mg: Optional[float] = None
    vitamin_b2_riboflavin_mg: Optional[float] = None
    vitamin_b3_niacin_mg: Optional[float] = None
    vitamin_b5_pantothenic_acid_mg: Optional[float] = None
    vitamin_b6_mg: Optional[float] = None
    vitamin_b7_biotin_mcg: Optional[float] = None
    vitamin_b9_folate_mcg: Optional[float] = None
    vitamin_b12_mcg: Optional[float] = None
    choline_mg: Optional[float] = None


class Minerals(BaseModel):
    """Mineral content in recommended daily values"""
    calcium_mg: Optional[float] = None
    iron_mg: Optional[float] = None
    magnesium_mg: Optional[float] = None
    phosphorus_mg: Optional[float] = None
    potassium_mg: Optional[float] = None
    sodium_mg: Optional[float] = None
    zinc_mg: Optional[float] = None
    copper_mg: Optional[float] = None
    manganese_mg: Optional[float] = None
    selenium_mcg: Optional[float] = None
    iodine_mcg: Optional[float] = None
    chromium_mcg: Optional[float] = None


class Micronutrients(BaseModel):
    """Complete micronutrient profile"""
    vitamins: Vitamins = Vitamins()
    minerals: Minerals = Minerals()


class NutritionalInfo(BaseModel):
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    sugar_g: Optional[float] = None
    sodium_mg: Optional[float] = None
    saturated_fat_g: Optional[float] = None
    trans_fat_g: Optional[float] = None
    cholesterol_mg: Optional[float] = None
    micronutrients: Optional[Micronutrients] = None

    # Legacy field for backward compatibility
    vitamins: Dict[str, Any] = {}


class Recipe(BaseModel):
    id: str
    name: str
    description: str
    meal_type: MealType
    ingredients: List[Dict[str, Any]]
    instructions: List[str]
    prep_time_minutes: int
    cook_time_minutes: int
    servings: int
    nutrition: NutritionalInfo
    tags: List[str] = []
    diet_type: List[DietType] = []
    image_url: Optional[str] = None


class MealPlan(BaseModel):
    id: str
    user_id: str
    date: date
    breakfast: Optional[Recipe] = None
    lunch: Optional[Recipe] = None
    dinner: Optional[Recipe] = None
    snacks: List[Recipe] = []
    total_nutrition: NutritionalInfo
    created_at: datetime
    ai_notes: Optional[str] = None


class DietPlanRequest(BaseModel):
    user_id: str
    diet_type: DietType
    daily_calorie_target: int = Field(ge=1200, le=5000)
    num_days: int = Field(ge=1, le=30, default=7)
    meals_per_day: int = Field(ge=2, le=6, default=3)
    allergies: List[str] = []
    disliked_foods: List[str] = []
    goals: List[GoalType] = []


class DietPlanResponse(BaseModel):
    meal_plans: List[MealPlan]
    ai_recommendations: str
    weekly_nutrition_summary: NutritionalInfo
    shopping_list: List[Dict[str, Any]]


# Progress Tracking Schemas
class YogaProgress(BaseModel):
    user_id: str
    date: date
    sessions_completed: int
    total_minutes: int
    calories_burned: float
    poses_mastered: List[str]
    flexibility_score: Optional[float] = None
    notes: Optional[str] = None


class DietProgress(BaseModel):
    user_id: str
    date: date
    meals_logged: int
    calories_consumed: float
    protein_g: float
    carbs_g: float
    fat_g: float
    water_ml: Optional[float] = None
    weight: Optional[float] = None
    notes: Optional[str] = None


class ProgressSummary(BaseModel):
    user_id: str
    period: str
    yoga_stats: Dict[str, Any]
    diet_stats: Dict[str, Any]
    achievements: List[str]
    recommendations: str


# Analytics Schemas
class AnalyticsRequest(BaseModel):
    user_id: str
    start_date: date
    end_date: date
    metrics: List[str] = ["yoga", "diet", "progress"]


class AnalyticsResponse(BaseModel):
    user_id: str
    period: str
    yoga_analytics: Dict[str, Any]
    diet_analytics: Dict[str, Any]
    insights: List[str]
    trends: Dict[str, Any]
    ai_summary: str


# Micronutrient Schemas
class MicronutrientGoals(BaseModel):
    """Daily micronutrient goals based on RDA (Recommended Daily Allowance)"""
    user_id: str
    age: int
    gender: str

    # Vitamin goals (customizable)
    vitamin_a_mcg: float = 900  # Adult male RDA
    vitamin_c_mg: float = 90
    vitamin_d_mcg: float = 15
    vitamin_e_mg: float = 15
    vitamin_k_mcg: float = 120
    vitamin_b1_mg: float = 1.2
    vitamin_b2_mg: float = 1.3
    vitamin_b3_mg: float = 16
    vitamin_b5_mg: float = 5
    vitamin_b6_mg: float = 1.7
    vitamin_b7_mcg: float = 30
    vitamin_b9_mcg: float = 400
    vitamin_b12_mcg: float = 2.4
    choline_mg: float = 550

    # Mineral goals
    calcium_mg: float = 1000
    iron_mg: float = 8
    magnesium_mg: float = 420
    phosphorus_mg: float = 700
    potassium_mg: float = 3400
    sodium_mg: float = 2300  # Upper limit
    zinc_mg: float = 11
    copper_mg: float = 0.9
    manganese_mg: float = 2.3
    selenium_mcg: float = 55
    iodine_mcg: float = 150
    chromium_mcg: float = 35


class MicronutrientDeficiency(BaseModel):
    """Detected micronutrient deficiencies"""
    nutrient_name: str
    current_intake: float
    recommended_intake: float
    deficit_percentage: float
    health_impacts: List[str]
    food_sources: List[str]
    severity: str  # low, moderate, high


class MicronutrientAnalysis(BaseModel):
    """Comprehensive micronutrient analysis"""
    user_id: str
    period: str
    start_date: date
    end_date: date

    # Average daily intake
    avg_vitamins: Vitamins
    avg_minerals: Minerals

    # Goals
    goals: MicronutrientGoals

    # Analysis results
    deficiencies: List[MicronutrientDeficiency]
    adequacies: List[str]  # Nutrients meeting goals
    excesses: List[str]  # Nutrients exceeding safe upper limits

    # AI recommendations
    ai_recommendations: str
    supplement_suggestions: List[str]
    dietary_adjustments: List[str]

    # Visual data for charts
    vitamin_completion_percentages: Dict[str, float]
    mineral_completion_percentages: Dict[str, float]


class MicronutrientRequest(BaseModel):
    """Request for micronutrient analysis"""
    user_id: str
    start_date: date
    end_date: date
    include_ai_analysis: bool = True
