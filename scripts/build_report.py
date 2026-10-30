"""Rebuild the evidence DRAFT PDF from reviewed source; no runtime imagery."""
import json
from pathlib import Path
from xml.sax.saxutils import escape
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak

root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'output/source/corrective-artifacts.json').read_text(encoding='utf-8'))
target = root / 'output/pdf/BeeWise-Lab3-Implementation-Report-DRAFT.pdf'
title = ParagraphStyle('title', fontName='Helvetica-Bold', fontSize=25, leading=30, textColor=colors.HexColor('#162CD4'), spaceAfter=18)
subtitle = ParagraphStyle('subtitle', fontName='Helvetica-Bold', fontSize=12, leading=17, textColor=colors.HexColor('#52627A'), spaceAfter=22)
body = ParagraphStyle('body', fontName='Helvetica', fontSize=11, leading=17, textColor=colors.HexColor('#14213D'), spaceAfter=18)
story = []
for i, page in enumerate(data['pdfPages']):
    if i: story.append(PageBreak())
    story.extend([Paragraph(escape(page['title']), title), Paragraph(escape(page['subtitle']), subtitle)])
    story.extend(Paragraph(escape(text), body) for text in page['paragraphs'])

def footer(canvas, doc):
    canvas.setStrokeColor(colors.HexColor('#FFC500'))
    canvas.setLineWidth(4)
    canvas.line(42, 805, 553, 805)
    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(colors.HexColor('#52627A'))
    canvas.drawString(42, 28, f"BeeWise | DRAFT | {data['date']} | runtime/cloud evidence missing")
    canvas.drawRightString(553, 28, str(doc.page))

SimpleDocTemplate(str(target), pagesize=(595,842), rightMargin=46, leftMargin=46,
                  topMargin=65, bottomMargin=55, title='BeeWise Lab 3 corrective evidence DRAFT',
                  author='BeeWise project').build(story, onFirstPage=footer, onLaterPages=footer)
print(f'Wrote {target}')
