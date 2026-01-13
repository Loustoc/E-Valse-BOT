import struct

# Motor states
OFF = 0b00  # Motor off
FWD = 0b01  # Motor forward
BCK = 0b10  # Motor backward

def move(left_motor, right_motor, duration):
    """
    Create a move tuple.

    Args:
        left_motor: OFF, FWD, or BCK
        right_motor: OFF, FWD, or BCK
        duration: 0-255 time units

    Returns:
        Tuple of (motor_byte, duration)
    """
    motor_byte = (left_motor << 2) | right_motor
    return (motor_byte, min(duration, 255))

def create_dance_blocks(moves, motor_speed=0x155, led_period=500):
    """
    Generate two 512-byte blocks: Header + Moves

    Header format (v3):
        Offset 0-3:   "STEP" (magic)
        Offset 4-5:   Version (0x0003)
        Offset 6-7:   Number of moves
        Offset 8-9:   Motor speed (PWM 0x000-0x3FF)
        Offset 10-11: LED blink period (ms)
        Offset 12-511: Padding (zeros)

    Moves format (2 bytes per move):
        Byte 1: Motor control
            Bits 3-2: Left motor  (00=off, 01=fwd, 10=back)
            Bits 1-0: Right motor (00=off, 01=fwd, 10=back)
        Byte 2: Duration (0-255)

        End marker: 0xFF 0xFF
    """
    magic = b"STEP"
    version = 0x0003
    num_moves = len(moves)

    header = (
        magic +
        struct.pack(">H", version) +
        struct.pack(">H", num_moves) +
        struct.pack(">H", motor_speed) +
        struct.pack(">H", led_period)
    )
    header_block = header + b"\x00" * (512 - len(header))

    # Build moves block (2 bytes per move)
    moves_bytes = bytearray()
    for motor_byte, duration in moves:
        moves_bytes.append(motor_byte)
        moves_bytes.append(duration)

    # Add end marker
    moves_bytes.append(0xFF)
    moves_bytes.append(0xFF)

    moves_block = bytes(moves_bytes) + b"\x00" * (512 - len(moves_bytes))

    return header_block + moves_block


# ============================================
# Helper moves for creating dances
# ============================================
def forward(duration):
    """Both motors forward"""
    return move(FWD, FWD, duration)

def backward(duration):
    """Both motors backward"""
    return move(BCK, BCK, duration)

def rotate_left(duration):
    """Left backward + Right forward"""
    return move(BCK, FWD, duration)

def rotate_right(duration):
    """Left forward + Right backward"""
    return move(FWD, BCK, duration)

def turn_left(duration):
    """Right motor only"""
    return move(OFF, FWD, duration)

def turn_right(duration):
    """Left motor only"""
    return move(FWD, OFF, duration)

def stop(duration):
    """Both motors off (pause)"""
    return move(OFF, OFF, duration)

# ============================================
# DANCE2
# ============================================

DANCE2 = [
    rotate_right(14),      # Rotate left for 21 units
    forward(20),          # Go forward for 10 units
    turn_left(14),        # Turn left (left off, right fwd) for 10 units
]

DANCE2_SPEED = 0x075      # Slow speed for waltz (higher = slower)
DANCE2_LED = 678         # 1 second LED period


# ============================================
# VALSE dance (converted from danses_moves.s)
# ============================================
# Original VALSE (slow waltz):
#   1. Left motor backward + Right motor forward (rotate left) - 21 units
#   2. Both motors forward - 10 units
#   3. Left motor off + Right motor forward (turn left) - 10 units

DANSE1 = [
    rotate_left(4),      # Rotate left for 21 units
    turn_left(20),  
    turn_right(8),  
    forward(10),          # Go forward for 10 units
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2),  
    turn_left(4),  
    turn_right(2)
]

DANSE1_SPEED = 0x84      # Slow speed for waltz (higher = slower)
DANSE1_LED = 298         # 1 second LED period


# ============================================
# Component moves for ITALODISCO
# ============================================
def frontback():
    """Forward then backward"""
    return [forward(1), backward(1)]

def walk():
    """Walk pattern: forward, rotate right, forward, rotate left"""
    return [
        forward(1),
        rotate_right(1),  # Note: duration ~1.5 in original, using 1
        forward(1),
        rotate_left(1),
    ]

def walk_back():
    """Walk backward pattern"""
    return [
        backward(1),
        rotate_left(1),
        backward(1),
        rotate_right(1),
    ]

def star():
    """Star pattern"""
    return [
        forward(1),
        backward(1),
        move(FWD, BCK, 3),  # Left fwd + Right back
    ]

def circle_right(duration=6):
    """Circle right: left backward + right forward"""
    return [rotate_left(duration)]

def circle_left(duration=6):
    """Circle left: left forward + right backward"""
    return [rotate_right(duration)]

def demicircle_right():
    """Half circle right"""
    return circle_right(3)

def demicircle_left():
    """Half circle left"""
    return circle_left(3)

def front(duration=4):
    """Go backward (robot moves forward)"""
    return [backward(duration)]

def frontshort():
    """Short forward"""
    return front(2)


# ============================================
# Available dances
# ============================================
DANCES = {
    "dance1": (DANSE1, DANSE1_SPEED, DANSE1_LED),
    "dance2": (DANCE2, DANCE2_SPEED, DANCE2_LED),
}


# ============================================
# Generate the binary file
# ============================================
if __name__ == "__main__":
    import sys
    dance_name = sys.argv[1] if len(sys.argv) > 1 else "all"

    # Special case: generate combined binary with all dances
    if dance_name == "all":
        output_file = "choreo_all.bin"
        total_bytes = 0
        # TEST: Use valse twice to check if issue is with dance position
        dance_list = ["dance1", "dance2"] 
        with open(output_file, "wb") as f:
            for name in dance_list:
                dance, speed, led = DANCES[name]
                binary_data = create_dance_blocks(dance, speed, led)
                f.write(binary_data)
                total_bytes += len(binary_data)
        print(f"Created {output_file} ({total_bytes} bytes)")
        print(f"  Contains: {dance_list[0]} (sectors 0-1), {dance_list[1]} (sectors 2-3)")
        sys.exit(0)

    if dance_name not in DANCES:
        print(f"Unknown dance: {dance_name}")
        print(f"Available dances: {', '.join(DANCES.keys())}, all")
        sys.exit(1)

    dance, motor_speed, led_period = DANCES[dance_name]

    output_file = f"choreo_{dance_name}.bin"
    with open(output_file, "wb") as f:
        binary_data = create_dance_blocks(dance, motor_speed, led_period)
        f.write(binary_data)

    print(f"Created {output_file} ({len(binary_data)} bytes)")
    print(f"  Dance: {dance_name.upper()}")
    print(f"  Version: 3 (2-byte motor format)")
    print(f"  Motor speed: 0x{motor_speed:03X} ({'slow' if motor_speed > 0x100 else 'fast'})")
    print(f"  LED period: {led_period}ms")
    print(f"  Moves: {len(dance)}")
    print()
    print("Move details:")
    for i, (motor, dur) in enumerate(dance):
        left = (motor >> 2) & 0x03
        right = motor & 0x03
        left_str = ["OFF", "FWD", "BCK", "???"][left]
        right_str = ["OFF", "FWD", "BCK", "???"][right]
        print(f"  {i+1:3}. L={left_str:3} R={right_str:3} dur={dur}")

    print()
    print("To write to SD card:")
    print(f"  dd if={output_file} of=/dev/sdX bs=512")
