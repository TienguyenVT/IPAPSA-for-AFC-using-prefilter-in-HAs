function [noisy,scaledNoise] = add_noise(s,n,SNRdB)
% add noise to a signal
% s: signal
% n: noise
% SNRdB: SNR in dB
% noisy = s + alpha*n
% scaledNoise = alpha*n
Es = sum(s(:).^2);      % signal power 
En = sum(n(:).^2);      % noise power
SNR = 10^(SNRdB/10);
alpha = sqrt(Es/(SNR*En));
noisy = s + alpha*n;
scaledNoise = alpha*n;
end

