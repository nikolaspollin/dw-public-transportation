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
      UPDATE Staging_Registered_Vehicles SET error_info = error_info||'Non-Integer value for fact column'
          WHERE REGEXP_INSTR(MOTORCYCLES, '^[0-9]+$') < 1 OR REGEXP_INSTR(PASSENGER_VEHICLES_TOTAL, '^[0-9]+$') < 1
          OR REGEXP_INSTR(PASSENGER_VEHICLES_COMMERCIAL, '^[0-9]+$') < 1;
      ```
- Bei den Haltestellendaten habe ich bspw. überprüft, ob der jeweilige Eintrag eine deutschlandweite ID oder lokale ID nutzt:
  - ```sql
        UPDATE Staging_Stops SET error_info = error_info||'Local Stop ID instead of Delphi ID' WHERE STOP_ID NOT LIKE 'de:%:%';
    ```

* Harmonization / Normalization:

- Die Daten haben sich im Wesentlichen nicht überschnitten, da die Datenquellen unterschiedliche Real-World-Objekte betrachten.
- Allerdings musste bspw. bei den Bevölkerungsdaten der amtliche Gemeindeschlüssel vereinheitlicht werden.
  - In den meisten anderen Daten wurde er als 8-Stellige, mit Nullen aufgefüllte, Zahl dargestellt.
  - In den Bevölkerungsdaten wurden allerdings nur die Nicht-Null Stellen dargestellt, weshalb von rechts mit Nullen aufgefüllt werden musste.
  - ```sql
    UPDATE Staging_Population SET SPATIAL_IDENTIFICATION = rpad(SPATIAL_IDENTIFICATION, 8, '0') WHERE length(SPATIAL_IDENTIFICATION) < 8;
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
         (T.WHEELCHAIR_ACCESSIBLE = 1) AS WHEELCHAIR_ACCESSIBLE, (T.BIKES_ALLOWED = 1) AS BIKES_ALLOWED, R.ROUTE_SHORT_NAME, R.ROUTE_LONG_NAME, ETM.ROUTE_TYPE,
         ETM.MAIN_CATEGORY_DESC, ETM.SUB_CATEGORY_DESC, A.AGENCY_NAME
  FROM Staging_Trips T
         JOIN Staging_Routes R ON T.ROUTE_ID = R.ROUTE_ID
         JOIN Staging_GTFS_Extended_Type_Mapping ETM ON R.ROUTE_TYPE = ETM.ROUTE_TYPE
         JOIN Staging_Agencies A ON R.AGENCY_ID = A.AGENCY_ID
  ) AS src
ON target.GTFS_TRIP_ID = src.TRIP_ID
WHEN MATCHED THEN
  UPDATE SET target.TRIP_HEADSIGN = src.TRIP_HEADSIGN, target.TRIP_SHORT_NAME = src.TRIP_SHORT_NAME, target.DIRECTION  = src.DIRECTION,
             target.WHEELCHAIR_ACCESSIBLE = src.WHEELCHAIR_ACCESSIBLE, target.BIKES_ALLOWED = src.BIKES_ALLOWED, target.ROUTE_SHORT_NAME = src.ROUTE_SHORT_NAME,
             target.ROUTE_LONG_NAME = src.ROUTE_LONG_NAME, target.TRANSPORT_MODE_CODE = src.ROUTE_TYPE, target.TRANSPORT_MODE_MAIN_CATEGORY = src.MAIN_CATEGORY_DESC,
             target.TRANSPORT_MODE_SUB_CATEGORY = src.SUB_CATEGORY_DESC, target.AGENCY_NAME = src.AGENCY_NAME
WHEN NOT MATCHED THEN
  INSERT (GTFS_TRIP_ID, TRIP_HEADSIGN, TRIP_SHORT_NAME, DIRECTION, WHEELCHAIR_ACCESSIBLE,
          BIKES_ALLOWED, ROUTE_SHORT_NAME, ROUTE_LONG_NAME, TRANSPORT_MODE_CODE,
          TRANSPORT_MODE_MAIN_CATEGORY, TRANSPORT_MODE_SUB_CATEGORY, AGENCY_NAME)
  VALUES (
           src.TRIP_ID, src.TRIP_HEADSIGN, src.TRIP_SHORT_NAME, src.DIRECTION,
           src.WHEELCHAIR_ACCESSIBLE, src.BIKES_ALLOWED, src.ROUTE_SHORT_NAME, src.ROUTE_LONG_NAME,
           src.ROUTE_TYPE, src.MAIN_CATEGORY_DESC,
           src.SUB_CATEGORY_DESC, src.AGENCY_NAME
         );
```

TODO
## Analytical Queries
*Write 7 SQL queries here. These can be your query ideas from your presentation (Challenge 1), but can also be other queries. Write at least one query with `GROUPING SETS` (or `ROLLUP` or `CUBE`) , one with a window function (no ranking), one with a ranking function, one with a statistical function (e.g., `STDEV_POP`), and one skyline query. Start each query with a comment that describes the query. (Ex. Sheet 6)*

```sql
-- Query 1: GROUPING SETS / ROLLUP / CUBE
-- 🖊️ 
SELECT 🖊️ 
```
```sql
-- Query 2: Window Function (no ranking) 
-- 🖊️ 
SELECT 🖊️ 
```
```sql
-- Query 3: Window Function (ranking query)
-- 🖊️ 
SELECT 🖊️ 
```
```sql
-- Query 4: Statistical Function
-- 🖊️ 
SELECT 🖊️ 
```
```sql
-- Query 5: Skyline Query
-- 🖊️ 
SELECT 🖊️ 
```
```sql
-- Query 6: 
-- 🖊️ 
SELECT 🖊️ 
```
```sql
-- Query 7: 
-- 🖊️ 
SELECT 🖊️ 
```


**Please check: Have you written your name on the very top?**
