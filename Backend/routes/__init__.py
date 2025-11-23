from .yoga_routes import router as yoga_router
from .diet_routes import router as diet_router
from .analytics_routes import router as analytics_router

__all__ = ["yoga_router", "diet_router", "analytics_router"]
