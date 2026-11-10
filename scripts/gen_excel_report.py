#!/usr/bin/env python3
import csv
import sys
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment

def gen_excel(pred_csv="results/predict_output.csv", gt_csv="data/ground_truth_labels.csv", out_xlsx="reports/Bang_tinh_Accuracy.xlsx"):
    gt = {}
    with open(gt_csv, "r") as f:
        for r in csv.DictReader(f):
            gt[int(r["ImageIndex"])] = int(r["Label"])
    
    preds = {}
    with open(pred_csv, "r") as f:
        for r in csv.DictReader(f):
            preds[int(r["ImageIndex"])] = int(r["Predict"])

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Sheet1"

    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid")
    center = Alignment(horizontal="center", vertical="center")

    headers = ["Index", "Label", "Predict", "Compare", "Accuracy"]
    for col_idx, h in enumerate(headers, start=1):
        cell = ws.cell(1, col_idx, h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = center

    num_rows = min(len(preds), 1000)
    for r in range(2, num_rows + 2):
        idx = r - 2
        ws.cell(r, 1, idx).alignment = center
        ws.cell(r, 2, gt.get(idx, 0)).alignment = center
        ws.cell(r, 3, preds.get(idx, 0)).alignment = center
        ws.cell(r, 4, f"=IF(B{r}=C{r}, 1, 0)").alignment = center

    acc_cell = ws.cell(2, 5, f"=COUNTIF(D2:D{num_rows+1}, 1)/{num_rows}")
    acc_cell.font = Font(name="Calibri", size=11, bold=True, color="006100")
    acc_cell.fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
    acc_cell.alignment = center
    acc_cell.number_format = "0.00%"

    ws.column_dimensions['A'].width = 10
    ws.column_dimensions['B'].width = 10
    ws.column_dimensions['C'].width = 10
    ws.column_dimensions['D'].width = 12
    ws.column_dimensions['E'].width = 15

    wb.save(out_xlsx)
    print(f"[OK] Generated {out_xlsx} ({num_rows} images)")
    
    # Also write standardized academic English filename for IEEE reporting
    eng_xlsx = "reports/Accuracy_Evaluation.xlsx"
    if out_xlsx != eng_xlsx:
        wb.save(eng_xlsx)
        print(f"[OK] Generated {eng_xlsx} ({num_rows} images)")

if __name__ == "__main__":
    p = sys.argv[1] if len(sys.argv) > 1 else "results/predict_output.csv"
    g = sys.argv[2] if len(sys.argv) > 2 else "data/ground_truth_labels.csv"
    o = sys.argv[3] if len(sys.argv) > 3 else "reports/Bang_tinh_Accuracy.xlsx"
    gen_excel(p, g, o)
