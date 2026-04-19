#!/usr/bin/env python3
"""
Test script for Gemini integration.
"""

import asyncio
import sys
import os

# Add the gpt_server directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from llm_service import LLMService

async def test_gemini():
    """Test Gemini integration."""
    print("🧪 Testing Gemini Integration")
    print("=" * 30)

    # Test messages
    messages = [
        {"role": "user", "content": "Hello! Please respond with just 'Hello from Gemini!'"}
    ]

    try:
        print("Sending test message to Gemini...")
        response = await LLMService.get_response(messages, temperature=0.1, max_tokens=50)
        print(f"✅ Response received: {response}")

        if "Hello" in response or "hello" in response:
            print("🎉 Gemini integration is working!")
            return True
        else:
            print("❌ Unexpected response format")
            return False

    except Exception as e:
        error_str = str(e)
        print(f"❌ Error: {error_str}")
        
        if "API_KEY_INVALID" in error_str or "403" in error_str:
            print("\n💡 This error means your Gemini API key is invalid.")
            print("   You need to:")
            print("   1. Get a Gemini API key from https://aistudio.google.com/app/apikey")
            print("   2. Add it to GEMINI_API_KEY in the .env file")
        elif "400" in error_str or "PERMISSION_DENIED" in error_str:
            print("\n💡 This error means your Gemini API key doesn't have the right permissions.")
            print("   Try creating a new API key from https://aistudio.google.com/app/apikey")
        
        return False

if __name__ == "__main__":
    success = asyncio.run(test_gemini())
    if not success:
        print("\nTroubleshooting tips:")
        print("1. Get a Gemini API key from https://aistudio.google.com/app/apikey")
        print("2. Add it to GEMINI_API_KEY in .env")
        print("3. Make sure GEMINI_MODEL is set (default: gemini-1.5-flash)")
        sys.exit(1)