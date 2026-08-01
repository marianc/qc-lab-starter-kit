from fastapi import FastAPI
from fastapi.responses import Response
from jinja2 import Environment, FileSystemLoader
import os

from .routes.report_routes import register_report_routes
from .routes.certificate_routes import register_certificate_routes
from .routes.spec_routes import register_spec_routes

app = FastAPI(title="Reporting PDF Service", version="1.0.0")

templates_dir = os.path.join(os.path.dirname(__file__), "templates")
env = Environment(loader=FileSystemLoader(templates_dir))

register_report_routes(app, env)
register_certificate_routes(app, env)
register_spec_routes(app, env)

@app.get("/health")
def health():
    return {"status": "ok"}
