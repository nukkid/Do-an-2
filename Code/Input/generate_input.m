
% ECG giả lập + nhiễu, Q1.7 signed 8-bit, xuất input hex

clear; clc;

Fs = 200;                 % Hz
t = 0:1/Fs:1;             % 1 giây
N = length(t);

% ECG gốc sạch (1 Hz)
rng(0);
ecg_clean_true = 0.7*sin(2*pi*1*t);

% Thêm nhiễu cấu trúc 20 Hz
ecg_with_noise = ecg_clean_true + 0.3*sin(2*pi*20*t);

% Thêm nhiễu Gaussian
noise = 0.1*randn(1,N);

% Tín hiệu input cuối cùng
signal = ecg_with_noise + noise;

% Chuẩn hoá biên độ
signal = signal / max(abs(signal));

% Q1.7
signal_q7 = int8(round(signal * 127));

% Xuất hex
fid = fopen('ECG_Input','w');
for i = 1:N
    fprintf(fid,'%02X\n', typecast(signal_q7(i),'uint8'));
end
fclose(fid);

disp('Generated ECG_Input.txt');
% =========================================================
% VẼ TÍN HIỆU
% =========================================================
figure;

subplot(2,1,1);
plot(t, ecg_clean_true);
title('ECG sạch (1 Hz)'); xlabel('t (s)'); ylabel('Biên độ'); grid on;

subplot(2,1,2);
plot(t, signal);
title('Tín hiệu + nhiễu (chuẩn hoá)'); xlabel('t (s)'); ylabel('Biên độ'); grid on;
