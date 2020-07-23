import urllib.request

CDNS = {
    "dev": "http://dev-cdn.climbicus.com",
    "stag": "http://stag-cdn.climbicus.com",
    "prod": "http://prod-cdn.climbicus.com",
}


def download_image(path):
    path_cdn = path
    path_cdn = path_cdn.replace("s3://climbicus-dev", CDNS["dev"])
    path_cdn = path_cdn.replace("s3://climbicus-stag", CDNS["stag"])
    path_cdn = path_cdn.replace("s3://climbicus-prod", CDNS["prod"])
    
    fbytes_image = urllib.request.urlopen(path_cdn).read()
    return fbytes_image