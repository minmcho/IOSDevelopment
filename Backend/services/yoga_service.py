"""
Yoga Service - Business logic for yoga planning and tracking
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from Backend.agents import KimiYogaAgent
from Backend.models.database import YogaSessionDB, YogaProgressDB, YogaPoseDB, User
from Backend.models.schemas import (
    YogaPlanRequest,
    YogaPlanResponse,
    YogaSession,
    YogaPose,
    YogaProgress,
    YogaLevel,
)


class YogaService:
    """
    Yoga Service with advanced features:
    - AI-powered session generation
    - Progress tracking
    - Pose library management
    - Personalized recommendations
    - Achievement system
    """

    def __init__(self, db: AsyncSession):
        self.db = db
        self.agent = KimiYogaAgent()

    async def create_yoga_plan(
        self,
        request: YogaPlanRequest,
        user_profile: Optional[Dict] = None
    ) -> YogaPlanResponse:
        """Create a personalized yoga plan using AI"""

        # Get user profile if not provided
        if not user_profile:
            user_profile = await self._get_user_profile(request.user_id)

        # Generate plan using KIMI agent
        async with self.agent as agent:
            plan_response = await agent.generate_yoga_plan(request, user_profile)

        # Save session to database
        await self._save_session(plan_response.session)

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
            "fitness_level": user.fitness_level,
            "goals": user.goals,
            "dietary_restrictions": user.dietary_restrictions,
        }

    async def _save_session(self, session: YogaSession) -> None:
        """Save yoga session to database"""
        db_session = YogaSessionDB(
            id=session.id,
            user_id=session.user_id,
            title=session.title,
            style=session.style.value,
            level=session.level.value,
            duration_minutes=session.duration_minutes,
            poses=[pose.dict() for pose in session.poses],
            warm_up=[pose.dict() for pose in session.warm_up],
            cool_down=[pose.dict() for pose in session.cool_down],
            created_at=session.created_at,
            completed=session.completed,
        )

        self.db.add(db_session)
        await self.db.commit()

    async def get_user_sessions(
        self,
        user_id: str,
        limit: int = 10,
        completed_only: bool = False
    ) -> List[YogaSession]:
        """Get user's yoga sessions"""
        query = select(YogaSessionDB).where(YogaSessionDB.user_id == user_id)

        if completed_only:
            query = query.where(YogaSessionDB.completed == True)

        query = query.order_by(YogaSessionDB.created_at.desc()).limit(limit)

        result = await self.db.execute(query)
        db_sessions = result.scalars().all()

        return [self._db_to_schema(s) for s in db_sessions]

    def _db_to_schema(self, db_session: YogaSessionDB) -> YogaSession:
        """Convert database model to schema"""
        return YogaSession(
            id=db_session.id,
            user_id=db_session.user_id,
            title=db_session.title,
            style=db_session.style,
            level=db_session.level,
            duration_minutes=db_session.duration_minutes,
            poses=[YogaPose(**p) for p in db_session.poses],
            warm_up=[YogaPose(**p) for p in db_session.warm_up] if db_session.warm_up else [],
            cool_down=[YogaPose(**p) for p in db_session.cool_down] if db_session.cool_down else [],
            created_at=db_session.created_at,
            completed=db_session.completed,
            completed_at=db_session.completed_at,
            notes=db_session.notes,
        )

    async def complete_session(
        self,
        session_id: str,
        user_id: str,
        notes: Optional[str] = None
    ) -> YogaSession:
        """Mark a session as completed and update progress"""
        result = await self.db.execute(
            select(YogaSessionDB).where(
                YogaSessionDB.id == session_id,
                YogaSessionDB.user_id == user_id
            )
        )
        db_session = result.scalar_one_or_none()

        if not db_session:
            raise ValueError("Session not found")

        # Update session
        db_session.completed = True
        db_session.completed_at = datetime.utcnow()
        if notes:
            db_session.notes = notes

        # Update daily progress
        await self._update_progress(
            user_id,
            date.today(),
            db_session.duration_minutes,
            db_session.calories_burned or 0,
            [p.get('name') for p in db_session.poses]
        )

        await self.db.commit()

        return self._db_to_schema(db_session)

    async def _update_progress(
        self,
        user_id: str,
        progress_date: date,
        minutes: int,
        calories: float,
        poses: List[str]
    ) -> None:
        """Update or create daily progress record"""
        result = await self.db.execute(
            select(YogaProgressDB).where(
                YogaProgressDB.user_id == user_id,
                YogaProgressDB.date == progress_date
            )
        )
        progress = result.scalar_one_or_none()

        if progress:
            # Update existing
            progress.sessions_completed += 1
            progress.total_minutes += minutes
            progress.calories_burned += calories
            existing_poses = set(progress.poses_mastered or [])
            existing_poses.update(poses)
            progress.poses_mastered = list(existing_poses)
        else:
            # Create new
            progress = YogaProgressDB(
                user_id=user_id,
                date=progress_date,
                sessions_completed=1,
                total_minutes=minutes,
                calories_burned=calories,
                poses_mastered=poses,
            )
            self.db.add(progress)

        await self.db.commit()

    async def get_progress(
        self,
        user_id: str,
        start_date: date,
        end_date: date
    ) -> List[YogaProgress]:
        """Get yoga progress for a date range"""
        result = await self.db.execute(
            select(YogaProgressDB).where(
                YogaProgressDB.user_id == user_id,
                YogaProgressDB.date >= start_date,
                YogaProgressDB.date <= end_date
            ).order_by(YogaProgressDB.date)
        )

        progress_records = result.scalars().all()

        return [
            YogaProgress(
                user_id=p.user_id,
                date=p.date,
                sessions_completed=p.sessions_completed,
                total_minutes=p.total_minutes,
                calories_burned=p.calories_burned,
                poses_mastered=p.poses_mastered or [],
                flexibility_score=p.flexibility_score,
                notes=p.notes,
            )
            for p in progress_records
        ]

    async def analyze_progress(self, user_id: str) -> Dict[str, Any]:
        """Get AI-powered progress analysis"""
        sessions = await self.get_user_sessions(user_id, limit=30, completed_only=True)

        sessions_data = [
            {
                "title": s.title,
                "style": s.style.value,
                "level": s.level.value,
                "duration": s.duration_minutes,
                "date": s.completed_at.isoformat() if s.completed_at else None,
            }
            for s in sessions
        ]

        async with self.agent as agent:
            analysis = await agent.analyze_progress(user_id, sessions_data)

        return analysis

    async def get_pose_library(
        self,
        difficulty: Optional[YogaLevel] = None,
        search: Optional[str] = None,
        limit: int = 50
    ) -> List[YogaPose]:
        """Get poses from the library"""
        query = select(YogaPoseDB)

        if difficulty:
            query = query.where(YogaPoseDB.difficulty == difficulty.value)

        if search:
            query = query.where(
                YogaPoseDB.name.ilike(f"%{search}%") |
                YogaPoseDB.sanskrit_name.ilike(f"%{search}%")
            )

        query = query.limit(limit)

        result = await self.db.execute(query)
        db_poses = result.scalars().all()

        return [
            YogaPose(
                id=p.id,
                name=p.name,
                sanskrit_name=p.sanskrit_name,
                description=p.description,
                benefits=p.benefits,
                difficulty=YogaLevel(p.difficulty),
                duration_seconds=p.duration_seconds,
                instructions=p.instructions,
                precautions=p.precautions or [],
                image_url=p.image_url,
                video_url=p.video_url,
            )
            for p in db_poses
        ]
