# Import models so SQLAlchemy metadata is fully registered before init_db runs.
from app.modules.feed.models import FeedComment, FeedPost, FeedPostLike
from app.modules.notifications.models import AppNotification, DeviceToken
from app.modules.profiles.models import Profile
from app.modules.rides.models import RideSession
from app.modules.zones.models import Zone, ZoneClaimEvent

__all__ = ['AppNotification', 'DeviceToken', 'FeedComment', 'FeedPost', 'FeedPostLike', 'Profile', 'RideSession', 'Zone', 'ZoneClaimEvent']
