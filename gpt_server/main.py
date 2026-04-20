from fastapi import FastAPI, HTTPException, Depends, status, Query, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from typing import Annotated
from contextlib import asynccontextmanager
from datetime import timedelta
from sqlalchemy.orm import Session
import schemas
import crud
import auth
import database
import models
from config import get_settings
from llm_service import LLMService

# Get settings
settings = get_settings()

# Error message constants
USER_NOT_FOUND = "User not found"
CONVERSATION_NOT_FOUND = "Conversation not found"
NOT_AUTHORIZED = "Not authorized to access this conversation"

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    database.init_db()
    yield

# Initialize FastAPI app with lifespan
app = FastAPI(
    title="ChatGPT Clone API",
    description="A complete ChatGPT clone API built with FastAPI",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# AUTH ENDPOINTS
# ============================================================================

@app.post("/api/v1/auth/register", response_model=schemas.User, tags=["Auth"])
async def register(user_data: schemas.RegisterRequest, db: Annotated[Session, Depends(database.get_db)]):
    """Register a new user."""
    # Check if user already exists
    db_user = crud.get_user_by_username(db, user_data.username)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )
    
    db_user = crud.get_user_by_email(db, user_data.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    new_user = crud.create_user(db, user_data)
    return new_user

@app.post("/api/v1/auth/login", response_model=schemas.Token, tags=["Auth"])
async def login(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Annotated[Session, Depends(database.get_db)]
):
    """Login user and get tokens."""
    # Find user
    user = crud.get_user_by_username(db, form_data.username)
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Create tokens
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    access_token = auth.create_access_token(
        data={"sub": user.username},
        expires_delta=access_token_expires
    )
    refresh_token = auth.create_refresh_token(
        data={"sub": user.username},
        expires_delta=refresh_token_expires
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@app.get("/api/v1/auth/me", response_model=schemas.User, tags=["Auth"])
async def get_current_user_info(
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)]
):
    """Get current user information."""
    user = crud.get_user_by_username(db, current_user.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=USER_NOT_FOUND
        )
    return user

# ============================================================================
# CONVERSATION ENDPOINTS
# ============================================================================

@app.get("/api/v1/conversations", response_model=list[schemas.Conversation], tags=["Conversations"])
async def get_conversations(
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)],
    skip: Annotated[int, Query()] = 0,
    limit: Annotated[int, Query()] = 10
):
    """Get all conversations for current user."""
    user = crud.get_user_by_username(db, current_user.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=USER_NOT_FOUND
        )
    
    conversations = crud.get_user_conversations(db, user.id, skip, limit)
    return conversations

@app.post("/api/v1/conversations", response_model=schemas.Conversation, tags=["Conversations"])
async def create_conversation(
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)],
    conversation_data: schemas.ConversationCreate = Body(...)
):
    """Create a new conversation."""
    user = crud.get_user_by_username(db, current_user.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=USER_NOT_FOUND
        )
    
    conversation = crud.create_conversation(
        db,
        user.id,
        conversation_data.title or "New Conversation"
    )
    return conversation

@app.get("/api/v1/conversations/{conversation_id}", response_model=schemas.Conversation, tags=["Conversations"])
async def get_conversation(
    conversation_id: int,
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)]
):
    """Get a specific conversation."""
    conversation = crud.get_conversation(db, conversation_id)
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=CONVERSATION_NOT_FOUND
        )
    
    # Verify ownership
    user = crud.get_user_by_username(db, current_user.username)
    if conversation.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=NOT_AUTHORIZED
        )
    
    return conversation

@app.patch("/api/v1/conversations/{conversation_id}", response_model=schemas.Conversation, tags=["Conversations"])
async def update_conversation(
    conversation_id: int,
    conversation_data: schemas.ConversationCreate,
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)]
):
    """Update conversation title."""
    conversation = crud.get_conversation(db, conversation_id)
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=CONVERSATION_NOT_FOUND
        )
    
    # Verify ownership
    user = crud.get_user_by_username(db, current_user.username)
    if conversation.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=NOT_AUTHORIZED
        )
    
    updated = crud.update_conversation_title(db, conversation_id, conversation_data.title)
    return updated

@app.delete("/api/v1/conversations/{conversation_id}", tags=["Conversations"])
async def delete_conversation(
    conversation_id: int,
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)]
):
    """Delete a conversation."""
    conversation = crud.get_conversation(db, conversation_id)
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=CONVERSATION_NOT_FOUND
        )
    
    # Verify ownership
    user = crud.get_user_by_username(db, current_user.username)
    if conversation.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=NOT_AUTHORIZED
        )
    
    crud.delete_conversation(db, conversation_id)
    return {"message": "Conversation deleted"}

# ============================================================================
# CHAT ENDPOINTS
# ============================================================================

@app.post("/api/v1/chat", response_model=schemas.ChatResponse, tags=["Chat"])
async def chat(
    chat_request: schemas.ChatRequest,
    current_user: Annotated[schemas.TokenData, Depends(auth.get_current_user)],
    db: Annotated[Session, Depends(database.get_db)]
):
    """Send a message and get a response."""
    user = crud.get_user_by_username(db, current_user.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=USER_NOT_FOUND
        )
    
    # Create or get conversation
    if chat_request.conversation_id:
        conversation = crud.get_conversation(db, chat_request.conversation_id)
        if not conversation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=CONVERSATION_NOT_FOUND
            )
        if conversation.user_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=NOT_AUTHORIZED
            )
    else:
        conversation = crud.create_conversation(db, user.id)
    
    # Save user message
    user_message = crud.create_message(
        db,
        conversation.id,
        "user",
        chat_request.message
    )
    
    # Get conversation history for context
    messages_history = crud.get_conversation_messages(db, conversation.id)
    
    # Prepare messages for LLM
    llm_messages = []
    for msg in messages_history:
        llm_messages.append({
            "role": msg.role,
            "content": msg.content
        })
    
    # Get response from LLM
    response_text = await LLMService.get_response(llm_messages)
    
    # Save assistant message
    assistant_message = crud.create_message(
        db,
        conversation.id,
        "assistant",
        response_text
    )
    
    return {
        "conversation_id": conversation.id,
        "user_message": user_message,
        "assistant_message": assistant_message
    }

# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.get("/health", tags=["Health"])
async def health():
    """Health check endpoint."""
    return {"status": "ok"}

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint."""
    return {
        "message": "ChatGPT Clone API",
        "version": "1.0.0",
        "docs": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8002)
