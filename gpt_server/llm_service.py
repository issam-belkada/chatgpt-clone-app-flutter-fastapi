from config import get_settings
import aiohttp
import logging
import asyncio
import time
from groq import AsyncGroq

settings = get_settings()

logger = logging.getLogger("uvicorn.error")

class LLMService:
    @staticmethod
    async def get_response(messages: list, temperature: float = 0.7, max_tokens: int = 1024):
        trimmed_messages = LLMService._trim_messages(messages)

        providers = [
            ("Gemini", LLMService._gemini_response),
            ("Groq",   LLMService._groq_response),
        ]

        start_time = time.time()

        for name, func in providers:
            key_attr = f"{name.upper()}_API_KEY"
            if not getattr(settings, key_attr, None):
                logger.warning(f"⚪ {name}: no API key configured, skipping.")
                continue

            for attempt in range(3):
                response, status_code = await func(trimmed_messages, temperature, max_tokens)

                if status_code == 200:
                    duration = round(time.time() - start_time, 2)
                    logger.info(f"🟢 SUCCESS: {name} responded in {duration}s")
                    return response

                if status_code in [503, 429]:
                    wait_time = (2 ** attempt) + 1  # 2s, 3s, 5s
                    logger.warning(f"🟡 {name} busy ({status_code}). Retrying in {wait_time}s... (Attempt {attempt + 1})")
                    await asyncio.sleep(wait_time)
                    continue
                else:
                    logger.warning(f"🟠 {name} failed with status {status_code}. Moving to next provider.")
                    break

        logger.error("🔴 CRITICAL: All providers failed or timed out.")
        return "I'm currently overloaded. Please try again in a few moments."

    @staticmethod
    def _trim_messages(messages: list, limit: int = 10):
        # Remove messages with empty content (cause 400 errors)
        clean_messages = [m for m in messages if m.get("content") and str(m["content"]).strip()]
        # Limit context window
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
                    "generationConfig": {
                        "temperature": temperature,
                        "maxOutputTokens": max_tokens,
                    },
                }
                url = (
                    f"https://generativelanguage.googleapis.com/v1beta/models/"
                    f"{settings.GEMINI_MODEL}:generateContent?key={settings.GEMINI_API_KEY}"
                )

                async with session.post(url, json=data, timeout=10) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result["candidates"][0]["content"]["parts"][0]["text"], 200
                    return "Error", response.status
        except Exception as e:
            logger.error(f"Gemini exception: {e}")
            return str(e), 500

    @staticmethod
    async def _groq_response(messages: list, temperature: float, max_tokens: int):
        try:
            client = AsyncGroq(api_key=settings.GROQ_API_KEY)
            completion = await client.chat.completions.create(
                model=settings.GROQ_MODEL,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
            )
            return completion.choices[0].message.content, 200
        except Exception as e:
            logger.error(f"Groq exception: {e}")
            err = str(e).lower()
            if "429" in err or "rate limit" in err:
                return str(e), 429
            if "503" in err or "unavailable" in err:
                return str(e), 503
            return str(e), 500