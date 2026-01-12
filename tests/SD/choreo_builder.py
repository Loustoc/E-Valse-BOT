import struct

direction_map = {
    "R": 0b00, # Droite
    "L": 0b01, # Gauche
    "F": 0b10, # Avant
    "B": 0b11, # Arrière
}

def create_dance_blocks(moves):
    """Génère deux blocs de 512 octets : Header + Mouvements"""
    
    magic = b"STEP"
    version = 0x0001
    num_moves = len(moves)
    header = magic + struct.pack(">H", version) + struct.pack(">H", num_moves)
    header_block = header + b"\x00" * (512 - len(header))

    seq_bytes = bytearray()
    for dir_char, duration in moves:
        if dir_char not in direction_map:
            raise ValueError(f"Direction invalide: {dir_char}")
        byte = (direction_map[dir_char] << 6) | (min(duration, 63) & 0x3F)
        seq_bytes.append(byte)
    
    if len(seq_bytes) < 512:
        seq_bytes.append(0xFF)
        
    seq_block = seq_bytes + b"\x00" * (512 - len(seq_bytes))
    
    return header_block + seq_block

danse_1 = [("F", 10), ("R", 5), ("F", 10), ("L", 5), ("B", 10)]
danse_2 = [("R", 20), ("R", 20), ("R", 20), ("R", 20)]         
danse_3 = [("F", 5), ("B", 5), ("F", 5), ("B", 5), ("F", 30)]

all_dances = [danse_1, danse_2, danse_3]

with open("choreo.bin", "wb") as f:
    for i, moves in enumerate(all_dances):
        binary_data = create_dance_blocks(moves)
        f.write(binary_data)
