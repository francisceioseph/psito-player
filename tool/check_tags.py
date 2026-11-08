#!/usr/bin/env python3
"""O juiz do editor de tags: o mutagen, que não é o nosso leitor.

  check_tags.py seed <arquivo>   enche o arquivo de tags que o editor não mexe:
                                 ReplayGain, MusicBrainz, nota, ordem de artista,
                                 dois artistas e uma capa
  check_tags.py dump <arquivo>   imprime em JSON todas as tags e o áudio

Só para os testes e o CI (python3-mutagen).
"""
import base64
import hashlib
import json
import sys

import mutagen
from mutagen.aac import AAC
from mutagen.apev2 import APEv2, APEValue, BINARY
from mutagen.flac import FLAC, Picture
from mutagen.id3 import (
    ID3, APIC, COMM, POPM, TALB, TCOM, TCON, TDRC, TIT2, TPE1, TPE2, TPOS,
    TRCK, TSOP, TXXX, UFID, USLT,
)
from mutagen.mp4 import MP4, MP4Cover, MP4FreeForm

PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA"
    "hKmMIQAAAABJRU5ErkJggg=="
)


def id3_frames(tags):
    tags.add(TIT2(encoding=3, text="Antigo"))
    tags.add(TPE1(encoding=3, text=["Ana", "Bruno"]))
    tags.add(TPE2(encoding=3, text="Vários"))
    tags.add(TALB(encoding=3, text="Álbum"))
    tags.add(TRCK(encoding=3, text="3/12"))
    tags.add(TPOS(encoding=3, text="1/2"))
    tags.add(TDRC(encoding=3, text="1997"))
    tags.add(TCON(encoding=3, text="Rock"))
    tags.add(TCOM(encoding=3, text="Compositora"))
    tags.add(COMM(encoding=3, lang="por", desc="", text="comentário"))
    tags.add(COMM(encoding=3, lang="eng", desc="iTunNORM", text="0000"))
    tags.add(TXXX(encoding=3, desc="REPLAYGAIN_TRACK_GAIN", text="-6.50 dB"))
    tags.add(TXXX(encoding=3, desc="MusicBrainz Album Id", text="abc"))
    tags.add(USLT(encoding=3, lang="por", desc="", text="letra\nsegunda"))
    tags.add(POPM(email="x@y", rating=196, count=3))
    tags.add(UFID(owner="http://musicbrainz.org", data=b"rec-id"))
    tags.add(TSOP(encoding=3, text="Ana, Sort"))
    tags.add(APIC(encoding=3, mime="image/png", type=3, desc="", data=PNG))
    tags.add(APIC(encoding=3, mime="image/png", type=4, desc="verso", data=PNG))


VORBIS = {
    "TITLE": "Antigo", "ARTIST": ["Ana", "Bruno"], "ALBUMARTIST": "Vários",
    "ALBUM": "Álbum", "TRACKNUMBER": "3", "TRACKTOTAL": "12",
    "DISCNUMBER": "1", "DATE": "1997", "GENRE": ["Rock", "Pop"],
    "COMPOSER": "Compositora", "COMMENT": "comentário",
    "REPLAYGAIN_TRACK_GAIN": "-6.50 dB", "MUSICBRAINZ_ALBUMID": "abc",
    "LYRICS": "letra\nsegunda", "RATING": "80", "ARTISTSORT": "Ana, Sort",
}


def flac_picture(kind):
    p = Picture()
    p.type = kind
    p.mime = "image/png"
    p.data = PNG
    return p


def open_file(path):
    if path.endswith(".aac"):
        return mutagen.File(path, options=[AAC])
    return mutagen.File(path)


def seed(path):
    f = open_file(path)
    name = type(f).__name__
    if name == "FLAC":
        f.delete()
        f.clear_pictures()
        for k, v in VORBIS.items():
            f[k] = v
        f.add_picture(flac_picture(3))
        f.add_picture(flac_picture(4))
        f.save(padding=lambda info: 256)
    elif name in ("OggVorbis", "OggOpus"):
        f.delete()
        for k, v in VORBIS.items():
            f[k] = v
        f["METADATA_BLOCK_PICTURE"] = [
            base64.b64encode(flac_picture(3).write()).decode(),
            base64.b64encode(flac_picture(4).write()).decode(),
        ]
        f.save()
    elif name == "MP4":
        f.delete()
        f["\xa9nam"] = "Antigo"
        f["\xa9ART"] = ["Ana", "Bruno"]
        f["aART"] = "Vários"
        f["\xa9alb"] = "Álbum"
        f["trkn"] = [(3, 12)]
        f["disk"] = [(1, 2)]
        f["\xa9day"] = "1997"
        f["\xa9gen"] = "Rock"
        f["\xa9wrt"] = "Compositora"
        f["\xa9cmt"] = "comentário"
        f["\xa9lyr"] = "letra\nsegunda"
        f["soar"] = "Ana, Sort"
        f["----:com.apple.iTunes:replaygain_track_gain"] = [
            MP4FreeForm(b"-6.50 dB")
        ]
        f["----:com.apple.iTunes:MusicBrainz Album Id"] = [MP4FreeForm(b"abc")]
        f["covr"] = [
            MP4Cover(PNG, imageformat=MP4Cover.FORMAT_PNG),
            MP4Cover(PNG, imageformat=MP4Cover.FORMAT_PNG),
        ]
        f.save()
    elif name in ("WavPack", "MonkeysAudio"):
        try:
            APEv2(path).delete()
        except Exception:
            pass
        tag = APEv2()
        tag["Title"] = "Antigo"
        tag["Artist"] = ["Ana", "Bruno"]
        tag["Album Artist"] = "Vários"
        tag["Album"] = "Álbum"
        tag["Track"] = "3/12"
        tag["Disc"] = "1/2"
        tag["Year"] = "1997"
        tag["Genre"] = "Rock"
        tag["Composer"] = "Compositora"
        tag["Comment"] = "comentário"
        tag["REPLAYGAIN_TRACK_GAIN"] = "-6.50 dB"
        tag["MUSICBRAINZ_ALBUMID"] = "abc"
        tag["Cover Art (Front)"] = APEValue(b"cover.png\x00" + PNG, BINARY)
        tag["Cover Art (Back)"] = APEValue(b"back.png\x00" + PNG, BINARY)
        tag.save(path)
    else:
        # MP3, AAC, WAV e AIFF: ID3v2
        if name in ("WAVE", "AIFF"):
            if f.tags is None:
                f.add_tags()
            tags = f.tags
            tags.clear()
            id3_frames(tags)
            f.save()
        else:
            tags = ID3()
            id3_frames(tags)
            tags.save(path, v2_version=4 if "--v23" not in sys.argv else 3)


def value(v):
    if isinstance(v, bytes):
        return "sha1:" + hashlib.sha1(v).hexdigest()
    if hasattr(v, "data") and isinstance(getattr(v, "data"), bytes):
        return {
            k: value(x) for k, x in sorted(vars(v).items()) if not k.startswith("_")
        }
    if isinstance(v, (list, tuple)):
        return [value(x) for x in v]
    if isinstance(v, (str, int, float, bool)) or v is None:
        return v
    if hasattr(v, "value"):
        return value(v.value)
    return str(v)


def dump(path):
    f = open_file(path)
    out = {"type": type(f).__name__, "tags": {}, "pictures": []}
    info = f.info
    out["info"] = {
        k: getattr(info, k)
        for k in ("length", "sample_rate", "channels", "bitrate")
        if hasattr(info, k)
    }
    tags = f.tags
    if isinstance(f, AAC):
        # O mutagen não liga o ID3 da frente ao AAC
        try:
            tags = ID3(path)
        except Exception:
            tags = None
    if tags is not None:
        for key in sorted(tags.keys()):
            item = tags[key]
            if hasattr(item, "pprint") and type(item).__module__.startswith(
                "mutagen.id3"
            ):
                frame = {
                    k: value(x)
                    for k, x in sorted(vars(item).items())
                    if not k.startswith("_") and k != "encoding"
                }
                out["tags"][key] = frame
            else:
                out["tags"][key] = value(item)
    for p in getattr(f, "pictures", []):
        out["pictures"].append([p.type, p.mime, value(p.data)])
    json.dump(out, sys.stdout, ensure_ascii=False, sort_keys=True)


if __name__ == "__main__":
    {"seed": seed, "dump": dump}[sys.argv[1]](sys.argv[2])
