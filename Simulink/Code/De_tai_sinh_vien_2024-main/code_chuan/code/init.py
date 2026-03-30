import loader 
import numpy as np

    #   Input:
    #        x   --> far-end signal
    #        d   --> reference signal
    #        miu --> step size
    #        ord --> length of the adaptive filter
    #        p   --> projection order
    #        dlt --> regularization constant
    #        a   --> IPNLMS parameter
    #        h1  --> true impulse response of the echo path
    #   Output:
    #        normalized misalignment in dB
    
def init_parameter(x , ord , p , dlt):
    N = len(x)  # length of data in
    w = np.zeros(ord)  # adaptive filter weights
    x1 = np.zeros(ord) # input signal
    D = np.zeros(p) # desired signal
    X = np.zeros((ord, p)) # matrix two side ord p 
    P = np.zeros((ord, p)) # matrix two side ord p
    m = np.zeros((N,1)) # misalignment 
    e = np.zeros((N,1)) # error
    S0 = dlt * np.eye(p)  # matrix two side p p  
    S = np.zeros((p, p))  # vector with dimension p p
    return N, w, x1, D, X, P, m, e, S0, S

