#!/usr/bin/env python3
import sys
import csv
import json

def evaluate(pred_file="sim/predict_output.csv", gt_file="data/ground_truth_labels.csv", out_json=None):
    gt = {}
    with open(gt_file, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            gt[int(row["ImageIndex"])] = int(row["Label"])

    total = 0
    correct = 0
    preds = {}
    with open(pred_file, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            idx = int(row["ImageIndex"])
            pred = int(row["Predict"])
            preds[idx] = pred
            if idx in gt:
                total += 1
                if pred == gt[idx]:
                    correct += 1

    acc = (correct / total * 100.0) if total > 0 else 0.0
    print(f"=======================================================")
    print(f" CNN MNIST INFERENCE ACCURACY REPORT")
    print(f"=======================================================")
    print(f" Evaluated Images : {total} / {len(gt)}")
    print(f" Correct Matches  : {correct}")
    print(f" Accuracy (%)     : {acc:.2f}%")
    print(f"=======================================================")

    res = {
        "total_images": total,
        "correct": correct,
        "accuracy_pct": acc
    }
    if out_json:
        with open(out_json, "w") as f:
            json.dump(res, f, indent=2)

    return acc

if __name__ == "__main__":
    pred = sys.argv[1] if len(sys.argv) > 1 else "sim/predict_output.csv"
    gt = sys.argv[2] if len(sys.argv) > 2 else "data/ground_truth_labels.csv"
    evaluate(pred, gt)
