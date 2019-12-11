from abc import ABC, abstractmethod

import boto3
import werkzeug


class InputOutput:

    def __init__(self):
        self.provider = None

    def load(self, provider):
        self.provider = provider


class InputOutputProvider(ABC):

    @abstractmethod
    def download_file(self, local_path):
        pass

    @abstractmethod
    def upload_file(self, file: werkzeug.FileStorage, remote_path):
        pass


class S3InputOutputProvider(InputOutputProvider):

    def __init__(self):
        self.s3 = boto3.client("s3")
        self.bucket = "climbicus"

    def download_file(self, local_path):
        raise NotImplementedError()

    def upload_file(self, file, remote_path):
        file.seek(0)
        resp = self.s3.put_object(
            Body=file,
            Bucket=self.bucket,
            Key=remote_path,
            ContentType=file.content_type,
        )

        assert resp["ResponseMetadata"]["HTTPStatusCode"] == 200

        return f"s3://{self.bucket}/{remote_path}"
