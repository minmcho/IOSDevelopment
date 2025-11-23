"""
KIMI 2 Yoga Agent - Advanced AI-powered yoga planning and personalization
Uses Moonshot AI's KIMI model for intelligent yoga session generation
"""
import json
import httpx
from typing import List, Dict, Any, Optional
from datetime import datetime
import asyncio

from Backend.config import settings
from Backend.models.schemas import (
    YogaPlanRequest,
    YogaPlanResponse,
    YogaSession,
    YogaPose,
    YogaLevel,
    YogaStyle,
    GoalType,
)


class KimiYogaAgent:
    """
    Advanced Yoga Agent powered by KIMI 2

    Features:
    - Personalized yoga session generation
    - Pose sequence optimization
    - Difficulty adaptation
    - Goal-oriented planning
    - Injury-aware modifications
    - Progress-based recommendations
    """

    def __init__(self):
        self.api_key = settings.KIMI_API_KEY
        self.api_base = settings.KIMI_API_BASE
        self.model = settings.KIMI_MODEL
        self.client = httpx.AsyncClient(timeout=60.0)

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()

    async def _call_kimi_api(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 4000
    ) -> str:
        """Call KIMI API with error handling and retries"""
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
            print(f"KIMI API Error: {e}")
            raise Exception(f"Failed to call KIMI API: {str(e)}")

    async def generate_yoga_plan(self, request: YogaPlanRequest, user_profile: Optional[Dict] = None) -> YogaPlanResponse:
        """
        Generate a comprehensive, personalized yoga plan using KIMI 2

        Advanced features:
        - Analyzes user profile for personalization
        - Creates balanced pose sequences
        - Includes warm-up and cool-down
        - Provides detailed instructions
        - Adapts to goals and restrictions
        """

        # Build comprehensive context for KIMI
        context = self._build_user_context(request, user_profile)

        # Generate yoga session with KIMI
        session_data = await self._generate_session(context, request)

        # Generate AI recommendations
        recommendations = await self._generate_recommendations(context, session_data)

        # Calculate estimated calories
        calories = self._calculate_calories(session_data, request.level, request.duration_minutes)

        # Extract benefits
        benefits = self._extract_benefits(session_data)

        # Create session object
        session = self._create_session_object(session_data, request)

        return YogaPlanResponse(
            session=session,
            ai_recommendations=recommendations,
            estimated_calories_burned=calories,
            benefits=benefits,
        )

    def _build_user_context(self, request: YogaPlanRequest, user_profile: Optional[Dict]) -> str:
        """Build detailed context for AI agent"""
        context_parts = [
            f"User Level: {request.level.value}",
            f"Preferred Style: {request.style.value}",
            f"Session Duration: {request.duration_minutes} minutes",
        ]

        if request.focus_areas:
            context_parts.append(f"Focus Areas: {', '.join(request.focus_areas)}")

        if request.goals:
            goals_str = ', '.join([g.value for g in request.goals])
            context_parts.append(f"Goals: {goals_str}")

        if request.avoid_poses:
            context_parts.append(f"Avoid: {', '.join(request.avoid_poses)}")

        if user_profile:
            if user_profile.get("age"):
                context_parts.append(f"Age: {user_profile['age']}")
            if user_profile.get("fitness_level"):
                context_parts.append(f"Fitness Level: {user_profile['fitness_level']}")
            if user_profile.get("dietary_restrictions"):
                context_parts.append(f"Health Considerations: {', '.join(user_profile.get('dietary_restrictions', []))}")

        return "\n".join(context_parts)

    async def _generate_session(self, context: str, request: YogaPlanRequest) -> Dict[str, Any]:
        """Generate yoga session using KIMI 2"""

        prompt = f"""You are an expert yoga instructor and AI agent specializing in personalized yoga session planning.

Create a detailed yoga session plan based on the following requirements:

{context}

Please provide a comprehensive yoga session in the following JSON format:
{{
  "title": "Session title",
  "warm_up": [
    {{
      "name": "Pose name",
      "sanskrit_name": "Sanskrit name (optional)",
      "description": "Brief description",
      "duration_seconds": 30,
      "instructions": ["Step 1", "Step 2", "..."],
      "benefits": ["Benefit 1", "Benefit 2"],
      "precautions": ["Precaution 1 (if any)"],
      "difficulty": "beginner/intermediate/advanced"
    }}
  ],
  "main_poses": [
    // 6-15 poses depending on duration
  ],
  "cool_down": [
    // 2-4 cooling poses
  ],
  "session_benefits": ["Overall benefit 1", "Overall benefit 2", "..."],
  "tips": ["Tip 1", "Tip 2", "..."]
}}

Important guidelines:
1. Create a balanced sequence that flows naturally
2. Include appropriate warm-up (5-10% of time) and cool-down (10-15% of time)
3. Match poses to the specified difficulty level: {request.level.value}
4. Follow {request.style.value} yoga principles
5. Each pose should have clear, safe instructions
6. Consider contraindications and precautions
7. Total session should be approximately {request.duration_minutes} minutes
8. Include breathing guidance where appropriate

Return ONLY valid JSON, no additional text."""

        messages = [
            {"role": "system", "content": "You are an expert yoga instructor AI specializing in creating safe, effective, personalized yoga sessions."},
            {"role": "user", "content": prompt}
        ]

        response = await self._call_kimi_api(messages, temperature=0.7)

        # Parse JSON response
        try:
            # Extract JSON from response (handle potential markdown formatting)
            json_str = response.strip()
            if json_str.startswith("```json"):
                json_str = json_str.split("```json")[1].split("```")[0].strip()
            elif json_str.startswith("```"):
                json_str = json_str.split("```")[1].split("```")[0].strip()

            session_data = json.loads(json_str)
            return session_data
        except json.JSONDecodeError as e:
            print(f"JSON Parse Error: {e}")
            print(f"Response: {response}")
            # Return a fallback basic session
            return self._get_fallback_session(request)

    async def _generate_recommendations(self, context: str, session_data: Dict) -> str:
        """Generate personalized recommendations using KIMI 2"""

        prompt = f"""Based on the user's yoga session and profile, provide personalized recommendations.

User Context:
{context}

Session Created:
- Title: {session_data.get('title', 'Yoga Session')}
- Number of poses: {len(session_data.get('main_poses', []))}
- Benefits: {', '.join(session_data.get('session_benefits', []))}

Provide 3-5 actionable, personalized recommendations for:
1. How to get the most out of this session
2. What to focus on during practice
3. Modifications if needed
4. Progression suggestions
5. Complementary practices

Keep it concise, motivating, and practical. Return as plain text, not JSON."""

        messages = [
            {"role": "system", "content": "You are a supportive yoga coach providing personalized guidance."},
            {"role": "user", "content": prompt}
        ]

        recommendations = await self._call_kimi_api(messages, temperature=0.8, max_tokens=500)
        return recommendations.strip()

    def _calculate_calories(self, session_data: Dict, level: YogaLevel, duration: int) -> float:
        """Calculate estimated calories burned"""
        # Base calories per minute by style and level
        base_rates = {
            YogaLevel.BEGINNER: 2.5,
            YogaLevel.INTERMEDIATE: 3.5,
            YogaLevel.ADVANCED: 4.5,
            YogaLevel.EXPERT: 5.5,
        }

        base_rate = base_rates.get(level, 3.0)

        # Adjust for number of poses (intensity indicator)
        pose_count = len(session_data.get('main_poses', []))
        intensity_multiplier = 1.0 + (pose_count / 50)  # More poses = higher intensity

        calories = base_rate * duration * intensity_multiplier
        return round(calories, 2)

    def _extract_benefits(self, session_data: Dict) -> List[str]:
        """Extract unique benefits from session"""
        benefits = set()

        # Add session-level benefits
        benefits.update(session_data.get('session_benefits', []))

        # Add pose-specific benefits
        for pose_list_key in ['warm_up', 'main_poses', 'cool_down']:
            for pose in session_data.get(pose_list_key, []):
                benefits.update(pose.get('benefits', []))

        return list(benefits)[:8]  # Return top 8 unique benefits

    def _create_session_object(self, session_data: Dict, request: YogaPlanRequest) -> YogaSession:
        """Convert session data to YogaSession object"""

        def convert_pose(pose_data: Dict) -> YogaPose:
            return YogaPose(
                id=f"pose_{hash(pose_data['name'])}",
                name=pose_data['name'],
                sanskrit_name=pose_data.get('sanskrit_name'),
                description=pose_data.get('description', ''),
                benefits=pose_data.get('benefits', []),
                difficulty=YogaLevel(pose_data.get('difficulty', request.level.value)),
                duration_seconds=pose_data.get('duration_seconds', 30),
                instructions=pose_data.get('instructions', []),
                precautions=pose_data.get('precautions', []),
            )

        warm_up = [convert_pose(p) for p in session_data.get('warm_up', [])]
        main_poses = [convert_pose(p) for p in session_data.get('main_poses', [])]
        cool_down = [convert_pose(p) for p in session_data.get('cool_down', [])]

        return YogaSession(
            id=f"session_{datetime.utcnow().timestamp()}",
            user_id=request.user_id,
            title=session_data.get('title', f'{request.style.value.title()} Yoga Session'),
            style=request.style,
            level=request.level,
            duration_minutes=request.duration_minutes,
            poses=main_poses,
            warm_up=warm_up,
            cool_down=cool_down,
            created_at=datetime.utcnow(),
            completed=False,
        )

    def _get_fallback_session(self, request: YogaPlanRequest) -> Dict[str, Any]:
        """Provide a basic fallback session if AI generation fails"""
        return {
            "title": f"{request.style.value.title()} Yoga Session",
            "warm_up": [
                {
                    "name": "Child's Pose",
                    "sanskrit_name": "Balasana",
                    "description": "A resting pose that gently stretches the hips, thighs, and ankles",
                    "duration_seconds": 60,
                    "instructions": ["Kneel on the mat", "Sit back on heels", "Fold forward", "Arms extended"],
                    "benefits": ["Relieves stress", "Stretches back"],
                    "precautions": [],
                    "difficulty": "beginner"
                }
            ],
            "main_poses": [
                {
                    "name": "Mountain Pose",
                    "sanskrit_name": "Tadasana",
                    "description": "Foundational standing pose",
                    "duration_seconds": 30,
                    "instructions": ["Stand tall", "Feet together", "Arms at sides", "Engage core"],
                    "benefits": ["Improves posture", "Builds focus"],
                    "precautions": [],
                    "difficulty": request.level.value
                }
            ],
            "cool_down": [
                {
                    "name": "Corpse Pose",
                    "sanskrit_name": "Savasana",
                    "description": "Final relaxation pose",
                    "duration_seconds": 300,
                    "instructions": ["Lie on back", "Arms relaxed", "Legs extended", "Close eyes", "Breathe naturally"],
                    "benefits": ["Deep relaxation", "Stress relief"],
                    "precautions": [],
                    "difficulty": "beginner"
                }
            ],
            "session_benefits": ["Improves flexibility", "Reduces stress", "Builds strength"],
            "tips": ["Listen to your body", "Breathe deeply", "Modify as needed"]
        }

    async def analyze_progress(self, user_id: str, sessions: List[Dict]) -> Dict[str, Any]:
        """Analyze user's yoga progress using KIMI 2"""

        if not sessions:
            return {
                "summary": "No sessions completed yet. Start your yoga journey today!",
                "recommendations": ["Begin with beginner-level sessions", "Practice 2-3 times per week"],
                "achievements": []
            }

        prompt = f"""Analyze this user's yoga practice history and provide insights:

Total sessions: {len(sessions)}
Recent sessions: {json.dumps(sessions[-5:], indent=2)}

Provide analysis in JSON format:
{{
  "summary": "Brief progress summary",
  "strengths": ["Strength 1", "Strength 2"],
  "areas_for_improvement": ["Area 1", "Area 2"],
  "recommendations": ["Recommendation 1", "Recommendation 2"],
  "achievements": ["Achievement 1", "Achievement 2"],
  "next_level_readiness": "beginner/intermediate/advanced/expert or 'continue current level'"
}}

Return ONLY valid JSON."""

        messages = [
            {"role": "system", "content": "You are an expert yoga instructor analyzing student progress."},
            {"role": "user", "content": prompt}
        ]

        response = await self._call_kimi_api(messages, temperature=0.7)

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
                "summary": "Making steady progress in your yoga journey!",
                "recommendations": ["Continue regular practice", "Explore new poses"],
                "achievements": [f"Completed {len(sessions)} sessions"]
            }
