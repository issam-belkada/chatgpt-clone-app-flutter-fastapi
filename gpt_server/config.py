from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from functools import lru_cache
import os

class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "ChatGPT Clone API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = "sqlite:///./chatgpt.db"
    
    # JWT Settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # CORS settings
    CORS_ORIGINS: list = ["*"]
    
    # Gemini Settings
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.0-flash-exp")
    
    model_config = ConfigDict(env_file=".env", extra="ignore")
    
    # DeepSeek
    DEEPSEEK_API_KEY: str = os.getenv("DEEPSEEK_API_KEY", "")
    DEEPSEEK_MODEL: str = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")
    
    model_config = ConfigDict(env_file=".env", extra="ignore")
    
    # Grok Settings
    GROK_API_KEY: str = os.getenv("GROK_API_KEY", "")
    GROK_MODEL: str = os.getenv("GROK_MODEL", "grok-beta")
    
    model_config = ConfigDict(env_file=".env", extra="ignore")

@lru_cache()
def get_settings():
    return Settings()
