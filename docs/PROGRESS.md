# Progress Log

## Day 1
- [x] EfficientNet-B0 trained on APTOS2019 (val_acc 82.7%)
- [x] ONNX export and MATLAB import working (4M params, 240 layers)
- [x] Grad-CAM explainability working in MATLAB
- [x] Quality gate (Laplacian sharpness + CLAHE), threshold 15
- [ ] Segmentation
- [ ] Simulink/SimEvents district model
- [ ] Web app (Streamlit + Supabase)
- SimEvents cross-check (matlab/netra_dist.slx, built by build_district_sim.m): 2 ophthalmologists, single run.
  A: 3117 queued at day 30 (plain-MATLAB mean 3126); B: 11 queued, mean queue wait 28.7 min (plain-MATLAB 16.9 min, 10-run mean).
  B generator creates AI-referred patients only (no merge block in the library). Priority ordering verified only in the plain-MATLAB model.

## Day 2: District resource-allocation model
- Plain-MATLAB discrete-event sim: Scenario A (FIFO) vs B (AI triage, priority queue), 30 days, 10-20 runs.
- ALL parameters are assumptions, not district data: 200 pts/day, 10 min service, 1 min AI, 8 h clinic day, APTOS class mix, 82.7% AI accuracy with +/-1 grade errors.
- With 2 ophthalmologists, A saturates at about 96 pts/day; B stays stable to about 236 pts/day (about 2.4x).
- Staffing: FIFO needs 5 ophthalmologists for a stable queue; B is stable at 2.
- Safety cost: about 6% of true grade >=2 patients not referred (from the +/-1 error model, not the real confusion matrix).
- Outputs: results/district_sim.png, district_sweep.csv, district_lambda_sweep.csv, district_capacity.png.
- SimEvents cross-check (matlab/netra_dist.slx, built by matlab/build_district_sim.m), 2 ophthalmologists, single run:
  A 3117 queued at day 30 (plain-MATLAB mean 3126); B 11 queued, mean queue wait 28.7 min (plain-MATLAB 16.9 min, 10-run mean).
  B generator creates AI-referred patients only (no merge block in the library). Priority ordering verified only in the plain-MATLAB model.
