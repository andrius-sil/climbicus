from abc import ABC, abstractmethod

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

    def download_file(self, local_path):
        raise NotImplementedError()

    def upload_file(self, file, remote_path):
        raise NotImplementedError()
