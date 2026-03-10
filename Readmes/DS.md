# Các thuật toán PEM-IPAPSA, PEM-MIPAPSA, PEM-BSMIPAPSA cho khử phản hồi âm thanh trong máy trợ thính

Dựa trên bài báo: **Linh T.T. Tran, Felix Albu, "Improved proportionate affine projection sign algorithms for adaptive feedback cancellation using pre-filters in hearing aids", DSP Journal 2025.**

---

## 1. Tổng quan hệ thống PEM-AFC

Mô hình PEM-AFC sử dụng bộ lọc ngược dự đoán (pre-filter) để làm trắng tín hiệu đầu vào, giảm tương quan giữa tín hiệu incoming và tín hiệu loa.

- Tín hiệu incoming được mô hình hóa như một quá trình AR:  
  `x(n) = A^(-1)(q) w(n)`
- Tín hiệu microphone:  
  `m(n) = x(n) + v(n)` với `v(n) = h^T u(n)` là tín hiệu phản hồi.
- Tín hiệu loa:  
  `u(n) = K(q) e(n)` với `K(q)` là đường tiếng forward.

**Pre-whitening:**
```
m_p(n) = Â(q) m(n)
u_p(n) = Â(q) u(n)
e_p(n) = m_p(n) - ĥ^T(n) u_p(n)
```

---

## 2. Các thuật toán đề xuất

### 2.1. PEM-IPAPSA (Improved Proportionate Affine Projection Sign Algorithm)

Công thức cập nhật:
```
ĥ(n+1) = ĥ(n) + μ * u_p,gs(n) / √(u_p,gs^T(n) u_p,gs(n) + ε)
```
với:
- `u_p,gs(n) = B(n) U_p(n) sgn[e_p(n)]`
- `B(n) = diag{b₀(n), b₁(n), ..., b_{Lh-1}(n)}` là ma trận proportionate
- `b_k(n) = (1-β)/(2Lh) + (1+β) * |ĥ_k(n)| / (||ĥ(n)||₁ + ξ)`
- `U_p(n) = [u_p(n), u_p(n-1), ..., u_p(n-P+1)]`

**Tham số:**
| Tham số | Giá trị | Ý nghĩa |
|---------|--------|---------|
| μ | 8×10⁻⁶ | Step-size |
| P | 2 | Projection order |
| β | 0 | Proportionate factor (β = -1 → APSA, β = 1 → PAPSA) |
| ξ | 10⁻⁶ | Hằng số nhỏ |
| ε | (1-β)/(2Lh) × δ | Regularization, với δ = 10⁻⁶ |
| Lh | 64 | Chiều dài bộ lọc ước lượng |

---

### 2.2. PEM-MIPAPSA (Memory Improved PAPSA)

Sử dụng "proportionate history" từ `P` mẫu trước đó.

Công thức:
```
b(n) = [b₀(n), b₁(n), ..., b_{Lh-1}(n)]^T
Q̃(n) = [b(n) ⊙ u_p(n), Q̃₋₁(n-1)]
Q̃₋₁(n-1) = [b(n-1) ⊙ u_p(n-1), ..., b(n-P+1) ⊙ u_p(n-P+1)]
ũ_p,gs(n) = Q̃(n) sgn[e_p(n)]
ĥ(n+1) = ĥ(n) + μ * ũ_p,gs(n) / √(ũ_p,gs^T(n) ũ_p,gs(n) + ε)
```

**Tham số:** giống PEM-IPAPSA.

---

### 2.3. PEM-BSMIPAPSA (Block-Sparse Memory IPAPSA)

Chia bộ lọc thành `M` blocks, mỗi block dài `N` (`Lh = M × N`). Cùng step-size trong một block, proportionate theo block.

Ma trận proportionate theo block:
```
B̂(n) = [b̂₀(n)·1_N, b̂₁(n)·1_N, ..., b̂_{M-1}(n)·1_N]^T
b̂_k(n) = (1-β)/(2Lh) + (1+β) * ||ĥ_k(n)||₂ / (2M * Σⱼ||ĥ_j(n)||₂ + ε)
```
với `1_N` là vector hàng toàn 1 độ dài `N`.

Cập nhật:
```
û_p,gs(n) = Q̂(n) sgn[e_p(n)]
Q̂(n) = [b̂(n) ⊙ u_p(n), Q̂₋₁(n-1)]
ĥ(n+1) = ĥ(n) + μ * û_p,gs(n) / √(û_p,gs^T(n) û_p,gs(n) + ε)
```

**Tham số:**
| Tham số | Giá trị | Ý nghĩa |
|---------|--------|---------|
| M | 8 | Số blocks |
| N | Lh/M = 8 | Độ dài mỗi block |
| Các tham số khác | như trên | |

---

## 3. Các thuật toán so sánh (Baselines)

| Thuật toán | Step-size μ | Ghi chú |
|------------|-------------|---------|
| PEM-NLMS | 10⁻³ | NLMS cơ bản |
| PEM-IPNLMS | 10⁻³ | Improved PNLMS, β = 0 |
| PEM-APA | 8×10⁻⁴ | Affine Projection, P = 2 |
| PEM-IPAPA | 8×10⁻⁴ | Improved Proportionate APA, P = 2 |

---

## 4. Cấu hình mô phỏng chung

| Tham số | Giá trị | Mô tả |
|---------|--------|-------|
| fₛ | 16 kHz | Tần số lấy mẫu |
| Lh_true | 100 | Chiều dài feedback path thực |
| Lh_est | 64 | Chiều dài bộ lọc ước lượng |
| d_k | 96 samples | Độ trễ đường forward |
| K | 30 dB | Độ lợi đường forward |
| d_fb | 1 sample | Độ trễ trong bộ khử feedback |
| Lₐ | 20 | Bậc mô hình AR của pre-filter |
| Frame length | 160 samples | Cập nhật pre-filter mỗi 10 ms |
| δ, ξ | 10⁻⁶ | Hằng số nhỏ |
| β | 0 | Hệ số proportionate |
| ε | (1-β)/(2Lh) × δ | Regularization |

---

## 5. Các loại nhiễu trong thí nghiệm

### 5.1. Background noise
- White Gaussian Noise (WGN)
- Babble noise (từ NOISEX-92)
- SNR: [0, 5, 10, 20, 30] dB

### 5.2. Impulsive noise

**Bernoulli-Gaussian (BG)**
```
y(n) = c(n) × g(n)
c(n): Bernoulli với P(c=1) = α = 0.1
g(n): Gaussian trắng, zero-mean
SIR = 0 dB
```

**Alpha-stable noise**
| Tham số | Giá trị |
|--------|--------|
| κ | 1.8 (stability) |
| λ | 0 (symmetric) |
| η | 1 (scale) |
| ρ | 0 (location) |
| SIR | 0 dB |

---

## 6. Feedback paths
- **H₁(f)**: Free-field feedback path
- **H₂(f)**: Telephone-near feedback path
- Thay đổi feedback path sau 30 giây từ H₁ → H₂

---

## 7. Pseudocode đầy đủ

```python
# Input parameters
μ = 8e-6           # step-size (IPAPSA, MIPAPSA, BSMIPAPSA)
P = 2               # projection order
Lh = 64             # estimated filter length
M = 8               # number of blocks (for BS-MIPAPSA)
N = Lh // M         # block length
δ = ξ = 1e-6
β = 0
ε = (1-β)/(2*Lh) * δ

# Initialize
h_hat = np.zeros(Lh)
a_hat = np.zeros(La)   # La = 20
U_p = np.zeros((Lh, P))  # buffer for past P input vectors

# Main loop
for n in range(N_samples):
    # Update pre-filter every 160 samples (using Levinson-Durbin)
    if n % 160 == 0:
        a_hat = levinson_durbin(m[n-L_win+1:n+1], La)
    
    # Pre-whitening
    m_p = np.dot(a_hat, m[n:n-La:-1])   # convolution
    u_p = np.dot(a_hat, u[n:n-La:-1])
    
    # Update U_p matrix (shift and insert new u_p)
    U_p[:, 1:] = U_p[:, :-1]
    U_p[:, 0] = u_p
    
    # Error vector
    e_p = m_p - U_p.T @ h_hat
    
    # Proportionate matrix
    if algo == 'IPAPSA':
        b = (1-β)/(2*Lh) + (1+β) * np.abs(h_hat) / (np.sum(np.abs(h_hat)) + ξ)
        B = np.diag(b)
        u_pgs = B @ U_p @ np.sign(e_p)
        h_hat += μ * u_pgs / (np.sqrt(u_pgs.T @ u_pgs) + ε)
    
    elif algo == 'MIPAPSA':
        b = (1-β)/(2*Lh) + (1+β) * np.abs(h_hat) / (np.sum(np.abs(h_hat)) + ξ)
        # Build Q̃ matrix (memory proportionate)
        # Simplified: we need to store past b⊙u_p
        # ... (implementation detail)
        u_pgs = Q̃ @ np.sign(e_p)
        h_hat += μ * u_pgs / (np.sqrt(u_pgs.T @ u_pgs) + ε)
    
    elif algo == 'BSMIPAPSA':
        # Block-sparse proportionate
        h_blocks = h_hat.reshape(M, N)
        norm_blocks = np.linalg.norm(h_blocks, axis=1)
        sum_norm = np.sum(norm_blocks)
        b_hat = (1-β)/(2*Lh) + (1+β) * norm_blocks / (2*M*sum_norm + ε)
        # Expand to full length
        B_full = np.repeat(b_hat, N)
        # Build Q̂ matrix with memory (similar to MIPAPSA)
        u_pgs = Q̂ @ np.sign(e_p)
        h_hat += μ * u_pgs / (np.sqrt(u_pgs.T @ u_pgs) + ε)
```

---

## 8. Độ phức tạp tính toán (số phép nhân trên mỗi mẫu đầu ra)

| Thuật toán | Công thức | Giá trị số (Lh=64, P=2, M=8) |
|------------|----------|------------------------------|
| PEM-NLMS | Γ + 3Lh + 2 | 261 |
| PEM-IPNLMS | Γ + 8Lh + 2 | 581 |
| PEM-APA | Γ + (P²+2P)Lh + 2P⁰ | 583 |
| PEM-IPAPA | Γ + (P²+3P+4)Lh + 2P⁰ | 967 |
| PEM-IPAPSA | Γ + (2P+6)Lh + P | 709 |
| PEM-MIPAPSA | Γ + (3P+7)Lh + P | 901 |
| PEM-BSMIPAPSA | Γ + (3P+2)Lh + P + 4M + 12M + 1 | 614 |

Trong đó:
```
Γ = (5Lₐ² + 2LₐL + Lₐ)/(2L) + 2Lₐ
với Lₐ = 20, L = 160 (frame length) → Γ ≈ 40 + (5*400 + 2*20*160 + 20)/320 = 40 + (2000 + 6400 + 20)/320 = 40 + 8420/320 ≈ 40 + 26.31 = 66.31
```
Như vậy Γ ≈ 66.

---

## 9. Các chỉ số đánh giá

- **Normalized Misalignment (MIS)**  
  ```
  MIS = 10 log₁₀ { ∫|H(eʲᵒ) - e⁻ʲᵒᶠᵇ Ĥ(eʲᵒ)|² dω / ∫|H(eʲᵒ)|² dω }
  ```
- **Added Stable Gain (ASG)**  
  ```
  ASG = 10 log₁₀ { 1 / min|H(eʲᵒ) - e⁻ʲᵒᶠᵇ Ĥ(eʲᵒ)|² } - 10 log₁₀ { min|1/H(eʲᵒ)|² }
  ```
- **PESQ** (Perceptual Evaluation of Speech Quality): thang điểm 0.5–4.5

---

