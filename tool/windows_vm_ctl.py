#!/usr/bin/env python3
"""A tela, o mouse e o teclado da VM de Windows, pelo QMP do QEMU.

  windows_vm_ctl.py <socket> screenshot <arquivo.png>
  windows_vm_ctl.py <socket> click <x> <y> [left|right|double]
  windows_vm_ctl.py <socket> move <x> <y>
  windows_vm_ctl.py <socket> scroll <up|down> [vezes]
  windows_vm_ctl.py <socket> key <ctrl-alt-delete>
  windows_vm_ctl.py <socket> type <texto>

As coordenadas são pixels da tela da VM. O texto é digitado como num teclado
americano, então só vale o que não tem acento.
"""
import json
import os
import socket
import struct
import sys
import tempfile
import time

ABS_MAX = 0x7FFF
ALIASES = {
    "enter": "ret",
    "space": "spc",
    "win": "meta_l",
    "del": "delete",
}
SYMBOLS = {
    " ": ("spc", False),
    "\n": ("ret", False),
    "\t": ("tab", False),
    "-": ("minus", False),
    "_": ("minus", True),
    "=": ("equal", False),
    "+": ("equal", True),
    "[": ("bracket_left", False),
    "{": ("bracket_left", True),
    "]": ("bracket_right", False),
    "}": ("bracket_right", True),
    "\\": ("backslash", False),
    "|": ("backslash", True),
    ";": ("semicolon", False),
    ":": ("semicolon", True),
    "'": ("apostrophe", False),
    '"': ("apostrophe", True),
    "`": ("grave_accent", False),
    "~": ("grave_accent", True),
    ",": ("comma", False),
    "<": ("comma", True),
    ".": ("dot", False),
    ">": ("dot", True),
    "/": ("slash", False),
    "?": ("slash", True),
    "!": ("1", True),
    "@": ("2", True),
    "#": ("3", True),
    "$": ("4", True),
    "%": ("5", True),
    "^": ("6", True),
    "&": ("7", True),
    "*": ("8", True),
    "(": ("9", True),
    ")": ("0", True),
}


class Qmp:
    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.connect(path)
        self.reader = self.sock.makefile("r", encoding="utf8")
        json.loads(self.reader.readline())  # o cumprimento
        self.call("qmp_capabilities")

    def call(self, command, **arguments):
        message = {"execute": command}
        if arguments:
            message["arguments"] = arguments
        self.sock.sendall(json.dumps(message).encode() + b"\n")
        while True:
            reply = json.loads(self.reader.readline())
            if "error" in reply:
                sys.exit(f"QEMU recusou {command}: {reply['error']['desc']}")
            if "return" in reply:
                return reply["return"]

    def events(self, events):
        self.call("input-send-event", events=events)


def screen_size(qmp):
    with tempfile.NamedTemporaryFile(suffix=".png") as shot:
        # O QEMU roda com o mesmo usuário e grava por cima deste arquivo
        qmp.call("screendump", filename=shot.name, format="png")
        with open(shot.name, "rb") as data:
            header = data.read(24)
    return struct.unpack(">II", header[16:24])


def key_event(code, down):
    return {
        "type": "key",
        "data": {"down": down, "key": {"type": "qcode", "data": code}},
    }


def button_event(name, down):
    return {"type": "btn", "data": {"down": down, "button": name}}


def press(qmp, codes):
    qmp.events([key_event(code, True) for code in codes])
    time.sleep(0.05)
    qmp.events([key_event(code, False) for code in reversed(codes)])
    time.sleep(0.03)


def char_codes(char):
    if "a" <= char <= "z" or "0" <= char <= "9":
        return [char]
    if "A" <= char <= "Z":
        return ["shift", char.lower()]
    if char not in SYMBOLS:
        sys.exit(f"não sei digitar {char!r}")
    code, shift = SYMBOLS[char]
    return ["shift", code] if shift else [code]


def move(qmp, x, y):
    width, height = screen_size(qmp)
    if not (0 <= x < width and 0 <= y < height):
        sys.exit(f"({x}, {y}) está fora da tela de {width}x{height}")
    qmp.events(
        [
            {
                "type": "abs",
                "data": {"axis": "x", "value": x * ABS_MAX // max(width - 1, 1)},
            },
            {
                "type": "abs",
                "data": {"axis": "y", "value": y * ABS_MAX // max(height - 1, 1)},
            },
        ]
    )
    time.sleep(0.05)


def click(qmp, button):
    qmp.events([button_event(button, True)])
    time.sleep(0.05)
    qmp.events([button_event(button, False)])
    time.sleep(0.05)


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    path, command, args = argv[1], argv[2], argv[3:]
    try:
        qmp = Qmp(path)
    except OSError as e:
        sys.exit(f"a VM não está ligada ({e})")
    if command == "screenshot":
        qmp.call("screendump", filename=os.path.abspath(args[0]), format="png")
    elif command == "move":
        move(qmp, int(args[0]), int(args[1]))
    elif command == "click":
        kind = args[2] if len(args) > 2 else "left"
        move(qmp, int(args[0]), int(args[1]))
        click(qmp, "right" if kind == "right" else "left")
        if kind == "double":
            click(qmp, "left")
    elif command == "scroll":
        wheel = "wheel-up" if args[0] == "up" else "wheel-down"
        for _ in range(int(args[1]) if len(args) > 1 else 1):
            click(qmp, wheel)
    elif command == "key":
        press(qmp, [ALIASES.get(part, part) for part in args[0].split("-")])
    elif command == "type":
        codes = [char_codes(char) for char in args[0]]
        for item in codes:
            press(qmp, item)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
