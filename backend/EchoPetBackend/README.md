# Echo Pet Backend

FastAPI backend for Echo Pet Companion AI Agent.

By default it runs in deterministic local Stub mode for safe preview and testing. When `ECHOPET_AI_MODE=deepseek` and `DEEPSEEK_API_KEY` are configured, the same endpoint calls DeepSeek's OpenAI-compatible chat API with `deepseek-v4-flash`.

## Scope

- `GET /health`
- `POST /v1/pets/{petId}/companion/chat`
- Receives the iOS `CompanionContextPayload`
- Uses pet profile, LifePrint, Timeline, daily care tasks, and recent chat context when allowed
- Always appends the AI-generated disclosure
- Never claims the pet has truly been resurrected

## Model Configuration

The planned production model is configured through environment variables:

```bash
ECHOPET_AI_PROVIDER=deepseek
ECHOPET_AI_MODEL=deepseek-v4-flash
ECHOPET_AI_MODE=stub
DEEPSEEK_API_KEY=
DEEPSEEK_BASE_URL=https://api.deepseek.com
ECHOPET_AI_TIMEOUT_SECONDS=20
```

To enable real AI, set:

```bash
ECHOPET_AI_MODE=deepseek
DEEPSEEK_API_KEY=your_key_here
```

The server calls the OpenAI-compatible DeepSeek endpoint:

`POST https://api.deepseek.com/chat/completions`

The request disables thinking mode for lower-latency companion replies and caps output length for app chat UX.

The client API contract stays unchanged.

## Run Tests

The first tests use Python standard library only:

```bash
cd "/Users/zizy/Documents/New project/EchoPet-iOS/backend/EchoPetBackend"
python3 -m unittest discover -s tests -p "test_*.py"
```

## Run FastAPI

Install dependencies first:

```bash
cd "/Users/zizy/Documents/New project/EchoPet-iOS/backend/EchoPetBackend"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Then preview:

```bash
curl http://127.0.0.1:8000/health
```

If FastAPI dependencies are not installed yet, use the standard-library preview server:

```bash
cd "/Users/zizy/Documents/New project/EchoPet-iOS/backend/EchoPetBackend"
python3 -m app.dev_server
```

It exposes the same preview routes:

- `GET /health`
- `POST /v1/pets/{petId}/companion/chat`

Companion chat:

```bash
curl -X POST http://127.0.0.1:8000/v1/pets/00000000-0000-0000-0000-000000000001/companion/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "我有点想豆包",
    "relationship": {
      "userRole": "主人",
      "petRole": "猫"
    },
    "context": {
      "languageCode": "zh_Hans",
      "tone": "gentleCompanion",
      "pet": {
        "petId": "00000000-0000-0000-0000-000000000001",
        "name": "豆包",
        "species": "猫",
        "breed": "狸花猫",
        "age": "4 岁",
        "relationshipLabel": "家人",
        "personality": "亲人、安静、好奇",
        "mbti": "温柔观察型",
        "favoriteThings": ["窗边晒太阳"],
        "habits": ["听到钥匙声就跑来"]
      },
      "lifePrint": {
        "summary": "豆包喜欢安静陪伴。",
        "updatedAt": "2026-08-09T00:00:00Z",
        "personalityTraits": ["亲人、安静"],
        "favoriteThings": ["窗边晒太阳"],
        "habits": ["等钥匙声"],
        "sourceMemoryIds": ["00000000-0000-0000-0000-000000000002"],
        "isAiGenerated": true
      },
      "timelineMemories": [{
        "timelineId": "00000000-0000-0000-0000-000000000003",
        "memoryId": "00000000-0000-0000-0000-000000000002",
        "date": "2022-04-08T00:00:00Z",
        "title": "第一次回家",
        "story": "豆包慢慢靠近你的手。",
        "mediaAssetCount": 2,
        "sourceMemoryIds": ["00000000-0000-0000-0000-000000000002"]
      }],
      "dailyTasks": [{
        "taskId": "00000000-0000-0000-0000-000000000004",
        "title": "换一碗新鲜水",
        "template": "feeding",
        "isCompleted": false
      }],
      "recentMessages": [],
      "privacy": {
        "allowsMemoryContext": true,
        "usesPetProfile": true,
        "usesLifePrint": true,
        "usesTimeline": true,
        "usesDailyTasks": true,
        "usesChatHistory": false
      }
    }
  }'
```
