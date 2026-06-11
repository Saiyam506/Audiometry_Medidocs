import base64
import io
import os
import random
import subprocess
import tempfile
from datetime import datetime
from typing import List, Optional, Tuple
import shutil

import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from jinja2 import Environment, FileSystemLoader

app = FastAPI()

# Allow cross-origin requests from local test servers (web build served on localhost)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "templates")
env = Environment(loader=FileSystemLoader(TEMPLATES_DIR))
logger = logging.getLogger(__name__)


class PTAEarData(BaseModel):
    hz_500: float
    hz_1000: float
    hz_2000: float
    hz_4000: float


class WRSAnswer(BaseModel):
    word_id: int
    prompt_word: Optional[str] = None
    selected_word: Optional[str] = None
    correct_word: Optional[str] = None
    is_correct: bool


class HearingReportRequest(BaseModel):
    patient_name: str
    patient_age: int
    patient_gender: str
    patient_mobile: str = ""
    blood_group: str = ""
    uhid: str = ""
    emp_id: str = ""
    kit_no: str = ""
    wrs_language: str
    wrs_completed: bool = False
    left_ear: PTAEarData
    right_ear: PTAEarData
    wrs_answers: List[WRSAnswer]


class HearingReportResponse(BaseModel):
    pdf_base64: str
    left_pta: float
    right_pta: float
    wrs_percentage: float
    overall_score: int
    hearing_status: str


EXCELLENT_SUMMARY_SETS = {
    "Set A": [
        "Hearing sensitivity within normal limits.",
        "PTA values indicate normal hearing.",
        "No clinically significant hearing loss.",
    ],
    "Set B": [
        "Healthy hearing thresholds observed.",
        "Speech frequencies well preserved.",
        "No abnormal auditory findings.",
    ],
    "Set C": [
        "Excellent auditory performance.",
        "Hearing levels remain stable.",
        "Results consistent with normal hearing.",
    ],
    "Set D": [
        "Clear hearing response detected.",
        "Both ears show normal sensitivity.",
        "No follow-up required at this time.",
    ],
}

AVERAGE_SUMMARY_SETS = {
    "Set A": [
        "Mild hearing changes observed.",
        "Hearing remains functional for daily activities.",
        "Periodic monitoring is recommended.",
    ],
    "Set B": [
        "Slight threshold elevation detected.",
        "Speech perception likely unaffected.",
        "Hearing conservation measures advised.",
    ],
    "Set C": [
        "Minor auditory variations present.",
        "No severe hearing deficit identified.",
        "Follow-up testing may be beneficial.",
    ],
    "Set D": [
        "Early signs of hearing reduction.",
        "Communication ability remains adequate.",
        "Routine reassessment recommended.",
    ],
}

LIKELY_LOSS_SUMMARY_SETS = {
    "Set A": [
        "Hearing loss indicators detected.",
        "Elevated thresholds observed.",
        "Specialist evaluation recommended.",
    ],
    "Set B": [
        "Reduced hearing sensitivity present.",
        "Speech perception may be affected.",
        "Audiological consultation advised.",
    ],
    "Set C": [
        "Significant auditory changes identified.",
        "Hearing performance below normal range.",
        "Further assessment recommended.",
    ],
    "Set D": [
        "Abnormal hearing thresholds detected.",
        "Functional hearing may be impacted.",
        "Clinical follow-up is advised.",
    ],
}


def get_random_summary_lines(overall_score: int) -> List[str]:
    if overall_score >= 80:
        sets = EXCELLENT_SUMMARY_SETS
    elif overall_score >= 60:
        sets = AVERAGE_SUMMARY_SETS
    else:
        sets = LIKELY_LOSS_SUMMARY_SETS

    return list(random.choice(list(sets.values())))


def calc_pta(ear: PTAEarData) -> float:
    values = [ear.hz_500, ear.hz_1000, ear.hz_2000, ear.hz_4000]
    return round(sum(values) / 4.0, 1)


def classify_pta(pta: float) -> str:
    if pta <= 25:
        return "Normal Hearing"
    if pta <= 40:
        return "Mild Hearing Loss"
    if pta <= 55:
        return "Moderate Hearing Loss"
    if pta <= 70:
        return "Moderately Severe Hearing Loss"
    if pta <= 90:
        return "Severe Hearing Loss"
    return "Profound Hearing Loss"


def calc_wrs(answers: List[WRSAnswer]) -> float:
    total = len(answers)
    if total == 0:
        return 0.0
    correct = sum(1 for a in answers if a.is_correct)
    return round((correct / total) * 100.0, 1)


def calc_overall_score(left_pta: float, right_pta: float, wrs_percent: float) -> Tuple[int, str]:
    average_pta = (left_pta + right_pta) / 2.0
    pta_score = max(0.0, 100.0 - average_pta)
    overall = (pta_score + wrs_percent) / 2.0
    overall_clamped = max(0, min(100, int(round(overall))))
    if overall_clamped >= 90:
        status = "Excellent"
    elif overall_clamped >= 75:
        status = "Good"
    elif overall_clamped >= 60:
        status = "Fair"
    else:
        status = "Needs Evaluation"
    return overall_clamped, status


def calc_pta_only_score(left_pta: float, right_pta: float) -> Tuple[int, str]:
    average_pta = (left_pta + right_pta) / 2.0
    pta_score = max(0.0, 100.0 - average_pta)
    overall_clamped = max(0, min(100, int(round(pta_score))))
    if overall_clamped >= 80:
        status = "Excellent"
    elif overall_clamped >= 60:
        status = "Average"
    else:
        status = "Likely Hearing Loss"
    return overall_clamped, status


@app.post("/hearing/report", response_model=HearingReportResponse)
def hearing_report(req: HearingReportRequest):
    left_pta = calc_pta(req.left_ear)
    right_pta = calc_pta(req.right_ear)
    left_status = classify_pta(left_pta)
    right_status = classify_pta(right_pta)
    pta_overall_score, pta_overall_status = calc_pta_only_score(
        left_pta, right_pta)
    wrs_percent = calc_wrs(req.wrs_answers)
    wrs_completed = req.wrs_completed or (len(req.wrs_answers) > 0)
    if wrs_completed:
        overall_score, hearing_status = calc_overall_score(
            left_pta, right_pta, wrs_percent)
    else:
        overall_score, hearing_status = calc_pta_only_score(
            left_pta, right_pta)

    # Render HTML
    score_bar_html = (
        f'<div class="bar-fill" style="width: {overall_score:.0f}%"></div>'
    )

    base = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    def report_image(base_dir: str, filename: str) -> str:
        return os.path.join(base_dir, "assets", "report_image", filename)

    tpl = env.get_template("report.html")
    summary_lines = get_random_summary_lines(overall_score)
    wrs_detailed_rows = [
        {
            "index": idx + 1,
            "word_id": answer.word_id,
            "prompt_word": (answer.prompt_word or f"Word {answer.word_id}").strip(),
            "selected_word": (answer.selected_word or "").strip(),
            "correct_word": (answer.correct_word or answer.prompt_word or "").strip(),
            "is_correct": answer.is_correct,
        }
        for idx, answer in enumerate(req.wrs_answers)
    ]
    rendered = tpl.render(
        user_data={
            "uhid": req.uhid,
            "name": req.patient_name,
            "mobile": req.patient_mobile,
            "blood": req.blood_group,
            "age": req.patient_age,
            "gender": req.patient_gender,
            "emp_id": req.emp_id,
            "kit_no": req.kit_no,
        },
        date_time=datetime.now().strftime("%d-%m-%Y %I:%M %p"),
        medilabs_logo=f"file:///{report_image(base, 'medilabs_logo.png')}".replace(
            "\\", "/"),
        nabl_logo=f"file:///{report_image(base, 'nabl_logo.png')}".replace(
            "\\", "/"),
        overall_score=overall_score,
        score_bar_html=score_bar_html,
        hearing_status=hearing_status,
        summary_lines=summary_lines,
        left_pta=left_pta,
        right_pta=right_pta,
        left_status=left_status,
        right_status=right_status,
        pta_overall_score=pta_overall_score,
        pta_overall_status=pta_overall_status,
        wrs_completed=wrs_completed,
        wrs_language=req.wrs_language,
        total_words=len(req.wrs_answers),
        correct_answers=sum(1 for a in req.wrs_answers if a.is_correct),
        wrs_answers=req.wrs_answers,
        wrs_detailed_rows=wrs_detailed_rows,
        wrs_percentage=wrs_percent,
        left_values={
            "500": req.left_ear.hz_500,
            "1000": req.left_ear.hz_1000,
            "2000": req.left_ear.hz_2000,
            "4000": req.left_ear.hz_4000,
        },
        right_values={
            "500": req.right_ear.hz_500,
            "1000": req.right_ear.hz_1000,
            "2000": req.right_ear.hz_2000,
            "4000": req.right_ear.hz_4000,
        },
    )

    # Generate PDF via wkhtmltopdf with a hard timeout so API does not hang.
    pdf_b64 = ""
    temp_pdf_path = None
    temp_html_path = None
    try:
        # Try to find wkhtmltopdf executable
        wkpath = shutil.which("wkhtmltopdf")
        if not wkpath:
            # common install location on Windows
            candidate = r"C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
            if os.path.exists(candidate):
                wkpath = candidate

        logger.info(f"Detected wkhtmltopdf path from shutil.which: {wkpath}")
        candidate = r"C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
        logger.info(
            f"Checking candidate path: {candidate} exists={os.path.exists(candidate)}")
        if wkpath:
            with tempfile.NamedTemporaryFile(delete=False, suffix=".html", mode="w", encoding="utf-8") as temp_html:
                temp_html.write(rendered)
                temp_html_path = temp_html.name

            with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp_pdf:
                temp_pdf_path = temp_pdf.name
                print(temp_pdf.name)

            cmd = [
                wkpath,
                "--enable-local-file-access",
                "--load-error-handling",
                "ignore",
                "--load-media-error-handling",
                "ignore",
                temp_html_path,
                temp_pdf_path,
            ]
            subprocess.run(cmd, capture_output=True,
                           text=True, timeout=20, check=True)

            with open(temp_pdf_path, "rb") as pdf_file:
                pdf_bytes = pdf_file.read()

            pdf_b64 = base64.b64encode(pdf_bytes).decode("utf-8")
    except subprocess.TimeoutExpired:
        logger.exception(
            "PDF generation timed out; returning response without PDF.")
    except subprocess.CalledProcessError:
        logger.exception("wkhtmltopdf failed; returning response without PDF.")
    except Exception:
        logger.exception(
            "PDF generation failed; wkhtmltopdf may be missing or failed.")
    finally:
        if temp_pdf_path and os.path.exists(temp_pdf_path):
            os.remove(temp_pdf_path)

        if temp_html_path and os.path.exists(temp_html_path):
            os.remove(temp_html_path)

    return HearingReportResponse(
        pdf_base64=pdf_b64,
        left_pta=left_pta,
        right_pta=right_pta,
        wrs_percentage=wrs_percent,
        overall_score=overall_score,
        hearing_status=hearing_status,
    )
