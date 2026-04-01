from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.core.security import CurrentUser, get_current_user, require_superadmin
from app.modules.notifications.schemas import (
    BroadcastNotificationRequest,
    DeviceTokenDeleteRequest,
    DeviceTokenRequest,
    NotificationResponse,
    NotificationUnreadCountResponse,
    TestNotificationRequest,
    UserNotificationRequest,
)
from app.modules.notifications.service import NotificationService
from app.modules.shared.schemas import MessageResponse

router = APIRouter()


@router.get('', response_model=list[NotificationResponse])
async def list_notifications(
    limit: int = Query(default=50, ge=1, le=100),
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[NotificationResponse]:
    service = NotificationService(session)
    notifications = await service.list_notifications(user, limit=limit)
    return [service.to_response(item) for item in notifications]


@router.get('/unread-count', response_model=NotificationUnreadCountResponse)
async def get_unread_notification_count(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> NotificationUnreadCountResponse:
    unread_count = await NotificationService(session).unread_count(user)
    return NotificationUnreadCountResponse(unread_count=unread_count)


@router.post('/device-token', response_model=MessageResponse)
async def register_device_token(
    request: DeviceTokenRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> MessageResponse:
    await NotificationService(session).register_device_token(
        user,
        request.token,
        request.platform,
    )
    return MessageResponse(message='device token saved')


@router.post('/device-token/delete', response_model=MessageResponse)
async def delete_device_token(
    request: DeviceTokenDeleteRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> MessageResponse:
    await NotificationService(session).unregister_device_token(user, request.token)
    return MessageResponse(message='device token deleted')


@router.post('/read-all', response_model=MessageResponse)
async def mark_all_notifications_read(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> MessageResponse:
    updated = await NotificationService(session).mark_all_read(user)
    return MessageResponse(message=f'{updated} notification(s) marked as read')


@router.post('/{notification_id}/read', response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> NotificationResponse:
    service = NotificationService(session)
    notification = await service.mark_read(user, notification_id)
    if notification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Notification not found')
    return service.to_response(notification)


@router.post('/test', response_model=MessageResponse)
async def send_test_notification(
    request: TestNotificationRequest,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> MessageResponse:
    delivered = await NotificationService(session).send_test_notification(
        user,
        request.title,
        request.body,
        route=request.route,
        entity_id=request.entity_id,
        payload_json=request.payload_json,
    )
    return MessageResponse(message=f'test notification attempted for {delivered} device(s)')


@router.post('/user', response_model=NotificationResponse)
async def send_user_notification(
    request: UserNotificationRequest,
    user: CurrentUser = Depends(require_superadmin),
    session: AsyncSession = Depends(get_db_session),
) -> NotificationResponse:
    _ = user
    service = NotificationService(session)
    try:
        notification, _delivered = await service.create_user_notification(
            request.recipient_user_id,
            type=request.type,
            title=request.title,
            body=request.body,
            route=request.route,
            entity_id=request.entity_id,
            payload_json=request.payload_json,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    return service.to_response(notification)


@router.post('/broadcast', response_model=MessageResponse)
async def send_broadcast_notification(
    request: BroadcastNotificationRequest,
    user: CurrentUser = Depends(require_superadmin),
    session: AsyncSession = Depends(get_db_session),
) -> MessageResponse:
    _ = user
    created, delivered = await NotificationService(session).send_broadcast(
        type=request.type,
        title=request.title,
        body=request.body,
        route=request.route,
        entity_id=request.entity_id,
        payload_json=request.payload_json,
    )
    return MessageResponse(
        message=f'broadcast stored for {created} user(s), push attempted for {delivered} device(s)'
    )
