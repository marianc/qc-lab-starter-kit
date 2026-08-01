from fastapi import HTTPException
from fastapi.responses import Response
from jinja2 import Environment
import weasyprint
import traceback
from datetime import datetime
from typing import Optional
from ..dtos.spec_dtos import SpecificationRequestDto

def format_date_ddmmyyyy(date_str: Optional[str]) -> str:
    if not date_str:
        return "-"
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f"):
        try:
            dt = datetime.strptime(date_str.strip(), fmt)
            return dt.strftime("%d.%m.%Y")
        except ValueError:
            continue
    return date_str

def register_spec_routes(app, env: Environment):
    @app.post("/specification-pdf")
    def generate_specification(payload: SpecificationRequestDto):
        try:
            template = env.get_template("specification.html")
            generated_date = datetime.now().strftime("%d.%m.%Y %H:%M:%S")

            report_dict = payload.report.model_dump()
            if report_dict.get("dateSubmitted"):
                report_dict["dateSubmitted"] = format_date_ddmmyyyy(report_dict["dateSubmitted"])
            if report_dict.get("dateCancelled"):
                report_dict["dateCancelled"] = format_date_ddmmyyyy(report_dict["dateCancelled"])
            
            html_content = template.render(
                report=report_dict,
                generated_date=generated_date
            )
            
            pdf_bytes = weasyprint.HTML(string=html_content).write_pdf()
            spec_id = report_dict.get('id', 'preview')

            return Response(
                content=pdf_bytes,
                media_type="application/pdf",
                headers={
                    "Content-Disposition": f"attachment; filename=specification_{spec_id}.pdf"
                }
            )
        except Exception as e:
            err_msg = "".join(traceback.format_exception(type(e), e, e.__traceback__))
            print("ERROR generating specification PDF:", err_msg)
            raise HTTPException(status_code=500, detail=str(e) + "\n" + err_msg)
