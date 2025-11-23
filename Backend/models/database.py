"""
Database models using SQLAlchemy
"""
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Date, JSON, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    password_hash = Column(String)
    age = Column(Integer)
    weight = Column(Float)
    height = Column(Float)
    gender = Column(String)
    fitness_level = Column(String)
    goals = Column(JSON)
    dietary_restrictions = Column(JSON)
    preferred_diet_type = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    yoga_sessions = relationship("YogaSessionDB", back_populates="user", cascade="all, delete-orphan")
    meal_plans = relationship("MealPlanDB", back_populates="user", cascade="all, delete-orphan")
    yoga_progress = relationship("YogaProgressDB", back_populates="user", cascade="all, delete-orphan")
    diet_progress = relationship("DietProgressDB", back_populates="user", cascade="all, delete-orphan")


class YogaSessionDB(Base):
    __tablename__ = "yoga_sessions"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String, nullable=False)
    style = Column(String, nullable=False)
    level = Column(String, nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    poses = Column(JSON, nullable=False)
    warm_up = Column(JSON)
    cool_down = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    notes = Column(Text)
    calories_burned = Column(Float)

    user = relationship("User", back_populates="yoga_sessions")


class MealPlanDB(Base):
    __tablename__ = "meal_plans"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    breakfast = Column(JSON)
    lunch = Column(JSON)
    dinner = Column(JSON)
    snacks = Column(JSON)
    total_nutrition = Column(JSON, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    ai_notes = Column(Text)

    user = relationship("User", back_populates="meal_plans")


class YogaProgressDB(Base):
    __tablename__ = "yoga_progress"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    sessions_completed = Column(Integer, default=0)
    total_minutes = Column(Integer, default=0)
    calories_burned = Column(Float, default=0.0)
    poses_mastered = Column(JSON)
    flexibility_score = Column(Float)
    notes = Column(Text)

    user = relationship("User", back_populates="yoga_progress")


class DietProgressDB(Base):
    __tablename__ = "diet_progress"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    meals_logged = Column(Integer, default=0)
    calories_consumed = Column(Float, default=0.0)
    protein_g = Column(Float, default=0.0)
    carbs_g = Column(Float, default=0.0)
    fat_g = Column(Float, default=0.0)
    water_ml = Column(Float)
    weight = Column(Float)
    notes = Column(Text)

    user = relationship("User", back_populates="diet_progress")


class RecipeDB(Base):
    __tablename__ = "recipes"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False, index=True)
    description = Column(Text)
    meal_type = Column(String, nullable=False, index=True)
    ingredients = Column(JSON, nullable=False)
    instructions = Column(JSON, nullable=False)
    prep_time_minutes = Column(Integer)
    cook_time_minutes = Column(Integer)
    servings = Column(Integer, default=1)
    nutrition = Column(JSON, nullable=False)
    tags = Column(JSON)
    diet_type = Column(JSON)
    image_url = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(String, default="ai")


class YogaPoseDB(Base):
    __tablename__ = "yoga_poses"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False, index=True)
    sanskrit_name = Column(String)
    description = Column(Text, nullable=False)
    benefits = Column(JSON, nullable=False)
    difficulty = Column(String, nullable=False, index=True)
    duration_seconds = Column(Integer, default=30)
    instructions = Column(JSON, nullable=False)
    precautions = Column(JSON)
    image_url = Column(String)
    video_url = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
