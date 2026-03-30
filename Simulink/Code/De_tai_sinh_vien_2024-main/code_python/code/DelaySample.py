import numpy as np

# delay từng mẫu 
# nếu delay  = 2 thì khởi tạo mảng bằng 0 với delay+1 phần tử  [ 0,0,0]
# nếu mẫu truyền vào 2 thì mãng delay [2 , 0 , 0]
# nêú mẫu truyền vào mẫu tiếp theo là 3 thì mảng [3 , 2 , 0]
# tiếp thì sẽ có mảng là [ 1 , 3, 2,]
#nếu truyền tiếp vào thì vẫn giũ nguyên size và đẩy con 2 ra ngoài và thêm mẫu tiếp theo vào [5 , 1 ,3]
# cứ thế cho đến hết 


def delay_sample(x, delay, delayline_in):
    """
    Delays sample x with delay.
    
    INPUTS:
        x             = input data (Dimensions: 1 x nr_channels)
        delay         = discrete-time delay
        delayline_in  = input delayline (Dimensions: (delay+1) x nr_channels)
    OUTPUTS:
        output        = output data (Dimensions: 1 x nr_channels)
        delayline_out = output delayline
    """
    # Create delayline_out by appending x to the beginning of delayline_in and removing the last element
    delayline_out = np.vstack([x, delayline_in[:-1, :]])
    
    # Extract output as the element at the delay+1 position from delayline_out
    output = delayline_out[-1, :]
    
    return output, delayline_out


