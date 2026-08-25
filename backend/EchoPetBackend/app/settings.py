from dataclasses import dataclass
from os import getenv


@dataclass(frozen=True)
class BackendSettings:
    environment: str = getenv("ECHOPET_ENV", "local")
    ai_provider: str = getenv("ECHOPET_AI_PROVIDER", "deepseek")
    ai_model: str = getenv("ECHOPET_AI_MODEL", "deepseek-v4-flash")
    ai_mode: str = getenv("ECHOPET_AI_MODE", "stub")
    deepseek_api_key: str = getenv("DEEPSEEK_API_KEY", "")
    deepseek_base_url: str = getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
    ai_timeout_seconds: float = float(getenv("ECHOPET_AI_TIMEOUT_SECONDS", "20"))


settings = BackendSettings()
