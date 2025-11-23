# iOS Login Backend API

A modern, well-structured FastAPI backend for the iOS Login application with support for email/password authentication and OAuth providers (Gmail, Hotmail).

## Architecture

The backend follows a clean, modular architecture with clear separation of concerns:

```
backend/
├── routers/          # API endpoints (presentation layer)
│   ├── auth.py      # Authentication endpoints
│   ├── users.py     # User management endpoints
│   ├── health.py    # Health check endpoints
│   └── dependencies.py  # Shared route dependencies
├── services/         # Business logic (service layer)
│   ├── auth_service.py  # Authentication business logic
│   ├── user_service.py  # User management business logic
│   └── jwt_service.py   # JWT token operations
├── db/              # Database layer
│   ├── database.py  # Database connection and session management
│   └── models.py    # SQLAlchemy database models
├── schemas/         # Data validation (Pydantic models)
│   ├── auth.py      # Authentication schemas
│   └── user.py      # User schemas
├── config.py        # Application configuration
└── main.py         # FastAPI application entry point
```

## Features

- **RESTful API** with FastAPI
- **Clean Architecture** with separated layers:
  - Routers: Handle HTTP requests/responses
  - Services: Contain business logic
  - Database: Data persistence layer
  - Schemas: Data validation and serialization
- **JWT Authentication** with access and refresh tokens
- **Email/Password Authentication**
- **OAuth Support** (Gmail, Hotmail) - ready for implementation
- **Password Hashing** with bcrypt
- **SQLAlchemy ORM** with support for SQLite, PostgreSQL, MySQL
- **Pydantic Validation** for request/response data
- **CORS Support** for cross-origin requests
- **Database Migrations** ready structure
- **Health Check** endpoint

## Setup

### 1. Install Dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and update the settings:
- `JWT_SECRET_KEY`: Generate a secure key with `openssl rand -hex 32`
- `DATABASE_URL`: Configure your database connection
- OAuth credentials (if using OAuth)

### 3. Run the Application

```bash
# Development mode with auto-reload
uvicorn backend.main:app --reload

# Production mode
python -m backend.main
```

The API will be available at `http://localhost:8000`

### 4. View API Documentation

FastAPI provides automatic interactive API documentation:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/oauth/login` - Login with OAuth (requires implementation)
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout (revoke refresh token)
- `POST /api/auth/change-password` - Change password
- `GET /api/auth/me` - Get current user info

### Users

- `GET /api/users/me` - Get current user profile
- `PUT /api/users/me` - Update current user profile
- `DELETE /api/users/me` - Delete current user account
- `GET /api/users/{user_id}` - Get user by ID
- `GET /api/users/` - List all users (paginated)

### Health

- `GET /health` - Health check
- `GET /` - API information

## Database Models

### User
- `id`: Primary key
- `email`: Unique email address
- `full_name`: User's full name
- `hashed_password`: Bcrypt hashed password
- `auth_provider`: Authentication method (email, gmail, hotmail)
- `provider_id`: OAuth provider user ID
- `is_active`: Account active status
- `is_verified`: Email verification status
- `created_at`: Account creation timestamp
- `updated_at`: Last update timestamp

### RefreshToken
- `id`: Primary key
- `user_id`: Associated user ID
- `token`: Refresh token value
- `is_revoked`: Token revocation status
- `expires_at`: Token expiration timestamp
- `created_at`: Token creation timestamp

## OAuth Implementation

The backend is prepared for OAuth integration. To implement:

### Gmail OAuth

1. Install Google Auth library:
```bash
pip install google-auth google-auth-oauthlib
```

2. Uncomment and implement the verification code in `routers/auth.py:oauth_login()`

3. Add your Google OAuth credentials to `.env`

### Hotmail/Outlook OAuth

1. Install MSAL library:
```bash
pip install msal
```

2. Uncomment and implement the verification code in `routers/auth.py:oauth_login()`

3. Add your Microsoft OAuth credentials to `.env`

## Security Features

- Password hashing with bcrypt
- JWT tokens with expiration
- Refresh token rotation
- Token revocation support
- CORS protection
- SQL injection protection (via SQLAlchemy)
- Request validation (via Pydantic)

## Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests (after creating tests)
pytest
```

## Production Deployment

### Important Security Steps

1. **Change JWT Secret**: Use a strong, random secret key
2. **Use HTTPS**: Always use HTTPS in production
3. **Configure CORS**: Restrict allowed origins
4. **Use Production Database**: Switch from SQLite to PostgreSQL/MySQL
5. **Implement OAuth**: Complete OAuth token verification
6. **Add Rate Limiting**: Prevent abuse
7. **Enable Logging**: Monitor application activity
8. **Add Monitoring**: Use tools like Sentry, DataDog, etc.

### Environment Variables

Ensure all environment variables are properly set in production:
- Strong `JWT_SECRET_KEY`
- Production `DATABASE_URL`
- Restricted `CORS_ORIGINS`
- OAuth credentials (if using)

### Database Migration

For production, use Alembic for database migrations:

```bash
pip install alembic
alembic init alembic
# Configure alembic.ini and create migrations
```

## Development Tips

- **Code Organization**: Each layer has a specific responsibility
  - Routers: HTTP handling only
  - Services: Business logic and validation
  - DB: Data access and persistence
  - Schemas: Data validation

- **Adding New Features**:
  1. Define schemas in `schemas/`
  2. Create database models in `db/models.py`
  3. Implement business logic in `services/`
  4. Create API endpoints in `routers/`
  5. Register router in `main.py`

- **Service Singletons**: Services are instantiated as singletons for reuse

## License

This is a sample project for demonstration purposes.
