import numpy as np 
from scipy.linalg import solve_toeplitz
from PemAFCinit import PemAFCinit
from DelaySample import delay_sample  
from FilterSample import filter_sample


def PemAFC_Modified(Mic, Ls, AF, AR, UpdateFC, sel):
    """
    Update equation of time-domain LMS-based implementation of PEM-based
    adaptive feedback canceller

    INPUTS:
    * Mic = microphone sample
    * Ls  = loudspeaker sample
    * AF  = time-domain LMS-based feedback canceller and its properties
             -AF['wTD']: time-domain filter coefficients (dimensions: AF['N'] x 1)  
             -AF['N']  : time-domain filter length
             -AF['mu'] : stepsize
             -AF['p']  : power in step-size normalization
             -AF['lambda']: weighing factor for power computation
             -AF['TDLLs']: time-delay line of loudspeaker samples
             (dimensions: AF['N'] x 1)
             -AF['TDLLswh']: time-delay line of pre-whitened loudspeaker
             samples (dimensions: AF['N'] x 1)
    * AR        = auto-regressive model and its properties
                   -AR['w']           : coefficients of previous AR-model
                   -AR['N']           : filter length AR model (Note: N= Nh + 1)
                   -AR['framelength'] : framelength on which AR model is estimated
                   -AR['TDLMicdelay'] : time-delay line of microphone samples
                                     (dimensions: AR['framelength']+1 x 1)
                   -AR['TDLLsdelay']  : time-delay line of loudspeaker samples
                                     (dimensions: AR['framelength']+1 x 1)
                   -AR['TDLMicwh']    : time-delay line of pre-whitened
                                     microphone signal
                                     (dimensions: AR['N'] x 1)
                   -AR['TDLLswh']     : time-delay line of pre-whitened
                                     loudspeaker signal
                                     (dimensions: AR['N'] x 1)
                   -AR['frame']       : frame of AR['framelength'] error signals
                                     on which AR model is computed  
                   -AR['frameindex']
    * UpdateFC = boolean that indicates whether or not the feedback canceller should be updated 
                   (1 = update feedback canceller; 0 = do not update feedback canceller)  
    * RemoveDC   = boolean that indicates whether or not the DC component of the estimated feedback path should be removed 
                   (1 = remove DC of feedback canceller; 0 = do not remove DC of feedback canceller)  
    OUTPUTS:
    * e          = feedback-compensated signal 
    * AR         = updated AR-model and its properties
    * AF         = updated feedback canceller and its properties 
    """
    
    delta = 1e-10
    AF['TDLLs'] = np.concatenate(([Ls], AF['TDLLs'][:-1]))
    e = Mic - np.dot(AF['gTD'], AF['TDLLs'])

    e = 2 * np.tanh(0.5 * e)  # clip the error signal by tanh function

    # Delay microphone and loudspeaker signal by framelength
    Micdelay, AR['TDLMicdelay'] = delay_sample(Mic, AR['framelength'], AR['TDLMicdelay'])
    Lsdelay, AR['TDLLsdelay'] = delay_sample(Ls, AR['framelength'], AR['TDLLsdelay'])

    # Filter microphone and loudspeaker signal with AR-model
    Micwh, AR['TDLMicwh'] = filter_sample(Micdelay, AR['w'], AR['TDLMicwh'])
    Lswh, AR['TDLLswh'] = filter_sample(Lsdelay, AR['w'], AR['TDLLswh'])

    # Update AR-model  
    AR['frame'] = np.concatenate(([e], AR['frame'][:-1]))  # insert e at the first position of frame and shift other elements back by one position

    if AR['frameindex'] == AR['framelength'] - 1 and AR['N'] - 1 > 0:
        R = np.zeros(AR['N'])
        for j in range(AR['N']):
            R[j] = np.dot(AR['frame'], np.concatenate((AR['frame'][j:], np.zeros(j)))) / AR['framelength']
        a, Ep = np.linalg.solve_toeplitz(R, AR['N'] - 1)
        AR['w'] = a

    AR['frameindex'] += 1

    if AR['frameindex'] == AR['framelength']:
        AR['frameindex'] = 0

    AF['TDLLswh'] = np.concatenate(([Lswh], AF['TDLLswh'][:-1]))
    ep = Micwh - np.dot(AF['gTD'], AF['TDLLswh'])
    beta = 50
    if UpdateFC == 1:
        if sel == 0:
            # IPNLMS-11
            aa = 0
            kd = (1 - aa) / (2 * len(AF['gTD'])) + (1 + aa) * np.abs(AF['gTD']) / (delta + 2 * np.sum(np.abs(AF['gTD'])))
            Kd = np.diag(kd)
            AF['gTD'] = AF['gTD'] + (AF['mu'] / (np.dot(AF['TDLLswh'].T, np.dot(Kd, AF['TDLLswh'])) + delta * (1 - aa) / (2 * len(AF['gTD'])))) * np.dot(Kd, AF['TDLLswh']) * ep
        elif sel == 1:
            # IPNLMS-10
            aa = 0
            kd = (1 - aa) / (2 * len(AF['gTD'])) + (1 + aa) * (1 - np.exp(-beta * np.abs(AF['gTD']))) / (delta + 2 * np.sum(1 - np.exp(-beta * np.abs(AF['gTD']))))
            Kd = np.diag(kd)
            AF['gTD'] = AF['gTD'] + (AF['mu'] / (np.dot(AF['TDLLswh'].T, np.dot(Kd, AF['TDLLswh'])) + delta * (1 - aa) / (2 * len(AF['gTD'])))) * np.dot(Kd, AF['TDLLswh']) * ep
        elif sel == 2:
            # PLNMS
            aa = 1 - delta
            kd = (1 - aa) / (2 * len(AF['gTD'])) + (1 + aa) * np.abs(AF['gTD']) / (delta + 2 * np.sum(np.abs(AF['gTD'])))
            Kd = np.diag(kd)
            AF['gTD'] = AF['gTD'] + (AF['mu'] / (np.dot(AF['TDLLswh'].T, np.dot(Kd, AF['TDLLswh'])) + delta / len(AF['gTD']))) * np.dot(Kd, AF['TDLLswh']) * ep
        elif sel == 3:
            # PNLMS edit
            rho = 5 / len(AF['gTD'])
            zeta = 0.01
            lambda1 = np.maximum(zeta, np.abs(AF['gTD']))
            lambda_ = np.maximum(rho * lambda1, np.abs(AF['gTD']))
            kd = lambda_ / np.sum(lambda_)
            Kd = np.diag(kd)
            AF['gTD'] = AF['gTD'] + (AF['mu'] / (np.dot(AF['TDLLswh'].T, np.dot(Kd, AF['TDLLswh'])) + delta / len(AF['gTD']))) * np.dot(Kd, AF['TDLLswh']) * ep
        elif sel == 4:
            # NLMS
            AF['gTD'] = AF['gTD'] + (AF['mu'] / (np.linalg.norm(AF['TDLLswh'])**2 + delta)) * AF['TDLLswh'] * ep

    return e, AF, AR
