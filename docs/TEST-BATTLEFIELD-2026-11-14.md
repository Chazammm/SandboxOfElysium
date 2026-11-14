# Schlussbild, leeres Feld und zusätzliche Geländearten — 14.11.2026

## Stand und Bindung der Nachweise

Dieser Bericht trennt sichtbare Bedienung, native Probes im tatsächlichen Spiel und Offlineprüfungen. Der abschließende normale Build besteht die unten aufgeführten Gruppen; frühere unvollständige oder fehlgeschlagene Versuche bleiben getrennt erhalten. Eine vorhandene Capability allein gilt nicht als bestandene Prüfung.

- Eigene CoE5 **5.43**, Windows x64, EXE-SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`.
- Nutzerstand: Sandbox **0.1.0+editor.4**, Extender **3.4.0**, DLL-SHA256 `e08b5a56b0e2e5eac7bcbe6d09fe2b798cd585950955fcdff1c92e1fc29ff9af`, Sandbox-Quellhash `df24879e59ceec17b41d9a26f35278fc202fc6761e7186ab6c1d52c5e8dba4ed`.
- Erster sichtbarer Kandidat: Sandbox **0.1.0+editor.5**, DLL-SHA256 `fed1bff370bec08b2de2f4a69f5eb36a9804ff2f49a3f15af1aa4fce41fa51fe`, Sitzung `238dd83139fe4a4baec3134ff74156ee`.
- Historischer korrigierter API-Kandidat: DLL-SHA256 `e9c93442207d0eac0607182e81043881d07c9b50e9148e766f051b8692306455`, Sitzung `3aa7f0da0dd44801918f158386d3633b`, Launcher-UTC `2026-11-14T13:59:23Z`, Sandbox-Quellhash `20db500868da6f337c6deba34b10d7d1d3b7838659e26d3f54e4913edc435ee6`. Seine abgeschlossenen Terrain-/Empty-/Filtergruppen und sein unvollständiger Großkampf bleiben getrennt.
- Abschließender normaler Build **ohne Terrain-Kandidatenflag**: DLL-SHA256 `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`, Sitzung `54f26dddea5a440db8ffd327e9351cee`, Sandbox-Quellhash `409c10230c2853cd68a2227c2a345d5a001e30637cd720f66240cd2465c796ed`. Launcher-Bindung: `docs/evidence/battlefield-2026-11-14/final-54f26ddd/last-launch.json` (lokaler Beleg; nicht veröffentlicht), Quellbindung: `docs/evidence/battlefield-2026-11-14/final-54f26ddd/launcher-context.ini` (lokaler Beleg; nicht veröffentlicht).

Getestet wird ausschließlich in der vorhandenen isolierten Spielkopie mit eigenem Profil. Die ursprünglichen Diagnosen, Szenarien und Recovery-Dateien bleiben erhalten. Die drei unten genannten Nutzerdiagnosen stimmen per SHA256 weiterhin mit den Kopien in `private/battlefield-before-931288ebeb7b426b9b288b1cdd116463/profile-data` überein. Private Spiel-/Extender-Binärdateien und native Forschungsdaten gehören nicht in das Modpaket. Kein PR, Kontakt, Push oder Release wurde durchgeführt.

Der vollständige Bestandsaudit meldet **60/60 ursprüngliche Dateien hashgleich**: 31 Diagnosen, 23 Berichtsdateien und sechs Dateien mit Szenarioabschnitt (zwei Recovery-Dateien, eine bereits reparierte Datei, drei frühere QA-Dateien). `Test.ini` und `ggg.ini` gehören zu den Berichten, nicht zu den Szenarien. Bei vorhandenen generierten Verwaltungsdateien änderten sich nur der Launcher-Kontext und das fortgeschriebene `last-battle`; neue Berichte erhalten eigene Archivnamen. Die drei kontrollierten regulären Dateien — installierte Spiel-EXE, reguläre Extender-DLL und normale Spielkonfiguration — blieben **3/3 hashgleich**. Diese Prüfung wird von den bewusst neu erzeugten Testausgaben getrennt.

## Tatsächlicher Nutzerablauf

Gelesen wurden die unveränderten Dateien `diagnostics-5bd42749aa2c47d4ba1b-{1,2,3}.ini` und die zugehörigen fünf `battle-5bd42749aa2c47d4ba1bcafdd15a239a-*.ini`. Die Diagnose enthält höchstens 64 aktuelle Aktionen; ältere Fehlerbilder und Vorher-/Nachher-Snapshots können aus einer anderen Feldgeneration stammen.

| Export | Belegter Ablauf und Zustand |
|---|---|
| `…-1.ini` | Sechs Einheiten geladen, danach Spearman, zwei Strange Seraphs und Abomination ergänzt. Zehnerkampf: Runde 6, Sieger 24; Rematch: Runde 7, Sieger 24. Letzter Bericht: A4 gestartet/0 überlebt, B6/5. Aktueller Export: fünf lebende native Zeilen mit fehlenden Ankern, **null belegte Rohzellen**, keine Bearbeitungssperre und kein protokollierter Fehler. |
| `…-2.ini` | Begrenztes Log beginnt erst mit Sequenz 87. Mehrfach `clear_extra` mit **einer verbleibenden Einheit**, dazwischen zweimal Reset auf zehn Einheiten. Export in Vorbereitung: Modell und native Abfrage jeweils eine Einheit, keine nativen Issues. Dies belegt, dass die bisherige Aktion bewusst den Feldkommandanten behielt; es ist kein Nachweis eines unsichtbaren zusätzlichen Akteurs. |
| `…-3.ini` | Nach erneutem Leeren bleiben wieder eine Einheit; Rider, Abomination of Desolation und zwei Seraphs ergänzen die Aufstellung auf fünf. Save, Clear, Load mit fünf Einheiten, natürlicher Kampf Runde 14, Sieger 24. Bericht: A3/0 Überlebende, B2/2. Aktueller Export: zwei lebende native Zeilen ohne Anker und wieder **null belegte Rohzellen**. |

Die alten Berichte nennen bei sämtlichen fünf Kämpfen `final_position_count=0`. Die beiden Zehnerberichte haben fünf beobachtete Aftermath-Positionen; der Fünferbericht trotz zweier Überlebender nur eine. Das bisherige `BATTLE_TURN_EFFECTS`-Teilprotokoll reicht daher nicht als vollständige Schlussaufstellung.

Der letzte Fehler in Export 3 lautet dagegen „This creature is unique … already on the field“, mit `restored=unchanged`. Seine Vorher-/Nachher-Daten gehören zu Feldgeneration 9 und sind gekürzt; der aktuelle Nachkampfzustand gehört zu Generation 11. Dieser gespeicherte Guard-Fehler ist kein Beweis dafür, dass eine neue Platzierung das spätere leere Schlussfeld verursacht hat. Die Zeitlücken des begrenzten Logs werden nicht durch erfundene Aktionen ergänzt.

## Ursache und neue Schlussdarstellung

Die unveränderte alte DLL reproduzierte im echten Spiel: natürlicher Kampf Runde **5**, Sieger **0**, **ein Überlebender**, danach **null belegte native Rohzellen**. Baseline-Ergebnis: `docs/evidence/battlefield-2026-11-14/baseline-final-cleared.ini` (lokaler Beleg; nicht veröffentlicht).

Die native Analyse erklärt dies: Nach Bestimmung des Gewinners laufen 75 Nachwirkungs-Ticks. Danach folgen Nachkampf-Abrechnung, Entfernung bestimmter temporärer Akteure und schließlich der vollständige Reset des Kampfzellenrasters. Ein offenes Testfeld erhält damit nicht automatisch seine Einheitenanker. Lebende native Datensätze und das sichtbare Kampflog können bestehen bleiben, obwohl das Raster leer ist. Einzelheiten, geprüfte Callsite und Datenquellen stehen in [NATIVE-FINAL-FIELD-2026-11-14.md](NATIVE-FINAL-FIELD-2026-11-14.md).

Der Extender erfasst deshalb genau **nach den Nachwirkungs-Ticks und vor der Nachkampf-Abrechnung** einen nativen Einheiten-/Zellen-Snapshot, Quelle `post_aftermath_before_upkeep`. Der ursprüngliche native Ablauf einschließlich Upkeep und Entfernung temporärer Einheiten läuft anschließend vollständig weiter. Es werden keine alten Einheiten wiederbelebt und keine Raster-IDs in die native Simulation zurückgeschrieben.

Die Sandbox zeichnet daraus eine ausdrücklich lesende Schlussansicht mit den erfassten Ankern, Monsteridentitäten, Besitzern und vollständigen Footprints. Tote Akteure sowie lebende Akteure ohne verifizierten Anker werden nicht an erfundene Positionen gesetzt. Native Herkunft und Generationen unterscheiden Unique-Kopien, während des Kampfscopes erzeugte Einheiten und später neu belegte Handles. `createdDuringFight` belegt die Erzeugungszeit, nicht automatisch einen bestimmten Beschwörungszauber. Ein Fluchtmarker wird als gelesener Marker ausgewiesen; eine vollständige Fluchtgeschichte wird nicht behauptet.

`complete=true` betrifft die überprüfte Einheiten-/Zellenaufnahme an dieser Zeitgrenze. **`sceneComplete=false` bleibt gesetzt:** Projektile, Partikel, Animationen, Sound und sämtliche Renderer-/Zeitdaten werden nicht als vollständige native Szene konserviert. Snapshot und aktueller Zustand nach Upkeep bleiben in Bericht und Diagnosen getrennt.

Survivor-Inspect öffnet die echte native Karte des **jetzt** noch lebenden passenden Datensatzes, nicht eine historische Karte mit Snapshotwerten. Nach der Aufnahme entfernte oder ersetzte Akteure erhalten einen verständlichen Unverfügbarkeitsgrund. Die Karte bleibt lesend. Die Schlussansicht blockiert Add/Move/Delete/Fire/Fight; Back to Sandbox, Reset und Rematch bauen die separat bewahrte Ausgangsaufstellung wieder auf. Vorherige Berichte bleiben archiviert.

## Tatsächlich leeres Bearbeitungsfeld

`emptyEditor=true` ist ein eigener geprüfter API-Modus. Beide Seiten dürfen leer sein. Er erzeugt keinen `NEW_COMMANDER`, keinen Pflichtkommandanten und keinen versteckten Dummy. Alle ausdrücklich gewünschten A-/B-Einheiten entstehen über den normalen nativen `NEW_UNIT`-Pfad ohne Leader. Die Rückgabe enthält `commander=-1`; der Runtime-Zeiger `primaryId` bleibt leer.

Eine leere Actorliste bedeutet nicht, dass auch native Bäume, Steine und andere Geländeobjekte fehlen müssen. Im korrigierten API-Lauf wurden beim leeren Plain-Feld **0 Modell-/0 native Actorzeilen**, **0 erzeugte Actor-Datensätze**, aber **4 native Geländedatensätze/-zellen** gemessen.

Das spätere Hinzufügen und vollständige Entfernen beider Teams ist erlaubt. Der Kampf prüft die tatsächlichen lebenden nativen Actors und ihre vollständige Herkunft vor Beginn: 0/0 und B-only ergeben `missing_team_a`, A-only `missing_team_b`. Diese Ablehnungen ändern weder Runde, Sieger, Allokationen, Raster noch HP/Zauber/Items. Alte API-Aufrufe ohne den Modus behalten ihren echten geschützten Primärkommandanten und die Ablehnung `primary_commander`.

Zusätzlich wurde nach einem Legacy-Kommandantenfeld geschlossen, leer neu geöffnet und A/B ergänzt. Der aktuelle Lauf las einen Commander-Datensatz numerisch zurück: keine `commanderUnit`-Referenz auf die neuen Akteure, unveränderter Commander-High-Water-Mark 0. `unitCommander=-1` wurde nur zusätzlich als Leader-Angabe gelesen und nicht allein als Beweis fehlender Commander-Eigenschaft verwendet.

## Zusätzliche Geländearten: Pipeline und Freigabegrenze

IDs und Namen stammen aus dem bereits vorhandenen tatsächlichen Terrain-Katalogexport und werden im laufenden Spiel erneut gebunden. Keine ID wurde geraten.

| ID / Name | Native neutrale Ground-ID | Stand der Erweiterung |
|---|---:|---|
| 0 Plain | 0 | Bisher unterstützt; korrigierter aktueller Native-Matrixlauf bestanden. |
| 2 Forest | 0 | Bisher unterstützt; korrigierter aktueller Native-Matrixlauf bestanden. |
| 12 Mountains | 0 | Kandidatenmatrix und normaler Endbuild vollständig bestanden; freigegeben. |
| 107 Swamp | 5 | Kandidatenmatrix und normaler Endbuild vollständig bestanden; freigegeben. |
| 117 Desert | 4 | Kandidatenmatrix und normaler Endbuild vollständig bestanden; freigegeben. |

Alle verwenden den vorhandenen nativen Elysium-Kontext mit Temperatur **25**, nativer Ground-Initialisierung und regulärer Battle-Setup-/Vegetations-/Hindernis-Erzeugung. Mountains setzt den nativen Mountain-Zweig mit Ridge-/Felsmerkmalen; Swamp und Desert besitzen eigene native Scatter-Zweige. Es werden keine dekorativen Ersatzbäume oder Ersatzhügel manuell hinzugefügt.

Der neue Policy-Header verlangt exakte ID/Name-Bindung; neue Kandidaten zusätzlich ihre Land-Flags, General-Battlemap und das Fehlen ausgeschlossener Wasser-/Fort-/Höhlen-/Spezialebenen-Tags. Erst nach Prüfung der vollständigen aktuellen Kandidatenmatrix wurden die drei betreffenden Source-Zeilen auf `verified=1` gesetzt. Der normale Endbuild ohne Kandidatenflag wurde anschließend in zwei getrennten Sitzungen tatsächlich getestet; auch nach der Platzierungskorrektur bestanden alle fünf Karten erneut.

Der Test prüft echte 1×1-/2×2-/3×3-Aufstellung und innere Trefferzellen, Löschen, gültiges Bewegen, tatsächlich blockierende Objekte soweit vorhanden, Feldrand, Save/Load, zwei natürliche Kämpfe, exaktes Reset/Rematch, vollständigen Cleanup und Wiederherstellung des geliehenen Welt-/Quadrat-/Ebenenkontexts. Beobachtete Bewegungsübergänge sind **kein quantitativer Vergleich von Kampagnen-Bewegungskosten**. Jahreszeiten, Klima-/Nachbargradienten, Verzauberungen und Fraktionseffekte werden nicht nachgestellt. Wasser, Forts, Belagerungen, andere Ebenen und Mac sind nicht freigegeben.

## Erhaltene Kandidatenfehler und korrigierter Testaufbau

Der erste vollständige Kandidat bleibt unter first-candidate: `docs/evidence/battlefield-2026-11-14/first-candidate` (lokaler Beleg; nicht veröffentlicht) erhalten:

- Empty-Probe zunächst **4/5**: Die Caster-Gruppe suchte fälschlich den exakten Namen `Priestess`. Der geladene geprüfte Name lautet `Anointed Priestess`. Nur der Testname wurde korrigiert; ID-/Namensprüfung wurde nicht gelockert.
- Terrain-Matrix zunächst Plain und die drei neuen Landkandidaten bestanden, **Forest fehlgeschlagen**. Der Test hatte nach einer Viereraufstellung die großen Prüfeinheiten entfernt, einen Actor an einen beliebigen aktuell freien Rand bewegt und diese Positionen als Zweieraufstellung gespeichert. Beim erneuten nativen Aufbau blockierten Bäume die gespeicherten Ziele; auch die Rückkehr zu dieser nicht mehr realisierbaren Testaufstellung scheiterte. Der Runtime meldete den fehlgeschlagenen Rollback und sperrte; der nachfolgende Cleanup wurde verifiziert. Dies wird nicht als Erfolg umgedeutet.
- Der korrigierte Test legt nach den Großformat-Prüfungen ausdrücklich die endgültige **Zweier-Testaufstellung nativ neu** an, zeichnet deren tatsächliche Anker auf und setzt temporäre Bewegungsversuche vor dem Speichern dorthin zurück. **Alle folgenden Save/Load-/Reset-/Rematch-Aufbauten verlangen weiterhin exakt diese gespeicherten Positionen.** Es gibt keinen automatischen Neuaufstellungs-Fallback für Nutzerdateien. Eine weiterhin blockierte Rückkehr würde erneut als Fehler zählen.

Native Deployment sucht mittels realer Platzierungsprüfung und begrenzter Wiederholungen einen freien Platz; seine Anker sind keine allgemeine Garantie für einen späteren anderen Roster. Die genaue Ursache jedes alten einzelnen Scatter-Unterschieds wird damit nicht zusätzlich als bewiesen behauptet.

## Sichtbar in der tatsächlichen Spieloberfläche geprüft

Diese Livebeobachtungen gehören zum ersten Kandidaten `fed1…`, nicht automatisch zum späteren korrigierten DLL-Build. Die früher gespeicherten Bilddateien sind nicht zuverlässig zuordenbar und werden nicht als Bildbeleg verwendet. Native Exporte und die später frisch aufgenommenen öffentlichen Ansichten sind separat gekennzeichnet.

| Bedienung | Beobachtung / Nachweis |
|---|---|
| Clear battlefield | **Team A 0 / Team B 0**, kein platzierter Actor; normale native Geländeobjekte bleiben erlaubt. Leeres Feld (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Leere Seite → Start battle | Verständlicher Hinweis, mindestens eine Einheit pro Team zu platzieren. Ablehnung (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Empty/B-only Save/Load | Leere Datei `qae5.ini` mit `count=0`, B-only `qab5.ini` mit `count=1`; sichtbare Rückkehr zu A0/B0 beziehungsweise A0/B1. Empty laden (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), B-only laden (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Natürlicher kleiner Kampf | Bericht Runde **6**, Sieger A; je ein Spearman auf A/B, A überlebt, B verloren. Zwei getrennte archivierte Berichte. Rematch-Bericht (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Schlussansicht | **Snapshot A1/B0**, Spearman an erfasstem Feldanker sichtbar; Quellen-/Vollständigkeitshinweis und lesender Modus werden angezeigt. Schlussbild (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Survivor-Inspect | Echte native Spearman-Karte mit HP **3/6**, Stärke, Moral, Rüstung, Spear und Beschreibung; Exit vorhanden. Native Karte (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Back/Reset/Rematch | Ursprüngliche A1/B1-Aufstellung sichtbar zurück, weiterer Kampf/Rematch mit Bericht. Back (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Reset (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |

Die zugehörigen ersten sichtbaren Report-/Szenario-/Diagnosedaten: `docs/evidence/battlefield-2026-11-14/first-visible` (lokaler Beleg; nicht veröffentlicht) bestätigen 640 erfasste Zellen, `final_snapshot_complete=1`, keine Snapshot-Issues und gleichzeitig `final_scene_complete=0`. Die danach geleerte Live-Abfrage wird separat mit `observation_phase=after` und passendem Scope ausgewiesen. Das ist gerade kein Widerspruch zu den sichtbaren Snapshot-Einheiten.

Große Überlebende und Beschwörungen sind mit diesen kleinen Bildern allein nicht bewiesen. Die folgenden späteren Nachweise gehören ausdrücklich zum normalen Endbuild.

## Zusätzlich gefundener und behobener Wiederaufbauzyklus

Der normale erste Folgelauf erfasste die echte Zehneraufstellung vollständig und beendete den Kampf natürlich, verweigerte aber den anschließenden exakten Wiederaufbau. Eine getrennte Wiederholung scheiterte bereits beim frischen Aufbau vor dem Kampf. Dieser zweite Fehler war damit kein Beweis eines nach dem Kampf liegen gebliebenen Actors. Erhaltene erste normale Ergebnisse: `docs/evidence/menu-mods-2026-11-14/normal-6f2f739f/battlefield-results.ini` (lokaler Beleg; nicht veröffentlicht), getrennte Reproduktion: `docs/evidence/battlefield-2026-11-14/normal-b336a180/battlefield-results.ini` (lokaler Beleg; nicht veröffentlicht).

Die neue Diagnose `diagnostics-b336a18090da41608030-6.ini` hält den Zustand **vor dem Schließen des fehlgeschlagenen Feldes** fest: Die Testmodelle 1/2/3 sind Underworld-Gods mit 3×3-Footprint, Testmodell 9 ein 2×2-Seraph. Deren gewünschte Anker sind (21,6), (21,12), (21,17), (19,15); aktuelle Startanker blockieren sich über vollständige Footprints. Der zuerst wartende God wurde wiederholt nach (0,0) „geparkt“. Die tatsächliche Schleife zwischen anderen Einheiten wurde dadurch nicht freigegeben; der Wiederholungszähler lief aus. Diese Modell-/nativen IDs gehören zur neuen Reproduktion, nicht zu vermuteten früheren Nutzer-Löschungen. Das native Cleanup bestätigte danach alle eigenen Actors als stillgelegt.

`Runtime:place` bildet nun zuerst die vollständige Zielgeometrie ab. Überlappende/außerhalb liegende Ziel-Footprints werden vor einer Bewegung abgewiesen. Bei einer Blockade wird **jeder noch wartende Actor höchstens einmal** auf eine nativ erlaubte Zwischenfläche außerhalb **sämtlicher Ziel-Footprints** evakuiert. Nicht nur die Zielanker sind geschützt. Ein Actor verbleibt nie erfolgreich an einem Zwischenplatz: Abschließend müssen alle exakten Zielanker, Footprints, Teams und Konfigurationen global bestätigt sein. Fehlen sichere Zwischenplätze oder blockieren echte Geländeobjekte ein Ziel, bleibt dies eine explizite Ablehnung mit den bestehenden Rollback-/Recovery-Regeln. Temporäre Schritte sind diagnostisch als `deployment_parking`, noch ohne Erfolgsgarantie, protokolliert.

Der aus der echten Diagnose rekonstruierte Zehneraufbau besteht danach **zwei natürliche Kämpfe inklusive Rematch**, beide Runde **7**, Sieger **24**, mit exaktem Wiederaufbau nach beiden Kämpfen. Bekannte/memorisierte Zauber, Items, Teamzuordnung und gespeicherte Positionen bleiben identisch. Keine Nutzerdatei wurde für den Test neu positioniert. Die ursprüngliche Vermischung von geleertem Nachkampfraster und lebenden Datensätzen wird separat durch den finalen Snapshot gelöst.

## Abschließender nativer und Offline-Prüfstand

Die Dateien unter final-54f26ddd: `docs/evidence/battlefield-2026-11-14/final-54f26ddd` (lokaler Beleg; nicht veröffentlicht) wurden nach dem vollständigen Lauf gesichert. Alle folgenden Gruppen bestehen mit der oben genannten normalen DLL und dem aktuellen Sandbox-Quellstand:

| Native Gruppe | Nachgewiesener Umfang |
|---|---|
| Editing **5/5** | Inkrementelle Priestess auf beiden Teams, Copy/Move, native Spell-Validierung, Legacy-Commander-Schutz, Save/Load/abgelehnter Aufbau/Reset/Rematch, Fehlerexport, Projektion Plain/Forest. |
| Placement **4/4** | 1×1-/2×2-/3×3-Löschen und Zellwiederverwendung, Zauber/Item-Erhalt, Unique-Guards, tatsächliche Forest-Blockade, injizierte Cleanup-Ablehnung mit Sperre und expliziter Recovery. |
| Inspector **3/3 ausgewählt** | Original ungültig abgewiesen und explizite gültige Kopie, atomare unabhängige Memorierung, vollständige native Footprints und Frame-Preflight. Die separate Sechser-Kampfgruppe unten ersetzt keinen ungeprüften Inspector-Fall. |
| Empty **5/5** | 0/0 und beide einseitigen Aufbauten, unveränderte Kampfablehnung, Persistenz, Unique-Vorprüfung, konfigurierter Anointed Priestess mit Chest über fremde/letzte Löschungen und Wiederverwendung, vollständige Commander-Referenzprüfung, zwei natürliche Kämpfe mit Wiederaufbau. |
| Terrain **5/5** | Plain/Forest/Mountains/Swamp/Desert jeweils vollständige Umwelt-/Großformat-/Objektblockade-/Persistenzmatrix und je **zwei** natürliche Kämpfe mit exaktem Reset/Rematch, Cleanup und wiederhergestelltem Leihkontext. |
| Sechs konfigurierte Gods | Natürlicher Kampf Runde **16**, Sieger **0**, zwei große Überlebende, vollständige zeitlich gebundene Aufnahme, lesende Abweisungen, Cleanup und exakte Konfigurationsrückkehr. |
| Tatsächlicher Zehneraufbau | Kampf und Rematch Runde **7**, Sieger **24**; vollständige Aufnahme und exakte Rückkehr nach beiden. Erster Snapshot: **17** lebende positionierte Actors, davon **12** im Kampf neu erzeugt und anschließend entfernt; fünf ursprüngliche Überlebende nach Cleanup. |
| Explizite Beschwörungsprobe | Bewahrter Underworld-Caster mit seinen tatsächlich bekannten Summon-Zaubern in einer ausdrücklich getrennten Testkopie. Runde **5**, Sieger **24**; **9** lebende Actors am Aufnahmezeitpunkt, davon **8** neue Beschwörungsakteure, die später nativ entfernt werden. Capture bleibt unverändert, keine Wiederbelebung für Inspect. |
| Filter | Alle **1851** Monster vor Feldöffnung/in Feldansicht identisch boolesch klassifiziert, keine unbekannten Werte. human 434, animal 138, undead 198, demonic 60, flying 233, ranged **714**. |

Die eigenständige kleine Final-Probe bestand außerdem bereits mit derselben normalen DLL unter normal-63b293: `docs/evidence/battlefield-2026-11-14/normal-63b293/final-results.ini` (lokaler Beleg; nicht veröffentlicht). Die aktuelle CrabCult-Matrix ist getrennt im [Menü-/Modbericht](TEST-MENU-MODS-2026-11-14.md) belegt.

**Offline: 97 Lua-Fälle bestanden** — Modell 20, Editor/Privacy 10, Integrität 13, Interface 18, Caster 8, Preview/Inspect/Repair 15, Battlefield 13 — plus Syntaxprüfung aller verteilten Lua-Dateien/Probes. Vollständige Ausgabe: `docs/evidence/battlefield-2026-11-14/offline-97.txt` (lokaler Beleg; nicht veröffentlicht). Zusätzliche kontrollierte C-/Lua-Tests: Empty-Dispatcher/Vertrag 31, Schlussaufnahme 26, Ranged-Dispatcher 29, Terrain-Policy 51 normal und 51 Kandidat. Diese Prüfungen mit kontrollierten Readbacks sind ausdrücklich keine echten Spielsimulationen.

Begrenzte Exportlisten bevorzugen Actors vor Geländeobjekten, damit dichtes Gelände späte Beschwörungen nicht allein durch die Grenze verdeckt: Bericht/Diagnose höchstens 48, Probe höchstens 64 Zeilen. Die native vollständige Aufnahme wird weder umsortiert noch verkleinert. Ein gekürzter Export bleibt als solcher gekennzeichnet.

## Sichtbare große Schlussansicht und verbleibende Grenzen

Im normalen Endbuild wurde die unveränderte gültige Sechserkopie sichtbar geladen und an ihren gespeicherten Positionen geöffnet. Der erste natürliche Kampf endete Runde **16**, Sieger **A**, mit zwei überlebenden God Emperor, Wandzeit rund **114 s**. Beide 3×3-Überlebenden erscheinen im Schlussbild an den erfassten Endankern mit Blue-Footprint, korrektem Sprite und Snapshot A2/B0. Ein Rechtsklick auf eine **innere** Footprint-Zelle öffnete den passenden echten God: **70/161 HP**, zehn Kills und die nativen bekannten/memorisierten Listen (vier je Schule). Das lange native Fenster lässt sich bis Exit scrollen; nach Schließen blieb die Schlussansicht unverändert. Große Schlussansicht (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), native Karte (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). Während des Kampfes waren Horde-of-the-Night-Shades und ihre tatsächlichen Sprites sichtbar. Kampf mit Beschwörungen (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). Der sichtbar gestartete **Rematch** endete ebenfalls Runde **16**, Sieger A, A2/B0, rund **44 s**. **Back to Sandbox** und anschließend **Reset** stellten beide Teams mit je drei großen Einheiten an ihren gespeicherten Ankern wieder her. Rematch (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Rückkehr (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Reset (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg).

Noch nicht als natürlicher echter Fall nachgewiesen sind konkrete Transformationen und Konversionen sowie ein reguläres Kampfende mit lebenden ursprünglichen Actors beider Seiten. Owner-/Monsterwechsel ohne falschen Generationsverlust werden durch die native Implementierung und kontrollierte Tests abgedeckt; das wird nicht als sichtbare Transformation ausgegeben. Vollständige Flucht-/Erzeugungshistorien und allgemeine Instanz-/RNG-Snapshots sind nicht zugesagt. Snapshot-Effekte/Projektile/Animationen fehlen ausdrücklich. Lange physische Rechts-Ziehfolgen, alle Zooms, Wasser/Forts/Spezialebenen, Mac und beliebige Mod-Skriptkombinationen bleiben außerhalb dieser Abnahme.

Frühere lange Hintergrundversuche hatten keinen vollständigen Abschlussbericht und zählen nicht als PASS. Danach wurden die großen privaten Probes aus dem fertig geladenen sichtbaren Hauptmenü gestartet; natürliche Beschleunigung verwendet nur den nativen Speed-up-Pfad, keinen Stop/Skip. Die reine `FINISHED`-Marke wird nie anstelle der einzelnen PASS-/FAIL-Gruppen gewertet. Ursprüngliche Fehlschläge bleiben in ihren gebundenen Unterordnern erhalten.

## Mit der BAT testen

1. `SandboxOfElysium-Testen.bat` im Projektordner doppelklicken; Profil-/Build-Bestätigung abwarten.
2. **Sandbox**, Karte/Farben unter **Current setup**, dann **Battlefield → Open with native deployment** oder die exakte Keep-positions-Variante wählen.
3. Teams wählen, Einheit suchen, Select, Rechtsklick auf die Karte. Beide Teams dürfen während der Vorbereitung leer sein; vor Start mindestens eine Einheit pro Seite setzen.
4. **Start battle → View post-battle field** zeigt den lesenden Snapshot. Rechtsklick auf einen verifizierten Überlebenden: aktuelle native Inspect-Karte. **Back to Sandbox** stellt die ursprüngliche Aufstellung wieder her; **Rematch** kämpft damit erneut.

Experimenteller Extender und Build-Ausgaben bleiben außerhalb der Mod. Kein Release, PR oder Kontakt; ursprüngliche Diagnosen/Recovery/Szenarien und normale Installation bleiben bewahrt.

**Abschlusskontrolle:** Standard-BAT ohne Prüfschalter nochmals tatsächlich gestartet, isoliertes Profil frisch bestätigt, normales Menü bei `1200*900` vollständig sichtbar und über Main menu/Quit beendet. Es läuft keine eigene Testkopie mehr. Genau CoE5SE, SandboxOfElysium und SandboxLauncherCheck sind im privaten Standardprofil aktiv; keine privaten Regressionen und kein CrabCult automatisch aktiviert. Die Testkopie stimmt mit allen aktuellen Mod-Quelldateien überein. Finaler Hash-/Inhaltsaudit: `docs/evidence/battlefield-2026-11-14/final-preservation.json` (lokaler Beleg; nicht veröffentlicht) bestätigt 60 unveränderte Originaldateien, keine fehlenden Originale und drei unveränderte reguläre Dateien; nur die vorgesehenen generierten Dateien `last-battle.ini` und `launcher-context.ini` wurden fortgeschrieben. Neue QA-Dateien bleiben erhalten. `-CheckOnly`, PowerShell-Parser und Whitespace-Prüfung bestanden.


Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
