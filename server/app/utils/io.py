import re
from abc import ABC, abstractmethod

import boto3

CDNS = {
    "dev": "http://dev-cdn.climbicus.com",
    "stag": "http://stag-cdn.climbicus.com",
    "prod": "http://prod-cdn.climbicus.com",
}


def s3_cdn_path(path):
    return path \
        .replace("s3://climbicus-dev", CDNS["dev"]) \
        .replace("s3://climbicus-stag", CDNS["stag"]) \
        .replace("s3://climbicus-prod", CDNS["prod"])


class InputOutput:

    def __init__(self):
        self.provider = None

    def load(self, provider):
        self.provider = provider


class InputOutputProvider(ABC):

    @abstractmethod
    def download_file(self, remote_path):
        pass

    @abstractmethod
    def upload_filepath(self, remote_path):
        pass


class S3InputOutputProvider(InputOutputProvider):

    def __init__(self, env):
        self.s3 = boto3.client("s3")
        self.bucket = f"climbicus-{env}"

    def download_file(self, remote_path):
        m = re.match("s3:\/\/([a-zA-Z\d-]+)\/(.+)", remote_path)
        assert m

        bucket = m.group(1)
        path = m.group(2)

        resp = self.s3.get_object(
            Bucket=bucket,
            Key=path,
        )

        assert resp["ResponseMetadata"]["HTTPStatusCode"] == 200

        return resp["Body"].read()

    def upload_filepath(self, remote_path):
        return f"s3://{self.bucket}/{remote_path}"
