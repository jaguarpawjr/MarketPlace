A small guide to integrate the agent directly from Flutter

## Usage

The Flutter app now has a fully functional AI chat screen for farmers. The agent is available on the **AI Agent** tab and allows farmers to ask open-ended questions about farming, crop care, and general agricultural knowledge.

### Running with the AI Agent Enabled

1. **Set the API Key** (required):

```bash
flutter run --dart-define=GENAI_API_KEY=YOUR_GOOGLE_API_KEY
```

2. **For iOS/Android builds**, use:

```bash
flutter build apk --dart-define=GENAI_API_KEY=YOUR_GOOGLE_API_KEY
flutter build ios --dart-define=GENAI_API_KEY=YOUR_GOOGLE_API_KEY
```

### Setup

The `AIAgentService` in `lib/services/ai_agent_service.dart` connects to Google's Gemini API. It:
- Supports open-ended questions (not limited to predefined queries)
- Uses `gemini-2.5-pro` model by default
- Handles message history on the client side
- Returns text responses suitable for farming advice

### Features

- **Real-time Chat**: Farmers can ask any question and get immediate responses
- **Persistent History**: Messages are retained during the session
- **Error Handling**: Graceful error messages if the API is unreachable or API key is invalid
- **Loading Indicators**: Visual feedback while waiting for responses

### Security

- **API Key**: Passed via `GENAI_API_KEY` at compile time, with `.env` fallback for local development
- **No Backend Required**: Calls Gemini API directly from Flutter (suitable for development/testing)
- **For Production**: Consider proxying through a backend server to keep the API key secure

### Troubleshooting

If the AI Agent tab shows an error:
1. Check that `GENAI_API_KEY` is set correctly when running `flutter run`, or that `.env` contains `GENAI_API_KEY` or `GOOGLE_API_KEY`
2. Verify your API key has access to the Generative API
3. Check network connectivity
4. Review the error message displayed in the app

## Architecture

The farmer's homepage (`lib/Homepage/homepage.dart`) already has an "AI Agent" tab that renders the new `AIChatScreen` (`lib/screens/ai_chat.dart`). The chat screen:
- Initializes `AIAgentService` on startup
- Maintains a local list of messages (`ChatMessage` objects)
- Sends user input to Gemini and displays responses

