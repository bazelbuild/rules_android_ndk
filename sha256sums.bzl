"""
SHA256 checksums for downloaded NDK archives
"""

_NDK_PACKAGE_SHA256SUMS = {
    # r26
    "android-ndk-r26-windows.zip": "a748c6634b96991e15cb8902ffa4a498bba2ec6aa8028526de3c4c9dfcf00663",
    "android-ndk-r26-darwin.zip": "b2ab2fd17f71e2d2994c8c0ba2e48e99377806e05bf7477093344c26ab71dec0",
    "android-ndk-r26-linux.zip": "1505c2297a5b7a04ed20b5d44da5665e91bac2b7c0fbcd3ae99b6ccc3a61289a",
    # r25c
    "android-ndk-r25c-windows.zip": "f70093964f6cbbe19268f9876a20f92d3a593db3ad2037baadd25fd8d71e84e2",
    "android-ndk-r25c-darwin.zip": "b01bae969a5d0bfa0da18469f650a1628dc388672f30e0ba231da5c74245bc92",
    "android-ndk-r25c-linux.zip": "769ee342ea75f80619d985c2da990c48b3d8eaf45f48783a2d48870d04b46108",
}

def ndk_sha256(filename, repository_ctx):
    """Get the sha256 for a specific NDK release

    Args:
        filename: the name of the NDK release file (as seen on https://developer.android.com/ndk/downloads)
        repository_ctx: the repository_rule ctx

    Returns:
        a sha256sum string to use with ctx.download_and_extract
    """
    internal_sha256 = _NDK_PACKAGE_SHA256SUMS.get(filename)
    external_sha256 = repository_ctx.attr.sha256s.get(filename)
    if internal_sha256 == None and external_sha256 == None:
        fail("This NDK version is unsupported, and you haven't supplied a custom sha256sum for", filename)
    return _NDK_PACKAGE_SHA256SUMS.get(filename)
