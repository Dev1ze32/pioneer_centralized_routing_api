import logging
import threading
import time
from sqlalchemy import text
from db import managed_connection

logger = logging.getLogger(__name__)

# 24 hours in seconds
CLEANUP_INTERVAL_SECONDS = 86400

# FIX I3: Wait 60 seconds after startup before the first cleanup run.
# This avoids hitting the DB during cold start (when it may not be ready
# yet in Docker) and avoids adding load at the exact moment the server boots.
_INITIAL_DELAY_SECONDS = 60

def _cleanup_loop():
    time.sleep(_INITIAL_DELAY_SECONDS)
    while True:
        try:
            with managed_connection() as conn:
                result = conn.execute(text("""
                    DELETE FROM pending_approvals 
                    WHERE status IN ('APPROVED', 'REJECTED') 
                      AND resolved_at < NOW() - INTERVAL '30 days'
                """))
                
                # Only log if something was actually deleted
                if result.rowcount > 0:
                    logger.info("Cleaned up %d old records from pending_approvals", result.rowcount)
        except Exception as e:
            logger.exception("Error during pending_approvals cleanup: %s", e)
            
        time.sleep(CLEANUP_INTERVAL_SECONDS)

def start_cleanup_thread():
    """Starts the background thread for cleaning up old pending approvals."""
    thread = threading.Thread(target=_cleanup_loop, daemon=True)
    thread.start()
    logger.info("Pending approvals cleanup background thread started (first run in %ds).", _INITIAL_DELAY_SECONDS)
