import pandas as pd

# ---------------------------------------------------------
# 1. Datei einlesen
# ---------------------------------------------------------
# Datei laden, Spalte A ignorieren (B:L) und Header erst einmal ignorieren
df = pd.read_excel('registered_vehicles.xlsx', sheet_name='FZ 3.1', usecols='B:L', skiprows=7, header=None)

# Header aus den ersten beiden Zeilen des Bereichs (B:Z) extrahieren
header_lvl_0 = df.iloc[0]
header_lvl_1 = df.iloc[1]

# Header setzen und die beiden Zeilen aus dem Datensatz entfernen
df.columns = [header_lvl_0, header_lvl_1]
df = df.drop([0, 1]).reset_index(drop=True)

# ---------------------------------------------------------
# 2. Den hierarchischen Header abflachen (Flatten)
# ---------------------------------------------------------
# Wenn Excel-Spalten verbunden sind, füllt Pandas die leeren Sub-Kategorien oft mit "Unnamed".
# Ziel sind saubere, eindimensionale Spaltennamen.
neue_spalten = []
for col in df.columns:
    lvl_0 = str(col[0]).strip() # Hauptkategorie
    lvl_1 = str(col[1]).strip() # Subkategorie

    # Wenn es keine echte Subkategorie gibt (Pandas nennt es "Unnamed..."),
    # nehmen wir nur die Hauptkategorie. Sonst verbinden wir beide mit Unterstrich.
    if 'Unnamed' in lvl_1:
        neue_spalten.append(lvl_0)
    else:
        neue_spalten.append(f"{lvl_0}_{lvl_1}")

df.columns = neue_spalten

# Um im Skript flexibel zu bleiben, greifen wir auf die ersten drei Spalten über ihren Index zu.
# (Falls die Namen durch das Abflachen leicht variieren)
col_land = df.columns[0]
col_bezirk = df.columns[1]
col_gemeinde = df.columns[2]

# ---------------------------------------------------------
# 3. Verbundene Zeilen auflösen (Forward Fill)
# ---------------------------------------------------------
# Pandas hat die verbundenen Excel-Zellen bereits als NaN (leer) eingelesen.
# Wir füllen diese nun einfach mit dem jeweils letzten gültigen Wert nach unten auf.
df[col_land] = df[col_land].ffill()
df[col_bezirk] = df[col_bezirk].ffill()

# ---------------------------------------------------------
# 4. Aggregierte Summenzeilen filtern
# ---------------------------------------------------------
# a) Die Bezirk-Summen filtern (wo in der Gemeinde-Spalte "ZUSAMMEN" steht)
# na=False verhindert Fehler, falls leere Zellen existieren. case=False ignoriert Groß-/Kleinschreibung.
df = df[~df[col_gemeinde].astype(str).str.contains('ZUSAMMEN', na=False, case=False)]

# b) Die Bundesland-Summen filtern (wo in der Land-Spalte "... INSGESAMT" steht)
df = df[~df[col_land].astype(str).str.contains('INSGESAMT', na=False, case=False)]

# Optional: Evtl. komplett leere Artefakt-Zeilen am Dateiende entfernen
df = df.dropna(subset=[col_gemeinde])

# ---------------------------------------------------------
# 5. Export für Exasol
# ---------------------------------------------------------
df.to_csv('registered_vehicles_flat.csv', index=False, sep=';', encoding='utf-8')