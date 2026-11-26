import os

from flask import Flask

from .db import fetch_one


def create_app():
    app = Flask(__name__)
    app.secret_key = os.environ["SECRET_KEY"]

    @app.get("/health")
    def health():
        fetch_one("SELECT 1")
        return {"status": "ok"}

    return app
