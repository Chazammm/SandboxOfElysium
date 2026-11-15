# Installation und Test — editor.8

## Zuerst den richtigen Stand wählen

Der aktuelle Repository-Stand **0.1.0+editor.8** ist eine experimentelle Windows-Entwicklungsversion für **Conquest of Elysium 5.43 x64**. Er enthält die Sandbox-Mod, Dokumentation und lokale Entwicklungswerkzeuge. Er ist **kein vollständiges, allgemein installierbares Spielerpaket**.

Der vollständige Editor benötigt zusätzliche APIs aus einem **separaten, lokal gebauten experimentellen CoE5SE 3.4.0**. Ein unveränderter offizieller CoE5SE, auch 3.4.4, stellt nicht alle benötigten Funktionen bereit. Ein „Source code (zip)“-Download ersetzt diese Abhängigkeit nicht. Der kleine vorbereitete Ranged-Beitrag allein genügt ebenfalls nicht für den ganzen Editor.

CoE5SE-Dateien oder dessen veränderte DLL werden hier nicht mitgeliefert: Die [CoE5SE-Lizenz](https://github.com/musical-pianist/coe5se/blob/d96f2b784e97e115022a2598da2c821dd9520135/LICENSE.txt) untersagt das Beilegen in Mods. Ein vollständiges öffentliches Experiment-Komplettpaket ist deshalb derzeit nicht verfügbar. Spiel, Schlüsseldateien und andere Mods werden ebenfalls nicht verteilt. Die bisherigen 0.1.0-Prototyp-Nachweise in älteren Berichten sind keine Abnahme des aktuellen Editors mit einem offiziellen Extender.

## Auf dem bereits eingerichteten Entwicklungsrechner

Hier sind die getrennten Spielkopien und der experimentelle Extender bereits vorhanden. Dafür gilt:

1. Ein noch laufendes Sandbox-Testspiel schließen. Der Starter verändert keinen bereits laufenden Prozess.
2. Im Ordner **Sandbox of Elysium** die Datei **SandboxOfElysium-Testen.bat** doppelt anklicken.
3. Die Konsole prüft Spiel, lokale Mod-Dateien, Extender-Build und das eigene Testprofil. Falls notwendig wird der separate Extender mit der vorhandenen Toolchain neu gebaut. Ein Fehler lässt das Fenster offen. Die Profilumleitung muss vom neu gestarteten Spiel bestätigt werden; ohne Bestätigung wird der Start abgebrochen.
4. Im Hauptmenü **Sandbox** wählen. Unter **Battlefield** **Open with native deployment (reposition units)** öffnen.
5. Oben **Team A** oder **Team B** wählen, rechts eine Einheit suchen, **Select** und mit Rechtsklick auf einer freien Zelle platzieren. Ein zweiter Klick auf dasselbe **Select** hebt die Auswahl wieder auf.
6. Mindestens eine Einheit pro Team setzen und **Start battle** wählen. Nach dem Kampf **Back to Sandbox (restore setup)**, **Reset setup** oder **Rematch** verwenden.

Der Starter benötigt Windows PowerShell, Python3, die bereits vorbereitete `private/lab/identity.json` und `private/terrain-lab`-Umgebung, die eigene geprüfte CoE5-5.43-Installation, den separaten Ordner `../SandboxOfElysium-ExtenderLab-current` und die vorhandene llvm-mingw-Toolchain. Diese privaten Bestandteile sind absichtlich nicht im Git-Download. Die BAT ist **kein Erstinstaller für fremde Rechner**. `SandboxOfElysium-Testen.bat -CheckOnly` prüft die vorhandenen Pfade ohne einen Spielstart.

Die normale CoE5-Installation und ihr Profil werden nicht aktualisiert. Szenarien und Diagnosen dieses Teststarters liegen unter **private/terrain-lab/profile/coe5se_data/SandboxOfElysium**. Vor manuellen Änderungen diese eigenen Dateien sichern; der Starter löscht sie nicht. Für bereits vorhandene private CrabCult-Dateien kann `-CrabCult` verwendet werden; diese Mod ist nicht enthalten.

## Installation auf einem anderen Rechner

1. Eine eigene passende Windows-Version von CoE5 installieren. Den offiziellen Extender nur über die [offizielle CoE5SE-Seite](https://github.com/musical-pianist/coe5se) und dessen Anleitung beziehen. Das allein macht editor.8 noch nicht vollständig nutzbar.
2. Dieses Repository herunterladen oder klonen. Die eigentlichen Mod-Dateien liegen unter **mod/SandboxOfElysium**. Nicht den gesamten Repository-Ordner als CoE5-Mod installieren.
3. Für den aktuellen vollständigen Editor sind ein separat rechtmäßig bereitgestellter passender experimenteller Extender und eine passend eingerichtete isolierte Testkopie erforderlich. Beides wird durch diesen Download nicht installiert. Ohne diese Voraussetzungen hier stoppen; keine DLLs aus unbekannten Quellen einsetzen und keine reguläre Installation durch einen experimentellen Build ersetzen.
4. Sobald eine unabhängig eingerichtete Testkopie mit dem passenden Extender vorhanden ist, den vollständigen Ordner **mod/SandboxOfElysium** in deren eigenes **mods**-Verzeichnis kopieren und **CoE5SE** sowie **SandboxOfElysium** im ausschließlich dafür verwendeten Profil aktivieren. Die `.c5m` muss direkt im Ordner SandboxOfElysium liegen. Vorhandene Szenarien gesondert behalten. Der konkrete zusätzliche Profilaufbau gehört zur separaten Testumgebung; die vorhandene BAT setzt ihn voraus.

Mac, Linux, Multiplayer und beliebige andere Modkombinationen sind für diesen Entwicklungsstand nicht abgenommen. Eine neue öffentliche Extender-Freigabe müsste gesondert erfolgen; der Mod-Download behauptet keine solche Freigabe.

## Items, Magie und bekannte Grenzen

- Ohne aktive Itemauswahl rechts auf eine gesetzte Einheit → **Edit**. **Items** zeigt ihre tatsächlichen anatomischen Plätze. **Remove → Remove cursed item** entfernt ein verfluchtes Item nach ausdrücklicher Bestätigung; **Cancel** behält es. Zum Ersetzen zuerst entfernen.
- **Permanente Verletzungen werden dadurch nicht geheilt.** Der aktuelle Szenariotyp speichert vollständige native Verletzungen/HP nicht; nach Laden/Reset/Rematch können diese abweichen. Neue Augen-/Herzimplantate bleiben geschützt.
- Wenn das Entfernen eines Itembonus memorierte Zauber ungültig machen würde, bleibt die Ausrüstung unverändert. Die betroffenen Zauber im Tab **Magic Schools & Spells** selbst abwählen und erneut versuchen. Es werden keine Zufallszauber stillschweigend ersetzt.
- Beide Teams dürfen beim Aufbau leer sein; ein Kampf braucht jeweils mindestens eine Einheit. **Clear battlefield** darf das Feld vollständig leeren.
- **Modded Items / Modded schools** beziehen sich auf nachgewiesene geladene Herkunft; unklare Herkunft bleibt Unknown. Fremde Mods müssen separat installiert und aktiv sein.

[Aktueller Crystal-Heart-Test mit Grenzen](docs/TEST-CURSED-2026-11-15.md), [Fenster und Mod-Filter](docs/TEST-PANEL-2026-11-15.md), [Starter-Prüfungen](docs/TEST-LAUNCHER-2026-11-13.md).

## Fehler und Entfernen

Bei einem Startfehler die Konsolenmeldung lesen; fehlende private Testdateien werden durch einen erneuten Git-Download nicht erzeugt. **Editing locked**: **Export Diagnostics**, dann die angebotene sichere Wiederherstellung verwenden. Keine Szenario-/Recovery-Datei löschen, um eine Sperre zu umgehen.

Zum Melden im Editor **Export Diagnostics** wählen und die neu angelegte `.ini` gezielt prüfen/weitergeben. Nicht das ganze private Profil, Spielschlüssel oder komplette Rohlogs veröffentlichen. Testdaten bleiben im oben genannten separaten Ordner.

Zum Entfernen zuerst das Testspiel schließen. In einem selbst eingerichteten Testprofil SandboxOfElysium deaktivieren; die gesicherten Szenarien nach Wunsch behalten. Den gesamten privaten Testordner erst nach bewusster eigener Sicherung/Entscheidung manuell entfernen. Die reguläre CoE5SE-Installation muss für diese lokale Testumgebung nicht geändert oder deinstalliert werden.
