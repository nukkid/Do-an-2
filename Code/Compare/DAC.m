clear; clc; close all;

%% ================== 1. CẤU HÌNH & LOAD DATA ==================
Fs = 200; N_TAPS = 29; delay = (N_TAPS-1)/2;

read_q15 = @(filename) double(typecast(uint16(hex2dec(textread(filename, '%s'))), 'int16')) / 32768;

y_matlab  = read_q15('Output_Reference.txt');
y_verilog = read_q15('Output_V.txt');

N_total   = length(y_verilog);
t_real    = (0:N_total-1)/Fs;

%% ================== 2. CHUẨN HÓA BIÊN ĐỘ ĐẦU VÀO ==================
ecg_clean_raw = 0.7 * sin(2*pi*1*t_real)'; 
ecg_with_noise = ecg_clean_raw + 0.3 * sin(2*pi*20*t_real)';
rng(0); 
noise = 0.1 * randn(1, N_total)';
signal_raw = ecg_with_noise + noise;

scale_factor = max(abs(signal_raw)); 
ecg_clean = ecg_clean_raw / scale_factor; 

%% ================== 3. TÍNH TOÁN SAI SỐ KHỚP DỮ LIỆU ==================
% Khớp pha Verilog vs MATLAB
y_mat_part  = y_matlab(delay+1:end); 
L_comp      = min(length(y_mat_part), length(y_verilog));
y_mat_final = y_mat_part(1:L_comp);
y_ver_final = y_verilog(1:L_comp);

err_hw  = y_ver_final - y_mat_final;
rmse_hw = sqrt(mean(err_hw.^2));
mae_hw  = mean(abs(err_hw));

% Khớp pha Verilog vs Clean
L_real    = min(length(y_verilog), length(ecg_clean));
y_v_real  = y_verilog(1:L_real);
y_c_real  = ecg_clean(1:L_real);

err_real  = y_v_real - y_c_real;
rmse_real = sqrt(mean(err_real.^2));
mae_real  = mean(abs(err_real));

%% ================== 4. VẼ ĐỒ THỊ ĐỐI CHIẾU (1 FIGURE) ==================
figure('Name','Ket qua Kiem chung He thong FIR FPGA','Color','w','Position',[100, 100, 800, 650]);
tiledlayout(2,1,'TileSpacing','loose','Padding','compact');

% Hàng 1: Verilog vs MATLAB (Kiểm chứng thiết kế phần cứng)
nexttile; 
plot((0:L_comp-1)/Fs, y_mat_final, 'b', 'LineWidth', 1.5); hold on;
plot((0:L_comp-1)/Fs, y_ver_final, 'r--', 'LineWidth', 1.2); grid on;
title(sprintf('1. Kiem chung Logic: Verilog vs MATLAB (RMSE: %.6f, MAE: %.6f)', rmse_hw, mae_hw));
legend('MATLAB (Ref)', 'Verilog (HW)'); ylabel('Amplitude');

% Hàng 2: Verilog vs Clean Input (Hiệu năng khôi phục tín hiệu)
nexttile; 
plot((0:L_real-1)/Fs, y_c_real, 'b', 'LineWidth', 1.5); hold on;
plot((0:L_real-1)/Fs, y_v_real, 'r', 'LineWidth', 1.2); grid on;
title(sprintf('2. Hieu nang thuc te: Verilog vs Clean Input (RMSE: %.6f, MAE: %.6f)', rmse_real, mae_real));
legend('Clean Input','Verilog Output'); xlabel('Time (s)'); ylabel('Amplitude');

%% ================== 5. IN KẾT QUẢ RA COMMAND WINDOW ========================
fprintf('\n================================================\n');
fprintf('KẾT QUẢ PHÂN TÍCH HỆ THỐNG ĐIỆN TIM GIẢ LẬP:\n');
fprintf('1. So voi Ly thuyet MATLAB (Kiem chung logic phan cung):\n');
fprintf('   - RMSE = %.6f\n   - MAE  = %.6f\n', rmse_hw, mae_hw);
fprintf('2. Verilog so voi Clean Input (Kiem chung hieu nang thuc te):\n');
fprintf('   - RMSE = %.6f\n   - MAE  = %.6f\n', rmse_real, mae_real);
fprintf('   - Do tre pha vat ly: %d mau (~%.1f ms)\n', delay, (delay/Fs)*1000);
fprintf('================================================\n');