from config import get_settings
import aiohttp
import json
import logging
import asyncio
import time

settings = get_settings()

# Use the uvicorn error logger to ensure it shows up in your Fedora terminal
logger = logging.getLogger("uvicorn.error")

class LLMService:
    @staticmethod
    async def get_response(messages: list, temperature: float = 0.7, max_tokens: int = 150):
        # Trim messages to prevent 400 Context Window errors
        trimmed_messages = LLMService._trim_messages(messages)
        
        providers = [
            ("Gemini", LLMService._gemini_response),
            ("DeepSeek", LLMService._deepseek_response),
            ("Grok", LLMService._grok_response)
        ]

        start_time = time.time()

        for name, func in providers:
            # Check if API key exists for the provider
            key_attr = f"{name.upper()}_API_KEY"
            if not getattr(settings, key_attr, None):
                continue

            for attempt in range(3):  # Increased to 3 attempts for better reliability
                response, status_code = await func(trimmed_messages, temperature, max_tokens)
                
                if status_code == 200:
                    duration = round(time.time() - start_time, 2)
                    # Logs who responded in your terminal
                    logger.info(f"🟢 SUCCESS: {name} responded in {duration}s")
                    return response # Returns ONLY the string to Flutter
                
                # Exponential Backoff logic for busy servers (503) or rate limits (429)
                if status_code in [503, 429]:
                    wait_time = (2 ** attempt) + 1 # 2s, 3s, 5s...
                    logger.warning(f"🟡 {name} busy ({status_code}). Retrying in {wait_time}s... (Attempt {attempt+1})")
                    await asyncio.sleep(wait_time)
                    continue
                else:
                    logger.warning(f"🟠 {name} failed with status {status_code}. Moving to next provider.")
                    break 

        logger.error("🔴 CRITICAL: All providers failed or timed out.")
        return "I'm currently overloaded. Please try again in a few moments."
        
    @staticmethod
    def _trim_messages(messages: list, limit: int = 10):
        # 1. Remove any messages with empty content which cause 400 errors
        clean_messages = [m for m in messages if m.get("content") and str(m["content"]).strip()]
        
        # 2. Limit context
        if len(clean_messages) > limit:
            clean_messages = clean_messages[-limit:]
            
        return clean_messages

    @staticmethod
    async def _gemini_response(messages: list, temperature: float, max_tokens: int):
        try:
            async with aiohttp.ClientSession() as session:
                contents = []
                for msg in messages:
                    role = "user" if msg["role"] == "user" else "model"
                    contents.append({"role": role, "parts": [{"text": msg["content"]}]})
                
                data = {
                    "contents": contents,
                    "generationConfig": {"temperature": temperature, "maxOutputTokens": max_tokens}
                }
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_MODEL}:generateContent?key={settings.GEMINI_API_KEY}"
                
                async with session.post(url, json=data, timeout=10) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result["candidates"][0]["content"]["parts"][0]["text"], 200
                    return "Error", response.status
        except Exception as e:
            return str(e), 500

    @staticmethod
    async def _deepseek_response(messages: list, temperature: float, max_tokens: int):
        try:
            async with aiohttp.ClientSession() as session:
                headers = {"Authorization": f"Bearer {settings.DEEPSEEK_API_KEY}", "Content-Type": "application/json"}
                data = {"model": settings.DEEPSEEK_MODEL, "messages": messages, "temperature": temperature, "max_tokens": max_tokens}
                async with session.post("https://api.deepseek.com/chat/completions", json=data, headers=headers, timeout=10) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result["choices"][0]["message"]["content"], 200
                    return "Error", response.status
        except Exception as e:
            return str(e), 500


    @staticmethod
    async def _grok_response(messages: list, temperature: float, max_tokens: int):
        try:
            # Protocol: Strictly alternate roles for Grok 4.x
            formatted_messages = []
            last_role = None
            for m in messages:
                role = "assistant" if m["role"] in ["model", "assistant"] else "user"
                if role == last_role: continue
                formatted_messages.append({"role": role, "content": m["content"]})
                last_role = role

            async with aiohttp.ClientSession() as session:
                headers = {
                    "Authorization": f"Bearer {settings.GROK_API_KEY}",
                    "Content-Type": "application/json"
                }
                # Use the updated model name 'grok-4.3'
                data = {
                    "model": "grok-4.3", 
                    "messages": formatted_messages,
                    "temperature": temperature,
                    "max_tokens": max_tokens
                }
                # Note: Standard OpenAI-compatible path is usually /v1/chat/completions
                url = "https://api.x.ai/v1/chat/completions"
                async with session.post(url, json=data, headers=headers, timeout=12) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result["choices"][0]["message"]["content"], 200
                    
                    error_text = await response.text()
                    logger.error(f"Grok API Failure: {error_text}")
                    return "Error", response.status
        except Exception as e:
            return str(e), 500