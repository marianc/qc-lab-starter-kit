from fastapi import HTTPException
from fastapi.responses import Response
from jinja2 import Environment
import weasyprint
import traceback
from datetime import datetime
from ..dtos.certificate_dtos import QualityCertificateRequestDto

def register_certificate_routes(app, env: Environment):
    @app.post("/quality-certificate-pdf")
    def generate_quality_certificate(payload: QualityCertificateRequestDto):
        try:
            template = env.get_template("quality_certificate.html")
            generated_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            html_content = template.render(
                report=payload.report.model_dump(),
                generated_date=generated_date
            )
            
            pdf_bytes = weasyprint.HTML(string=html_content).write_pdf()
            cert_id = payload.report.id or 'preview'
            
            return Response(
                content=pdf_bytes,
                media_type="application/pdf",
                headers={
                    "Content-Disposition": f"attachment; filename=quality_certificate_{cert_id}.pdf"
                }
            )
        except Exception as e:
            err_msg = "".join(traceback.format_exception(type(e), e, e.__traceback__))
            print("ERROR generating quality certificate PDF:", err_msg)
            raise HTTPException(status_code=500, detail=str(e) + "\n" + err_msg)
