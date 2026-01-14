# Opcodes autorisés uniquement
AVANT    = 0x01
ARRIERE  = 0x02
PIVOT_D  = 0x03
PIVOT_G  = 0x04
STOP     = 0x05
WAIT     = 0xFE

def move(opcode, duration):
    """Combine une commande et un délai [Opcode, 0xFE, Durée]"""
    return [opcode, WAIT, duration]

def create_sector(moves):
    """Crée 512 octets : Signature 'ST' + Mouvements + Fin 0xFF + Padding"""
    # Signature attendue par SD_IndexDances (Little Endian 'ST' = 0x5453)
    sector = bytearray([0x53, 0x54]) 
    sector.extend(moves)
    sector.append(0xFF) # Fin de chorégraphie
    
    # Remplissage à 512 octets
    sector.extend([0x00] * (512 - len(sector)))
    return sector

def create_dance_block(moves):
    """Génère le duo Secteur Header + Secteur Data (1024 octets)"""
    # Votre code SD_IndexDances cherche 'ST' au début d'un secteur
    # On crée un header vide avec 'ST' puis le secteur de données avec 'ST'
    header = create_sector([]) # Juste la signature
    data = create_sector(moves)
    return header + data

# --- CONSTRUCTION DES DANSES ---

# Danse 1 : Carré (Avance -> Tourne à droite x4)
danse_triangle = []
for _ in range(3):
    danse_triangle.extend(move(AVANT, 3))
    danse_triangle.extend(move(PIVOT_D, 2)) # Pivot plus long pour l'angle
danse_triangle.extend(move(STOP, 0))

danse_moonwalk = move(AVANT, 4)
for _ in range(4):
    danse_moonwalk.extend(move(ARRIERE, 1))
    danse_moonwalk.extend(move(STOP, 1))
danse_moonwalk.extend(move(STOP, 0))

danse_sentinelle = []
for _ in range(3):
    danse_sentinelle.extend(move(PIVOT_G, 2))
    danse_sentinelle.extend(move(STOP, 2))
    danse_sentinelle.extend(move(PIVOT_D, 2))
    danse_sentinelle.extend(move(STOP, 2))
danse_sentinelle.extend(move(STOP, 0))

danse_tournis = (
    move(PIVOT_D, 5) + 
    move(PIVOT_D, 3) + 
    move(PIVOT_D, 1) + 
    move(PIVOT_G, 5) + 
    move(STOP, 0)
)

with open("choreo_all.bin", "wb") as f:
    f.write(create_dance_block(danse_moonwalk))   # Secteurs 0 & 1
    f.write(create_dance_block(danse_sentinelle))  # Secteurs 2 & 3
    f.write(create_dance_block(danse_tournis))  # Secteurs 4 & 5
    f.write(create_dance_block(danse_triangle))  # Secteurs 4 & 5

print("Fichier choreo_all.bin généré avec succès.")