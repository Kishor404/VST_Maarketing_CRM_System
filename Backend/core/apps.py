# core/apps.py
from django.apps import AppConfig
import os

class CoreConfig(AppConfig):
    name = "core"

    def ready(self):
        # initialize firebase admin once, if certificate found
        try:
            import firebase_admin
            from firebase_admin import credentials
            from django.conf import settings
            cred_path = os.environ.get("FIREBASE_CRED_PATH") or getattr(settings, "FIREBASE_CRED_PATH", None)
            if cred_path and os.path.exists(cred_path):
                if not firebase_admin._apps:   # avoid re-initialization
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
            else:
                # optional: log info, but avoid printing in production
                pass
        except Exception:
            # avoid failing startup because firebase init failed
            pass
