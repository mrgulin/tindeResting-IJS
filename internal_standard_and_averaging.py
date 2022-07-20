import numpy as np

arr = np.loadtxt('BPA_TPs_tentative.csv', skiprows=1, delimiter=',')
with open('BPA_TPs_tentative.csv') as f:
    header = f.readline()
    header = header.strip().split(',')

arr_norm = arr.copy()
arr_norm[:, 8:] = arr[:, 8:] / arr[-1][8:]

columns_without_parallel = np.array([i.split('_')[0]+'_'+i.split('_')[2] for i in header[8:]])
unique_columns = np.unique(columns_without_parallel)

arr_v3 = np.zeros((len(arr_norm) - 1, 8 + len(unique_columns)))
arr_v3[:, :8] = arr_norm[:-1, :8]
for line in range(len(arr_v3)):
    for column in range(len(unique_columns)):
        parallels = arr_norm[line][8:][columns_without_parallel == unique_columns[column]]
        arr_v3[line][column + 8] = np.average(parallels)

with open('merged_averaged_result.csv', 'w') as conn:
    conn.write(",".join(header[:8] + list(unique_columns)) + '\n')
    for line in arr_v3:
        conn.write(",".join([str(i) for i in line]) + '\n')
