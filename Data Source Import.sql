IMPORT INTO Staging_Frequencies (trip_id, start_time, end_time, headway_secs)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/frequencies.txt'
    (1, 2, 3, 4) ROW SEPARATOR = 'CRLF' SKIP  = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Trips (route_id, service_id, trip_id, trip_headsign, trip_short_name, direction_id, wheelchair_accessible, bikes_allowed)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/trips.txt'
    (1, 2, 3, 4, 5, 6, 9, 10) ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Routes (route_id, agency_id, route_short_name, route_long_name, route_type)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/routes.txt'
    (1, 2, 3, 4, 5) ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Agencies (agency_id, agency_name)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/agency.txt'
    (1, 2) ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Calender_Dates (service_id, "date", exception_type)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/calendar_dates.txt'
    ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Calender (service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/calendar.txt'
    ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Stop_Times (trip_id, stop_id, stop_sequence, pickup_type, drop_off_type, arrival_time, departure_time)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/stop_times.txt'
    (1, 2, 3, 4, 5, 7, 8) ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Stops (stop_id, stop_name, stop_description, stop_lat, stop_lon, location_type, parent_station, wheelchair_boarding, platform_code)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/stops.txt'
    (1, 3, 4, 5, 6, 7, 8, 9, 10) ROW SEPARATOR = 'CRLF' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Extended_Stops (seqno, type, dhid, parent, name, latitude, longitude, municipalitycode, municipality, districtcode, district, description, authority, delfiname, sev)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/extended_stops.csv'
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 18) ROW SEPARATOR  = 'CRLF' NULL = '-' COLUMN SEPARATOR = ';' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Registered_Vehicles (state_name, district, municipality, motorcycles, passenger_vehicles_total, passenger_vehicles_commercial)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/registered_vehicles_flat.csv'
    (1, 2, 3, 4, 5, 6) ROW SEPARATOR = 'LF' COLUMN SEPARATOR = ';' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Population (reporting_date, spatial_identification, location_name, age_group_name, total_population, male_population, female_population)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/population.csv'
    ROW SEPARATOR = 'LF' COLUMN SEPARATOR = ';' NULL = '-' IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;


IMPORT INTO Staging_Spatial_Classification (gem2024, gem_name, bez_gem, fl24, krs2024, krs_name, rbg2024, rgb_name, rlg2024, rlg_name, rs52024, rs5_name, gtu2024, gtu_name, bld2024, bld_name)
    FROM LOCAL CSV FILE '/Users/niki/Projekte/SQL/DW/dw-public-transportation/data_sources/spatial_classification_flat.csv'
    (1, 3, 4, 6, 13, 14, 33, 34, 37, 38, 41, 42, 57, 58, 91, 92) ROW SEPARATOR = 'LF' COLUMN SEPARATOR = ';' SKIP = 1 IGNORE CERTIFICATE
    ERRORS INTO error_tbl REJECT LIMIT UNLIMITED;