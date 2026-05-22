import pandas as pd

# ---------------------------------------------------------
# Datei einlesen
# ---------------------------------------------------------
# per skiprows=[1] zweite Zeile ignorieren (Erklärung des Headers)
df = pd.read_excel('spatial_classification.xlsx', sheet_name='Gemeindereferenz (inkl.Kreise)', skiprows=[1], usecols='A:EV', header=0)

# ---------------------------------------------------------
# Export für Exasol
# ---------------------------------------------------------
df.to_csv('spatial_classification_flat.csv', index=False, sep=';', encoding='utf-8')