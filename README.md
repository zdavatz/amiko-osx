AmiKo/CoMed für macOS
=====================

## Funktionen
* Rezept 
  * erstellen
  * importieren
  * exportieren
    * Email
    * AirDrop
    * Finder
  * [drucken](https://github.com/zdavatz/amiko-osx/files/1992084/RZ_2018-05-08T151321.pdf)
* Einnahmeanweisung pro Packung hinterlegen
* Adresse 
  * aus macOS Adressbuch übernehmen
  * im AmiKo Adressbuch speichern und verwalten
* Voll-Text-Suche
* Fachinfo-Suche nach
  * Markennamen
  * ATC-Code (Original/Generikum)
  * Hersteller
  * Swissmedic-Nummer
  * BAG/Swissmedic Kategorie

## .amk File lesen
*  `cat RZ_2017-09-22T211907.amk | base64 --decode` wird das JSON File auslesen.

## Datenbankverzeichnis
* amiko-osx/AmiKoOSX
  * `wget http://pillbox.oddb.org/amiko_db_full_idx_de.zip`
  * `wget http://pillbox.oddb.org/amiko_db_full_idx_fr.zip`
  * `wget http://pillbox.oddb.org/amiko_frequency_de.db.zip`
  * `wget http://pillbox.oddb.org/amiko_frequency_fr.db.zip`

## Build Target
* 10.12
