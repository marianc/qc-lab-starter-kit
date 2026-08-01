from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from jinja2 import Environment
import weasyprint
import traceback
from datetime import datetime
from ..dtos.report_dtos import TestingReportRequestDto

router = APIRouter()

def register_report_routes(app, env: Environment):
    @app.post("/testing-report-pdf")
    def generate_testing_report(payload: TestingReportRequestDto):
        try:
            template = env.get_template("testing_report.html")
            generated_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            html_content = template.render(
                report=payload.report.model_dump(),
                generated_date=generated_date
            )
            
            pdf_bytes = weasyprint.HTML(string=html_content).write_pdf()
            report_id = payload.report.id or 'preview'
            
            return Response(
                content=pdf_bytes,
                media_type="application/pdf",
                headers={
                    "Content-Disposition": f"attachment; filename=testing_report_{report_id}.pdf"
                }
            )
        except Exception as e:
            err_msg = "".join(traceback.format_exception(type(e), e, e.__traceback__))
            print("ERROR generating testing report PDF:", err_msg)
            raise HTTPException(status_code=500, detail=str(e) + "\n" + err_msg)
