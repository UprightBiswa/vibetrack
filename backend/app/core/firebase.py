from pathlib import Path

from app.core.config import settings

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
except ModuleNotFoundError:  # pragma: no cover - optional dependency in local dev
    firebase_admin = None
    credentials = None
    messaging = None


def initialize_firebase() -> bool:
    if firebase_admin is None or credentials is None:
        return False

    if firebase_admin._apps:
        return True

    if settings.google_application_credentials:
        credential_path = Path(settings.google_application_credentials)
        if not credential_path.exists() and credential_path.parts[:1] == ('backend',):
            credential_path = Path(*credential_path.parts[1:])
        if credential_path.exists():
            cred = credentials.Certificate(str(credential_path))
            firebase_admin.initialize_app(cred)
            return True

    if settings.fcm_project_id and settings.fcm_client_email and settings.fcm_private_key:
        cred = credentials.Certificate(
            {
                'type': 'service_account',
                'project_id': settings.fcm_project_id,
                'private_key': settings.fcm_private_key.replace('\\n', '\n'),
                'client_email': settings.fcm_client_email,
                'token_uri': 'https://oauth2.googleapis.com/token',
            }
        )
        firebase_admin.initialize_app(cred)
        return True

    return False


def send_push(token: str, title: str, body: str, data: dict[str, str] | None = None) -> str:
    if not initialize_firebase() or messaging is None:
        raise RuntimeError('Firebase Admin SDK is not installed or configured')

    message = messaging.Message(
        token=token,
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
    )
    return messaging.send(message)
