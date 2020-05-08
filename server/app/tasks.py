import os

from app import celery, s3_client
from app.utils.encoding import b64str_to_bytes


@celery.task()
def upload_test_file_task(b64_str, filepath):
    filedir = os.path.dirname(filepath)
    if not os.path.exists(filedir):
        os.makedirs(filedir)

    fb = b64str_to_bytes(b64_str)
    with open(filepath, "wb") as f:
        f.write(fb)

    return filepath


@celery.task()
def upload_file_task(b64_str, bucket, remote_path, content_type):
    fb = b64str_to_bytes(b64_str)
    resp = s3_client.put_object(
        Body=fb,
        Bucket=bucket,
        Key=remote_path,
        ContentType=content_type,
    )

    assert resp["ResponseMetadata"]["HTTPStatusCode"] == 200

    return remote_path
