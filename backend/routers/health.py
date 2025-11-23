"""
Health check and status endpoints.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.db.database import get_db
from pydantic import BaseModel
from datetime import datetime


router = APIRouter(tags=["Health"])


class HealthResponse(BaseModel):
    """Health check response schema."""
    status: str
    timestamp: datetime
    database: str


@router.get("/health", response_model=HealthResponse)
def health_check(db: Session = Depends(get_db)):
    """
    Health check endpoint to verify API and database status.

    Args:
        db: Database session

    Returns:
        Health status information
    """
    # Test database connection
    try:
        db.execute("SELECT 1")
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"

    return HealthResponse(
        status="healthy" if db_status == "healthy" else "degraded",
        timestamp=datetime.utcnow(),
        database=db_status
    )


@router.get("/")
def root():
    """
    Root endpoint with API information.

    Returns:
        API information
    """
    return {
        "name": "iOS Login Backend API",
        "version": "1.0.0",
        "status": "running"
    }
