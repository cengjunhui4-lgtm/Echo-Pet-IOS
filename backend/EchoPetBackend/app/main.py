from __future__ import annotations

from typing import Any

from fastapi import FastAPI
from pydantic import BaseModel, Field

from .agent import build_companion_reply
from .settings import settings


class RelationshipContext(BaseModel):
    user_role: str = Field(alias="userRole")
    pet_role: str = Field(alias="petRole")


class CompanionChatRequest(BaseModel):
    message: str
    relationship: RelationshipContext
    context: dict[str, Any] | None = None


def create_app() -> FastAPI:
    app = FastAPI(
        title="Echo Pet Backend",
        version="0.1.0",
        description="Echo Pet backend stub for Companion AI Agent integration.",
    )

    @app.get("/health")
    def health() -> dict[str, str]:
        return {
            "status": "ok",
            "environment": settings.environment,
            "aiProvider": settings.ai_provider,
            "aiModel": settings.ai_model,
            "aiMode": settings.ai_mode,
        }

    @app.post("/v1/pets/{pet_id}/companion/chat")
    def companion_chat(pet_id: str, request: CompanionChatRequest) -> dict[str, Any]:
        return build_companion_reply(
            request.model_dump(by_alias=True),
            pet_id=pet_id,
        )

    return app


app = create_app()
