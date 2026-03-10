---

# 1) DILE-style Markdown (kỹ thuật — copy vào repo / tài liệu kỹ sư)

```markdown
# PEM-IPAPSA / PEM-MIPAPSA / PEM-BSMIPAPSA — Trích xuất từ Tran & Albu (DSP, 2025). :contentReference[oaicite:4]{index=4}

## Tóm tắt ý tưởng
- Hệ: PEM-AFC (Prediction Error Method adaptive feedback cancellation) — dùng prefilter Â(q) để tiền-làm trắng (pre-whiten) tín hiệu microphone và loudspeaker trước khi áp adaptive update. :contentReference[oaicite:5]{index=5}
- Các thuật toán chính: kết hợp **proportionate** gain matrix với **affine projection sign** family → dẫn tới PEM-IPAPSA, PEM-MIPAPSA, PEM-BSMIPAPSA. (Công thức cập nhật ở các eq. (15),(18),(19),(21),(23)-(25)). :contentReference[oaicite:6]{index=6}

---

## Notation chính (nhanh)
- u(n): loudspeaker vector length Lh (u(n), u(n−1),...)
- h (true): feedback path (length Lh)
- ĥ(n): ước lượng adaptive filter (length Lĥ)
- up(n) = Â(q) u(n), mp(n) = Â(q) m(n)  → prewhitened signals
- P: projection order (số cột trong U_p)
- e_p(n) = m_p(n) − U_p^T(n) ĥ(n)  → vector lỗi a-posteriori kích thước P
- sgn[.] : signum element-wise

---

## Các công thức quan trọng (nguyên văn, để implement)

### 1) Proportionate gain — IPAPSA
- Gain matrix B(n) = diag{ b_k(n) } với

\[
b_k(n) = \frac{1-\beta}{2 Lĥ} \;+\; (1+\beta)\; \frac{ | \, \hat h_k(n) \, |_2^2 }{ \lVert \hat h(n) \rVert_1 + \xi }
\]

(trong bài viết đánh dấu bằng biểu thức như eq.(16)). :contentReference[oaicite:7]{index=7}

- Vector cập nhật (PEM-IPAPSA) — eq.(18):

\[
\hat h(n+1) = \hat h(n) + \mu \; \frac{ u_{p,gs}(n) }{ \sqrt{ u_{p,gs}^T(n) u_{p,gs}(n) + \varepsilon } }
\]

với \( u_{p,gs}(n) = B(n) U_p(n)\ \mathrm{sgn}[e_p(n)] \). :contentReference[oaicite:8]{index=8}

---

### 2) Memory-IPAPSA (MIPAPSA)
- Định nghĩa Q(n) = B(n) U_p(n) và xấp xỉ Q̃(n) = [ b(n) ⊙ u_p(n), Q̃_{-1}(n) ] (xem eq.(19)-(20)).
- Cập nhật: (eq.(21))

\[
\hat h(n+1) = \hat h(n) + \mu \; \frac{ \tilde u_{p,gs}(n) }{ \sqrt{ \tilde u_{p,gs}^T(n) \tilde u_{p,gs}(n) + \varepsilon } }
\]

với \(\tilde u_{p,gs}(n) = \tilde Q(n)\ \mathrm{sgn}[e_p(n)]\). :contentReference[oaicite:9]{index=9}

---

### 3) Block-Sparse MIPAPSA (BS-MIPAPSA) → PEM-BSMIPAPSA
- Chia ĥ(n) thành M block, mỗi block dài N (Lĥ = M×N). (eq.(22))
- Block gain scalar cho block k:

\[
\breve b_k(n) = \frac{1-\beta}{2 Lĥ} \;+\; (1+\beta)\; \frac{ \| \hat h_k(n) \|_2^2 }{ 2M \sum_{j=0}^{M-1} \| \hat h_j(n) \|_2^2 + \xi }
\]

(Eq.(24)). Sau đó, B̌(n) = [ b̌_0(n) 1_N, b̌_1(n) 1_N, ...]ᵀ (eq.(23)). :contentReference[oaicite:10]{index=10}

- Cập nhật (eq.(25)):

\[
\hat h(n+1) = \hat h(n) + \mu \; \frac{ \breve u_{p,gs}(n) }{ \sqrt{ \breve u_{p,gs}^T(n) \breve u_{p,gs}(n) + \varepsilon } }
\]

với \(\breve u_{p,gs}(n) = \breve Q(n)\ \mathrm{sgn}[e_p(n)]\). :contentReference[oaicite:11]{index=11}

---

## Pseudocode đầy đủ (tóm tắt từ Table 1)
1. Input: μ>0, ε>0, P (projection order), Lĥ (estimated filter length), u(n), m(n), other params (β, δ, ξ), M (blocks), N (block length).
2. Initialize: ĥ(0)=0; â(0)=0.
3. For n = 1,2,...
   - Estimate prefilter â(n) bằng Levinson-Durbin (LPC) trên 1 frame (bài báo: cập nhật every 10 ms). :contentReference[oaicite:12]{index=12}
   - m_p(n) = â^T(n) m(n);  u_p(n) = â^T(n) u(n).
   - e_p(n) = m_p(n) − U_p^T(n) ĥ(n).
   - Tính b_k(n) như công thức trên; B(n)=diag{b_k}.
   - **CASE PEM-IPAPSA**: u_{p,gs}=B(n) U_p(n) sgn[e_p(n)] → cập nhật theo (18).
   - **CASE PEM-MIPAPSA**: xây Q̃(n) như eq.(19)-(20), tính ũ_{p,gs}=Q̃(n) sgn[e_p(n)] → cập nhật theo (21).
   - **CASE PEM-BSMIPAPSA**: tách block; tính b̌_k(n) theo eq.(24), B̌(n) → Q̌(n) → ǔ_{p,gs} → cập nhật theo (25).
   - Lưu/giám sát MIS / ASG / PESQ theo nhu cầu. :contentReference[oaicite:13]{index=13}

---

## Các tham số mặc định (những giá trị đã dùng trong mô phỏng)
> tất cả giá trị này lấy trực tiếp từ phần "Simulation setup" của bài báo. :contentReference[oaicite:14]{index=14}

- Length of true feedback path: Lh = 100 (sample).
- Estimated filter length: Lĥ = 64.
- Projection order: P = 2 (mặc định; bài báo thử P khác nhau; chọn 2 cho hearing aids để giữ chi phí tính toán thấp). :contentReference[oaicite:15]{index=15}
- Step-sizes (đã dùng để đảm bảo cùng tốc độ hội tụ ban đầu):
  - PEM (APSA family: IPAPSA, MIPAPSA, BS-MIPAPSA): μ = 8 × 10⁻⁶.
  - PEM-APA, PEM-IPAPA: μ = 8 × 10⁻⁴.
  - PEM-NLMS, PEM-IPNLMS: μ = 1 × 10⁻³. :contentReference[oaicite:16]{index=16}
- β = 0 (tham số trong biểu thức b_k; bài báo khuyến nghị β = −0.5 hoặc 0; họ chọn 0 trong mô phỏng). :contentReference[oaicite:17]{index=17}
- δ = ξ = 10⁻⁶ (regularization); ε được chọn theo công thức trong bài (là small positive), cụ thể bài viết cho: ε = (1−β) / (2 Lĥ) · δ  (với β=0 → ε ≈ δ/(2Lĥ) ). **Với Lĥ=64 và δ=1e-6 → ε ≈ 7.8125e-9**. (bạn có thể đặt ε = 1e-8 làm giá trị tiện dụng). :contentReference[oaicite:18]{index=18}
- Prefilter (Â(q)) order = 20; coefficients estimated every 10 ms using Levinson-Durbin. :contentReference[oaicite:19]{index=19}
- Forward path: delay d_k = 96 samples, gain |K| = 30 dB. Delay in canceler path d_fb = 1 sample. :contentReference[oaicite:20]{index=20}
- Number of blocks (PEM-BSMIPAPSA): M = 8 (→ block length N = Lĥ / M = 8). :contentReference[oaicite:21]{index=21}

---

## Các lưu ý triển khai (kỹ sư)
- Cập nhật prefilter (Levinson-Durbin) tốn O(L_a^2); bài báo dùng L_a = 20 và update mỗi 10 ms. (Tradeoff: update nhanh giúp giảm bias nhưng tăng chi phí). :contentReference[oaicite:22]{index=22}
- P tăng → hội tụ nhanh hơn nhưng chi phí tính toán tăng rất mạnh (P=2 được khuyến nghị cho HA); bài báo đo tăng phép nhân khi P=3,5,7. :contentReference[oaicite:23]{index=23}
- Khởi tạo ĥ(0)=0; theo dõi MIS và ASG để đánh giá độ hội tụ trong mục thử nghiệm. :contentReference[oaicite:24]{index=24}

---

## Tài liệu tham khảo ngắn (trong bài báo)
- Pseudocode và các eq. chính nằm trong Table 1 và các eq. (13)-(25) của bài. :contentReference[oaicite:25]{index=25}
```

---

# 2) LFA prompt (prompt sẵn dùng cho AI/agent để *tự động* thêm/triển khai thuật toán vào hệ thống của bạn)

```
You are an AI engineer agent that will implement and validate PEM-IPAPSA, PEM-MIPAPSA and PEM-BSMIPAPSA for an existing adaptive feedback-cancellation system. Use the equations and pseudocode from Tran & Albu (Digital Signal Processing, 2025) as the authoritative reference.

TASKS:
1. Implement modules (language: Python preferred; provide C++/embedded-C pseudo-ports) for:
   - prefilter estimation (Levinson-Durbin, order L_a=20, frame update every 10 ms),
   - PEM-IPAPSA (eq. 15 & 18 + B(n) formula),
   - PEM-MIPAPSA (eq. 19 & 21 + Q̃ approximation),
   - PEM-BSMIPAPSA (eq. 23–25, block formation with M=8, N=Lĥ/M).

2. Use default config from the paper:
   - sampling fs=16kHz; Lh=100, Lh_hat=64, P=2, mu_IPAPSA_family=8e-6, mu_APA_family=8e-4, mu_NLMS=1e-3,
   - beta=0, delta=xi=1e-6, epsilon ≈ delta/(2*Lh_hat) (≈7.8125e-9),
   - prefilter order L_a=20, estimate every 10 ms,
   - forward delay d_k=96, forward gain=30 dB, feedback-canceler delay d_fb=1 sample.

3. Provide unit tests:
   - Synthetic test: simulate known sparse h (length 100) and speech-like u(n) (use IEEE sentences or TIMIT), measure MIS and ASG vs iterations.
   - Noise tests: add WGN and BG impulsive noise; SNR = [0,5,10,20,30] dB; SIR=0 dB for impulsive.
   - Parameter sweep: vary P in [2,3,5,7] and block count M in [2,4,8,16]; record MIS, PESQ, CPU ops per sample.

4. Deliverables:
   - Well-documented code (python package + C++ embedded stub),
   - YAML/JSON configuration file with all hyperparameters,
   - Automated test scripts and plots: MIS vs time, PESQ scores, computation ops per sample,
   - Short README explaining recommended defaults for hearing aids (P=2, mu family values, prefilter update frequency),
   - Benchmarks on a single-thread CPU (ops/sample) consistent with paper Table 3.

IMPLEMENTATION NOTES:
- Numeric stability: use double precision for internal updates; use robust sqrt denominator with ε.
- Perf: avoid full matrix inversions; implement Q̃ approximation as in the paper for MIPAPSA.
- Save checkpoints of ĥ(n) every second for debugging.

REFERENCE: Use Tran & Albu, DSP 165 (2025) as the canonical source for formulae and pseudocode. :contentReference[oaicite:26]{index=26}
```

