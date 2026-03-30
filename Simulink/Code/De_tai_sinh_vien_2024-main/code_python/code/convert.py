import numpy as np
from scipy.io import loadmat

def convert_mat_to_npy(link, mat_file_ff, mat_file_phone_near, npy_file_ff, npy_file_phone_near):
    # Load the .mat files
    mFBPathIRs16kHz_FF = loadmat(f'{link}{mat_file_ff}')
    mFBPathIRs16kHz_PhoneNear = loadmat(f'{link}{mat_file_phone_near}')

    # Extract the relevant arrays
    E = mFBPathIRs16kHz_FF['mFBPathIRs16kHz_FF'][:, 2, 0]
    Ec = mFBPathIRs16kHz_PhoneNear['mFBPathIRs16kHz_PhoneNear'][:, 2]

    # Save the arrays as .npy files
    np.save(f'{link}{npy_file_ff}', E)
    np.save(f'{link}{npy_file_phone_near}', Ec)

# Example usage:
# convert_mat_to_npy('D:\\De_tai_sinh_vien\\code_python\\sound_test\\', 'mFBPathIRs16kHz_FF.mat', 'mFBPathIRs16kHz_PhoneNear.mat', 'mFBPathIRs16kHz_FF.npy', 'mFBPathIRs16kHz_PhoneNear.npy')