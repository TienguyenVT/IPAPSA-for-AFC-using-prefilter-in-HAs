# Báo cáo Triển khai Thuật toán PEM-AFC

**Dự án:** Cập nhật khối Adaptive Filter trong mô hình Simulink AFC
**Tài liệu tham khảo:** Tran et al., DSP Journal 2025 - Improved proportionate affine projection sign algorithms for AFC using pre-filters in HAs.

---

## 1. Dòng thời gian và các bước đã thực hiện

Quá trình triển khai được chia thành 3 giai đoạn chính:

### Giai đoạn 1: Phân tích hệ thống và tài liệu (Planning)
- **Đọc code hiện tại ([adpative_filter.txt](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/adpative_filter.txt))**: Xác định hệ thống đang dùng `FILTER_ORDER = 22`, `AR_ORDER = 20`, hỗ trợ 5 thuật toán cơ bản (IPNLMS, NLMS, APA, IPAPA, HNLMS).
- **Phân tích yêu cầu thuật toán**: Đọc các file [DS.md](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/DS.md), [G.md](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/G.md), [GMN.md](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/GMN.md) để trích xuất các công thức toán học lõi của PEM-IPAPSA, PEM-MIPAPSA, PEM-BSMIPAPSA.
- **Lập kế hoạch triển khai**: Thiết kế cách nhúng 3 thuật toán mới vào cấu trúc `switch-case` (`sel`) hiện có mà không làm hỏng các tính năng cũ.

### Giai đoạn 2: Triển khai mã nguồn (Execution)
- **Cập nhật hàm khởi tạo**: Thêm buffer bộ nhớ `AF.Q_tilde_prev` để phục vụ riêng cho họ thuật toán có yếu tố "Memory" (MIPAPSA, BSMIPAPSA).
- **Tái sử dụng code**: Tận dụng tối đa các biến đã được tiền xử lý (pre-filtered) như `Lswh_ap_active` (ma trận đầu vào U_p) và `ewh_p` (vector lỗi e_p).
- **Viết mã cho 3 thuật toán**:
  - `sel = 8` (PEM-IPAPSA): Lập trình tính toán ma trận tỷ lệ (proportionate) $B(n)$ dựa trên $L_1$-norm của trọng số bộ lọc. Áp dụng hàm dấu (sign) lên vector lỗi.
  - `sel = 9` (PEM-MIPAPSA): Bổ sung ma trận nhớ $Q(n)$ lưu trữ các cột dữ liệu đầu vào đã được tỷ lệ hóa từ các mẫu thời gian trước đó.
  - `sel = 10` (PEM-BSMIPAPSA): Phân tách chiều dài bộ lọc thành các block ($M=2$, $N=11$) để tính toán ma trận tỷ lệ theo block (dựa trên $L_2$-norm) nhằm tối ưu hiệu năng.

### Giai đoạn 3: Rà soát và kiểm chứng (Verification)
- **Kiểm tra cú pháp**: Đảm bảo code viết tương thích với môi trường MATLAB/Simulink Coder.
- **Đối chiếu công thức**: Kiểm tra chéo từng dòng code với công thức tương ứng trong bài báo khoa học.
- **Tài liệu hóa**: Ghi chú rõ ràng cách thiết lập tham số để người dùng dễ dàng cấu hình qua file [variable_simulink.mat](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/variable_simulink.mat).

---

## 2. Chi tiết kỹ thuật: Triển khai như thế nào?

Toàn bộ sửa đổi được thực hiện trong file [adpative_filter.txt](file:///c:/Documents/NCKH/IPAPSA%20for%20AFC%20using%20prefilter%20in%20HAs/adpative_filter.txt). Dưới đây là cách ánh xạ từ toán học sang mã MATLAB:

### 2.1. Cơ chế tính Tỷ lệ (Proportionate Gain)
Bài báo yêu cầu hệ số $b_k(n)$ phụ thuộc vào độ lớn của tap bộ lọc tương ứng để hội tụ nhanh với các đường phản hồi sparse (thưa):
```matlab
% Công thức toán: b_k(n) = (1-β)/(2L) + (1+β)*|h_k(n)| / (||h||_1 + ξ)
b = (1 - aa) / (2 * FILTER_ORDER) + ...
    (1 + aa) * abs(AF.gTD) / (sum(abs(AF.gTD)) + xi);
```

### 2.2. Cơ chế Dấu (Sign Algorithm)
Thay vì dùng nghịch đảo ma trận phức tạp như APA truyền thống, các thuật toán mới chỉ lấy dấu của sai số dự đoán:
```matlab
% Công thức toán: u_{p,gs} = B * U_p * sgn(e_p)
u_pgs = B * Lswh_ap_active * sign(ewh_p);
```

### 2.3. Cơ chế Bộ nhớ (Memory) - Cho MIPAPSA
Sử dụng buffer `AF.Q_tilde_prev` để đẩy lùi (shift) các cột:
```matlab
% Cột đầu tiên là dữ liệu hiện tại, các cột sau lấy từ lịch sử
Q_tilde(:, 1) = b .* Lswh_ap_active(:, 1);
Q_tilde(:, 2:end) = AF.Q_tilde_prev(:, 1:end-1);
```

### 2.4. Cơ chế Khối thưa (Block-Sparse) - Cho BSMIPAPSA
Do `FILTER_ORDER = 22` của hệ thống hiện tại không chia hết cho $M=8$ như bài báo, thuật toán tự động điều chỉnh thành $M=2$ block (mỗi block $N=11$ tap) để đảm bảo không lỗi:
```matlab
M_bs = 2;  N_bs = 11;
% Tính norm cho từng block
for blk = 1:M_bs
    % Tính L2-norm của 11 phần tử trong block
    block_norms(blk) = norm(AF.gTD(idx_start:idx_end), 2);
end
```

---

## 3. Tại sao lại thực hiện theo cách này?

Việc thiết kế và triển khai được dẫn dắt bởi 4 nguyên tắc lõi:

1. **Tuân thủ Cấu trúc Sinh Code (C-Code Generation Compliance)**
   - Hệ thống được thiết kế để chạy Simulink Coder (`ert.tlc`), do đó không thể sử dụng các hàm động (dynamic allocation) của MATLAB.
   - *Quyết định:* Khởi tạo ma trận tĩnh `zeros(FILTER_ORDER, MAX_P - 1)` trong khối `isempty(AF)`. Tránh thay đổi kích thước mảng trong vòng lặp thời gian thực để đảm bảo code C sinh ra chạy mượt mà.

2. **Khả năng Tương thích ngược (Backward Compatibility)**
   - Hàm `Adaptive_Filter` hiện đang có `sel` từ 1 đến 7. Việc thêm tính năng không được làm vỡ các block cũ.
   - *Quyết định:* Gán 3 thuật toán mới vào `sel = 8, 9, 10`. Tái sử dụng tham số `miu`, `a`, `p`, `delta` đã có sẵn trong Simulink block matrix, không đòi hỏi sửa đổi giao diện Simulink.

3. **Chống lỗi do bất đồng bộ tham số (Mismatched Parameters)**
   - Bài báo giả định bộ lọc dài $L = 64$ và block $M=8$. Nhưng hệ thống hiện tại có $L = 22$.
   - *Quyết định:* Viết mã tính linh động số `N_bs = FILTER_ORDER / M_bs`, với fallback mặc định `M=2` (vì 22 chia hết cho 2). Nếu người dùng sau này đổi `FILTER_ORDER` thành số khác, mã rẽ nhánh bảo vệ (fallback thành $M=1$) sẽ kích hoạt để không crash hệ thống.

4. **Tối ưu Hóa Toán Học (Mathematical Nuances)**
   - Tại mẫu số của phương trình cập nhật trọng số, bài báo yêu cầu một hằng số $\epsilon$ siêu nhỏ để tránh chia cho 0.
   - *Quyết định:* Lập trình $\epsilon$ độc lập theo công thức bài báo `eps_val = (1 - aa) / (2 * FILTER_ORDER) * AF.delta`, thay vì dùng thẳng `delta`, để tôn trọng chính xác "hệ số điều chuẩn nhỏ" mà nhóm tác giả đã đề xuất để tối ưu ASG (Added Stable Gain).

---
*Báo cáo được lập tự động dựa trên quá trình sửa đổi mã nguồn. Tháng 03/2026.*
