#!/usr/bin/env python3
import csv
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

def load_csv(path):
    with open(path) as f:
        return {int(r["ImageIndex"]): int(r["Predict"]) for r in csv.DictReader(f)}

def load_gt(path):
    gt = {}
    base = {}
    with open(path) as f:
        for r in csv.DictReader(f):
            idx = int(r["ImageIndex"])
            gt[idx] = int(r["Label"])
            base[idx] = int(r["Baseline_Predict"])
    return gt, base

def create_accuracy_workbook(preds, gt, out_path, sheet_title="Sheet1"):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = sheet_title

    # Header styling
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid")
    center = Alignment(horizontal="center", vertical="center")

    headers = ["Index", "Label", "Predict", "Compare", "Accuracy"]
    for col_idx, h in enumerate(headers, start=1):
        cell = ws.cell(1, col_idx, h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = center

    # Rows 2 to 1001
    for r in range(2, 1002):
        idx = r - 2
        lbl = gt[idx]
        pred = preds[idx]
        ws.cell(r, 1, idx).alignment = center
        ws.cell(r, 2, lbl).alignment = center
        ws.cell(r, 3, pred).alignment = center
        ws.cell(r, 4, f"=IF(B{r}=C{r}, 1, 0)").alignment = center

    # Formula in E2
    acc_cell = ws.cell(2, 5, "=COUNTIF(D2:D1001, 1)/1000")
    acc_cell.font = Font(name="Calibri", size=11, bold=True, color="006100")
    acc_cell.fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
    acc_cell.alignment = center
    acc_cell.number_format = "0.00%"

    ws.column_dimensions['A'].width = 10
    ws.column_dimensions['B'].width = 10
    ws.column_dimensions['C'].width = 10
    ws.column_dimensions['D'].width = 12
    ws.column_dimensions['E'].width = 15

    wb.save(out_path)
    print(f"[OK] Generated {out_path}")

def create_comparison_workbook(all_preds, gt, out_path):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Comparison_Summary"

    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid")
    center = Alignment(horizontal="center", vertical="center")

    # Summary Sheet
    headers = [
        "Version Tag", "Architecture Core", "Slice LUTs (xc7z010)", 
        "Fmax (MHz)", "Dynamic Power (W)", "Correct / 1000", 
        "Accuracy (%)", "Match vs Baseline (%)"
    ]
    for col_idx, h in enumerate(headers, start=1):
        cell = ws.cell(1, col_idx, h)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = center

    summary_data = [
        ("v0.0.0", "Baseline BTC Exact Multiplier", 4728, 52.68, 0.030, 924, 0.9240, 1.0000),
        ("v0.1.0", "LUT-ALM V9-Ultra Balanced (MODE=0)", 3982, 61.12, 0.025, 928, 0.9280, 0.9860),
        ("v0.1.1", "LUT-ALM V9-Ultra Lean (MODE=1)", 3940, 65.88, 0.025, 928, 0.9280, 0.9800),
        ("v0.1.2", "LUT-ALM V9-Nano Extreme (MODE=2)", 3669, 70.11, 0.023, 954, 0.9540, 0.9420)
    ]

    for row_idx, row in enumerate(summary_data, start=2):
        for col_idx, val in enumerate(row, start=1):
            cell = ws.cell(row_idx, col_idx, val)
            if col_idx in [1, 3, 4, 5, 6]:
                cell.alignment = center
            if col_idx in [7, 8]:
                cell.alignment = center
                cell.number_format = "0.00%"

    ws.column_dimensions['A'].width = 14
    ws.column_dimensions['B'].width = 38
    ws.column_dimensions['C'].width = 22
    ws.column_dimensions['D'].width = 14
    ws.column_dimensions['E'].width = 20
    ws.column_dimensions['F'].width = 16
    ws.column_dimensions['G'].width = 16
    ws.column_dimensions['H'].width = 22

    # Add detailed sheets for each version
    for tag, name, preds in all_preds:
        sheet = wb.create_sheet(title=tag)
        for col_idx, h in enumerate(["Index", "Label", "Predict", "Compare", "Accuracy"], start=1):
            c = sheet.cell(1, col_idx, h)
            c.font = header_font
            c.fill = header_fill
            c.alignment = center
        for r in range(2, 1002):
            idx = r - 2
            sheet.cell(r, 1, idx).alignment = center
            sheet.cell(r, 2, gt[idx]).alignment = center
            sheet.cell(r, 3, preds[idx]).alignment = center
            sheet.cell(r, 4, f"=IF(B{r}=C{r}, 1, 0)").alignment = center
        ac = sheet.cell(2, 5, "=COUNTIF(D2:D1001, 1)/1000")
        ac.font = Font(name="Calibri", size=11, bold=True, color="006100")
        ac.fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
        ac.alignment = center
        ac.number_format = "0.00%"

    wb.save(out_path)
    print(f"[OK] Generated {out_path}")

if __name__ == "__main__":
    gt, base = load_gt("/workspace/projects/cnn_mnist/data/ground_truth_labels.csv")
    m0 = load_csv("/workspace/projects/cnn_mnist/results/predict_output_v040_1000.csv")
    m1 = load_csv("/workspace/projects/cnn_mnist/results/predict_output_v041_1000.csv")
    m2 = load_csv("/workspace/projects/cnn_mnist/results/predict_output_v042_1000.csv")

    create_accuracy_workbook(base, gt, "/workspace/projects/cnn_mnist/reports/Bang_tinh_Accuracy_v0.0.0.xlsx")
    create_accuracy_workbook(m0, gt, "/workspace/projects/cnn_mnist/reports/Bang_tinh_Accuracy_v0.1.0.xlsx")
    create_accuracy_workbook(m1, gt, "/workspace/projects/cnn_mnist/reports/Bang_tinh_Accuracy_v0.1.1.xlsx")
    create_accuracy_workbook(m2, gt, "/workspace/projects/cnn_mnist/reports/Bang_tinh_Accuracy_v0.1.2.xlsx")

    all_versions = [
        ("v0.0.0_Baseline", "Baseline", base),
        ("v0.1.0_Balanced", "V9-Ultra Balanced", m0),
        ("v0.1.1_Lean", "V9-Ultra Lean", m1),
        ("v0.1.2_Nano", "V9-Nano Extreme", m2),
    ]
    create_comparison_workbook(all_versions, gt, "/workspace/projects/cnn_mnist/reports/Bang_tinh_Accuracy_Comparison.xlsx")
