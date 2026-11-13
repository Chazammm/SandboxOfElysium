# SandboxOfElysium

Experimenteller Lua-Sandbox-Mod für **Conquest of Elysium 5**. Im Hauptmenü erscheint **Sandbox**. Zwei Armeen werden vorbereitet und kämpfen anschließend mit der normalen CoE5-Kampf-KI.

**Stand 0.1.0:** ein im echten Spiel geprüfter Prototyp. Die vollständige Wunschliste ist noch nicht umgesetzt. Insbesondere sind Kartenauswahl, manuelle Größenwahl, Item-Zuweisung, Magiestufen-Upgrades und ein vollständiges Ereignisprotokoll durch fehlende oder ungeklärte API-Zugriffe eingeschränkt. Die Oberfläche benennt diese Grenzen.

## Voraussetzungen und Installation

- Eigene Windows-Version von CoE5 **5.43**.
- [CoE5SE dev](https://github.com/musical-pianist/coe5se/tree/dev), untersucht und unverändert gebaut auf **57abc69a2ddb272a5b9049b4a561367066d9d99e**, Versionsangabe **3.3.0**. Andere Stände und macOS wurden nicht geprüft.
- Den Extender nach dessen eigener Anleitung installieren. Dieser Mod enthält und installiert keinen Extender.
- Den Ordner `mod/SandboxOfElysium` aus dem Repository (im Installations-ZIP direkt `SandboxOfElysium`) nach `%APPDATA%\coe5\mods\SandboxOfElysium` kopieren. Die `.c5m` muss direkt in diesem Ordner liegen, ohne zusätzliche Verschachtelung.
- In **Mods** CoE5SE und SandboxOfElysium einschalten und das Spiel neu starten.
- Im Hauptmenü **Sandbox → Prepare battlefield** wählen.

Die vorgefundene Installation enthielt CoE5SE 3.2.2. Sämtliche Tests dieses Projekts liefen mit einem separat gebauten 3.3.0-dev-Stand in einer privaten Spielkopie und einem eigenen Profil. Die reguläre Installation wurde nicht aktualisiert.

## Bedienung

- Standardaufstellung: Team A mit einem Spearman links, Team B mit einem Goblin rechts.
- Teamfarben im Einstiegsmenü anklicken, um durch sieben Farben zu wechseln. Gleiche Farben sind erlaubt; A/B bleiben verfeindet. Die Farbe ist auch im nativen Kampf an den Einheitentokens sichtbar.
- Im Editor oben das Team wählen. Rechts einen Eintrag anklicken oder **Browse sprites / search** öffnen. Der Browser zeigt das native Idle-Bild und wählt mit einem Klick die Einheit zum Platzieren.
- **Rechtsklick** auf eine leere Zelle platziert. Gedrückt halten und über neue Zellen ziehen wiederholt die Formation. Ein Rechtsklick auf eine vorhandene Einheit öffnet **Edit / Move / Copy / Delete**.
- Formation anklicken: **Single / Horizontal Row / Vertical Row / Square**. `+` wechselt die Anzahl 1–15 beziehungsweise die Quadratgröße 2–4.
- **Move:** Rechtsklick auf das Ziel; **Cancel move** oben rechts bricht ab. Das Original wird erst bei gültigem Ziel verändert. Escape ist für diesen Vorgang nicht zugesagt.
- Das Raster ist ein ausdrücklich gekennzeichneter **Zelleditor**. **Native view** zeigt das echte Schlachtfeld mit den echten Sprites. Die Ghost-Markierung prüft nur Zellgrenzen und belegte Ankerzellen; erst die native Platzierung prüft Hindernisse und große Einheiten vollständig.
- **Start battle** startet die echte Schlacht. Die nativen Geschwindigkeits- und Pause-Buttons bleiben verfügbar.
- Danach stehen Bericht, **Reset setup** und **Rematch** bereit. Die native Einheitendarstellung wird beim Kampfende bereinigt; die gewünschte echte Endaufstellung ist nicht verfügbar. Reset/Copy/Rematch können abgelehnt werden, wenn zufällige native Startzauber nicht exakt wiederherstellbar sind. Dieser Fall wurde bei einem Old Wizard tatsächlich beobachtet.
- **Clear** leert die Aufstellung. Im Einstiegsmenü lassen sich anschließend über **Add unit to setup** neue Einheiten mit `Team,x,y` ergänzen. Für ein natives Feld wird auf beiden Seiten mindestens eine Einheit benötigt.

Einheitenfilter verwenden tatsächlich gelesene Eigenschaften: human, animal, undead, demonic, flying und ranged. Aktivierte Mod-Einheiten erscheinen im geladenen Bestand. Eine zuverlässige Kategorie „Modded Units“ ist mangels Herkunftsmetadaten nicht verfügbar. Die Liste hat fünf Einträge pro Seite und Seitenbuttons; Mausrad-Scrolling und ein zweites Attack-Bild fehlen.

## Konfiguration, Szenarien und Berichte

Unter **Edit** lassen sich bekannte Zauber memorisieren oder entfernen, soweit das Spiel dies akzeptiert. Gleiche Namen werden durch ihre Zauber-ID unterschieden. Grundlegende Schulstufen lassen sich nicht ändern. Das Item-Menü zeigt Inventar, Namenssuche und die tatsächlich gelesenen Slot-Typen; die Zuweisung ist bis zur geklärten Slot-Kompatibilitätsprüfung deaktiviert.

Szenarien und Berichte liegen in `%APPDATA%\coe5\coe5se_data\SandboxOfElysium\` als `.ini`. Eigene Dateinamen dürfen keine Pfadtrenner enthalten. **Save / Load** bewahren Teams, Farben, Positionen, Inventar und memorisierte Zauber samt gelesenem Startzauberbestand. Fehlende aktive Mods, geänderte Einheitennummern/-namen, fehlende oder mehrdeutige Items/Zauber und ungültige Daten werden abgelehnt. Native Feldprüfung folgt beim Öffnen. Inhaltliche Änderungen unter identischer ID und identischem Namen sind noch nicht vollständig erkennbar.

Der letzte Kampf wird automatisch als `last-battle.ini` exportiert. Enthalten sind Sieger, letzte Runde, verstrichene Echtzeit inklusive Pausen, Startzahlen, Verluste, Überlebende und native Kill-Zähler. Nicht verfügbare Positionsdaten werden als `unavailable` exportiert; Beobachtungen aus einem Aftermath-Callback sind separat gekennzeichnet. Schaden ist ausdrücklich **nur teilweise zugeordnet**; ein vollständiges Zauberprotokoll ist **nicht verfügbar**. Beschworene Einheiten werden nicht als ursprüngliche Starttruppen gezählt; Überlebende werden ihrem ursprünglichen Team zugerechnet, Konvertierungen separat über den Endbesitzer sichtbar.

Die erste Einheit von Team A wird vom nativen Testfeld als Commander erzeugt. Kampagnenstart, Faction-Blessings und weitere weltabhängige Effekte werden durch die Sandbox nicht vollständig initialisiert. Getestet wurde der Offline-Einstieg über das Hauptmenü; Multiplayer und laufende Kampagnen sind kein unterstützter Sandbox-Einstieg.

Zur Deinstallation den Mod im Spiel deaktivieren und seinen Mod-Ordner entfernen. Gespeicherte Szenarien im Datenordner bleiben dabei erhalten. Bei Startproblemen Extender-Version und Ordnerstruktur prüfen; Diagnosen stehen je nach Loader-Stufe im Spielordner unter `coe5mod.log` beziehungsweise `coe5se_logs/coe5mod.log`.

## Nachweise und weitere Arbeit

- [Testergebnisse und Abweichungen](docs/TEST-RESULTS.md)
- [Technischer API-Bericht für musical_pianist (English)](docs/API-GAPS.md)
- [Umgebung und API-Matrix](docs/RECON.md)
- [Entwicklungsjournal](MODLOG.md)

Das Projekt enthält ausschließlich eigenen Mod-Code, ein eigenes Banner, Werkzeuge und erzeugte Testergebnisse. Keine Spielbinärdateien, Spielgrafiken, Lizenzschlüssel, Extender-Binärdateien oder fremden Mods. Mit Unterstützung von OpenAI Codex entwickelt; CoE5SE stammt von musical_pianist.
