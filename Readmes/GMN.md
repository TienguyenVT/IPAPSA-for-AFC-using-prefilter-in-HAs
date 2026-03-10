# 🎯 Prompt Triển khai Hệ thống Adaptive Feedback Cancellation (PEM-AFC)

**Ngữ cảnh & Vai trò:** Bạn là một Kỹ sư thuật toán Xử lý Tín hiệu Số (DSP Engineer) chuyên nghiệp. Nhiệm vụ của bạn là lập trình và tích hợp các thuật toán khử phản hồi âm thanh (AFC) dựa trên phương pháp Prediction Error Method (PEM) vào hệ thống máy trợ thính.

**Nhiệm vụ cốt lõi:** Viết mã nguồn (Python/C++) triển khai 3 thuật toán đề xuất: **PEM-IPAPSA**, **PEM-MIPAPSA**, và **PEM-BSMIPAPSA**, đồng thời thiết lập các thuật toán cơ sở (baseline) để so sánh hiệu năng dựa trên các cấu hình chuẩn xác dưới đây.

---


## 1. Cấu trúc Hệ thống Tổng quan (System Architecture)
[cite_start]Hệ thống được vận hành trong mô hình mạch kín (closed-loop) của máy trợ thính[cite: 30, 110]. 
* [cite_start]**Đường truyền xuôi (Forward path):** Độ trễ $d_k = 96$ mẫu (samples)[cite: 267]. Hệ số khuếch đại $|K| [cite_start]= 30$ dB[cite: 267, 268].
* [cite_start]**Đường khử phản hồi (Feedback canceller's path):** Độ trễ $d_{fb} = 1$ mẫu[cite: 268].
* [cite_start]**Bộ tiền lọc (Pre-filter) $\hat{A}(q)$:** Bộ lọc AR bậc 20 ($L_a = 20$)[cite: 115, 277]. [cite_start]Bộ lọc này được cập nhật mỗi 10 mili-giây (ms) bằng thuật toán Levinson-Durbin[cite: 277].

## 2. Cấu hình Siêu tham số (Hyperparameters & Setup)
Sử dụng chính xác các hằng số sau để khởi tạo thuật toán:
* [cite_start]Chiều dài bộ lọc phản hồi thực tế (để mô phỏng môi trường): $L_h = 100$[cite: 257].
* [cite_start]Chiều dài bộ lọc thích nghi ước lượng: $L_{\hat{h}} = 64$[cite: 274].
* [cite_start]Bậc chiếu (Projection order) cho các họ thuật toán APSA: $P = 2$[cite: 274].
* [cite_start]Tham số kiểm soát ma trận tỷ lệ: $\beta = 0$, $\delta = 10^{-6}$, $\xi = 10^{-6}$[cite: 268].
* [cite_start]Hằng số tránh chia cho 0: $\epsilon = \frac{1-\beta}{2L_{\hat{h}}}\delta$[cite: 268].
* [cite_start]Cấu hình chia khối (riêng cho BSMIPAPSA): Số khối $M = 8$, Chiều dài mỗi khối $N = L_{\hat{h}}/M = 8$[cite: 273, 394].

**Tốc độ học (Step-sizes $\mu$) cho các thuật toán:**
* [cite_start]**Nhóm đề xuất (PEM-IPAPSA, PEM-MIPAPSA, PEM-BSMIPAPSA):** $\mu = 8 \times 10^{-6}$[cite: 275].
* [cite_start]**Nhóm baseline 1 (PEM-APA, PEM-IPAPA):** $\mu = 8 \times 10^{-4}$[cite: 275].
* [cite_start]**Nhóm baseline 2 (PEM-NLMS, PEM-IPNLMS):** $\mu = 10^{-3}$[cite: 276].

---

## 3. Chi tiết Công thức Cập nhật Trọng số (Weight Updates)

[cite_start]Trong vòng lặp thời gian thực, với tín hiệu micro đã tiền lọc $m_p(n)$ và tín hiệu loa đã tiền lọc $u_p(n)$, sai số dự đoán được tính là $e_p(n) = m_p(n) - \mathbf{U}_p^T(n)\hat{\mathbf{h}}(n)$[cite: 146, 147, 188].

Vui lòng lập trình 3 thuật toán sau dựa trên công thức toán học lõi:

### A. Thuật toán PEM-IPAPSA (Improved Proportionate Affine Projection Sign Algorithm)
* Ma trận đường chéo kiểm soát $\mathbf{B}(n)$ có các phần tử: 
    $$b_k(n) = \frac{1-\beta}{2L_{\hat{h}}} + (1+\beta)\frac{|\hat{h}_k(n)|}{2\|\hat{h}_k(n)\|_1 + \xi}$$ [cite: 195, 196]
* Vector điều hướng: 
    $$u_{p,gs}(n) = B(n)U_p(n)\text{sgn}[e_p(n)]$$ [cite: 200]
* Cập nhật trọng số: 
    $$\hat{h}(n+1) = \hat{h}(n) + \frac{\mu u_{p,gs}(n)}{\sqrt{u_{p,gs}^T(n) u_{p,gs}(n) + \epsilon}}$$ [cite: 206]

### B. Thuật toán PEM-MIPAPSA (Memory IPAPSA)
* Lưu trữ lịch sử tỷ lệ qua các bậc chiếu $P$: 
    $$Q(n) = [b(n) \odot u_p(n), \dots, b(n) \odot u_p(n-P+1)]$$ [cite: 216]
* Sử dụng xấp xỉ ma trận với bộ nhớ: 
    $$\tilde{Q}(n) = [b(n) \odot u_p(n), \tilde{Q}_{-1}(n-1)]$$ [cite: 219]
* Vector điều hướng: 
    $$\tilde{u}_{p,gs}(n) = \tilde{Q}(n)\text{sgn}[e_p(n)]$$ [cite: 221]
* Cập nhật trọng số: 
    $$\hat{h}(n+1) = \hat{h}(n) + \frac{\mu \tilde{u}_{p,gs}(n)}{\sqrt{\tilde{u}_{p,gs}^T(n) \tilde{u}_{p,gs}(n) + \epsilon}}$$ [cite: 223]

### C. Thuật toán PEM-BSMIPAPSA (Block-Sparse Memory IPAPSA)
* Chia bộ lọc thành $M$ khối: 
    $$\hat{h}(n) = [\hat{h}_0(n), \hat{h}_1(n), \dots, \hat{h}_{M-1}(n)]$$ [cite: 231]
* Hệ số tỷ lệ theo khối: 
    $$\tilde{b}_k(n) = \frac{1-\beta}{2L_{\hat{h}}} + (1+\beta)\frac{\|\hat{h}_k(n)\|_2}{2M\sum_{j=0}^{M-1}\|\hat{h}_j(n)\|_2 + \xi}$$ [cite: 237]
* Tạo vector kiểm soát khối $\tilde{B}(n)$ chứa các $\tilde{b}_k(n)$ nhân với vector toàn số 1 độ dài $N$:
    $$\tilde{B}(n) = [\tilde{b}_0(n)\mathbf{1}_N, \tilde{b}_1(n)\mathbf{1}_N, \dots, \tilde{b}_{M-1}(n)\mathbf{1}_N]^T$$ [cite: 236]
* Ma trận bộ nhớ:
    $$\tilde{Q}(n) = [\tilde{B}(n) \odot u_p(n), \tilde{Q}_{-1}(n-1)]$$ [cite: 245]
* Vector điều hướng: 
    $$\tilde{u}_{p,gs}(n) = \tilde{Q}(n)\text{sgn}[e_p(n)]$$ [cite: 245]
* Cập nhật trọng số: 
    $$\hat{h}(n+1) = \hat{h}(n) + \frac{\mu \tilde{u}_{p,gs}(n)}{\sqrt{\tilde{u}_{p,gs}^T(n) \tilde{u}_{p,gs}(n) + \epsilon}}$$ [cite: 243]