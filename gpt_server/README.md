# FastAPI ChatGPT Clone Server

## Setup Instructions

### 1. Create and activate virtual environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Configure environment variables
- Copy or edit `.env` file with your settings
- Set `LLM_PROVIDER` to one of: `openai`, `huggingface`, or `local`

### 4. Run the server
```bash
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 5. Access the API
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- API Root: http://localhost:8000/

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user
- `GET /api/v1/auth/me` - Get current user

### Conversations
- `GET /api/v1/conversations` - Get all user conversations
- `POST /api/v1/conversations` - Create new conversation
- `GET /api/v1/conversations/{id}` - Get specific conversation
- `PATCH /api/v1/conversations/{id}` - Update conversation title
- `DELETE /api/v1/conversations/{id}` - Delete conversation

### Chat
- `POST /api/v1/chat` - Send a message and get response

## LLM Configuration

This application uses **Google Gemini** for all chat responses.

### Setup Gemini
1. Get a Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Set `GEMINI_API_KEY=your-api-key-here` in `.env`
3. Optionally change `GEMINI_MODEL` (default: gemini-1.5-flash)
   - Available models: `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-pro`

**Note**: Google Gemini API is free with a generous daily quota.

## Database

The API uses SQLAlchemy with SQLite by default. To use PostgreSQL:
1. Install: `pip install psycopg2-binary`
2. Update `.env`: `DATABASE_URL=postgresql://user:password@localhost:5432/chatgpt`

## Development

### Project Structure
- `main.py` - FastAPI application and routes
- `models.py` - SQLAlchemy database models
- `schemas.py` - Pydantic request/response models
- `crud.py` - Database CRUD operations
- `auth.py` - JWT authentication
- `database.py` - Database configuration
- `config.py` - Settings management
- `llm_service.py` - LLM provider integration

### Testing Local LLM Integration

Run the test script to verify your local LLM setup:

```bash
python test_local_llm.py
```

This will check if Ollama is running, if the configured model is available, and test a simple chat interaction.

## Production Deployment

For production:
1. Change `SECRET_KEY` in `.env` to a secure random value
2. Set `DEBUG=False`
3. Use PostgreSQL instead of SQLite
4. Deploy using Gunicorn: `gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app`
5. Use a reverse proxy (Nginx) for SSL/TLS
6. Set up proper logging and monitoring
