Data Warehousing | Summer Semester 2026 | Prof. Schildgen | OTH Regensburg

-----

**Name:** 🖊️ Nikolas Pollin

# Challenge 3: Data Modelling and Importing the Data

**Tasks:** 
1. Fill out this workbook. You can use a markdown software (e.g., [Zettlr](https://www.zettlr.com/)) for that, or an online editor (e.g., [md2pdf](https://md2pdf.netlify.app/) or Notion). 
2. You can use a [Markdown Cheat Sheet](https://padomi.id.lv/PRG/par__/Markdown-Cheat-Sheet.pdf) to understand how to write *italic*, **bold**, `code`, etc.
3. Fill out this workbook with care. It will be graded with points. Write high-class content, but compact. Before you submit, read everything again and improve. 
4. When you are finished, export your workbook as a PDF and upload it to ELO before the deadline. Open your PDF in a PDF viewer to check whether everything was exported correctly and no code blocks are cut off.
5. In this workbook, you need to write SQL commands. Put them in code blocks and split long queries into multiple lines.

```sql
-- This is just an example. You do not need to write anything here.
```

*You can fill out this workbook in English or German. You need to write everywhere where you see this:* 🖊️


## Title

Auswirkungen des ÖPNV Angebots im ländlichen Raum


## Staging Area: Tables
*Write down your `CREATE TABLE` commands to create your tables in which you import your data from the data sources.  (Ex. Sheet 3, Exercise 1.3)*

🖊️

## Forms of Heterogeneity

### Vergleich GTFS Daten mit Raumgliederung

- Technisch
  - Beide werden als fertig gepackte Datenpakete auf einem Webserver angeboten (File-Download).
  - GTFS Daten werden im CSV Format in TXT Files gezippt verteilt, während die Raumgliederungsdaten in einem Excel File gespeichert sind.
- Datenmodell
  - GTFS CSV Files sind Flat-Files ohne feste Struktur (bis auf den Header).
  - Raumgliederungsdaten sind in Excel enthalten und zählt daher eher als Spreadsheet-Modell.
- Syntaktisch
  - GTFS Daten speichern Gleitkommazahlen in amerikanischer Notation mit einem Punkt. Die Raumgliederung nutzt dafür ein Komma.
- Semantisch
  - Die GTFS Daten enthalten in dem erweiterten Haltestellen-Datensatz die amtlichen Gemeindeschlüssel (Referenz zur Gemeinde) als *Municipality Code*.
  - Der Raumgliederungs-Datensatz speichert diesen Wert als *Gemeinden-Kennziffer*.
- Schematisch
  - Sowohl die GTFS Daten als auch die Raumgliederung speichern einen geografischen Kontext.
  - GTFS speichert in den Hauptdaten zu einer Haltestelle nur die Koordinaten, nicht aber die Gemeindezugehörigkeit. Für die Zuordnung braucht man die erweiterten Haltestellen-Daten.
  - Die Raumgliederung speichert die geografische Zuordnung zu einer Gemeinde direkt als amtlichen Gemeindeschlüssel

### Vergleich der obigen mit den Fahrzeugzulassungen

- Technisch
  - Wird genauso wie die Raumgliederung als Excel File-Download angeboten (da Amt als Quelle).
- Datenmodell
  - Wird genau wie Raumgliederung als Excel gespeichert (Spreadsheet-Modell).
- Syntaktisch
  - Tausender Bereiche werden mit der deutschen Notation, also dem Punkt, getrennt.
- Semantisch
  - Amtlicher Gemeindeschlüssel ist zwar enthalten, wird allerdings zusammen mit Namen der Gemeinde in einem Feld kombiniert gespeichert (muss also aufgetrennt werden).

*Which forms of heterogeneity exist between two of your data sources? Write at least one example. (Ex. Sheet 3, Exercise 1.4)*

* 🖊️ 

## Star / Snowflake Schema
*Your task was to decide whether to use a star schema or a snowflake schema (or a mix of both) within your data warehouse. Provide the `CREATE TABLE` commands of your final schema here. (Ex. Sheet 3, Exercise 1.6)*

**Fact table(s):**

🖊️ 

**Dimension table(s):**

🖊️


## IMPORT
*Write down IMPORT commands to import data from your data sources into your staging area tables. (Ex. Sheet 3, Exercise 2.1)*

🖊️


## Numbers
* Numbers of rows in your biggest table: 🖊️
* Size (KB, MB, or GB) of your biggest table: 🖊️
* Name of that biggest table: 🖊️
* Total size (KB, MB, or GB) of your schema: 🖊️


## ME/R Model
*If you use Zettlr, Notion, or another local Markdown editor, embed the image of your ME/R Model here by writing `![ME/R Model](mer.jpg)`. If you create your PDF with a markdown-to-PDF conversion tool, then create this workbook PDF (without the image), and the image PDF as two separate files and combine them into one single PDF (e.g., with PDFSAM or pdftk). (Ex. Sheet 2, Exercise 1.1)*

🖊️ 



**Please check: Have you written your name on the very top?**