"""
Flask extensions — instantiated here with no app attached yet.

Keeping extensions in their own module breaks the circular import that occurs
when blueprints try to import `limiter` from `app.py`:

    app.py → routes/__init__.py → auth.py → app.py  ← circular!

With this file the import chain becomes:
    app.py      → extension.py   (fine, no project imports here)
    auth.py     → extension.py   (fine, no project imports here)
    app.py      → routes/...     (fine, extension.py is already loaded)

Usage
-----
In app.py:
    from extension import limiter
    limiter.init_app(app)

In any blueprint:
    from extension import limiter

    @bp.post("/login")
    @limiter.limit("10/minute")
    def login(): ...
"""

from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from config import Config

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[Config.RATE_LIMIT_DEFAULT],
    # In-memory storage is fine for a single-server internal deployment.
    # Switch to storage_uri="redis://localhost:6379" if you scale to
    # multiple gunicorn processes on separate machines.
    storage_uri="memory://",
)