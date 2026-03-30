from fastapi import APIRouter

from app.modules.admin.router import router as admin_router
from app.modules.auth.router import router as auth_router
from app.modules.config.router import router as config_router
from app.modules.feed.router import router as feed_router
from app.modules.health.router import router as health_router
from app.modules.notifications.router import router as notifications_router
from app.modules.profiles.router import router as profiles_router
from app.modules.rides.router import router as rides_router
from app.modules.zones.router import router as zones_router

api_router = APIRouter()
api_router.include_router(health_router, tags=['health'])
api_router.include_router(auth_router, prefix='/auth', tags=['auth'])
api_router.include_router(config_router, prefix='/config', tags=['config'])
api_router.include_router(profiles_router, prefix='/profiles', tags=['profiles'])
api_router.include_router(rides_router, prefix='/rides', tags=['rides'])
api_router.include_router(feed_router, prefix='/feed', tags=['feed'])
api_router.include_router(zones_router, prefix='/zones', tags=['zones'])
api_router.include_router(notifications_router, prefix='/notifications', tags=['notifications'])
api_router.include_router(admin_router, prefix='/admin', tags=['admin'])
