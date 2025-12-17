# TODO: Add Documentation regarding the Custom SD Format and .bin file creation

# choreo_builder.py
# Creates a choreography file for SD card (custom format)
# Format:
# Block 0 (header, 512 bytes):
#   Bytes 0-3   : Magic "STEP"
#   Bytes 4-5   : Version (0x0001)
#   Bytes 6-7   : Number of moves (uint16)
#   Bytes 8-511 : Reserved/padding
# Block 1+:
#   Each byte: Bits 7-6 = direction (-> max 63 in base 10), Bits 5-0 = duration
#   Directions: 00=R, 01=L, 10=F, 11=B

import struct

# TODO: More efficient moves gen

moves = [
    ("R", 5),
    ("F", 10),
    ("L", 3),
    ("B", 8),
    ("R", 7),
]

# TODO: distinction between rotation on itself and a left or right turn ?

direction_map = {
    "R": 0b00,
    "L": 0b01,
    "F": 0b10,
    "B": 0b11,
}

# -------------------------------
# Build header block (512 bytes)
# -------------------------------
magic = b"STEP"         # 4 bytes
version = 0x0001        # 2 bytes
num_moves = len(moves)  # 2 bytes
reserved = b"\x00" * (512 - 8)  # pad to 512 bytes

header_block = magic + struct.pack(">H", version) + struct.pack(">H", num_moves) + reserved

# -------------------------------
# Build sequence block(s)
# -------------------------------
seq_bytes = bytearray()
for dir_char, duration in moves:
    if dir_char not in direction_map:
        raise ValueError(f"Invalid direction: {dir_char}")
    if not (0 <= duration <= 63):
        raise ValueError("Duration must be 0-63")
    byte = (direction_map[dir_char] << 6) | (duration & 0x3F)
    seq_bytes.append(byte)

# Pad sequence block to 512 bytes
seq_block = seq_bytes + b"\x00" * (512 - len(seq_bytes))

# -------------------------------
# Write to file
# -------------------------------
with open("choreo.bin", "wb") as f:
    f.write(header_block)   # Block 0
    f.write(seq_block)      # Block 1 (first sequence)

print(f"Choreography file created: 'choreo.bin'")
print(f"Total moves: {len(moves)}")
