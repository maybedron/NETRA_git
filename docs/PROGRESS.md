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
