Data Warehousing | Summer Semester 2026 | Prof. Schildgen | OTH Regensburg

-----

**Name:**  Nikolas Pollin

# Challenge 4: Data Integration and Analytical Queries

## Title

Auswirkungen des ÖPNV Angebots im ländlichen Raum


## Data Transformation
*How did you perform your data transformation? Fill out the following list with short answers and optionally one example SQL query each. Which tasks were necessary for your project? Why? Why not? How did you do it? Write at least one SQL query here. (Ex. Sheet 4, Exercise 1)*

* Checking data quality and fixing data errors:

- Ich bin für jede Tabelle jede Spalte durchgegangen und habe mir überlegt, welche Werte insgesamt im Feld möglich sind und wie gültige Werte aussehen müssen.
- Häufig bin ich durch die Daten per *LIMIT* und *OFFSET* gesprungen und habe stichprobenartig die Daten überprüft.
- Viele der Spalten in der Staging Area waren *VARCHARS*, da auch oft bei Zahlenwerten einzelne Sondersymbole (z.B. X für keine Daten oder . für ungenaue Angaben) vorkamen (bspw. bei Bevölkerungsdaten). 
- In diesen Fällen konnte ich mit einer Regular Expression leicht nachprüfen, ob nur gültige Zahlenwerte enthalten sind und entsprechende Sonderzeichen mit NULL ersetzen.
  - ```sql
      SELECT * FROM Staging_Population WHERE REGEXP_INSTR(TOTAL_POPULATION, '^[0-9]+$') < 1;
      SELECT * FROM Staging_Population WHERE REGEXP_INSTR(MALE_POPULATION, '^[0-9]+$') < 1;
      SELECT * FROM Staging_Population WHERE REGEXP_INSTR(FEMALE_POPULATION, '^[0-9]+$') < 1;
      ```
- Auch bei den Fahrzeugzulassungen wurden teils Symbole in den Fakten-Spalten eingesetzt:
  - ```sql
      UPDATE Staging_Registered_Vehicles 
                SET error_info = error_info||'Non-Integer value for fact column'
          WHERE REGEXP_INSTR(MOTORCYCLES, '^[0-9]+$') < 1 
                OR REGEXP_INSTR(PASSENGER_VEHICLES_TOTAL, '^[0-9]+$') < 1
                OR REGEXP_INSTR(PASSENGER_VEHICLES_COMMERCIAL, '^[0-9]+$') < 1;
      ```
- Bei den Haltestellendaten habe ich bspw. überprüft, ob der jeweilige Eintrag eine deutschlandweite ID oder lokale ID nutzt:
  - ```sql
        UPDATE Staging_Stops SET error_info = error_info||'Local Stop ID instead of Delphi ID' 
                WHERE STOP_ID NOT LIKE 'de:%:%';
    ```

* Harmonization / Normalization:

- Die Daten haben sich im Wesentlichen nicht überschnitten, da die Datenquellen unterschiedliche Real-World-Objekte betrachten.
- Allerdings musste bspw. bei den Bevölkerungsdaten der amtliche Gemeindeschlüssel vereinheitlicht werden.
  - In den meisten anderen Daten wurde er als 8-Stellige, mit Nullen aufgefüllte, Zahl dargestellt.
  - In den Bevölkerungsdaten wurden allerdings nur die Nicht-Null Stellen dargestellt, weshalb von rechts mit Nullen aufgefüllt werden musste.
  - ```sql
    UPDATE Staging_Population SET SPATIAL_IDENTIFICATION = rpad(SPATIAL_IDENTIFICATION, 8, '0') 
            WHERE length(SPATIAL_IDENTIFICATION) < 8;
    ```
- Außerdem werden Dates nicht mehr als *VARCHARS* im YYYYMMDD Format, sondern als Date-Objekt gespeichert

* Deduplication: 

- Auch hier hatte ich fast keine Problemfälle, da die Datenquellen ja keine inhaltlichen Überschneidungen hatten.
- Einziger Sonderfall sind die Staging_Stops, die aus den GTFs Soll-Fahrplandaten stammen und direkt mit den ÖPNV-Fahrten verknüpft sind, sowie die Staging_Extended_Stops, aus dem deutschlandweiten Haltestellenverzeichnis.
- Da ich den zweiten Datensatz aber eben zur Vervollständigung des ersten mitaufgenommen habe, fällt er nicht wirklich unter Duplication.

* Fuzzy entity matching (Levensthein, Soundex, ...): 

- Auch hier sind nur wieder die regulären und die Extended-Stops relevant für Vergleiche.
- Außerdem gibt es nur den Haltestellennamen als möglichen Vergleichspartner, alle anderen Felder eignen sich überhaupt nicht.
- Da Haltestellennamen sehr häufig nicht eindeutig, sondern nur Stadtweit-identifizierbar sind, eignen sich weder Levensthein noch Soundex wirklich dafür.
- Außerdem ist Levensthein selbst nach längerem Warten nicht durchgelaufen
  - ```sql
     SELECT count(*) FROM Staging_Stops S1, Staging_Extended_Stops S2
        WHERE S1.STOP_NAME = S2.NAME OR edit_distance(S1.STOP_NAME, S2.NAME) < 3;
    ```
- Soundex findet deutlich zu viele Matches und ist praktisch unbrauchbar. 
  - ```sql
    SELECT count(*) FROM Staging_Stops S1, Staging_Extended_Stops S2
        WHERE soundex(S1.STOP_NAME) = soundex(S2.NAME);
    ```

* Data Fusion (merge multiple rows into one target row):

- Ist nicht aufgetreten, da bspw. GTFS Daten duplikatfrei sind


## Data Integration
*Write down a MERGE command to integrate data from your staging area into your target data-warehouse schema: (Ex. Sheet 4, Exercise 2)*

```sql
        MERGE INTO Dim_Trips AS target
        USING (
          SELECT T.TRIP_ID, T.TRIP_HEADSIGN, T.TRIP_SHORT_NAME,
                 CASE WHEN T.DIRECTION_ID = 1 THEN 'Rückrichtung' ELSE 'Hinrichtung' END as DIRECTION,
                 (T.WHEELCHAIR_ACCESSIBLE = 1) AS WHEELCHAIR_ACCESSIBLE, 
                 (T.BIKES_ALLOWED = 1) AS BIKES_ALLOWED, 
                 R.ROUTE_SHORT_NAME, R.ROUTE_LONG_NAME, ETM.ROUTE_TYPE,
                 ETM.MAIN_CATEGORY_DESC, ETM.SUB_CATEGORY_DESC, A.AGENCY_NAME
          FROM Staging_Trips T
                 JOIN Staging_Routes R ON T.ROUTE_ID = R.ROUTE_ID
                 JOIN Staging_GTFS_Extended_Type_Mapping ETM ON R.ROUTE_TYPE = ETM.ROUTE_TYPE
                 JOIN Staging_Agencies A ON R.AGENCY_ID = A.AGENCY_ID
          ) AS src
        ON target.GTFS_TRIP_ID = src.TRIP_ID
        WHEN MATCHED THEN
          UPDATE SET target.TRIP_HEADSIGN = src.TRIP_HEADSIGN, 
                     target.TRIP_SHORT_NAME = src.TRIP_SHORT_NAME, 
                     target.DIRECTION  = src.DIRECTION, 
                     target.WHEELCHAIR_ACCESSIBLE = src.WHEELCHAIR_ACCESSIBLE, 
                     target.BIKES_ALLOWED = src.BIKES_ALLOWED,
                     target.ROUTE_SHORT_NAME = src.ROUTE_SHORT_NAME,
                     target.ROUTE_LONG_NAME = src.ROUTE_LONG_NAME, 
                     target.TRANSPORT_MODE_CODE = src.ROUTE_TYPE, 
                     target.TRANSPORT_MODE_MAIN_CATEGORY = src.MAIN_CATEGORY_DESC,
                     target.TRANSPORT_MODE_SUB_CATEGORY = src.SUB_CATEGORY_DESC, 
                     target.AGENCY_NAME = src.AGENCY_NAME
        WHEN NOT MATCHED THEN
          INSERT (GTFS_TRIP_ID, TRIP_HEADSIGN, TRIP_SHORT_NAME, DIRECTION, WHEELCHAIR_ACCESSIBLE,
                  BIKES_ALLOWED, ROUTE_SHORT_NAME, ROUTE_LONG_NAME, TRANSPORT_MODE_CODE,
                  TRANSPORT_MODE_MAIN_CATEGORY, TRANSPORT_MODE_SUB_CATEGORY, AGENCY_NAME)
          VALUES (
                   src.TRIP_ID, src.TRIP_HEADSIGN, src.TRIP_SHORT_NAME, src.DIRECTION,
                   src.WHEELCHAIR_ACCESSIBLE, src.BIKES_ALLOWED, 
                   src.ROUTE_SHORT_NAME, src.ROUTE_LONG_NAME,
                   src.ROUTE_TYPE, src.MAIN_CATEGORY_DESC,
                   src.SUB_CATEGORY_DESC, src.AGENCY_NAME
                 );
```

## Analytical Queries
*Write 7 SQL queries here. These can be your query ideas from your presentation (Challenge 1), but can also be other queries. Write at least one query with `GROUPING SETS` (or `ROLLUP` or `CUBE`) , one with a window function (no ranking), one with a ranking function, one with a statistical function (e.g., `STDEV_POP`), and one skyline query. Start each query with a comment that describes the query. (Ex. Sheet 6)*

```sql
  -- Query 1: GROUPING SETS / ROLLUP / CUBE
  -- Wie viele Motorräder sind in den jeweiligen Gemeinden, Kreisen & Bundesländern zugelassen 
  -- (hierarchisch aufgeschlüsselt)?
  
    SELECT
          -- Lesbarer Wert für NULL Werte bei gröberer Hierarchiestufe
          coalesce(DM.STATE_NAME, 'Alle Bundesländer') AS Bundesland,
          coalesce(DM.COUNTY_NAME, 'Alle Kreise') AS Kreis,
          coalesce(DM.NAME, 'Alle Gemeinden') AS Gemeinde,
          SUM(FRV.AMOUNT) AS Anzahl_Motorräder 
      FROM Fact_Registered_Vehicles FRV
      JOIN Dim_Vehicle_Type DVT ON FRV.VEHICLE_TYPE_ID = DVT.VEHICLE_TYPE_ID
      JOIN Dim_Municipalities DM ON FRV.MUNICIPALITY_CODE = DM.MUNICIPALITY_CODE
      -- In den Daten gibt es keine kommerziellen Motorräder, 
      --  daher hier kein Aggregieren der verschiedenen Types
      WHERE DVT.TYPE = 'Motorrad' AND FRV."date" = '2025-01-01'
      GROUP BY ROLLUP ( 
          (DM.STATE_CODE, DM.STATE_NAME), 
          (DM.COUNTY_CODE, DM.COUNTY_NAME), 
          (DM.MUNICIPALITY_CODE, DM.NAME) 
        );
```

```sql
  -- Query 2: Window Function (no ranking) 
  -- Wie oft halten Verkehrsmittel im Jahr 2026 in den verschiedenen Gemeinden und 
  -- wie hoch ist dieser Anteil an der Menge der Halte im gesamten Landkreis? 
  
  WITH Municipality_Stops AS (
      SELECT DM.COUNTY_CODE, DM.COUNTY_NAME, DM.MUNICIPALITY_CODE, DM.NAME,
             DM.SPATIAL_TYPOLOGY_DESC, DM.MUNICIPALITY_TYPE_DESC,
             COUNT("FS".STOP_SEQUENCE) AS Halte_Gesamt
          FROM Fact_Stops "FS"
          JOIN Dim_Stations DS ON "FS".STATION_ID = DS.STATION_ID
          JOIN Dim_Municipalities DM ON DS.MUNICIPALITY_CODE = DM.MUNICIPALITY_CODE
          -- Nur für bestimmtes Jahr (da STOCK Datentyp)
          WHERE "FS"."date" BETWEEN '2026-01-01' AND '2026-12-31'
          -- Gruppieren nach Gemeinde
          GROUP BY (
                    DM.COUNTY_CODE, DM.COUNTY_NAME, 
                    DM.MUNICIPALITY_CODE, DM.NAME, 
                    DM.SPATIAL_TYPOLOGY_DESC, DM.MUNICIPALITY_TYPE_DESC
                   )
      )
  SELECT MS.COUNTY_CODE AS "Kreis-AGS", MS.COUNTY_NAME AS Landkreis, MS.MUNICIPALITY_CODE AS AGS, 
         MS.NAME AS Gemeinde, MS.SPATIAL_TYPOLOGY_DESC AS "Raumtyp", 
         MS.MUNICIPALITY_TYPE_DESC AS "Gemeindeart",
         MS.Halte_Gesamt AS "Gesamte Halte in Gemeinde", 
         SUM(MS.Halte_Gesamt) OVER (partition by MS.COUNTY_CODE) AS "Gesamte Halte in Landkreis",
         ROUND(
                 (MS.Halte_Gesamt * 100.0) / (SUM(MS.Halte_Gesamt) OVER (partition by MS.COUNTY_CODE)),
                 4
         ) AS "Prozentualer Halteanteil im Landkreis"
      FROM Municipality_Stops MS;
```

```sql
  -- Query 3: Window Function (ranking query)
  -- Welche sind die 3 größten Gemeinden (nach Einwohnerzahl) in jedem Bundesland (2024)?
    
  WITH 
      Aggregated_Population AS (
        SELECT FC.MUNICIPALITY_CODE, SUM(FC.AMOUNT) AS Einwohner_Gesamt
            FROM Fact_Census FC
            -- Stichtag
            WHERE "date" = '2024-12-31' AND FC.AMOUNT IS NOT NULL
            GROUP BY FC.MUNICIPALITY_CODE
  ), Ranked_Municipalities AS (
      SELECT DM.STATE_CODE, DM.STATE_NAME, DM.MUNICIPALITY_CODE, DM.NAME, AP.Einwohner_Gesamt,
             -- Für Fragestellung kommen nur lückenlose Ränge infrage
             DENSE_RANK() OVER (partition by DM.STATE_CODE order by AP.Einwohner_Gesamt DESC) AS Rang
          FROM Aggregated_Population AP
          JOIN Dim_Municipalities DM ON AP.MUNICIPALITY_CODE = DM.MUNICIPALITY_CODE
  )
  SELECT RM.STATE_CODE AS "Bundesland-Kennziffer", RM.STATE_NAME AS Bundesland, RM.MUNICIPALITY_CODE AS AGS, 
         RM.NAME AS Gemeinde, RM.Einwohner_Gesamt AS "Einwohnerzahl in Gemeinde", RM.Rang
      FROM Ranked_Municipalities RM
      -- Alle größeren Werte herausfiltern
      WHERE RM.Rang <= 3
      ORDER BY RM.STATE_NAME, RM.Rang; 
```

```sql
  -- Query 4: Statistical Function
  -- Korreliert ein geringes ÖPNV-Angebot (gemessen an Verkehrsmittel-Halten) mit 
  --  einer überdurchschnittlichen PKW-Zulassung?
    
  WITH
      -- Einwohner für normalisierte Vergleiche
      Aggregated_Population AS (
      SELECT FC.MUNICIPALITY_CODE, SUM(FC.AMOUNT) AS Einwohner_Gesamt 
          FROM Fact_Census FC
          WHERE FC."date" = '2024-12-31'
          GROUP BY FC.MUNICIPALITY_CODE
  ), -- PKWs pro Gemeinde
      Aggregated_Vehicles AS (
      SELECT FRV.MUNICIPALITY_CODE, SUM(FRV.AMOUNT) AS PKW_Gesamt
          FROM Fact_Registered_Vehicles FRV
          JOIN Dim_Vehicle_Type DVT ON FRV.VEHICLE_TYPE_ID = DVT.VEHICLE_TYPE_ID
          WHERE DVT.TYPE = 'PKW' AND FRV."date" = '2025-01-01'
          GROUP BY FRV.MUNICIPALITY_CODE
  ), Municipality_Stops AS (
      SELECT DS.MUNICIPALITY_CODE, COUNT("FS".STOP_SEQUENCE) AS Halte_Gesamt
          FROM Fact_Stops "FS"
          JOIN Dim_Stations DS ON "FS".STATION_ID = DS.STATION_ID
          -- Nur für bestimmtes Jahr (da STOCK Datentyp)
          WHERE "FS"."date" BETWEEN '2026-01-01' AND '2026-12-31'
          -- Gruppieren nach Gemeinde
          GROUP BY DS.MUNICIPALITY_CODE
  ), Municipality_Densities AS (
      -- Coalesce: Fallback 0 für NULL Werte
      -- NullIf: Verhindert Division und gibt NULL aus, falls Einwohner 0 sind
      SELECT AP.MUNICIPALITY_CODE, 
             (COALESCE(MS.Halte_Gesamt, 0) * 1000.0) / NULLIF(AP.Einwohner_Gesamt, 0) AS Halte_Dichte, 
             (COALESCE(AV.PKW_Gesamt, 0) * 1000.0) / NULLIF(AP.Einwohner_Gesamt, 0) AS PKW_Dichte
          FROM Aggregated_Population AP
          LEFT JOIN Aggregated_Vehicles AV ON AP.MUNICIPALITY_CODE = AV.MUNICIPALITY_CODE
          LEFT JOIN Municipality_Stops MS ON AP.MUNICIPALITY_CODE = MS.MUNICIPALITY_CODE
  )
  SELECT DM.SPATIAL_SETTLEMENT_CODE AS RBG, DM.SPATIAL_SETTLEMENT_DESC AS "Räumliche Besiedelung",
         ROUND(CORR(MD.Halte_Dichte, MD.PKW_Dichte), 3) AS "Korrelation Halte-Dichte / PKW-Dichte", 
         ROUND(STDDEV(MD.PKW_Dichte), 3) AS "Standardabweichung PKW-Dichte"
      FROM Municipality_Densities MD
      JOIN Dim_Municipalities DM ON MD.MUNICIPALITY_CODE = DM.MUNICIPALITY_CODE
      GROUP BY (DM.SPATIAL_SETTLEMENT_CODE, DM.SPATIAL_SETTLEMENT_DESC); 
```

```sql
  -- Query 5: Skyline Query
  -- Welche ländlichen Gemeinden haben die beste Flächenabdeckung 
  -- (höchste Anzahl Haltestellen) oder beste Taktung (Anzahl Halte)?
    
  WITH Municipality_Stops AS (
      SELECT DM.MUNICIPALITY_CODE, DM.NAME, 
             COUNT("FS".STOP_SEQUENCE) AS Halte_Gesamt, 
             COUNT(DISTINCT "FS".STATION_ID) AS Haltestellen_Anzahl 
          FROM Fact_Stops "FS"
          JOIN Dim_Stations DS ON "FS".STATION_ID = DS.STATION_ID
          JOIN Dim_Municipalities DM ON DS.MUNICIPALITY_CODE = DM.MUNICIPALITY_CODE
          WHERE "FS"."date" BETWEEN '2026-01-01' AND '2026-12-31'
              -- "Zentral" & "Sehr zentral" herausfiltern
              AND DM.GEOGRAPHICAL_LOCATION_CODE > 2
          GROUP BY (DM.MUNICIPALITY_CODE, DM.NAME)
  )
  SELECT MUNICIPALITY_CODE AS AGS, NAME AS Gemeinde, Halte_Gesamt AS "Anzahl Halte", 
         Haltestellen_Anzahl AS "Anzahl Haltestellen"
      FROM Municipality_Stops
      PREFERRING HIGH Halte_Gesamt PLUS HIGH Haltestellen_Anzahl; 
```

```sql
  -- Query 6: 
  -- Wie hoch war 2024 die durchschnittliche PKW Dichte in ländlichen Gegenden 
  -- im Vergleich zu Mittel- bis Großstädten?
  
  WITH 
      Aggregated_Vehicles AS (
        -- Alle PKWs für jede Gemeinde
        SELECT MUNICIPALITY_CODE, SUM(FRV.AMOUNT) AS Pkw_Gesamt
          FROM Fact_Registered_Vehicles FRV
          JOIN Dim_Vehicle_Type DVT ON FRV.VEHICLE_TYPE_ID = DVT.VEHICLE_TYPE_ID
          WHERE TYPE = 'PKW' AND "date" = '2025-01-01' 
          GROUP BY FRV.MUNICIPALITY_CODE
      ), 
      -- Alle Einwohner für jede Gemeinde
      Aggregated_Population AS (
          SELECT MUNICIPALITY_CODE, SUM(AMOUNT) AS Bevölkerung_Gesamt
          FROM Fact_Census FC 
          WHERE "date" = '2024-12-31'
          GROUP BY MUNICIPALITY_CODE
      )
  -- Gruppieren nach Städtisch & Ländlich und passende Durchschnitte ausrechnen
  SELECT 
          CASE 
              WHEN SPATIAL_TYPOLOGY_CODE > 53 THEN 'Ländliche Regionen'
              ELSE 'Mittel- bis Großstädte'
          END AS Gemeindeart,
          (SUM(AV.Pkw_Gesamt) * 1000 / SUM(AP.Bevölkerung_Gesamt)) AS "PKWs / 1000 Einwohner",
          (SUM(AV.Pkw_Gesamt) / SUM(DM.AREA_KM2)) AS "PKWs / km2"
      FROM Aggregated_Vehicles AV
      JOIN Aggregated_Population AP ON AV.MUNICIPALITY_CODE = AP.MUNICIPALITY_CODE
      JOIN Dim_Municipalities DM ON AV.MUNICIPALITY_CODE = DM.MUNICIPALITY_CODE 
      GROUP BY 1;
```

```sql
  -- Query 7: 
  -- In welchen ländlichen Gemeinden fahren weniger als 10 Busse am Tag?
    
  SELECT DM.MUNICIPALITY_CODE, DM.NAME, COUNT("FS".STOP_SEQUENCE) AS "Anzahl Halte"
      FROM Dim_Municipalities DM
      -- Left Joins, damit Gemeinden ohne Halte nicht herausgefiltert werden
      LEFT JOIN Dim_Stations DS ON DM.MUNICIPALITY_CODE = DS.MUNICIPALITY_CODE 
      LEFT JOIN Fact_Stops "FS" ON DS.STATION_ID = "FS".STATION_ID
                              -- Durchschnittstag (Mittwoch) für die Analyse betrachten 
                              -- (Durchschnittswerte würden Ergebnisse ggf. 
                              --    verzerren wegen Wochenenden etc)
                                  AND "date" = '2026-06-12'
      LEFT JOIN Dim_Trips DT ON "FS".TRIP_ID = DT.TRIP_ID
      WHERE DT.TRANSPORT_MODE_MAIN_CATEGORY = 'Bus'
          AND DM.SPATIAL_TYPOLOGY_CODE > 52 -- Keine Großstädte betrachten, falls dort keine 
                                            --  Daten zu Haltestellen existieren
      GROUP BY (DM.MUNICIPALITY_CODE, DM.NAME)
      HAVING COUNT("FS".STOP_SEQUENCE) < 10
      ORDER BY 3;
```