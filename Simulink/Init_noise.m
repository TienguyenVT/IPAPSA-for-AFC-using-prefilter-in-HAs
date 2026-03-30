%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Init_noise.m
% Script tính hệ số scale nhiễu cho Simulink (Hệ thống B)
% Chạy script này TRƯỚC KHI chạy Simulink model.
%
% Script này tính alpha_bab và alpha_imp giống hệt hàm add_noise.m
% của Hệ thống A: alpha = sqrt(Es / (SNR_linear * En))
%
% CÁC BIẾN ĐƯỢC TẠO TRONG WORKSPACE:
%   alpha_bab   : Hệ số scale cho nhiễu babble (dùng cho Constant block)
%   alpha_imp   : Hệ số scale cho nhiễu xung   (dùng cho Constant block)
%
% Trong Simulink:
%   - Tạo 2 Constant block với giá trị alpha_bab và alpha_imp
%   - Nối vào khối Change_Noise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ============ THAM SỐ ============
% Khởi tạo các biến nếu chưa có trong workspace
if ~exist('fs', 'var'), fs = 16000; end
if ~exist('N', 'var'), N = 60 * fs; end
if ~exist('SNR', 'var'), SNR = 30; end
if ~exist('SIR', 'var'), SIR = 10; end

fprintf('\n[Init_noise] Bắt đầu tính alpha...\n');

%% ============ 1. NĂNG LƯỢNG TÍN HIỆU SẠCH ============
Es = sum(u(:).^2);
fprintf('[Init_noise] Es (năng lượng speech) = %.4f\n', Es);

%% ============ 2. ALPHA CHO NHIỄU XUNG (IMPULSIVE) ============
% Giống hệt: [u_imp, scaled_imp] = add_noise(u, n_imp, SIR);
En_imp = sum(n_imp(:).^2);
SIR_linear = 10^(SIR/10);
alpha_imp = sqrt(Es / (SIR_linear * En_imp));
fprintf('[Init_noise] alpha_imp = %.6f (SIR = %d dB)\n', alpha_imp, SIR);

%% ============ 3. ALPHA CHO NHIỄU BABBLE ============
% Giống hệt: [u_bab] = add_noise(u, n_bab, SNR);
% Load babble.wav, resample về fs, rồi tính năng lượng
babble_path = fullfile('C:\Documents\NCKH\IPAPSA for AFC using prefilter in HAs\Simulink', 'NOISEX-92', 'babble.wav');
[n_babble_raw, fs_babble] = audioread(babble_path);
fprintf('[Init_noise] babble.wav: %d mẫu, fs = %d Hz\n', length(n_babble_raw), fs_babble);

% Resample về fs (giống hệ thống A dòng 194-195)
[pn, qn] = rat(fs / fs_babble);
n_bab_resampled = resample(n_babble_raw, pn, qn);
fprintf('[Init_noise] Sau resample: %d mẫu (fs = %d Hz)\n', length(n_bab_resampled), fs);

% Cắt hoặc pad cho đủ N mẫu (giống hệ thống A dòng 196)
if length(n_bab_resampled) >= N
    n_bab_resampled = n_bab_resampled(1:N);
else
    n_bab_resampled = [n_bab_resampled; zeros(N - length(n_bab_resampled), 1)];
end

En_bab = sum(n_bab_resampled(:).^2);
SNR_linear = 10^(SNR/10);
alpha_bab = sqrt(Es / (SNR_linear * En_bab));
fprintf('[Init_noise] alpha_bab = %.6f (SNR = %d dB)\n', alpha_bab, SNR);

%% ============ TÓM TẮT ============
fprintf('\n========================================\n');
fprintf('[Init_noise] HOÀN TẤT\n');
fprintf('========================================\n');
fprintf('  alpha_bab = %.6f  → Constant block cho babble\n', alpha_bab);
fprintf('  alpha_imp = %.6f  → Constant block cho impulsive\n', alpha_imp);
fprintf('========================================\n');
