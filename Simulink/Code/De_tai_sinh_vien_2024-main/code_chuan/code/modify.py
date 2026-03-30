import numpy as np
from init import init_parameter

#select 1 : APA 
#select 2 : NLMS
#select 3 : IPNLMS 
#select 4 : IPAPA

def modify(x, d, miu , ord , p , dlt ,a , h1 , select):
    N, w, x1, D, X, P, m, e, S0, S = init_parameter(x , ord , p , dlt)

    #APA
    if select == 1:
        for n in range(N):
            x1 = np.concatenate(([x[n]], x1[:ord-1]))
            X = np.column_stack((x1, X[:, :p-1]))
            D = np.concatenate(([d[n]], D[:p-1]))
            E = D - X.T @ w

            w = w + miu * X @ np.linalg.inv(dlt * np.eye(p) + X.T @ X) @ E
            m[n] = 20 * np.log10(np.linalg.norm(w - h1) / np.linalg.norm(h1))

    #NLMS 
    elif select == 2 :
        for n in range(N):
            x1 = np.concatenate(([x[n]], x1[:ord-1]))
            ep = d[n] - np.dot(x1, w)
            w = w + miu / (np.linalg.norm(x1)**2 + 1e-8) * x1 * ep
            m[n] = 20 * np.log10(np.linalg.norm(w - h1) / np.linalg.norm(h1))

    #IPNLMS
    elif select ==  3:
        for n in range(N):
            x1 = np.concatenate(([x[n]], x1[:ord-1]))
            ep = d[n] - np.dot(x1, w)

            kd = (1 - a) / (2 * ord) + (1 + a) * np.abs(w) / (1e-8 + 2 * np.sum(np.abs(w)))
            Kd = np.diag(kd)
            w = w + (miu / (np.dot(x1.T, np.dot(Kd, x1)) + 1e-8 * (1 - a) / (2 * ord))) * np.dot(Kd, x1) * ep

            m[n] = 20 * np.log10(np.linalg.norm(w - h1) / np.linalg.norm(h1))

    #select 4 : IPAPA
    elif select == 4:
        for n in range(N):
                # Update x1 by concatenating the current element x[n] with a slice of x1
            x1 = np.concatenate(([x[n]], x1[:ord-1]))
                # Update X by stacking x1 as a new column alongside existing columns of X
            X = np.column_stack((x1, X[:, :p-1]))
                # Update D by concatenating the current element d[n] with a slice of D
            D = np.concatenate(([d[n]], D[:p-1]))
                # Compute the product of the transpose of X and the weight vector w
            Y = X.T @ w
                # Calculate the error E as the difference between D and Y
            E = D - Y
                # Compute kd using the parameter a and the absolute values of w
            kd = (1-a) / (2 * ord) + (1 + a) * np.abs(w) / (10**-8 + 2 * np.sum(np.abs(w)))
                # Update P by stacking kd * x1 as a new column alongside existing columns of P
            P = np.column_stack((kd * x1, P[:, :p-1]))
                # Calculate S as the sum of dlt times an identity matrix and the product of the transpose of X and P
            S = dlt * np.eye(p) + X.T @ P
                # Compute E2 as the product of the transpose of E and the inverse of S
            E2 = E.T @ np.linalg.inv(S)
                # Update the weight vector w
            w = w + miu * P @ E2.T
                # Calculate m[n] as 20 times the base-10 logarithm of the ratio of the norm of w - h1 to the norm of h1
            m[n] = 20 * np.log10(np.linalg.norm(w - h1) / np.linalg.norm(h1))
            
    return m , w