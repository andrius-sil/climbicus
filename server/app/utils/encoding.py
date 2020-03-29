import base64


def test_image_str(resource_dir, image_name):
    filepath = f"{resource_dir}/route_images/{image_name}"
    with open(filepath, "rb") as f:
        return bytes_to_b64str(f.read())


def bytes_to_b64str(bytes_obj):
    base64_bytes = base64.b64encode(bytes_obj)
    base64_str = base64_bytes.decode("utf-8")

    return base64_str


def b64str_to_bytes(b64str):
    return base64.b64decode(b64str)
