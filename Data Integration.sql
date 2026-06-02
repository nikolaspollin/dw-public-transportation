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

--TODO Child Stops haben keine eigenen Municipality Daten → MunicipalityCode hat dort Defaultwert 00000 und Municipality ist NULL
-- TODO '-' muss in NULL transformiert werden (beim Merging oder Data Scrubbing)

-- Haben ihre eigene DHID im Parent Feld gesetzt, falls es kein darüberliegendes Parent mehr gibt
SELECT * FROM Staging_Extended_Stops WHERE DHID NOT LIKE 'de:%:%';
SELECT * FROM Staging_Extended_Stops WHERE PARENT IS NULL;


-- Frequencies

-- TODO Start Time & End Time haben teils einstellige Stunde (sollte normalisiert immer zweistellig sein)
SELECT * FROM Staging_Frequencies;


-- Routes

-- TODO nutzt extended Route Types statt den Basismöglichkeiten in https://gtfs.org/documentation/schedule/reference/#routestxt
SELECT * FROM Staging_Routes ORDER BY ROUTE_ID LIMIT 200 OFFSET 800;


-- Stop Times

-- TODO Arrival & Departure Time haben teils einstellige Stunden (sollte normalisiert werden)
SELECT * FROM Staging_Stop_Times ORDER BY TRIP_ID LIMIT 120 OFFSET 990;
SELECT * FROM Staging_Stop_Times WHERE PICKUP_TYPE > 2 OR DROP_OFF_TYPE > 2;


-- Stops

-- Trotz vieler gleicher Einträge bei Stop_Name gibt es keine Duplikate (mehrere Bushalte-Masten haben denselben Ortsbereichs-Namen)

-- Kleinere Unternehmen nutzen statt der Delphi ID für die Stop ID ggf. eigene ID Counter.
-- In diesem Fällen kann dann die Parent Station für den Join mit den extended Stations genutzt werden (enthält immer Delphi ID)

-- Stop_Description enthält teils nur Nummerierungen von Masten oder Gleisen
-- Längen- & Breitengrad werden noch als Varchar mit '.' als Separator genutzt
SELECT * FROM Staging_Stops WHERE STOP_ID NOT LIKE 'de:%:%';
SELECT * FROM Staging_Stops WHERE PARENT_STATION NOT LIKE 'de:%:%';


-- Trips

SELECT * FROM Staging_Trips WHERE DIRECTION_ID > 1;


-- Population

-- Datum im Format TT.MM.YYYY
-- Spatial Identification hat unterschiedliche Länge (5-Stellig für Bezirksschlüssel, 8-Stellig für Gemeindeschlüssel, ...)
SELECT * FROM Staging_Population WHERE REGEXP_INSTR(TOTAL_POPULATION, '^[0-9]+$') < 1;
SELECT * FROM Staging_Population WHERE REGEXP_INSTR(MALE_POPULATION, '^[0-9]+$') < 1;
SELECT * FROM Staging_Population WHERE REGEXP_INSTR(FEMALE_POPULATION, '^[0-9]+$') < 1;


-- Registered Vehicles

-- TODO Enthält an manchen Stellen Punkte falls der Zahlenwert nicht bekannt ist (muss durch NULL ersetzt werden)
-- TODO Enthält '-' Zeichen statt NULL bei nicht-gesetzten Werten (muss durch NULL ersetzt werden)
SELECT * FROM Staging_Registered_Vehicles WHERE REGEXP_INSTR(MOTORCYCLES, '^[0-9]+$') < 1;
SELECT * FROM Staging_Registered_Vehicles WHERE REGEXP_INSTR(PASSENGER_VEHICLES_TOTAL, '^[0-9]+$') < 1;
SELECT * FROM Staging_Registered_Vehicles WHERE REGEXP_INSTR(PASSENGER_VEHICLES_COMMERCIAL, '^[0-9]+$') < 1;


-- Spatial Classification

-- TODO Städte haben in GEM_NAME nach dem eigentlichen Namen den Suffix ', Stadt' (sollte entfernt werden)
SELECT * FROM Staging_Spatial_Classification ORDER BY GEM2024 LIMIT 450 OFFSET 3500;