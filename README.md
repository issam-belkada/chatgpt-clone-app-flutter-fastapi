# Complete ChatGPT Clone - Flutter + FastAPI

A full-featured ChatGPT clone built with Flutter for the frontend and FastAPI for the backend, featuring user authentication, conversation management, and multiple LLM provider support.

## Features

### Backend (FastAPI)
- 🔐 **User Authentication** - JWT-based auth with registration/login
- 💬 **Conversation Management** - Create, update, delete conversations
- 🤖 **Multiple LLM Support** - OpenAI, Hugging Face, or local models
- 🗄️ **Database Integration** - SQLite/PostgreSQL support
- 📡 **RESTful API** - Complete API with proper error handling

### Frontend (Flutter)
- 🎨 **Modern UI** - Dark theme with ChatGPT-like interface
- 🔐 **Authentication Flow** - Login/register screens
- 💬 **Real-time Chat** - Streaming-like message display
- 📱 **Conversation Management** - List, create, and manage conversations
- 📱 **Responsive Design** - Works on mobile and desktop

## Project Structure

```
chatgpt_clone_app/
├── client/                    # Flutter frontend
│   ├── lib/
│   │   ├── models/           # Data models
│   │   ├── providers/        # State management
│   │   ├── screens/          # UI screens
│   │   └── services/         # API service
│   ├── pubspec.yaml
│   └── README.md
├── gpt_server/              # FastAPI backend
│   ├── main.py              # FastAPI app
│   ├── models.py            # SQLAlchemy models
│   ├── schemas.py           # Pydantic schemas
│   ├── crud.py              # Database operations
│   ├── auth.py              # Authentication
│   ├── config.py            # Settings
│   ├── database.py          # Database setup
│   ├── llm_service.py       # LLM integration
│   ├── requirements.txt
│   └── README.md
└── README.md
```

## Quick Start

### Prerequisites
- Python 3.8+
- Flutter 3.0+
- Git

### 1. Clone and Setup Backend

```bash
cd gpt_server
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

### 3. Run Backend

```bash
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Setup Frontend

```bash
cd ../client
flutter pub get
flutter run
```

## Configuration

### LLM Providers

#### OpenAI
```env
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-3.5-turbo
```

#### Hugging Face
```env
LLM_PROVIDER=huggingface
HF_API_KEY=hf-your-key-here
HF_MODEL=gpt2
```

#### Local
```env
LLM_PROVIDER=local
# Implement local LLM in llm_service.py
```

### Database

#### SQLite (Default)
```env
DATABASE_URL=sqlite:///./chatgpt.db
```

#### PostgreSQL
```env
DATABASE_URL=postgresql://user:password@localhost:5432/chatgpt
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login user
- `GET /api/v1/auth/me` - Get current user

### Conversations
- `GET /api/v1/conversations` - List conversations
- `POST /api/v1/conversations` - Create conversation
- `GET /api/v1/conversations/{id}` - Get conversation
- `PATCH /api/v1/conversations/{id}` - Update conversation
- `DELETE /api/v1/conversations/{id}` - Delete conversation

### Chat
- `POST /api/v1/chat` - Send message and get response

## Development

### Backend Development
```bash
cd gpt_server
source venv/bin/activate
python -m uvicorn main:app --reload
# API docs: http://localhost:8000/docs
```

### Frontend Development
```bash
cd client
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS
```

### Testing
```bash
# Backend tests
cd gpt_server
pytest

# Frontend tests
cd client
flutter test
```

## Deployment

### Backend Deployment
```bash
# Using Gunicorn
pip install gunicorn
gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app

# Using Docker
docker build -t chatgpt-backend .
docker run -p 8000:8000 chatgpt-backend
```

### Frontend Deployment
```bash
# Build for web
flutter build web

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- OpenAI for the GPT models
- FastAPI for the excellent framework
- Flutter for the amazing UI toolkit
- Hugging Face for model hosting