import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, lfilter
from scipy.fftpack import fft
from scipy.io import loadmat
from PemAFC_Modified import PemAFC_Modified
from PemAFCinit import PemAFCinit
from convert import convert_mat_to_npy

def run_pem_td_feedback(link, prob_sig=0, in_sig=2, fs=16000, Kdb=30, d_k=96, d_fb=1, Lg_hat=64, SNR=25, mu=0.001):
    def SNRFactor(estKu, w, SNR):
        signal_power = np.mean(estKu**2)
        noise_power = np.mean(w**2)
        factor = np.sqrt(signal_power / (noise_power * 10**(SNR / 10)))
        return factor

    N = 80 * fs  # total number of samples
    K = 10**(Kdb / 20)

    # performance parameters
    MIS = np.zeros(N)
    MSG = np.zeros(N)
    ASG = np.zeros(N)

    # Convert .mat files to .npy files
    convert_mat_to_npy(link, 'mFBPathIRs16kHz_FF.mat', 'mFBPathIRs16kHz_PhoneNear.mat', 'mFBPathIRs16kHz_FF.npy', 'mFBPathIRs16kHz_PhoneNear.npy')

    # Load feedback path data from .npy files
    E = np.load(f'{link}mFBPathIRs16kHz_FF.npy')
    Ec = np.load(f'{link}mFBPathIRs16kHz_PhoneNear.npy')

    # Process the feedback path data
    g = E - np.mean(E)  # feedback path and remove mean value
    Lg = len(g)  # length of feedback path
    Nfreq = 512
    G = fft(g, Nfreq)

    gc = Ec - np.mean(Ec)  # feedback path and remove mean value
    Gc = fft(gc, Nfreq)

    TDLy = np.zeros(Lg)  # time-delay vector true feedback path

    # Desired Signal (incoming signal)
    if in_sig == 0:
        # 0) incoming signal is a white noise
        Var_noise = 0.001
        input_signal = np.sqrt(Var_noise) * np.random.randn(N)
    elif in_sig == 1:
        # 1) incoming signal is a synthesized speech
        Var = 1
        h_den = [1, -2 * 0.96 * np.cos(3000 * 2 * np.pi / 15750), 0.96**2]
        v = np.sqrt(Var) * np.random.randn(N)
        input_signal = lfilter([1], h_den, v)  # speech weighted noise
    elif in_sig == 2:
        # 2) incoming signal is a real speech segment from NOIZEUS
        input_signal = np.load(f'{link}HeadMid2_Speech_Vol095_0dgs_m1.npy')[:N, 0]
    else:
        # 3) incoming signal is a music
        input_signal = np.load(f'{link}HeadMid2_Music_Vol095_0dgs_m1.npy')[16000:N + 16000]

    input_signal = input_signal / np.max(np.abs(input_signal))
    ff = firwin(65, 0.025, pass_zero=False)
    u_ = lfilter(ff, 1, input_signal)

    u = np.zeros(N)
    for n in range(N):
        if n < len(u_):
            u[n] = u_[n]
        else:
            u[n] = u_[n % len(u_)]

    # Probe signal w(k)
    Var_P = 0.001
    if prob_sig == 1:
        w = np.sqrt(Var_P) * np.random.randn(N)
    else:
        w = np.zeros(N)

    # SNR
    if prob_sig == 1:
        estKu = K * u
        factor = SNRFactor(estKu, w, SNR)
        u = factor * u

    # Pre-whitening filter
    La = 20
    framelength = int(0.01 * fs)
    AF, AR = PemAFCinit(Lg_hat, mu, La, framelength)

    # Initialization data vectors
    y = np.zeros(N)
    e_delay = np.zeros(N + d_k)
    y_delayfb = np.zeros(N + d_fb)
    m = np.zeros(N)

    # PEM lattice algorithm
    for k in range(1, N):
        # Change the feedback path at sample N/2
        if k == N // 2:
            g = gc
            G = Gc

        y[k] = K * e_delay[k] + w[k]

        # Simulated feedback path: computation of microphone signal
        TDLy = np.concatenate(([y[k]], TDLy[:-1]))
        m[k] = u[k] + np.dot(g, TDLy)  # received microphone signal

        y_delayfb[k + d_fb] = y[k]

        # Feedback cancellation
        e_delay[k + d_k], AF, AR = PemAFC_Modified(m[k], y_delayfb[k], AF, AR, 1, 3)

        # Misalignment of the PEM-AFC
        g_hat = np.concatenate((np.zeros(d_fb), AF['gTD']))

        G_hat = fft(g_hat, Nfreq)
        G_tilde = G[:Nfreq // 2] - G_hat[:Nfreq // 2]

        # Misalignment
        MIS[k] = 20 * np.log10(np.linalg.norm(G_tilde) / np.linalg.norm(G[:Nfreq // 2]))

        # Maximum Stable Gain (MSG)
        MSG[k] = 20 * np.log10(np.min(1. / np.abs(G_tilde)))

        # Added Stable Gain (ASG)
        ASG[k] = MSG[k] - 20 * np.log10(np.min(1. / np.abs(G[:Nfreq // 2 + 1])))

        if k % (N // 50) == 0:
            print(f'{k / N * 100:.2f}%')

            t = np.linspace(0, (N - 1) / fs, N)

            plt.figure(1)
            plt.plot(t, MIS)
            plt.xlabel('Time [s]')
            plt.ylabel('MIS [dB]')
            plt.grid(True)
            plt.draw()
            plt.pause(0.01)

            plt.figure(2)
            plt.plot(t, MSG)
            plt.xlabel('Time [s]')
            plt.ylabel('MSG [dB]')
            plt.title('Maximum Stable Gain')
            plt.grid(True)
            plt.draw()
            plt.pause(0.01)

            plt.figure(3)
            plt.plot(t, ASG)
            plt.xlabel('Time [s]')
            plt.ylabel('ASG [dB]')
            plt.title('Added Stable Gain')
            plt.grid(True)
            plt.draw()
            plt.pause(0.01)

            plt.figure(4)
            plt.plot(g)
            plt.plot(g_hat, 'r')
            plt.grid(True)
            plt.draw()
            plt.pause(0.01)

            plt.figure(5)
            plt.plot(t, y)
            plt.xlabel('Time [s]')
            plt.ylabel('Amplitude')
            plt.legend(['PEM-NLMS'])
            plt.grid(True)
            plt.draw()
            plt.pause(0.01)

    # Average values of MIS, MSG, ASG
    aveMis = np.mean(MIS)
    aveMSG = np.mean(MSG)
    aveASG = np.mean(ASG)

    print(f'Average MIS: {aveMis:.2f} dB')
    print(f'Average MSG: {aveMSG:.2f} dB')
    print(f'Average ASG: {aveASG:.2f} dB')

# Example usage:
# run_pem_td_feedback('D:\\De_tai_sinh_vien\\code_python\\sound_test\\')

if __name__ == "__main__":
    run_pem_td_feedback('D:\\De_tai_sinh_vien\\code_python\\sound_test\\')
