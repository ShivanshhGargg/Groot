# Groot Web/PWA Frontend Scope

This Flutter frontend is based on the attached Groot plan, with the launch order adjusted for web app and PWA feedback before App Store / Play Store release.

## MVP User Surfaces

- Authentication: login/register shell with secure-token storage hooks
- Home: one recommended next move, up to five secondary commitments, risks, daily briefing insights
- Manager Inbox: text intake, upload hooks, voice upload hook, Groot Inbox address, needs-review queue
- Memories: searchable memory list, type filters, confidence indicators, confirmation flow
- Workflow Detail: state-machine view, complete/snooze/reassess actions
- Notifications: daily briefing, workflow, and extraction alerts with deep links
- Profile: preferences, theme, briefing time, notification intensity, data ownership prompt

## Backend Contract Targets

The app is ready to connect to the REST API described in the document:

- `POST /auth/login`
- `POST /auth/register`
- `GET /dashboard/home`
- `GET /memories`
- `PATCH /memories/{id}`
- `GET /workflows/{id}`
- `POST /workflows/{id}/snooze`
- `PATCH /workflows/{id}/state`
- `GET /needs-review`
- `POST /needs-review/{id}/resolve`
- `POST /inbox/upload`
- `POST /inbox/voice`
- `GET /notifications`
- `PATCH /notifications/{id}/read`
- `PATCH /users/preferences`

Until those endpoints are implemented, `lib/shared/data/groot_repository.dart` provides demo state so users can click through the app and give product feedback.

## PWA Notes

The web shell includes:

- `web/manifest.json`
- install icons at 192px and 512px
- maskable icons
- theme color metadata
- standalone display mode

Build with:

```bash
flutter build web --release --dart-define=GROOT_API_BASE_URL=https://api.groot.ai/api/v1
```
