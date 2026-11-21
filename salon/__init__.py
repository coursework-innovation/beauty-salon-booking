import os

from flask import Flask


def create_app():
    app = Flask(__name__)
    app.secret_key = os.environ["SECRET_KEY"]

    @app.get("/health")
    def health():
        return {"status": "ok"}

    return app