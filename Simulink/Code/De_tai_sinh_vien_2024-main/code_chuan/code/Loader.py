from scipy.io import loadmat

def load_mat_data(file_path):
    data = loadmat(file_path)
    
    x = data['x'].flatten() # Convert the 2D array to a 1D array
    d = data['d'].flatten() # Convert the 2D array to a 1D array
    miu = data['miu'].item() # Get the scalar value from the 2D array
    ord = data['ord'].item() # Get the scalar value from the 2D array
    p = data['p'].item() # Get the scalar value from the 2D array
    dlt = data['dlt'].item() # Get the scalar value from the 2D array
    a = data['a'].item() # Get the scalar value from the 2D array
    h1 = data['h1'].flatten() # Convert the 2D array to a 1D array
    N = len(x) # Get the length of the input data
    
    return x, d, miu, ord, p, dlt, a, h1, N
