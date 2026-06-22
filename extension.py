# extensions.py
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from config import Config

# Initialize without attaching to the app yet
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[Config.RATE_LIMIT_DEFAULT],
    # In-memory storage is fine for a single-server internal deployment.
    # If you ever run multiple gunicorn processes on separate machines,
    # switch to storage_uri="redis://localhost:6379" so limits are shared.
    storage_uri="memory://",
)