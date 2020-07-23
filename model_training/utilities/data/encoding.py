import io
import numpy as np

def nparraybytes_to_nparray(array_bytes):
    file = io.BytesIO(array_bytes)
    return np.load(file, allow_pickle=True)

def nparray_to_nparraybytes(array):
    file = io.BytesIO()
    np.save(file, array)
    file.seek(0)

    return file.read()