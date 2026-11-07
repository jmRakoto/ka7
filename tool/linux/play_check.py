"""Plays media files to their end with a libmpv, no sound card, no screen:
proves that library decodes them. Prints one line per file; exits 1 on any
failure.
    python3 -I play_check.py /path/libmpv.so.2 file...
"""
import ctypes
import sys

END_FILE, FILE_LOADED, VIDEO_RECONFIG = 7, 8, 17
EOF_REASON = 0


class Event(ctypes.Structure):
    _fields_ = [
        ("event_id", ctypes.c_int),
        ("error", ctypes.c_int),
        ("reply_userdata", ctypes.c_uint64),
        ("data", ctypes.c_void_p),
    ]


class EndFile(ctypes.Structure):
    _fields_ = [("reason", ctypes.c_int), ("error", ctypes.c_int)]


mpv = ctypes.CDLL(sys.argv[1])
mpv.mpv_create.restype = ctypes.c_void_p
mpv.mpv_wait_event.restype = ctypes.POINTER(Event)
mpv.mpv_wait_event.argtypes = [ctypes.c_void_p, ctypes.c_double]
mpv.mpv_get_property_string.restype = ctypes.c_void_p
mpv.mpv_get_property_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
mpv.mpv_set_option_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
mpv.mpv_command.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_char_p)]

failed = False
for path in sys.argv[2:]:
    handle = mpv.mpv_create()
    for key, value in [("ao", "null"), ("vo", "null"), ("terminal", "no")]:
        mpv.mpv_set_option_string(handle, key.encode(), value.encode())
    mpv.mpv_initialize(ctypes.c_void_p(handle))
    args = (ctypes.c_char_p * 3)(b"loadfile", path.encode(), None)
    mpv.mpv_command(handle, args)
    def prop(name):
        value = mpv.mpv_get_property_string(handle, name.encode())
        if not value:
            return ""
        text = ctypes.string_at(value).decode()
        mpv.mpv_free(ctypes.c_void_p(value))
        return text

    codecs, picture, has_video, result = "", "", False, "timed out"
    for _ in range(600):
        event = mpv.mpv_wait_event(handle, 0.1).contents
        if event.event_id == FILE_LOADED:
            has_video = bool(prop("current-tracks/video/codec"))
            codecs = "+".join(
                c for c in (prop("current-tracks/video/codec"), prop("current-tracks/audio/codec")) if c
            )
        # Only once a frame is decoded does the picture have a size.
        if event.event_id == VIDEO_RECONFIG and prop("video-params/w"):
            picture = f"{prop('video-params/w')}x{prop('video-params/h')}"
        if event.event_id == END_FILE:
            end = ctypes.cast(event.data, ctypes.POINTER(EndFile)).contents
            result = "played to the end" if end.reason == EOF_REASON else f"error {end.error}"
            break
    mpv.mpv_terminate_destroy(ctypes.c_void_p(handle))
    ok = result == "played to the end" and codecs and (picture or not has_video)
    failed |= not ok
    name = path.rsplit("/", 1)[-1]
    shown = f"{codecs or 'no codec'}{', picture ' + picture if picture else ''}"
    print(f"   {'ok ' if ok else 'FAILED'} {name}: {shown}, {result}")
sys.exit(1 if failed else 0)
