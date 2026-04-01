from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.firebase import send_push
from app.core.security import CurrentUser
from app.modules.notifications.models import AppNotification, DeviceToken
from app.modules.notifications.schemas import NotificationResponse
from app.modules.profiles.models import Profile
from app.modules.profiles.service import ProfileService


class NotificationService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.profile_service = ProfileService(session)

    async def register_device_token(self, user: CurrentUser, token: str, platform: str) -> None:
        await self.profile_service.get_or_create_profile(user)
        existing = await self.session.execute(
            select(DeviceToken).where(DeviceToken.token == token)
        )
        token_row = existing.scalar_one_or_none()
        if token_row is None:
            token_row = DeviceToken(
                id=str(uuid4()),
                user_id=user.user_id,
                token=token,
                platform=platform,
            )
            self.session.add(token_row)
        else:
            token_row.user_id = user.user_id
            token_row.platform = platform
        await self.session.commit()

    async def unregister_device_token(self, user: CurrentUser, token: str) -> None:
        await self.session.execute(
            delete(DeviceToken).where(
                DeviceToken.user_id == user.user_id,
                DeviceToken.token == token,
            )
        )
        await self.session.commit()

    async def list_notifications(
        self,
        user: CurrentUser,
        limit: int = 50,
    ) -> list[AppNotification]:
        await self.profile_service.get_or_create_profile(user)
        result = await self.session.execute(
            select(AppNotification)
            .where(AppNotification.recipient_user_id == user.user_id)
            .order_by(AppNotification.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars())

    async def unread_count(self, user: CurrentUser) -> int:
        await self.profile_service.get_or_create_profile(user)
        result = await self.session.execute(
            select(func.count(AppNotification.id)).where(
                AppNotification.recipient_user_id == user.user_id,
                AppNotification.read_at.is_(None),
            )
        )
        return int(result.scalar_one() or 0)

    async def mark_read(self, user: CurrentUser, notification_id: str) -> AppNotification | None:
        await self.profile_service.get_or_create_profile(user)
        notification = await self.session.get(AppNotification, notification_id)
        if notification is None or notification.recipient_user_id != user.user_id:
            return None
        if notification.read_at is None:
            notification.read_at = datetime.now(UTC)
            await self.session.commit()
            await self.session.refresh(notification)
        return notification

    async def mark_all_read(self, user: CurrentUser) -> int:
        await self.profile_service.get_or_create_profile(user)
        result = await self.session.execute(
            update(AppNotification)
            .where(
                AppNotification.recipient_user_id == user.user_id,
                AppNotification.read_at.is_(None),
            )
            .values(read_at=datetime.now(UTC))
        )
        await self.session.commit()
        return int(result.rowcount or 0)

    async def create_user_notification(
        self,
        recipient_user_id: str,
        *,
        type: str,
        title: str,
        body: str,
        route: str = '',
        entity_id: str = '',
        payload_json: dict | None = None,
    ) -> tuple[AppNotification, int]:
        recipient_profile = await self.session.get(Profile, recipient_user_id)
        if recipient_profile is None:
            raise ValueError('Recipient profile not found')

        notification = AppNotification(
            id=str(uuid4()),
            recipient_user_id=recipient_user_id,
            type=type,
            title=title,
            body=body,
            route=route,
            entity_id=entity_id,
            payload_json=payload_json or {},
        )
        self.session.add(notification)
        await self.session.flush()
        delivered = await self._deliver_notification(notification)
        await self.session.commit()
        await self.session.refresh(notification)
        return notification, delivered

    async def send_test_notification(
        self,
        user: CurrentUser,
        title: str,
        body: str,
        route: str = '',
        entity_id: str = '',
        payload_json: dict | None = None,
    ) -> int:
        await self.profile_service.get_or_create_profile(user)
        _, delivered = await self.create_user_notification(
            user.user_id,
            type='test',
            title=title,
            body=body,
            route=route,
            entity_id=entity_id,
            payload_json=payload_json,
        )
        return delivered

    async def send_broadcast(
        self,
        *,
        type: str,
        title: str,
        body: str,
        route: str = '',
        entity_id: str = '',
        payload_json: dict | None = None,
    ) -> tuple[int, int]:
        result = await self.session.execute(select(Profile.id))
        user_ids = list(result.scalars())
        created = 0
        delivered = 0
        for user_id in user_ids:
            _, sent = await self.create_user_notification(
                user_id,
                type=type,
                title=title,
                body=body,
                route=route,
                entity_id=entity_id,
                payload_json=payload_json,
            )
            created += 1
            delivered += sent
        return created, delivered

    async def _deliver_notification(self, notification: AppNotification) -> int:
        result = await self.session.execute(
            select(DeviceToken).where(DeviceToken.user_id == notification.recipient_user_id)
        )
        tokens = list(result.scalars())
        delivered = 0
        for token_row in tokens:
            try:
                send_push(
                    token_row.token,
                    notification.title,
                    notification.body,
                    data=self._build_push_payload(notification),
                )
                delivered += 1
            except RuntimeError:
                continue
            except Exception:
                await self.session.execute(
                    delete(DeviceToken).where(DeviceToken.id == token_row.id)
                )
        return delivered

    def to_response(self, notification: AppNotification) -> NotificationResponse:
        return NotificationResponse(
            id=notification.id,
            recipient_user_id=notification.recipient_user_id,
            type=notification.type,
            title=notification.title,
            body=notification.body,
            route=notification.route,
            entity_id=notification.entity_id,
            payload_json=notification.payload_json,
            is_read=notification.read_at is not None,
            read_at=notification.read_at,
            created_at=notification.created_at,
            updated_at=notification.updated_at,
        )

    def _build_push_payload(self, notification: AppNotification) -> dict[str, str]:
        payload = {
            'notification_id': notification.id,
            'type': notification.type,
            'route': notification.route,
            'entity_id': notification.entity_id,
            'title': notification.title,
            'body': notification.body,
        }
        for key, value in (notification.payload_json or {}).items():
            payload[str(key)] = str(value)
        return payload
