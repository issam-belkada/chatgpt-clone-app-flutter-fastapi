#!/usr/bin/env python3
"""
Test script for local LLM integration.
This script tests if the local LLM service is properly configured and working.
"""

import asyncio
import aiohttp
import json
import sys
import os

# Add the gpt_server directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from config import get_settings

settings = get_settings()

async def test_ollama_connection():
    """Test if Ollama is running and accessible."""
    try:
        async with aiohttp.ClientSession() as session:
            url = f"{settings.OLLAMA_BASE_URL}/api/tags"
            async with session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    models = data.get("models", [])
                    print(f"✅ Ollama is running at {settings.OLLAMA_BASE_URL}")
                    print(f"Available models: {[model['name'] for model in models]}")

                    # Check if our configured model is available
                    model_names = [model['name'] for model in models]
                    if settings.OLLAMA_MODEL in model_names:
                        print(f"✅ Model '{settings.OLLAMA_MODEL}' is available")
                        return True
                    else:
                        print(f"❌ Model '{settings.OLLAMA_MODEL}' not found. Available: {model_names}")
                        return False
                else:
                    print(f"❌ Ollama API returned status {response.status}")
                    return False
    except aiohttp.ClientConnectorError:
        print(f"❌ Cannot connect to Ollama at {settings.OLLAMA_BASE_URL}")
        print("Make sure Ollama is running: 'ollama serve'")
        return False
    except Exception as e:
        print(f"❌ Error testing Ollama: {str(e)}")
        return False

async def test_ollama_chat():
    """Test a simple chat with Ollama."""
    try:
        async with aiohttp.ClientSession() as session:
            messages = [{"role": "user", "content": "Hello! Please respond with just 'Hello from Ollama!'"}]

            data = {
                "model": settings.OLLAMA_MODEL,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": 0.1,
                    "num_predict": 50
                }
            }

            url = f"{settings.OLLAMA_BASE_URL}/api/chat"
            async with session.post(url, json=data) as response:
                if response.status == 200:
                    result = await response.json()
                    content = result.get("message", {}).get("content", "")
                    print(f"✅ Chat test successful!")
                    print(f"Response: {content[:100]}...")
                    return True
                else:
                    error_text = await response.text()
                    print(f"❌ Chat test failed: {response.status} - {error_text}")
                    return False
    except Exception as e:
        print(f"❌ Error in chat test: {str(e)}")
        return False

async def test_local_api():
    """Test custom local API if configured."""
    if settings.LOCAL_LLM_PROVIDER != "api":
        return True  # Skip if not using custom API

    try:
        async with aiohttp.ClientSession() as session:
            data = {
                "messages": [{"role": "user", "content": "Hello"}],
                "temperature": 0.7,
                "max_tokens": 50
            }

            url = f"{settings.LOCAL_API_BASE_URL}/generate"
            async with session.post(url, json=data) as response:
                if response.status == 200:
                    result = await response.json()
                    print(f"✅ Local API is working at {settings.LOCAL_API_BASE_URL}")
                    return True
                else:
                    print(f"❌ Local API test failed: {response.status}")
                    return False
    except aiohttp.ClientConnectorError:
        print(f"❌ Cannot connect to local API at {settings.LOCAL_API_BASE_URL}")
        return False
    except Exception as e:
        print(f"❌ Error testing local API: {str(e)}")
        return False

async def main():
    """Run all tests."""
    print("🧪 Testing Local LLM Integration")
    print("=" * 40)

    print(f"LLM Provider: {settings.LLM_PROVIDER}")
    print(f"Local LLM Provider: {settings.LOCAL_LLM_PROVIDER}")
    print()

    if settings.LLM_PROVIDER != "local":
        print("❌ LLM_PROVIDER is not set to 'local'. Set LLM_PROVIDER=local in .env")
        return

    success = True

    if settings.LOCAL_LLM_PROVIDER == "ollama":
        print("Testing Ollama integration...")
        if not await test_ollama_connection():
            success = False
        else:
            print("Testing Ollama chat...")
            if not await test_ollama_chat():
                success = False
    elif settings.LOCAL_LLM_PROVIDER == "api":
        print("Testing custom local API...")
        if not await test_local_api():
            success = False
    else:
        print(f"❌ Unknown LOCAL_LLM_PROVIDER: {settings.LOCAL_LLM_PROVIDER}")
        print("Supported providers: ollama, api")
        success = False

    print()
    if success:
        print("🎉 All tests passed! Local LLM integration is ready.")
    else:
        print("❌ Some tests failed. Please check the configuration and try again.")

if __name__ == "__main__":
    asyncio.run(main())