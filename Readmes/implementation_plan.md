# Thêm thuật toán PEM-IPAPSA, PEM-MIPAPSA, PEM-BSMIPAPSA vào Adaptive Filter

## Mô tả

Bổ sung 3 thuật toán mới từ bài báo **Tran & Albu (DSP Journal, 2025)** vào hệ thống AFC hiện tại. Các thuật toán này sử dụng **sign function** thay vì inverse matrix, giúp giảm chi phí tính toán đồng thời chống nhiễu xung (impulsive noise) tốt hơn.

### Hệ thống hiện tại
- File: [adpative_filter.txt](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/adpative_filter.txt) — MATLAB function với 6 thuật toán (sel = 1,4,5,6,7)
- FILTER_ORDER = 22, AR_ORDER = 20, MAX_P = 10, FRAMELENGTH = 160
- Đã có cơ chế PEM (pre-filter, AR model, Levinson-Durbin)
- Đã có ma trận `Lswh_ap` (input matrix cho affine projection)

### Các thuật toán mới
| sel | Thuật toán | Mô tả |
|-----|-----------|-------|
| 8 | PEM-IPAPSA | Improved Proportionate APA Sign Algorithm |
| 9 | PEM-MIPAPSA | Memory IPAPSA (lưu lịch sử proportionate) |
| 10 | PEM-BSMIPAPSA | Block-Sparse Memory IPAPSA |

---

## Proposed Changes

### Adaptive Filter Block

#### [MODIFY] [adpative_filter.txt](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/adpative_filter.txt)

**1. Thêm persistent variables** (sau dòng 21, trong phần khai báo persistent):
- `Q_tilde_prev`: Ma trận lưu trữ lịch sử (FILTER_ORDER × (MAX_P-1)) cho MIPAPSA/BSMIPAPSA
  - Lưu các cột `b(n-1)⊙u_p(n-1), ..., b(n-P+1)⊙u_p(n-P+1)` từ step trước

**2. Khởi tạo biến mới** (trong block `if isempty(AF)`, sau dòng ~41):
- `AF.Q_tilde_prev = zeros(FILTER_ORDER, MAX_P-1)` — memory buffer cho MIPAPSA/BSMIPAPSA

**3. Thêm 3 case mới** trong `%% --- THUẬT TOÁN THÍCH NGHI ---` (sau dòng 191):

#### sel == 8: PEM-IPAPSA
Công thức từ eq.(18) của bài báo:
```matlab
% 1. Tính proportionate vector b_k(n)
b = (1-a)/(2*FILTER_ORDER) + (1+a)*abs(AF.gTD) / (sum(abs(AF.gTD)) + delta);
B = diag(b);
% 2. Tính u_{p,gs}(n) = B(n) * U_p(n) * sgn(e_p(n))
u_pgs = B * Lswh_ap_active * sign(ewh_p);
% 3. Tính epsilon
eps_val = (1-a)/(2*FILTER_ORDER) * delta;
% 4. Cập nhật
AF.gTD = AF.gTD + miu * u_pgs / sqrt(u_pgs' * u_pgs + eps_val);
```

#### sel == 9: PEM-MIPAPSA
Công thức từ eq.(19)-(21):
```matlab
% 1. Tính b(n) (cùng công thức IPAPSA)
% 2. Xây Q_tilde(n) = [b(n)⊙u_p(n), Q_tilde_prev(n-1)]
%    Trong đó cột đầu tiên là b⊙u_p hiện tại, các cột còn lại từ step trước
% 3. u_tilde_pgs = Q_tilde * sgn(e_p)
% 4. Cập nhật gTD
% 5. Lưu Q_tilde_prev cho step tiếp theo
```

#### sel == 10: PEM-BSMIPAPSA
Công thức từ eq.(23)-(25):
```matlab
% 1. Chia gTD thành M blocks, mỗi block N phần tử
% 2. Tính b_hat_k theo l2-norm của mỗi block
% 3. Expand b_hat thành vector dài FILTER_ORDER (mỗi block = constant)
% 4. Xây Q_hat giống MIPAPSA nhưng dùng block-sparse b
% 5. Cập nhật tương tự MIPAPSA
```

> [!IMPORTANT]
> **Ánh xạ biến giữa bài báo và code hiện tại:**
> - `ĥ(n)` → `AF.gTD` (bộ lọc ước lượng)
> - `Lĥ` → `FILTER_ORDER` (= 22 trong hệ thống hiện tại, paper dùng 64)
> - `U_p(n)` → `Lswh_ap_active` (ma trận input đã pre-filter)
> - `e_p(n)` → `ewh_p` (vector error đã pre-filter)
> - `u_p(n)` → `AF.TDLLswh` (cột hiện tại) hoặc cột đầu trong `Lswh_ap_active`
> - `β` → `a` (input parameter, default = 0)
> - `ξ` → dùng `delta` (= 10⁻⁶)
> - `μ` → `miu` (input parameter)
> - `P` → `p` (projection order)
> - `M` (số blocks) → **tham số mới**, mặc định = 8 nếu phù hợp, hoặc tùy FILTER_ORDER

> [!WARNING]
> **Về FILTER_ORDER:** Hệ thống hiện tại dùng `FILTER_ORDER = 22`. Bài báo dùng `Lĥ = 64`. Thuật toán BSMIPAPSA cần chia bộ lọc thành `M` blocks đều nhau (`N = FILTER_ORDER/M`). Với `FILTER_ORDER = 22`, ta cần chọn `M` sao cho `22/M` là số nguyên. Các giá trị hợp lệ: `M = 1, 2, 11, 22`. Tôi sẽ dùng `M = 2` (N=11) làm mặc định an toàn, nhưng **hệ thống sẽ tự động tính** `N = floor(FILTER_ORDER/M)` và xử lý phần dư.

---

## Tham số mới cần thêm vào [variable_simulink.mat](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/variable_simulink.mat)

| Tên biến | Giá trị mặc định | Mô tả |
|----------|------------------|-------|
| `sel` | 8, 9, hoặc 10 | Chọn thuật toán mới |
| `miu` | 8×10⁻⁶ | Step-size cho IPAPSA family (paper default) |
| `p` | 2 | Projection order (đã có) |
| `a` | 0 | β parameter, proportionate factor (đã có) |
| `delta` | 10⁻⁶ | Regularization (đã có) |

> [!NOTE]
> Không cần thêm biến mới vào [variable_simulink.mat](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/variable_simulink.mat) ngoài việc thay đổi giá trị `sel` (= 8, 9, 10) và `miu` (= 8e-6) khi chạy các thuật toán mới. Tham số `M` (số blocks cho BSMIPAPSA) sẽ được tính tự động trong code dựa trên FILTER_ORDER.

---

## Verification Plan

### Manual Verification
1. **Kiểm tra cú pháp MATLAB**: Mở file [adpative_filter.txt](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/adpative_filter.txt) trong MATLAB, chạy thử với `sel = 8, 9, 10` để xác nhận không có lỗi cú pháp
2. **Kiểm tra công thức**: So sánh từng dòng code với các phương trình trong bài báo (eq. 15-25)
3. **Chạy mô phỏng Simulink**: Đặt `sel = 8` (IPAPSA), `miu = 8e-6`, chạy mô hình và kiểm tra MIS/ASG hội tụ
4. **So sánh kết quả**: Chạy lần lượt sel = 8, 9, 10 và so sánh MIS/ASG với các thuật toán hiện có (sel = 1,4,5,6)

> [!NOTE]
> Vì đây là code MATLAB/Simulink chạy trên máy cục bộ và cần Simulink license, verification chủ yếu là manual. Tôi sẽ đảm bảo code đúng cú pháp MATLAB và khớp với công thức từ bài báo.
