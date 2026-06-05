/*
 Übungsblatt 4

 Da die Datenquellen alle unterschiedliche Real-World Objekte beinhalten, gibt es keine Duplikate.
 Einzige Ausnahme sind die Extended_Stops, die allerdings eher eine Erweiterung der regulären Stops als ein Duplikat sind.
 Da die Tabellen alle aus amtlichen Quellen kommen, gibt es keine tatsächlichen Data Errors.
 Manche Tabellen können aber ungünstige Formatierungen bzw. Darstellungen beinhalten.
 Außerdem sind die GTFS Daten normalisiert und auch die anderen Quellen enthalten keine Zeilen-Duplikate.
 */

-- TODO MERGE Befehl aus Übungsblatt 4 Exercise 2 fehlt noch

-- Agencies

SELECT * FROM Staging_Agencies;
SELECT * FROM Staging_Agencies WHERE agency_id IS NULL OR agency_id < 0;


-- Calender

SELECT * FROM Staging_Calender ORDER BY SERVICE_ID LIMIT 300 OFFSET 1200;
SELECT * FROM Staging_Calender where length(START_DATE) != 8 or length(END_DATE) != 8; -- Datumslänge muss fest 8 Zeichen erfüllen
SELECT * FROM Staging_Calender where MONDAY > 1 or TUESDAY > 1 or WEDNESDAY > 1 or THURSDAY > 1 or FRIDAY > 1 or SATURDAY > 1 or SUNDAY > 1;


-- Calender Dates

SELECT * FROM Staging_Calender_Dates ORDER BY SERVICE_ID LIMIT 200 OFFSET 300;
SELECT * FROM Staging_Calender_Dates WHERE EXCEPTION_TYPE > 2 or EXCEPTION_TYPE < 0;
SELECT * FROM Staging_Calender_Dates WHERE length("date") != 8;
SELECT * FROM Staging_Calender_Dates CD1 JOIN Staging_Calender_Dates CD2
         ON CD1.SERVICE_ID = CD2.SERVICE_ID AND CD1."date" = CD2."date" WHERE CD1.EXCEPTION_TYPE != CD2.EXCEPTION_TYPE;


-- Extended Stops

-- Child Stops haben keine eigenen Municipality Daten → MunicipalityCode hat dort Defaultwert 00000 und Municipality ist NULL
-- '-' muss in NULL transformiert werden (beim Merging oder Data Scrubbing)

-- Haben ihre eigene DHID im Parent Feld gesetzt, falls es kein darüberliegendes Parent mehr gibt
SELECT * FROM Staging_Extended_Stops WHERE DHID NOT LIKE 'de:%:%';
SELECT * FROM Staging_Extended_Stops WHERE PARENT IS NULL;

ALTER TABLE Staging_Extended_Stops ADD COLUMN error_info VARCHAR(2000);
UPDATE Staging_Extended_Stops SET error_info = error_info||'Municipality not set, ' WHERE MUNICIPALITYCODE = '00000000' OR MUNICIPALITY = '-';


-- Frequencies

SELECT * FROM Staging_Frequencies;

ALTER TABLE Staging_Frequencies ADD COLUMN error_info VARCHAR(2000);
UPDATE Staging_Frequencies SET error_info = error_info||'Time has inconsistent length' WHERE length(START_TIME) < 8 OR length(END_TIME) < 8;


-- Routes

-- Nutzt extended Route Types statt den Basismöglichkeiten
SELECT * FROM Staging_Routes ORDER BY ROUTE_ID LIMIT 200 OFFSET 800;


-- Stop Times

SELECT * FROM Staging_Stop_Times ORDER BY TRIP_ID LIMIT 120 OFFSET 990;
SELECT * FROM Staging_Stop_Times WHERE PICKUP_TYPE > 2 OR DROP_OFF_TYPE > 2;

ALTER TABLE Staging_Stop_Times ADD COLUMN error_info VARCHAR(2000);
UPDATE Staging_Stop_Times SET error_info = error_info||'Time has inconsistent length' WHERE length(ARRIVAL_TIME) < 8 OR length(DEPARTURE_TIME) < 8;


-- Stops

-- Trotz vieler gleicher Einträge bei Stop_Name gibt es keine Duplikate (mehrere Bushalte-Masten haben denselben Ortsbereichs-Namen)

-- Kleinere Unternehmen nutzen statt der Delphi ID für die Stop ID ggf. eigene ID Counter.
-- In diesem Fällen kann dann die Parent Station für den Join mit den extended Stations genutzt werden (enthält immer Delphi ID)

-- Teils sind als Ziel Haltestellen im Ausland gespeichert. Diese werden für die Analysen nicht berücksichtigt (gibt auch keine Ortszuordnung dafür).

-- Stop_Description enthält teils nur Nummerierungen von Masten oder Gleisen
-- Längen- & Breitengrad werden noch als Varchar mit '.' als Separator genutzt
SELECT * FROM Staging_Stops WHERE STOP_ID NOT LIKE 'de:%:%';
SELECT * FROM Staging_Stops WHERE PARENT_STATION NOT LIKE 'de:%:%';

ALTER TABLE Staging_Stops ADD COLUMN error_info VARCHAR(2000);
UPDATE Staging_Stops SET error_info = error_info||'Local Stop ID instead of Delphi ID' WHERE STOP_ID NOT LIKE 'de:%:%';


-- Trips

SELECT * FROM Staging_Trips WHERE DIRECTION_ID > 1;


-- Population

-- Datum im Format TT.MM.YYYY (muss in YYYYMMDD umgewandelt werden)
-- Werte liegen für Bundesländer, Bezirke & Gemeinden vor (nur Gemeinden sind relevant)
-- Da teils nicht zwischen Bezirk & Stadt unterschieden werden kann wird hier nicht gefiltert.
-- Orts-Identifikationsnummer hat häufig weniger als 8 Stellen. Diese Zahlen müssen entsprechend mit 0 Padding hinten aufgefüllt werden.
SELECT * FROM Staging_Population WHERE REGEXP_INSTR(TOTAL_POPULATION, '^[0-9]+$') < 1;
SELECT * FROM Staging_Population WHERE REGEXP_INSTR(MALE_POPULATION, '^[0-9]+$') < 1;
SELECT * FROM Staging_Population WHERE REGEXP_INSTR(FEMALE_POPULATION, '^[0-9]+$') < 1;

-- Aggregierte Deutschland-Werte entfernen
DELETE FROM Staging_Population WHERE REGEXP_INSTR(SPATIAL_IDENTIFICATION, '^[0-9]+$') < 1;
-- Spatial Identification mit Padding auffüllen
UPDATE Staging_Population SET SPATIAL_IDENTIFICATION = rpad(SPATIAL_IDENTIFICATION, 8, '0') WHERE length(SPATIAL_IDENTIFICATION) < 8;
-- Fehlerhafte Whitespace-Formatierung der Ortsnamen entfernen
UPDATE Staging_Population SET LOCATION_NAME = trim(LOCATION_NAME);
-- 'Insgesamt' Aggregat entfernen
DELETE FROM Staging_Population WHERE AGE_GROUP_NAME = 'Insgesamt';


-- Registered Vehicles

-- Enthält an manchen Stellen Punkte falls der Zahlenwert nicht bekannt ist (muss durch NULL ersetzt werden)
-- Enthält '-' Zeichen statt NULL bei nicht-gesetzten Werten (muss durch NULL ersetzt werden)
SELECT * FROM Staging_Registered_Vehicles WHERE REGEXP_INSTR(MOTORCYCLES, '^[0-9]+$') < 1;
SELECT * FROM Staging_Registered_Vehicles WHERE REGEXP_INSTR(PASSENGER_VEHICLES_TOTAL, '^[0-9]+$') < 1;
SELECT * FROM Staging_Registered_Vehicles WHERE REGEXP_INSTR(PASSENGER_VEHICLES_COMMERCIAL, '^[0-9]+$') < 1;

ALTER TABLE Staging_Registered_Vehicles ADD COLUMN error_info VARCHAR(2000);
UPDATE Staging_Registered_Vehicles SET error_info = error_info||'Non-Integer value for fact column'
            WHERE REGEXP_INSTR(MOTORCYCLES, '^[0-9]+$') < 1 OR REGEXP_INSTR(PASSENGER_VEHICLES_TOTAL, '^[0-9]+$') < 1
            OR REGEXP_INSTR(PASSENGER_VEHICLES_COMMERCIAL, '^[0-9]+$') < 1;

-- '.' & '-' in Null umwandeln
UPDATE Staging_Registered_Vehicles SET MOTORCYCLES = NULL WHERE REGEXP_INSTR(MOTORCYCLES, '^[0-9]+$') < 1;
UPDATE Staging_Registered_Vehicles SET PASSENGER_VEHICLES_COMMERCIAL = NULL WHERE REGEXP_INSTR(PASSENGER_VEHICLES_COMMERCIAL, '^[0-9]+$') < 1;


-- Spatial Classification

-- Städte haben in GEM_NAME nach dem eigentlichen Namen den Suffix ', Stadt' (sollte entfernt werden)
SELECT * FROM Staging_Spatial_Classification ORDER BY GEM2024 LIMIT 450 OFFSET 3500;



-- /// Entity Matching ///

/*
 Da Stops und Extended_Stops die einzigen Tabellen sind, die gleiche Real-World Objekte modellieren,
 macht das Entity Matching nur dort Sinn.
 */

SELECT count(*) FROM STAGING_STOPS;
SELECT count(*) FROM STAGING_EXTENDED_STOPS;

-- Equal Join (Geplantes Konzept)
-- "Duplikate" bzw. letztendlich benötigte Matches (ohne Matches könnte man den Gemeindeschlüssel nicht bestimmen)
SELECT count(*) FROM Staging_Stops S1 JOIN Staging_Extended_Stops S2 ON S1.STOP_ID = S2.DHID;

-- Similarity Join (Levenshtein).
-- Einziges Feld, welches infrage kommt, ist der Haltestellenname. Dieser ist aber sehr häufig nicht eindeutig und oft nur
--  ein beschreibender Begriff, wie bspw. "Rathaus" oder "Stadtplatz" → nicht über verschiedene Orte hinweg identifizierbar.
-- (Query ist zu aufwendig und läuft nicht durch)
SELECT count(*) FROM Staging_Stops S1, Staging_Extended_Stops S2
        WHERE S1.STOP_NAME = S2.NAME OR edit_distance(S1.STOP_NAME, S2.NAME) < 3;

-- Similarity Join (Soundex).
-- Hätte dasselbe Problem, da Soundex auf dasselbe Feld angewendet werden müsste und dort genauso bei gleichklingenden
-- Haltestellen, keine zwingende tatsächliche Beziehung in der echten Welt besteht.
-- (Query läuft durch)
SELECT count(*) FROM Staging_Stops S1, Staging_Extended_Stops S2
    WHERE soundex(S1.STOP_NAME) = soundex(S2.NAME);

/*
 Levenshtein Query läuft nicht durch, da sie auf den angegebenen Daten zu aufwendig ist. Daten müssten vorher partitioniert werden.
 False Positive oder false negatives kann man letztendlich nicht bewerten, da der Name keine Aussagekraft
 über die tatsächliche Haltestelle hat.
 Aus oben genannten Gründen und der tatsache, das Daten gezielt so ausgewählt wurden, dass sie per IDs
 gejoined werden können, wird der Equal Join genutzt.
 */



-- /// Transformation ///
-- Tatsächliches Transformieren in ein passendes Format & anschließendes Laden ins Data Warehouse


-- Dim_Trips

-- DW generiert PK Trip_id selbstständig
-- Direction wird als deutscher Enum gespeichert (da alle Werte im DW deutsch sind)
-- Boolean Werte werden durch logische Gleichungen erzeugt
-- route_type enthält teils die Basic GTFS Types, teils aber auch die Extended GTFS Types. Daher ist es am sinnvollsten
-- ein Lookup Table zu bauen, der die Basis Types in Extended Types umwandelt und zusätzlich zu allen Types Klartext Beschreibungen ausgibt.
INSERT INTO Dim_Trips (GTFS_TRIP_ID, TRIP_HEADSIGN, TRIP_SHORT_NAME, DIRECTION, WHEELCHAIR_ACCESSIBLE,
                       BIKES_ALLOWED, ROUTE_SHORT_NAME, ROUTE_LONG_NAME, TRANSPORT_MODE_CODE,
                       TRANSPORT_MODE_MAIN_CATEGORY, TRANSPORT_MODE_SUB_CATEGORY, AGENCY_NAME)
SELECT T.TRIP_ID, T.TRIP_HEADSIGN, T.TRIP_SHORT_NAME,
       CASE WHEN T.DIRECTION_ID = 1 THEN 'Rückrichtung' ELSE 'Hinrichtung' END,
       (T.WHEELCHAIR_ACCESSIBLE = 1), (T.BIKES_ALLOWED = 1), R.ROUTE_SHORT_NAME, R.ROUTE_LONG_NAME, ETM.ROUTE_TYPE,
       ETM.MAIN_CATEGORY_DESC, ETM.SUB_CATEGORY_DESC, A.AGENCY_NAME
    FROM Staging_Trips T
    JOIN Staging_Routes R ON T.ROUTE_ID = R.ROUTE_ID
    JOIN Staging_GTFS_Extended_Type_Mapping ETM ON R.ROUTE_TYPE = ETM.ROUTE_TYPE
    JOIN Staging_Agencies A ON R.AGENCY_ID = A.AGENCY_ID;


-- Dim_Vehicle_Type

INSERT INTO Dim_Vehicle_Type ("TYPE", COMMERCIAL) VALUES ('Motorrad', false);
INSERT INTO Dim_Vehicle_Type ("TYPE", COMMERCIAL) VALUES ('PKW', false);
INSERT INTO Dim_Vehicle_Type ("TYPE", COMMERCIAL) VALUES ('PKW', true);


-- Dim_Population

-- In richtigem Env würde man Altersgruppen vermutlich per Python Skript extrahieren & transformieren.
-- Hier wurde das CSV Source File per KI generiert.
INSERT INTO Dim_Population (GENDER, AGE_GROUP_CODE, AGE_GROUP_DESC, MIN_AGE, MAX_AGE)
SELECT gender, age_group_code, age_group_desc,
       min_age, max_age FROM Staging_Population_Age_Groups;


-- Dim_Municipalities

INSERT INTO Dim_Municipalities
-- Beim Gemeindename muss der Suffix entfernt werden
SELECT GEM2024, trim(regexp_replace(GEM_NAME, ',.*$', '')), BEZ_GEM, FL24,
       KRS2024, KRS_NAME, BLD2024, BLD_NAME,
       RBG2024, RBG_NAME, RLG2024, RLG_NAME,
       RS52024, RS5_NAME, GTU2024, GTU_NAME
       FROM Staging_Spatial_Classification;


-- Dim_Stations

-- Da es teils Unternehmen gibt, die lokale IDs statt den Delphi IDs oder auch eigene Delphi IDs (die nicht kommuniziert wurden)
-- für stop_id nutzen, kann nicht für jede Haltestelle der passende Join Partner in den erweiterten Haltestellen gefunden werden.
-- In richtigem DWH würde man vermutlich überprüfen, welche Einträge keinen Join Partner finden und diese dann über das Parent Field joinen.
-- Logischerweise können diese Joins dann nur noch aggregierte Informationen (wie bspw. den Ort) und keine feinen Informationen (wie einen Haltestellennamen) liefern.
-- Hier werden Einträge ohne Join-Partner aus Effizienzgründen ignoriert

-- Extended Haltestellen haben eine Hierarchie-Tiefe von 3 Ebenen (in Bezug auf Parent Elemente), daher wird 3x gejoined.

-- Da es räumliche Veränderungen bei den Gemeinden gibt, sind manche Gemeindecodes in der Raumgliederung nicht auffindbar.
-- Aus Zeitgründen werden die Gemeinden ohne Match ignoriert, indem die Gemeinde-Dimension per Inner Join verknüpft wird.

INSERT INTO Dim_Stations (MUNICIPALITY_CODE, GTFS_STOP_ID, NAME, DESCRIPTION, TYPE, LATITUDE, LONGITUDE, WHEELCHAIR_ACCESSIBLE, PLATFORM_CODE)
SELECT ES3.MUNICIPALITYCODE,  S.STOP_ID, S.STOP_NAME, S.STOP_DESCRIPTION,
       CASE S.LOCATION_TYPE
           WHEN 0 THEN 'HALTESTELLE'
           WHEN 1 THEN 'BAHNHOF'
           WHEN 2 THEN 'EINGANG_AUSGANG'
           WHEN 3 THEN 'KNOTENPUNKT'
           WHEN 4 THEN 'BOARDING_BEREICH'
        END,
       S.STOP_LAT, S.STOP_LON, (S.WHEELCHAIR_BOARDING = 1), S.PLATFORM_CODE
    FROM Staging_Stops S JOIN Staging_Extended_Stops ES1 ON S.STOP_ID = ES1.DHID
    JOIN Staging_Extended_Stops ES2 ON ES1.PARENT = ES2.DHID
    JOIN Staging_Extended_Stops ES3 ON ES2.PARENT = ES3.DHID
    JOIN Dim_Municipalities M ON ES3.MUNICIPALITYCODE = M.MUNICIPALITY_CODE;


-- Fact_Census

-- Auch hier muss wieder mit Gemeinde-Dimension gejoined werden, da in der Bevölkerungstabelle auch Regierungsbezirke,
-- Kreise, Bundesländer,... sowie Gemeinden mit veränderter AGS enthalten sind, die keine passende AGS haben.

INSERT INTO Fact_Census (MUNICIPALITY_CODE, POPULATION_GROUP_ID, "date", AMOUNT)
SELECT SPATIAL_IDENTIFICATION, DP.POPULATION_GROUP_ID,
    TO_DATE(REPORTING_DATE, 'DD.MM.YYYY'), MALE_POPULATION
    FROM Staging_Population IP JOIN Dim_Population DP ON IP.AGE_GROUP_NAME = DP.AGE_GROUP_DESC
                               JOIN Dim_Municipalities M ON IP.SPATIAL_IDENTIFICATION = M.MUNICIPALITY_CODE
    WHERE DP.GENDER = 'männlich'
UNION ALL
SELECT SPATIAL_IDENTIFICATION, DP.POPULATION_GROUP_ID,
    TO_DATE(REPORTING_DATE, 'DD.MM.YYYY'), FEMALE_POPULATION
    FROM Staging_Population IP JOIN Dim_Population DP ON IP.AGE_GROUP_NAME = DP.AGE_GROUP_DESC
                               JOIN Dim_Municipalities M ON IP.SPATIAL_IDENTIFICATION = M.MUNICIPALITY_CODE
    WHERE DP.GENDER = 'weiblich';


-- Fact_Registered_Vehicles

-- Auch hier muss zuvor mit Gemeinde-Dimension gejoined werden

-- Motorräder
INSERT INTO Fact_Registered_Vehicles (MUNICIPALITY_CODE, VEHICLE_TYPE_ID, "date", AMOUNT)
SELECT LEFT(MUNICIPALITY, 8), 1, TO_DATE('01.01.2025', 'DD.MM.YYYY'), MOTORCYCLES
    FROM Staging_Registered_Vehicles JOIN Dim_Municipalities M ON LEFT(MUNICIPALITY, 8) = M.MUNICIPALITY_CODE
    WHERE MOTORCYCLES IS NOT NULL;

-- PKW (Privat)
INSERT INTO Fact_Registered_Vehicles (MUNICIPALITY_CODE, VEHICLE_TYPE_ID, "date", AMOUNT)
SELECT LEFT(MUNICIPALITY, 8), 2, TO_DATE('01.01.2025', 'DD.MM.YYYY'), (COALESCE(PASSENGER_VEHICLES_TOTAL, 0) - COALESCE(PASSENGER_VEHICLES_COMMERCIAL, 0))
    FROM Staging_Registered_Vehicles JOIN Dim_Municipalities M ON LEFT(MUNICIPALITY, 8) = M.MUNICIPALITY_CODE
    WHERE PASSENGER_VEHICLES_TOTAL IS NOT NULL;

-- PKW (kommerziell)
INSERT INTO Fact_Registered_Vehicles (MUNICIPALITY_CODE, VEHICLE_TYPE_ID, "date", AMOUNT)
SELECT LEFT(MUNICIPALITY, 8), 3, TO_DATE('01.01.2025', 'DD.MM.YYYY'), PASSENGER_VEHICLES_COMMERCIAL
    FROM Staging_Registered_Vehicles JOIN Dim_Municipalities M ON LEFT(MUNICIPALITY, 8) = M.MUNICIPALITY_CODE
    WHERE PASSENGER_VEHICLES_COMMERCIAL IS NOT NULL;


-- Fact_Stops

CREATE TABLE Staging_Dates (
    service_id INTEGER,
    "date" DATE
);

INSERT INTO Staging_Dates
SELECT * FROM (
        -- Generiert für jeden service_id Eintrag in Staging_Calender entsprechende Datumszeilen
        WITH Date_Numbers AS (
            -- Generiert virtuell die Zahlen 0 bis 1000 (reicht für fast 3 Jahre GTFS-Laufzeit)
            SELECT LEVEL - 1 AS n
            FROM DUAL CONNECT BY LEVEL <= 1000
        ),
        exploded_dates AS (
            SELECT C.service_id,
            -- Addiert die fortlaufenden Tage zum Startdatum
            ADD_DAYS(TO_DATE(C.start_date, 'YYYYMMDD'), N.n) AS exact_date,
            C.monday,
            C.tuesday,
            C.wednesday,
            C.thursday,
            C.friday,
            C.saturday,
            C.sunday
            FROM Staging_Calender C
            -- Passende Anzahl Zeilen für die Daten erzeugen
            JOIN Date_Numbers N ON N.n <= DAYS_BETWEEN(TO_DATE(C.end_date, 'YYYYMMDD'), TO_DATE(C.start_date, 'YYYYMMDD'))
        )
        SELECT service_id, exact_date AS date_key
        FROM exploded_dates
        -- Exasol TO_CHAR mit 'ID' gibt den Wochentag als Zahl (1=Mo bis 7=So)
        -- Wochentage filtern, die im Service Calender gar nicht geplant sind
        WHERE
            (TO_CHAR(exact_date, 'ID') = '1' AND monday = 1)
         OR (TO_CHAR(exact_date, 'ID') = '2' AND tuesday = 1)
         OR (TO_CHAR(exact_date, 'ID') = '3' AND wednesday = 1)
         OR (TO_CHAR(exact_date, 'ID') = '4' AND thursday = 1)
         OR (TO_CHAR(exact_date, 'ID') = '5' AND friday = 1)
         OR (TO_CHAR(exact_date, 'ID') = '6' AND saturday = 1)
         OR (TO_CHAR(exact_date, 'ID') = '7' AND sunday = 1)
)
UNION -- kein Union All damit keine Duplikate entstehen
SELECT SERVICE_ID, TO_DATE("date", 'YYYYMMDD') FROM Staging_Calender_Dates WHERE EXCEPTION_TYPE = 1
EXCEPT
SELECT SERVICE_ID, TO_DATE("date", 'YYYYMMDD') FROM Staging_Calender_Dates WHERE EXCEPTION_TYPE = 2;


-- LUA Skript für Zeitumrechnung in Integer
CREATE OR REPLACE LUA SCALAR SCRIPT time_to_seconds(time_str VARCHAR(20)) RETURNS INTEGER AS
    function run(ctx)
        -- NULL-Werte abfangen
        if ctx.time_str == nil then return nil end

        -- String an den Doppelpunkten splitten
        local h, m, s = string.match(ctx.time_str, "(%d+):(%d+):(%d+)")

        -- In Sekunden umrechnen
        if h and m and s then
            local seconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
            return decimal(seconds) -- Exasol castet Wert in Integer
        end

        return nil
    end
/

INSERT INTO Fact_Stops
WITH Pre_Aggregated_Stop_Times AS (
    SELECT
        SST.STOP_ID, SST.TRIP_ID, SST.STOP_SEQUENCE, SST.DROP_OFF_TYPE, SSt.PICKUP_TYPE,
        time_to_seconds(SST.ARRIVAL_TIME) AS ARRIVAL_TIME_SEC, time_to_seconds(SST.DEPARTURE_TIME) AS DEPARTURE_TIME_SEC,
        (time_to_seconds(SST.DEPARTURE_TIME) - time_to_seconds(SST.ARRIVAL_TIME)) AS DURATION_OF_STAY_SEC,
        -- Per Lead kann nächster Wert in einer Query abgefragt werden
        -- Falls keine nächste Haltestellen-Zeit mehr gefunden wird, wird NULL returned
        LEAD(time_to_seconds(SST.ARRIVAL_TIME)) OVER (PARTITION BY SST.TRIP_ID ORDER BY SST.STOP_SEQUENCE) AS NEXT_ARRIVAL_TIME_SEC
    FROM Staging_Stop_Times SST LIMIT 2000000 -- Konkrete Haltestellen-Stops müssen limited werden, da sonst Speicheraufwand von ~180 GB entsteht
)
SELECT DS.STATION_ID, DT.TRIP_ID, SD."date", AST.STOP_SEQUENCE, (AST.DROP_OFF_TYPE = 1), (AST.PICKUP_TYPE = 1),
        AST.ARRIVAL_TIME_SEC, AST.DEPARTURE_TIME_SEC, AST.DURATION_OF_STAY_SEC,
        -- Bei nicht gefundener NEXT_ARRIVAL_TIME_SEC (NULL), wird auch DURATION_UNTIL_NEXT_STOP_SEC = NULL
        CASE AST.NEXT_ARRIVAL_TIME_SEC
            WHEN AST.NEXT_ARRIVAL_TIME_SEC < DEPARTURE_TIME_SEC
            THEN AST.NEXT_ARRIVAL_TIME_SEC + 24 * 60 * 60 - DEPARTURE_TIME_SEC
            ELSE NEXT_ARRIVAL_TIME_SEC - DEPARTURE_TIME_SEC
        END
        -- Dimensions-Joins um Surrogatschlüssel des DW bereitzustellen
        FROM Pre_Aggregated_Stop_Times AST JOIN Dim_Stations DS ON AST.STOP_ID = DS.GTFS_STOP_ID
                            JOIN Dim_Trips DT ON AST.TRIP_ID = DT.GTFS_TRIP_ID
                            -- Tatsächlich neue extrahierte Daten
                            JOIN Staging_Trips ST ON AST.TRIP_ID = ST.TRIP_ID
                            JOIN Staging_Dates SD ON ST.SERVICE_ID = SD.SERVICE_ID;

-- Durch Date Explosion zu große Menge an Daten:
-- [40001] GlobalTransactionRollback msg: Quota for schema 'NIKOLAS_POLLIN' exceeded! Schema quota is set to 8589934592 bytes and attempted new raw size is 182310495765 bytes..
-- => Statt ~45 Millionen Halten werden nur ~2 Millionen betrachtet