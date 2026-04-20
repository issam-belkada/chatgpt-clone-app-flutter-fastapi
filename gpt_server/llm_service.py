from config import get_settings
import aiohttp
import json
import logging

settings = get_settings()

# Set up logging
logger = logging.getLogger(__name__)

class LLMService:
    """Service for handling Google Gemini API calls."""
    
    @staticmethod
    async def get_response(messages: list, temperature: float = 0.7, max_tokens: int = 150):
        """Get response from Gemini API."""
        return await LLMService._gemini_response(messages, temperature, max_tokens)
    
    @staticmethod
    async def _gemini_response(messages: list, temperature: float, max_tokens: int):
        """Get response from Google Gemini API."""
        if not settings.GEMINI_API_KEY:
            return "Gemini API key not configured."
        
        try:
            async with aiohttp.ClientSession() as session:
                headers = {
                    "Content-Type": "application/json"
                }
                
                # Convert messages to Gemini format
                contents = []
                for msg in messages:
                    role = "user" if msg["role"] == "user" else "model"
                    contents.append({
                        "role": role,
                        "parts": [{"text": msg["content"]}]
                    })
                
                data = {
                    "contents": contents,
                    "generationConfig": {
                        "temperature": temperature,
                        "maxOutputTokens": max_tokens
                    }
                }
                
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_MODEL}:generateContent?key={settings.GEMINI_API_KEY}"
                
                async with session.post(url, json=data, headers=headers) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result["candidates"][0]["content"]["parts"][0]["text"]
                    else:
                        error_text = await response.text()
                        logger.error(f"Gemini API error: {response.status} - {error_text}")
                        return f"Gemini API error: {response.status}. Check your API key and credits."
                        
        except Exception as e:
            logger.error(f"Error calling Gemini API: {str(e)}")
            return f"Error calling Gemini API: {str(e)}"
