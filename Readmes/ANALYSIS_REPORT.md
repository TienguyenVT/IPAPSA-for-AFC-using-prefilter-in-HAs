# Báo cáo Phân tích Hệ thống AFC

## Mục lục

1. [Tổng quan Dự án](#1-tổng-quan-dự-án)
2. [Cấu trúc Thư mục](#2-cấu-trúc-thư-mục)
3. [Phân tích Mô hình Simulink](#3-phân-tích-mô-hình-simulink)
4. [Phân tích Code C Sinh ra](#4-phân-tích-code-c-sinh-ra)
5. [Các Thuật toán Adaptive Filter](#5-các-thuật-toán-adaptive-filter)
6. [Phân tích Biến và Dữ liệu](#6-phân-tích-biến-và-dữ-liệu)
7. [Công cụ Hỗ trợ](#7-công-cụ-hỗ-trợ)
8. [Kết luận và Đề xuất](#8-kết-luận-và-đề-xuất)

---

## 1. Tổng quan Dự án

### 1.1 Mục tiêu

Dự án **"An Interactive Learning and Research Platform for Real-Time AFC"** (Nền tảng Nghiên cứu và Học tập Tương tác cho AFC Thời gian thực) được xây dựng nhằm mục đích:

- Cung cấp môi trường mô phỏng tương tác thời gian thực trên MATLAB/Simulink
- Nghiên cứu và học tập về các thuật toán **Loại bỏ Phản hồi Âm thanh (Acoustic Feedback Cancellation - AFC)**
- Sử dụng **Phương pháp Dự đoán Lỗi (Prediction Error Method - PEM)** để nâng cao hiệu quả triệt tiêu tiếng hú
- Hỗ trợ các ứng dụng thực tế như máy trợ thính, hội thảo trực tuyến, hệ thống PA

### 1.2 Vấn đề cần giải quyết

**Phản hồi âm thanh (Acoustic Feedback)** là hiện tượng xảy ra khi:

```
Tín hiệu từ loa → Micro (qua đường không khí) → Khuếch đại lại → Tiếng hú/rít
```

Điều này gây:
- Khó chịu cho người nghe
- Giảm chất lượng hệ thống âm thanh
- Có thể gây hỏng loa nếu không kiểm soát

### 1.3 Giải pháp đề xuất

Sử dụng **bộ lọc thích nghi (Adaptive Filter)** để ước tính đường phản hồi (Feedback Path) và triệt tiêu thành phần phản hồi trước khi nó được khuếch đại.

---

## 2. Cấu trúc Thư mục

```
An Interactive Learning and Research Platform for Real-Time AFC/
├── R2021a_PEM_Canceller_v4_goc.slx      # Mô hình Simulink chính
├── variable_simulink.mat                 # Dữ liệu biến mô phỏng
├── README.md                             # Hướng dẫn sử dụng
│
├── R2021a_PEM_Canceller_v4_goc_ert_rtw/  # Code C sinh ra từ Simulink
│   ├── R2021a_PEM_Canceller_v4_goc.h
│   ├── R2021a_PEM_Canceller_v4_goc_types.h
│   ├── R2021a_PEM_Canceller_v4_goc_data.c
│   ├── R2021a_PEM_Canceller_v4_goc_private.h
│   ├── ert_main.c
│   ├── rtwtypes.h
│   ├── rtGetInf.h/c
│   ├── rtGetNaN.h/c
│   ├── rt_nonfinite.h/c
│   └── zero_crossing_types.h
│
├── slprj/                                # Thư mục tạm Simulink
│
├── mat_to_readable.py                    # Tool Python đọc file .mat
├── simple_mat_reader.py                  # Tool đơn giản hơn
├── export_mat_variables.m                # Script MATLAB xuất biến
├── README_mat_reader.md                  # Hướng dẫn sử dụng tool
├── variable_simulink_analysis.json       # Kết quả phân tích biến
└── apdative-filter-simulink-block.txt    # Mô tả block Simulink
```

---

## 3. Phân tích Mô hình Simulink

### 3.1 Các Khối Chức năng Chính

| Khối | Tên hệ thống | Mô tả |
|------|--------------|-------|
| **Signal Source** | `<S5>`, `<S6>` | Nguồn tín hiệu (Speech/Music) |
| **Room Impulse Response** | `<Root>` | Mô hình phòng, đường phản hồi |
| **Adaptive Filter** | `<S2>` | Bộ lọc thích nghi - cốt lõi AFC |
| **Update AR Model** | `<S3>` | Cập nhật mô hình AR (Levinson-Durbin) |
| **AFC Performance Monitor** | `<S1>` | Đánh giá hiệu năng hệ thống |
| **dB Gain** | `<S4>` | Điều chỉnh độ lợi tín hiệu |

### 3.2 Sơ đồ Luồng Tín hiệu

```
                    ┌─────────────────────────────────────┐
                    │         SIGNAL SOURCE              │
                    │   (Speech / Music / White Noise)    │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │         ROOM IMPULSE RESPONSE       │
                    │      (Feedback Path - RIR)          │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │       ADAPTIVE FILTER               │
                    │   ┌─────────────────────────┐       │
                    │   │ • IPNLMS (sel=1)       │       │
                    │   │ • NLMS (sel=4)         │       │
                    │   │ • APA (sel=5)          │       │
                    │   │ • IPAPA (sel=6)        │       │
                    │   │ • HNLMS (sel=7)        │       │
                    │   └─────────────────────────┘       │
                    └──────────────┬──────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
┌──────────▼──────────┐  ┌────────▼─────────┐  ┌─────────▼─────────┐
│  UPDATE AR MODEL    │  │ AFC PERFORMANCE  │  │  ERROR OUTPUT     │
│  (Levinson-Durbin)   │  │    MONITOR       │  │  (e = y - y_hat)  │
└─────────────────────┘  └──────────────────┘  └───────────────────┘
```

### 3.3 Các Tham số Hệ thống

```matlab
% Tham số Bộ lọc
L = 22                    % Độ dài bộ lọc thích nghi (filter length)
AR_order = 20             % Bậc mô hình AR (AR order)
frame_length = 160        % Độ dài frame (samples)
Fs = 16000                % Tần số lấy mẫu (Hz)

% Tham số Thuật toán
mu = 0.001               % Step size (learning rate)
delta = 1e-6             % Regularization parameter
```

---

## 4. Phân tích Code C Sinh ra

### 4.1 Cấu trúc Dữ liệu (Data Structures)

Từ file header `R2021a_PEM_Canceller_v4_goc.h`, hệ thống sử dụng các cấu trúc:

#### Block Signals (Output của các khối)

```c
typedef struct {
  real_T Sum2;                         // Tổng tại Sum2
  real_T LevinsonDurbin[21];           // Hệ số AR từ Levinson-Durbin
  real_T e;                            // Tín hiệu lỗi sau triệt tiêu
  real_T W[22];                        // Hệ số bộ lọc thích nghi
  real_T dg_hat;                      // Ước tính đường phản hồi
  real_T Sum;                         // Tổng tại Sum
} B_R2021a_PEM_Canceller_v4_goc_T;
```

#### Block States (Trạng thái nội bộ)

```c
typedef struct {
  sNrdkIdWgltdvrJr4R5yRFH_R2021_T AR;   // AR model state
  s03vbnB58wVaDS4iGNamMUF_R2021_T AF;   // Adaptive filter state
  real_T dk_DSTATE[32];                 // Delay line for dk
  real_T ErrorDelayLine_Buff[21];     // Error delay line buffer
  real_T dg_hat_DSTATE[16];            // Feedback path estimate state
  real_T A_FILT_STATES[21];            // A filter states
  real_T dg_DSTATE[16];                // dg states
  real_T FeedbackPath_FILT_STATES[22]; // Feedback path filter states
  real_T A1_FILT_STATES[21];           // A1 filter states
  real_T FeedbackCanceller_FILT_STATES[22]; // Feedback canceller states
  real_T sample_counter;               // Đếm mẫu
  real_T current_feedback_path;        // Đường phản hồi hiện tại
  real_T sumMIS;                       // Tổng Misalignment
  real_T sumASG;                       // Tổng ASG
  real_T nSamples;                     // Số mẫu đã xử lý
  // ... các trạng thái khác
} DW_R2021a_PEM_Canceller_v4_go_T;
```

### 4.2 Các Hàm Chính

| Hàm | Mô tả |
|-----|-------|
| `R2021a_PEM_Canceller_v4_goc_initialize()` | Khởi tạo hệ thống |
| `R2021a_PEM_Canceller_v4_goc_step()` | Thực hiện một bước mô phỏng |
| `R2021a_PEM_Canceller_v4_goc_terminate()` | Kết thúc và dọn dẹp |

### 4.3 Các Hằng số Quan trọng

```c
// Hệ số bộ lọc g4 (Feedback Path coefficients)
Constant9_Value[22] = {
  -0.0052, -0.0123, -0.0005, 0.0087, -0.0021, -0.0058,
  3.30e-5, 0.0052, 0.0015, -0.0035, -0.0015, 0.0010,
  0.0018, -0.0010, -0.0005, 0.0002, 0.0006, -0.0004,
  -0.0003, 5.58e-5, 0.0003, 0.0
};

// Pooled Parameter (được sử dụng bởi Feedback Path)
pooled3[22] = {
  -0.0063, -0.0104, 0.0002, 0.0069, -0.0037, -0.0039,
  0.0018, 0.0044, -0.0001, -0.0035, -0.0003, 0.0012,
  0.0012, -0.0012, -0.0001, 0.0003, 0.0004, -0.0005,
  -0.0001, 9.02e-5, 0.0002, 0.0
};
```

---

## 5. Các Thuật toán Adaptive Filter

### 5.1 Tổng quan Thuật toán

Hệ thống hỗ trợ nhiều thuật toán bộ lọc thích nghi, được chọn qua tham số `sel`:

| `sel` | Thuật toán | Viết tắt | Đặc điểm |
|-------|------------|----------|----------|
| 1 | **IPNLMS** | Improved Proportionate NLMS | Phân bổ step size theo năng lượng filter |
| 4 | **NLMS** | Normalized LMS | Đơn giản, ổn định |
| 5 | **APA** | Affine Projection Algorithm | Sử dụng nhiều frame dữ liệu |
| 6 | **IPAPA** | Improved Proportionate APA | Kết hợp IPNLMS và APA |
| 7 | **HNLMS** | Hybrid NLMS | Kết hợp các ưu điểm |

### 5.2 Chi tiết từng Thuật toán

#### NLMS (Normalized Least Mean Squares)

```matlab
% Công thức:
e(n) = d(n) - w(n)' * x(n)
w(n+1) = w(n) + mu * x(n) * e(n) / (x(n)' * x(n) + delta)

% Ưu điểm: Đơn giản, ổn định
% Nhược điểm: Hội tụ chậm với tín hiệu correlated
```

#### IPNLMS (Improved Proportionate NLMS)

```matlab
% Công thức:
g(n) = diag(gamma1 * |w(n)| / (gamma2 + ||w(n)||1))
w(n+1) = w(n) + mu * g(n) * x(n) * e(n) / (x(n)' * x(n) + delta)

% Ưu điểm: Hội tụ nhanh cho sparse systems
% Phù hợp với acoustic feedback path (thường sparse)
```

#### APA (Affine Projection Algorithm)

```matlab
% Công thức:
X(n) = [x(n), x(n-1), ..., x(n-P+1)]  % P = projection order
e(n) = d(n) - X(n)' * w(n)
w(n+1) = w(n) + mu * X(n) * (X(n)' * X(n) + delta*I)^(-1) * e(n)

% Ưu điểm: Hội tụ nhanh hơn NLMS
% Nhược điểm: Tính toán phức tạp hơn
```

### 5.3 PEM (Prediction Error Method)

PEM được sử dụng để giải quyết vấn đề **Correlation Bias**:

```matlab
% Vấn đề: Tín hiệu speech/music có tự tương quan cao
% → Ước tính bộ lọc bị bias

% Giải pháp PEM:
1. Mô hình hóa tín hiệu đầu vào như process AR: x(n) = -a' * x(n-1) + v(n)
2. Sử dụng bộ lọc làm trắng (whitening filter) A(z)
3. Áp dụng adaptive filter trên tín hiệu đã làm trắng
4. Cập nhật hệ số AR định kỳ bằng Levinson-Durbin
```

---

## 6. Phân tích Biến và Dữ liệu

### 6.1 Các Biến Chính

| Biến | Kích thước | Mô tả |
|------|------------|-------|
| `gTD` / `g_hat` | 22×1 | Hệ số bộ lọc thích nghi ước tính |
| `W_true` | 22×1 | Đường phản hồi thực (ground truth) |
| `AR_coeffs` | 20×1 | Hệ số mô hình AR |
| `e` | N×1 | Tín hiệu lỗi sau triệt tiêu |
| `MIS` | scalar | Misalignment (độ lệch) |
| `ASG/MSG` | scalar | Added Stable Gain |
| `u(n)` | N×1 | Tín hiệu đầu vào |
| `y(n)` | N×1 | Tín hiệu đầu ra |

### 6.2 Các Chỉ số Hiệu năng

#### Misalignment (MIS)

```matlab
MIS = 20 * log10(||W_true - g_hat||2 / ||W_true||2)

% Ý nghĩa:
% - MIS < -20 dB: Rất tốt
% - MIS = -20 đến -10 dB: Tốt
% - MIS = -10 đến 0 dB: Chấp nhận được
% - MIS > 0 dB: Kém
```

#### Added Stable Gain (ASG/MSG)

```matlab
% ASG (Added Stable Gain): Tăng ích ổn định có thể thêm vào
% MSG (Maximum Stable Gain): Ích ổn định cực đại

ASG = 10 * log10(Pmax_feedback / Pactual_feedback)

% Ý nghĩa: ASG càng lớn → hệ thống càng ổn định
```

### 6.3 File Dữ liệu

- **`variable_simulink.mat`**: Chứa tất cả các biến workspace từ Simulink
- **`variable_simulink_analysis.json`**: Kết quả phân tích các biến

---

## 7. Công cụ Hỗ trợ

### 7.1 Python Scripts

#### mat_to_readable.py

Tool chính để đọc và chuyển đổi file .mat:

```bash
# Cú pháp sử dụng
python mat_to_readable.py <input_file.mat> [output_format]

# Ví dụ
python mat_to_readable.py variable_simulink.mat json
python mat_to_readable.py variable_simulink.mat txt
python mat_to_readable.py variable_simulink.mat csv
```

**Tính năng:**
- Đọc file .mat sử dụng scipy
- Hỗ trợ manual parsing nếu không có scipy
- Xuất ra JSON, TXT, CSV
- Phân tích tự động các biến liên quan đến AFC

#### simple_mat_reader.py

Phiên bản đơn giản hơn, phù hợp cho người mới bắt đầu:

```bash
python simple_mat_reader.py variable_simulink.mat
```

### 7.2 MATLAB Scripts

#### export_mat_variables.m

Script MATLAB để xuất các biến từ workspace:

```matlab
% Sử dụng trong MATLAB
export_mat_variables
```

### 7.3 Yêu cầu

```
Python:
- numpy
- scipy (khuyến nghị)
- h5py (tùy chọn)

MATLAB:
- MATLAB R2021a trở lên
- Simulink
- Signal Processing Toolbox
```

---

## 8. Kết luận và Đề xuất

### 8.1 Đánh giá Hệ thống

**Điểm mạnh:**
- ✅ Giao diện trực quan trong Simulink
- ✅ Nhiều thuật toán adaptive filter
- ✅ Tích hợp PEM để xử lý speech/music
- ✅ Công cụ đánh giá hiệu năng đầy đủ
- ✅ Code C được sinh tự động cho ứng dụng thời gian thực

**Điểm cần cải thiện:**
- ⚠️ Chưa có giao diện GUI độc lập
- ⚠️ Thiếu thuật toán RLS, FxLMS
- ⚠️ Chưa hỗ trợ real-time hardware (DSP, microcontroller)

### 8.2 Hướng Phát triển

1. **Thêm thuật toán mới:**
   - RLS (Recursive Least Squares)
   - FxLMS (Filtered-x LMS) cho active noise control
   - Kalman Filter-based AFC

2. **Tối ưu hóa:**
   - Tăng tốc độ hội tụ
   - Giảm độ phức tạp tính toán
   - Xử lý double-talk detection

3. **Ứng dụng thực tế:**
   - Triển khai trên DSP/ARM Cortex-M
   - Tạo giao diện MATLAB App Designer
   - Tích hợp với phần cứng âm thanh

4. **Mở rộng:**
   - Multi-microphone AFC
   - Adaptive feedback cancellation with noise
   - Deep learning-based approaches

---

## Thông tin Phiên bản

- **Phiên bản Model:** 21.25
- **Simulink Coder:** 24.1 (R2024a)
- **Ngày sinh code:** 08/02/2026
- **Target:** ert.tlc (Embedded Real-Time)

---

*Document generated as part of AFC system analysis*
*Date: March 2026*
