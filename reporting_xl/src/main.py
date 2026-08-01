from fastapi import FastAPI
from fastapi.responses import Response
from .routes.report_routes import register_report_routes
from .routes.certificate_routes import register_certificate_routes

app = FastAPI(title="Reporting Excel Service", version="1.0.0")

register_report_routes(app)
register_certificate_routes(app)

@app.get("/health")
def health():
    return {"status": "ok"}
