import base64
import io

import numpy as np
import orjson


def bytes_to_b64str(bytes_obj):
    base64_bytes = base64.b64encode(bytes_obj)
    base64_str = base64_bytes.decode("utf-8")

    return base64_str


def b64str_to_bytes(b64str):
    return base64.b64decode(b64str)


def nparray_to_nparraybytes(array):
    file = io.BytesIO()
    np.save(file, array)
    file.seek(0)

    return file.read()


def json_to_nparraybytes(json_str):
    array = np.array(orjson.loads(json_str)).astype("uint8")
    return nparray_to_nparraybytes(array)


def nparraybytes_to_nparray(array_bytes):
    file = io.BytesIO(array_bytes)
    return np.load(file, allow_pickle=True)
