import numpy as np
from DelaySample import delay_sample


def filter_sample(x, w, delayline_in):
    """
    Lọc mẫu dữ liệu đầu vào x với bộ lọc w.
    
    Parameters:
    x : np.ndarray
        Dữ liệu đầu vào với kích thước (1, nr_channels).
    w : np.ndarray
        Các hệ số của bộ lọc thời gian với kích thước (filterlength, nr_filters).
    delayline_in : np.ndarray
        Hàng đợi mẫu đầu vào với kích thước (filterlength, max(nr_channels, nr_filters)).
    
    Returns:
    output : np.ndarray
        Dữ liệu đầu ra với kích thước (1, max(nr_channels, nr_filters)).
    delayline_out : np.ndarray
        Hàng đợi mẫu đầu ra với kích thước (filterlength, max(nr_channels, nr_filters)).
    """
    nr_channels = x.shape[1]
    nr_filters = w.shape[1]
    filterlength = w.shape[0]
    max_size = max(nr_channels, nr_filters)
    
    # Đảm bảo kích thước của x phù hợp với delayline_in
    if x.shape[0] != 1 or x.shape[1] != max_size:
        raise ValueError('x phải có kích thước (1, max(nr_channels, nr_filters))')
    
    # Cập nhật delayline_out
    delayline_out = np.vstack((x, delayline_in[:-1, :]))
    
    # Lọc mẫu x với bộ lọc w
    if nr_channels > 1:
        output = np.dot(w.T, delayline_out)
    else:
        output = np.dot(delayline_out.T, w)
    
    return output, delayline_out

