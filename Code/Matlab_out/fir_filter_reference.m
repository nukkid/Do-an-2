clear; clc;

%% --- 1. Cấu hình & Đọc dữ liệu ngõ vào ---
Fs = 200; fc = 3; N_TAPS = 29;

fid = fopen('ECG_Input.txt', 'r');
assert(fid > 0, 'Không mở được file input');
C = textscan(fid, '%s'); fclose(fid);

signal_q7 = typecast(uint8(hex2dec(C{1})), 'int8'); % Đọc Q1.7
signal_float = double(signal_q7) / 128;
N = length(signal_q7);
t = (0:N-1)/Fs;

%% --- 2. Thiết kế bộ lọc & Lọc Bit-True ---
h_float = fir1(N_TAPS-1, fc/(Fs/2), 'low', hamming(N_TAPS));
h_float = h_float / sum(h_float); % DC gain = 1
h_q15   = int16(round(h_float * 32767));

% Lọc convolution dùng filter() thay cho vòng lặp for phức tạp (vẫn giữ đúng logic bit-true)
x_padded = [zeros(N_TAPS-1, 1); double(signal_q7)];
acc = filter(double(h_q15), 1, x_padded);
acc = acc(N_TAPS:end); % Bỏ phần đệm đầu

% Dịch bit (arithmetic shift right 7) và bão hòa (Saturate) về int16
ytmp = floor(acc / 2^7);
ytmp(ytmp > 32767)  = 32767;
ytmp(ytmp < -32768) = -32768;
y_ref = int16(ytmp);
y_float = double(y_ref) / 32768;

%% --- 3. Ghi dữ liệu ngõ ra (Hex) ---
fid = fopen('Output_Reference.txt', 'w');
assert(fid > 0, 'Không mở được file output');
fprintf(fid, '%04X\n', mod(double(y_ref), 65536));
fclose(fid);
fprintf('Đã xử lý xong %d mẫu.\n', N);

%% --- 4. Hiển thị Trực quan ---
% Figure 1: So sánh tín hiệu miền thời gian và tần số (FFT)
figure('Name', 'Phân tích Tín hiệu', 'Color', 'w');
tiledlayout(2, 2, 'TileSpacing', 'compact');

nexttile; plot(t, signal_float); grid on;
title('ECG Ngõ vào (Gốc + Nhiễu)'); ylabel('Amp');

nexttile; plot(t, y_float, 'r'); grid on;
title('ECG Ngõ ra (Sau lọc FIR)'); ylabel('Amp');

% Tính FFT nhanh để vẽ luôn
f = Fs * (0:floor(N/2)) / N;
Xf = abs(fft(signal_float)/N); Yf = abs(fft(y_float)/N);

nexttile; plot(f, 2*Xf(1:floor(N/2)+1)); grid on;
title('FFT Trước lọc'); xlabel('Freq (Hz)');

nexttile; plot(f, 2*Yf(1:floor(N/2)+1), 'r'); grid on;
title('FFT Sau lọc'); xlabel('Freq (Hz)');

% Figure 2: Đặc tính bộ lọc FIR
figure('Name', 'Đặc tính Bộ lọc', 'Color', 'w');
tiledlayout(3, 1, 'TileSpacing', 'compact');

nexttile; stem(0:N_TAPS-1, h_float, 'filled'); grid on;
title('Đáp ứng xung h[n]');

[H, F] = freqz(h_float, 1, 1024, Fs);
nexttile; plot(F, 20*log10(max(abs(H), 1e-12))); grid on;
title('Đáp ứng biên độ (dB)');

nexttile; plot(F, unwrap(angle(H))); grid on;
title('Đáp ứng pha (rad)'); xlabel('Frequency (Hz)');

%% --- 5. Lưu Workspace ---
save('filter_analysis.mat', 'Fs', 'fc', 'N_TAPS', 'h_q15', 'signal_q7', 'y_ref');