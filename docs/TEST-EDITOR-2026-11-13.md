# Editor, Priestess und Diagnose — 2026-11-13

Lokaler Entwicklungsstand **0.1.0+editor.1**, unveröffentlicht. Keine PRs, Nachrichten, Pushes oder experimentellen Binärdateien im Mod-Paket. Bestehende Änderungen und Szenarien wurden erhalten. Die Berichte zu 0.1.0, Terrain und BAT bleiben als historische Nachweise bestehen.

## Ursache und Korrektur

Der alte `Runtime:add` baute die **gesamte** Aufstellung neu. Native Einheitenerzeugung würfelt die Startzauber der Anointed Priestess erneut. Die Konfigurationsprüfung verglich den neuen Bestand mit dem gespeicherten und verweigerte korrekt die Abweichung. Auch der anschließende Wiederaufbau der alten Armee würfelte erneut und konnte fehlschlagen. Das Problem entstand beim Platzieren; ein Export war nicht die Ursache.

Im echten CoE5-Prozess reproduziert: Priestess als erster Commander, anschließend eine weitere Einheit. Bereits dieser erste zusätzliche Platzierungsversuch scheiterte mit der gemeldeten Fehlermeldung und `restore failed`, Feld danach geschlossen. Detaillierter alter Ablauf: `docs/evidence/editing-2026-11-13/baseline-detailed.ini` (lokaler Beleg; nicht veröffentlicht) enthält die unterschiedlichen gespeicherten und tatsächlich erzeugten Zauber. Dies ist eine nachvollziehbare Variante des Nutzerfehlers, keine Behauptung über jeden damaligen Mausklick.

Die vorhandene API `addTestFieldUnits` erzeugt neue Einheiten und überspringt bei nativer Aufstellung bereits eingesetzte lebende Einheiten. Sandbox fügt nun **inkrementell** hinzu. IDs, HP, Inventar und Zauber vorhandener Einheiten bleiben erhalten. Bei ungültigem Ziel entfernt die neue lokale Extender-Funktion nur die zusätzliche Einheit; vorhandene Positionen werden geprüft/wiederhergestellt. Native Feldverbreiterung wird erkannt, ist aber für extrem große Aufstellungen noch nicht vollständig getestet.

Für unvermeidbare Neuaufbauten bei Copy/Load/Reset/Rematch ergänzt der separate Extender `setTestFieldSpells`. Die nativen begrenzten Listen (60 bekannte, 30 memorisierte signed-short Einträge) und die native Memoriergrenze wurden untersucht. Der Setter validiert vollständig vor dem Schreiben, prüft beide Listen nach dem Schreiben und stellt bei Abweichung die Sicherung wieder her. Items werden vorher wiederhergestellt. Die Prüfung wurde nicht entfernt; es werden keine anderen Zufallszauber akzeptiert und keine ganzen Einheitenrecords kopiert. Die neue Entfernung verweigert den primären Feld-Commander und führt keine Todes-/Kill-Effekte aus.

Neuaufbauten prüfen Fähigkeiten vor dem Schließen. Bei einem späteren Fehler wird die unterstützte alte Konfiguration rekonstruiert; ein möglicher Wiederherstellungsfehler wird ausdrücklich angezeigt und diagnostiziert. Das ist **keine vollständige Engine-Transaktion**: RNG, Zähler und beliebige modabhängige Instanzeigenschaften sind nicht allgemein gesichert.

## Umgebung und Trennung

- Eigene Windows-x64-Installation: CoE5 **5.43**, Steam-Build **26458448**, EXE-SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`.
- Extender im separaten `SandboxOfElysium-ExtenderLab-current`, Branch `sandbox-test-field-terrain-3.4`, Basis **d96f2b784e97e115022a2598da2c821dd9520135**, Metadaten **3.4.0/API 11** plus lokale Änderungen. Kein unveränderter Upstream-Release.
- Geprüfter Editor-DLL-SHA256: `cf38abac73323e267d4955cb830462b604b3b4a22aa96fe0c8adc515aa77d390`. Quellstand und DLL-Hash werden im Starter-Kontext/Diagnosebericht getrennt ausgewiesen.
- Nur `private/terrain-lab/runtime` und eigenes `private/terrain-lab/profile`. BAT prüft Pfade, Spielhash, Build-Fingerabdruck und eine frische Rückmeldung aus genau diesem Profil. Keine echten Spielstände geladen; regulärer CoE5SE 3.2.2 bleibt getrennt.
- Native Forschungsexporte, Backups, Spieldateien, Schlüssel und Builds bleiben unter ignorierten privaten Verzeichnissen. Öffentliche Nachweise hier sind erzeugte Zustandsberichte aus dem eigenen Test.

Die neuen APIs sind in `coe5.lua` des separaten Extender-Checkouts dokumentiert. Der englische lokale Vorschlag liegt dort als **PR_DRAFT_SANDBOX_EDITOR.md**; er wurde nicht eingereicht. `battleUnitAt`, `battleCanStand` und die lesbaren Zauber-/Inventarzugriffe existierten bereits vorher.

## Sichtbar im Spiel bedient und beobachtet

| Ablauf | Beobachtung und Nachweis |
|---|---|
| BAT-Start | Aktuelle Dateien synchronisiert, Spiel mit Sandbox-Menüeintrag erschienen; frische Profilkennung und Plain/Forest-Fähigkeit bestätigt. Abschließender Start mit normaler Mod-Liste, ohne EditingProbe. |
| Suche/Select | Im rechten unteren Menü `ano` gesucht, zwei Treffer mit Idle-Sprites; Anointed Priestess **#208** mit Select gewählt. Fünf Zeilen sind ohne Filter sichtbar, Seitensteuerung vorhanden. |
| Erste und nächste Priestess | Erste für A auf (5,7), nächste für B auf (8,8); Team-Zähler 2/1 → 2/2, native Tokens erschienen ohne Zauberfehler. Erste Priestess blieb native ID **115**, HP **7**, gleicher Standort, alle sechs bekannten und vier memorisierten Zauber identisch. Vorher: `docs/evidence/editing-2026-11-13/ui-priestess-before.ini` (lokaler Beleg; nicht veröffentlicht), nachher: `docs/evidence/editing-2026-11-13/ui-priestess-after.ini` (lokaler Beleg; nicht veröffentlicht). |
| Kontext/Move | Rechtsklick auf vorhandene Priestess öffnete Edit/Move/Copy/Delete, ohne zusätzliche Platzierung. Move gewählt und auf freie Zelle verschoben; ID/HP/Zauber danach unverändert. |
| Fenstergröße | Native Karte bei tatsächlichem Fenster **1200×900** (UI 800×600), danach maximiert (UI **1136×600**). Native horizontale Kamera-/Zentrierung änderte sich 10 → 175 UI-Einheiten. Weitere Priestess am angeklickten Feld erschienen; Panels und Sprites blieben ausgerichtet. |
| Blockierter Baum | Rechtsklick auf sichtbaren Waldbaum: `Placed 0; skipped 1`, verständliche Ablehnung, Zähler blieben 2/3. Export enthält `native target blocked`, `existing army kept`; alle fünf vorhandenen Einheiten vor/nach dem Fehler identisch. Export: `docs/evidence/editing-2026-11-13/ui-resize-blocked-tree.ini` (lokaler Beleg; nicht veröffentlicht), maschineller Vergleich: `docs/evidence/editing-2026-11-13/ui-checks.json` (lokaler Beleg; nicht veröffentlicht). |
| Diagnose | Obere Schaltfläche bedient, drei unterschiedliche Dateien erzeugt, vollständiger Speicherort sichtbar und Inhalte anschließend gelesen. Ein weiterer Abschlusslauf prüfte Plain und den Diagnose-Dialog. |
| Abschlusskampf | Start battle im sichtbaren Plain-Editor: Spearman gegen Goblin, Team A gewann Runde 3 nach 9,891 s; Bericht sichtbar. Erzeugter Bericht: `docs/evidence/editing-2026-11-13/ui-final-plain-battle.ini` (lokaler Beleg; nicht veröffentlicht). |

Bei der ersten UI-Runde wurde ein zusätzlicher Integrationsfehler gefunden: Die neue Kartenfunktion verweigerte den Aufruf **nach** `BATTLE_WAIT next()`, weil ein nativer Framezähler bereits beendet war. Rechtsklicks wurden erfasst, aber keiner Zelle zugeordnet. Die Schutzprüfung berücksichtigt nun die vollständige Lua-Callback-Tiefe. Der native Regressionstest prüft genau diese Stelle; erst danach wurden die erfolgreichen Platzierungen oben durchgeführt. Fehlerexport vor der Korrektur: `docs/evidence/editing-2026-11-13/ui-before-frame-guard-fix.ini` (lokaler Beleg; nicht veröffentlicht) bleibt erhalten.

Beim Diagnose-Dialog wurde außerdem der gehaltene Rest eines Linksklicks an native Battle-Controls weitergereicht und öffnete das Battle Log. Ein bloßes einmaliges Löschen des Mauszustands/Resultats reichte nicht. Die linke Taste wird im Editor nun über die gesamte Haltezeit konsumiert; mittlere Taste und unabhängige native IDs bleiben erhalten. Kartenhinweise bleiben im Overlay. Abschließend Export → OK → direkte Rückkehr zur Karte sichtbar bestanden, danach der obige Kampf. Letzter Export: `docs/evidence/editing-2026-11-13/ui-final-diagnostics.ini` (lokaler Beleg; nicht veröffentlicht). Hinweise innerhalb der verschachtelten nativen Edit-/Report-Menüs bleiben synchron; diese letzte Unterscheidung wurde offline geprüft.

## Im echten Spiel über native API getestet

Diese Prüfungen laufen als eigene, standardmäßig deaktivierte `ZZSandboxEditingProbe` innerhalb von CoE5 gegen die produktiven Sandbox-Module. Sie sind keine Mausbedienung und keine simulierten Kämpfe. Endergebnis: `docs/evidence/editing-2026-11-13/regression-final.ini` (lokaler Beleg; nicht veröffentlicht): alle fünf Gruppen **PASS**.

| Prüfung | Ergebnis |
|---|---|
| Zwölf zusätzliche Einheiten, beide Teams | Konfigurierte ursprüngliche Priestess behält native ID, HP, bekannte/memorisierte Zauber, Item **A Chest Full of Fire** und zuvor verschobene Position nach jeder Hinzufügung. |
| Copy/Move/Delete | Kopie mit gleichen gespeicherten Zaubern und Item erstellt, verschoben, gelöscht; Originalzustand unverändert. |
| Setter-/Remove-Schutz | Acht echte Ablehnungen, u.a. doppelte/negative/nichtnumerische/sparse Zauber, Memorisiert-ohne-Bekannt, ungültige Einheit und primärer Commander; Originalzustand unverändert. |
| Save/Load und Fehler-Rückkehr | Tatsächliche INI gespeichert/gelesen, exakte Zauber wiederhergestellt. Absichtlich ungültige gespeicherte Position abgelehnt; alte Konfiguration wieder geöffnet. |
| Reset/Rematch | Zwei tatsächliche Priestess-vs-Goblin-Kämpfe; danach jeweils ursprüngliche Zauber und Positionen wiederhergestellt. Vier Aufrufe im laufenden Kampf wurden mit `in_fight` verweigert. Kampf 1: `docs/evidence/editing-2026-11-13/priestess-fight-1.ini` (lokaler Beleg; nicht veröffentlicht), Kampf 2: `docs/evidence/editing-2026-11-13/priestess-fight-2.ini` (lokaler Beleg; nicht veröffentlicht). |
| Diagnosefehler | Tatsächlicher Add-Versuch mit x=-1 verweigert, Armee unverändert; zwei eindeutige Exportnamen, Versionen sowie gespeicherte/tatsächliche Zauber vor/nach dem Fehler geprüft. Bericht: `docs/evidence/editing-2026-11-13/native-diagnostics.ini` (lokaler Beleg; nicht veröffentlicht). |
| Projektion/Terrain | Plain und Forest nativ geöffnet; sichtbare Zellzentren (520 von 640 im gemessenen Ausschnitt) zurück in dieselbe Zelle umgerechnet. Fünf echte WAIT-Aufrufe **nach next()** erfolgreich. Native Terrain-ID jeweils geprüft. Die früheren vollständigen Terrain-/Rücksetztests bleiben im [Terrainbericht](TERRAIN-EXPERIMENT-2026-11-13.md). |

Eine frühe Regression scheiterte an einem **Testskriptfehler**, das die schreibgeschützte Variable battleDelay setzen wollte. Dieser Versuch ist als `regression-01.ini` erhalten; der unzulässige Testzugriff wurde entfernt und die Prüfung erfolgreich wiederholt. Das ist vom behobenen Produktfehler getrennt.

## Außerhalb des Spiels geprüft

- **20** Modell-/Validierungsprüfungen: alle Formationen, Persistenz, Mod-/Inhaltsidentität und Terrain-/Legacy-Schutz.
- **8** Editor-/Diagnoseprüfungen: 64er-Ring/Chronologie, freie Exportnamen, synthetische Pfad-/Zugangsdaten-Redaktion, Kontextvorrang, gehaltene Rechtsklick-Ereignisse einmal je neuer Zelle, Panel-Abdeckung, Select, Move-Eingabe und Dialogresultat-/native-ID-Behandlung.
- Alle ausgelieferten Lua-Module und Probe-Skripte geparst; PowerShell-/Python-Syntax und BAT-Pfadprüfung geprüft. Die separat bestehenden 21 Terrain-Parserfälle gehören zum früheren Terrainbericht und wurden nicht als neue Editor-Tests gezählt.
- Reguläre Spiel-EXE, installierte Extender-DLL und normales coe5config anhand der vorhandenen Vorher-Hashes erneut unverändert bestätigt. Ergebnis ohne persönliche Pfade: `docs/evidence/editing-2026-11-13/normal-files-check.json` (lokaler Beleg; nicht veröffentlicht). Ein Doppelstart während der Prüfung wurde verständlich verweigert.

Offline-Eingabeereignisse belegen keine physische Rechtszieh-Geste oder native Kamerarichtigkeit. Ebenso bedeutet eine vorhandene API-Funktion allein keinen bestandenen Kampf.

## Diagnoseumfang und Grenzen

Erreichbar im Setup, oben auf der Karte und in Fehlerhinweisen. Sitzungskennung plus freier Zähler verhindern stilles Überschreiben; interne Namen sind für Save gesperrt. Automatisch gesammelt werden Aktion/technischer Fehler, betroffene Einheit/Ziel, Wiederherstellungsstatus und lesbare Aufstellung vor/nach dem Fehler. Export enthält Version, experimentellen DLL-Hash, Sandbox-Quellhash, Launcher-UTC, relative Ticks, aktive Mod-Namen, Terrain/Team sowie gespeicherte/tatsächliche Zauber-IDs und -Namen.

Maximal 64 Aktionen, 24 Einheiten je Snapshot, 4096 Zeichen je Wert; Kürzungen/fehlende Werte gekennzeichnet. Pro-Mod-Versionen und genaue Export-Uhrzeit sind unbekannt, Launcher-UTC ist kein Exportzeitpunkt. Keine Voll-Logs, Profileinstellungen, Schlüssel oder absoluten Pfade im Bericht; der lokale Speicherort wird nur im Hinweis angezeigt. Bei Quota-/Schreibfehlern erscheint eine Ablehnung.

## Noch offen / nicht vollständig getestet

- Lange **physische** Geste mit gedrückter rechter Maustaste: Werkzeug bietet keinen Rechtsdrag. Ereignislogik offline und wiederholte native Hinzufügungen geprüft; vollständige manuelle Gestenabnahme fehlt.
- Freies Schwenken mit mittlerer Taste sowie sämtliche Zoom-/Kamera-Kombinationen nicht vollständig bedient. Pfeil-/Mausrad-Versuche zeigten keine sicher beobachtbare Bewegung; daraus wird kein Kameratest abgeleitet. Größenwechsel mit geänderter nativer Zentrierung ist tatsächlich geprüft.
- Extrem große Armeen mit Notfall-Feldverbreiterung, alle großen Fußabdrücke, jede Fremdmod-/Inventar-/Magie-Kombination, vollständiges RNG-/Engine-Rollback und Fremdmod-Owner-Ablehnung nicht vollständig nativ geprüft.
- Primärer Commander muss bestehen bleiben; Clear extra units behält ihn. Ein vollständig leeres natives Feld fehlt.
- Basis-Magiestufen, allgemeine anatomische Item-Zuweisung, Attack-Sprite-Auswahl und vollständiges Cast-/Schadensprotokoll bleiben offen.
- macOS, Wasser, Belagerungen, Sonderdimensionen, Kampagneneffekte und Multiplayer sind nicht freigegeben.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
