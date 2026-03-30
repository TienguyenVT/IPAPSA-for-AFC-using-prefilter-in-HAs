%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug_NaN.m
% Script chẩn đoán NaN - Chạy SAU KHI chạy Simulink xong
% Script này kiểm tra từng tầng dữ liệu để tìm NaN xuất hiện ở đâu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('  CHẨN ĐOÁN NaN - Hệ thống B\n');
fprintf('============================================\n\n');

%% ============ 1. KIỂM TRA ALPHA VALUES ============
fprintf('--- 1. KIỂM TRA ALPHA ---\n');
if exist('alpha_bab','var')
    fprintf('  alpha_bab = %.6f  (isfinite: %d)\n', alpha_bab, isfinite(alpha_bab));
else
    fprintf('  [LỖI] alpha_bab KHÔNG CÓ trong workspace!\n');
end
if exist('alpha_imp','var')
    fprintf('  alpha_imp = %.6f  (isfinite: %d)\n', alpha_imp, isfinite(alpha_imp));
else
    fprintf('  [LỖI] alpha_imp KHÔNG CÓ trong workspace!\n');
end

%% ============ 2. KIỂM TRA N_IMP ============
fprintf('\n--- 2. KIỂM TRA n_imp ---\n');
if exist('n_imp','var')
    fprintf('  Size: [%d x %d]\n', size(n_imp,1), size(n_imp,2));
    fprintf('  Có NaN: %d\n', any(isnan(n_imp)));
    fprintf('  Có Inf: %d\n', any(isinf(n_imp)));
    fprintf('  Min = %.6f, Max = %.6f\n', min(n_imp), max(n_imp));
    fprintf('  Scaled max = %.6f (alpha_imp * max)\n', alpha_imp * max(abs(n_imp)));
else
    fprintf('  [LỖI] n_imp KHÔNG CÓ trong workspace!\n');
end

%% ============ 3. MÔ PHỎNG OFFLINE - GIỐNG HỆ THỐNG A ============
fprintf('\n--- 3. MÔ PHỎNG OFFLINE (giống Hệ thống A) ---\n');
if exist('u','var') && exist('n_imp','var')
    % Tính scaled_imp giống hệ thống A
    [~, scaled_imp_test] = add_noise(u, n_imp, SIR);
    fprintf('  scaled_imp: NaN=%d, Inf=%d, max=%.6f\n', ...
        any(isnan(scaled_imp_test)), any(isinf(scaled_imp_test)), max(abs(scaled_imp_test)));
    
    % So sánh alpha từ Init_noise vs add_noise trực tiếp
    Es_test = sum(u(:).^2);
    En_test = sum(n_imp(:).^2);
    alpha_test = sqrt(Es_test / (10^(SIR/10) * En_test));
    fprintf('  alpha_imp từ Init_noise = %.6f\n', alpha_imp);
    fprintf('  alpha_imp từ add_noise  = %.6f\n', alpha_test);
    fprintf('  Khớp nhau: %d\n', abs(alpha_imp - alpha_test) < 1e-10);
end

%% ============ 4. KIỂM TRA TÍN HIỆU SAU SIMULINK ============
fprintf('\n--- 4. KIỂM TRA TÍN HIỆU SAU SIMULINK ---\n');

% Kiểm tra các biến output từ Simulink (nếu có To Workspace blocks)
vars_to_check = {'y', 'e_delay', 'MIS', 'ASG', 'MIS_avg', 'ASG_avg', ...
                 'W_hat', 'W_true', 'MIS_instant'};
for i = 1:length(vars_to_check)
    vname = vars_to_check{i};
    if evalin('base', sprintf('exist(''%s'',''var'')', vname))
        val = evalin('base', vname);
        if isnumeric(val)
            first_nan = find(isnan(val(:)), 1);
            if isempty(first_nan)
                fprintf('  %15s: OK (no NaN), size=[%s]\n', vname, num2str(size(val)));
            else
                % Tìm NaN đầu tiên xuất hiện ở sample nào
                if isvector(val)
                    fprintf('  %15s: [NaN TẠI MẪU %d / %d] (%.4f giây)\n', ...
                        vname, first_nan, length(val), first_nan/16000);
                else
                    [row,col] = ind2sub(size(val), first_nan);
                    fprintf('  %15s: [NaN TẠI hàng=%d, cột=%d] size=[%s]\n', ...
                        vname, row, col, num2str(size(val)));
                end
            end
        end
    else
        fprintf('  %15s: không có trong workspace\n', vname);
    end
end

%% ============ 5. TÌM THỜI ĐIỂM NaN ĐẦU TIÊN ============
fprintf('\n--- 5. THỜI ĐIỂM NaN ĐẦU TIÊN ---\n');
earliest_nan = Inf;
earliest_var = 'N/A';

check_vars = {'y', 'e_delay', 'MIS_instant'};
for i = 1:length(check_vars)
    vname = check_vars{i};
    if evalin('base', sprintf('exist(''%s'',''var'')', vname))
        val = evalin('base', vname);
        if isnumeric(val) && isvector(val)
            first = find(isnan(val), 1);
            if ~isempty(first) && first < earliest_nan
                earliest_nan = first;
                earliest_var = vname;
            end
        end
    end
end

if earliest_nan < Inf
    fprintf('  NaN ĐẦU TIÊN xuất hiện ở biến "%s" tại mẫu %d (%.4f giây)\n', ...
        earliest_var, earliest_nan, earliest_nan/16000);
    fprintf('  → Đây là TẦNG ĐẦU TIÊN bị ảnh hưởng.\n');
else
    fprintf('  Không tìm thấy NaN trong y, e_delay, MIS_instant.\n');
    fprintf('  → NaN có thể nằm trong khối AFC_Performance_Monitor.\n');
end

fprintf('\n============================================\n');
fprintf('  KẾT THÚC CHẨN ĐOÁN\n');
fprintf('============================================\n');
