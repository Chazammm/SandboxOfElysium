# Platzierung, Löschen und Integrität — 2026-11-14

Nachfolgeprüfung mit **editor.3**: [Oberfläche und Lebenszyklus](TEST-INTERFACE-2026-11-14.md). Alle neun nativen Gruppen unten wurden mit dem neuen Build erneut bestanden. Der Unique-Guard bleibt standardmäßig aktiv; die neue explizite Mehrfachoption verwendet separate native Datensätze. Die folgenden Abschnitte dokumentieren weiterhin den ursprünglichen editor.2-Lauf.

Lokaler Fix **0.1.0+editor.2** für den gemeldeten Zustand „Einheit verschwunden, aber noch vorhanden“. Sandbox und Extender bleiben getrennt. Keine PR, Nachricht, Veröffentlichung oder Änderung der regulären Installation. Vorhandene uncommittete Arbeit wurde vor Änderungen privat gesichert.

## Tatsächliche Nutzerexporte

Unverändert gelesen und anschließend byteweise mit der Sicherung verglichen:

- `private/terrain-lab/profile/coe5se_data/SandboxOfElysium/diagnostics-f2aa0585830642fa8be8-1.ini`
- `private/terrain-lab/profile/coe5se_data/SandboxOfElysium/diagnostics-f2aa0585830642fa8be8-2.ini`

Beide stammen aus derselben Sitzung, CoE5 5.43, Sandbox editor.1, experimentelle DLL `cf38abac73323e267d4955cb830462b604b3b4a22aa96fe0c8adc515aa77d390`. Zeitbasis: Launcher-UTC 2026-11-13T22:52:02Z und relative Spiel-Ticks; kein verlässlich ermittelter genauer Exportzeitpunkt. Chronologie mit Dateihashes: `docs/evidence/placement-2026-11-14/user-export-timeline.json` (lokaler Beleg; nicht veröffentlicht) enthält die tatsächlich erhaltenen Ereignisse, ohne lokale Benutzerpfade.

| Erhaltene Ereignisse | Was daraus folgt |
|---|---|
| Export 1: Sequenz 278–341, 64 Ereignisse | Der Ring beginnt bereits mit Placement-Fehlern und `restore failed`. Frühere erfolgreiche Platzierungen/Löschungen und die erste Zustandsverletzung fehlen. |
| 278–335 | Wiederholte `native target blocked` bzw. `Native field rejected deployment...`, häufig im Abstand weniger Frames. Mehrfach unbestätigte Wiederherstellung, trotzdem weitere Bearbeitung. Die alte Diagnose protokolliert keine unverfälschte physische Maustastenfolge; die genaue Geste ist unbekannt. |
| Modellzustand in beiden Exporten | Modell-IDs **12, 13 und 14** verweisen gleichzeitig auf **Native-ID 19**, HP **0**, ohne gemeldeten Kartenanker. Ihre gespeicherten Zauber unterscheiden sich; die aktuellen gelesenen Listen stammen alle aus demselben toten Record. Modell-ID **15** verweist auf Native-ID **20**, ebenfalls HP 0. |
| 337–340 | Kontext für Modell 13 an gespeichertem Feld (16,11), dann Delete → `dead_unit`, `unchanged`. Diese dokumentierte Ablehnung ist kein Beleg für eine erfolgreiche Löschung und erklärt nicht den früheren Tod. Die native Remove-Funktion verweigert hier vor einer Änderung. |
| Export 2: Sequenz 283–346 | Überlappender Ring; nach Export 1 erneut Kontext für Modell 13 und `memorize` bei Sequenz 345, obwohl der Actor bereits tot ist. Der Editor arbeitet weiter mit einem beschädigten Mapping. |

Es wird **nicht** behauptet, welcher erste Rider wann vom Nutzer gelöscht wurde. Der erste beschädigende Nutzeraufruf ist nicht mehr enthalten. Die Ursache wurde deshalb getrennt im unveränderten alten Ablauf reproduziert und im nativen Code geprüft.

## Nachgewiesene Ursache

**Native Unique-Semantik:** `NEW_UNIT` prüft Monster-Ability 57 (`unique`). Für einen solchen Monstertyp sucht das Spiel einen vorhandenen Slot, bevorzugt einen lebenden, und **initialisiert genau diesen Record neu**. Das kann eine bereits eingesetzte Einheit mit neuen Zufallszaubern sein. Der bestehende Battle-Anker bleibt erhalten; `BATTLE_SETUP_SIDE` überspringt bereits verankerte lebende Actors. Eine zurückgegebene Unit-ID bedeutet daher nicht für alle Kreaturen „zusätzliche neue Einheit“.

Privat am eigenen CoE5-5.43-Binary verifiziert: Unique-Branch bei RVA 0x12984b, Suche 0x106600, NEW_UNIT 0x1297b0, SetupSide 0xe5da0. Native Funktionen/Daten wurden nur untersucht; kein Spielcode oder Disassembly wird mit der Mod ausgeliefert. Private Evidenz: `private/placement-desync-native-evidence-2026-11-14-agent.json`, 14 Records. Relevante Evidence-IDs: `ev_ba5e65f6988b9370da2b80effa7ac5ebd675627e34ed573cbc843b7c663c840c`, `ev_1908d8a91b3273912b0402eabc17a46fe59080bab21632a38a38b238f474f5e5`.

**Reproduktion im alten echten Spielprozess:** Zweimal `addTestFieldUnits(... {{202,1}})` lieferte dieselbe lebende Native-ID **9**. Nach fünf Strange Seraphs erzeugte der alte Runtime-Code mehrere logisch erfolgreiche Rider-Platzierungen, die alle auf diese eine ID zeigten. Das anschließende Löschen einer solchen Modellzeile setzte den gemeinsam referenzierten Actor auf HP 0; andere Modellzeilen blieben bestehen. Raw- und Runtime-Nachweis: `docs/evidence/placement-2026-11-14/baseline-native.ini` (lokaler Beleg; nicht veröffentlicht), alter Diagnoseexport: `docs/evidence/placement-2026-11-14/baseline-diagnostics.ini` (lokaler Beleg; nicht veröffentlicht). Die ID unterscheidet sich wegen anderer vorheriger Allokationen von der 19 im Nutzerexport.

Vier Sandbox-Fehler verstärkten dies:

1. `add` akzeptierte die zurückgegebene ID ohne eindeutige Identitäts-/Lebensprüfung und legte einen weiteren Modell-Eintrag an.
2. `place` bewegte bei Aliasen denselben Actor nacheinander an verschiedene Ziele. Einzelne erfolgreiche Moves ersetzten eine globale Endprüfung; der Ablauf konnte fälschlich Erfolg melden.
3. Die Fehlerbereinigung löschte den vermeintlich neuen Actor auch dann, wenn die ID schon einem alten Modell gehörte. `restore failed` war nur ein Hinweistext; die Formationsschleife und weitere Aktionen liefen weiter.
4. Native Trefferprüfung fiel bei keinem Treffer auf gespeicherte Modellanker zurück. Tote Modell-Geister blieben damit auswählbar; Spell-Änderungen waren ebenfalls nicht ausreichend geschützt.

Die nativen Fußabdrücke wurden gesondert geprüft: **Seraph #206 = 2×2**, getestete **Riders #202/#203 = 3×3**. Das native Grid speichert einen Actor-Anker; die weiteren Zellen werden von der nativen Trefferprüfung aus dem Fußabdruck abgeleitet. Ein 3×3-Actor besitzt neun Trefferzellen, nicht neun unabhängige Raw-Anker. Die ursprünglichen Footprint-Kollisionen sind somit teils berechtigte Ablehnungen; der Identitätsfehler machte daraus einen dauerhaften beschädigten Zustand.

## Änderungen

### Separater Extender

- Vollständige Unique-Prüfung **vor** Square-Änderungen oder erster Allokation: über Commander, beide Seiten und alle Gruppen. Derselbe Unique-Typ mehrfach angefordert → `unique_count`; bereits lebend vorhanden → `unique_exists`. Die defensive Suche erfasst die verifizierte physische Unit-Tabelle. Tote, sauber ausgeräumte Unique-Slots dürfen normal wiederverwendet werden.
- `addTestFieldUnits` liefert bei Ablehnung rückwärtskompatibel `nil, reason`. Eine bestehende Unique-Einheit wird nicht für einen Add-Versuch neu initialisiert.
- Move prüft zusätzlich Eigentümer, Mainmenu-Feld, Lebensstatus, Monstertyp, Kampfphase und Bounds.
- Read-only `testFieldState`, `testFieldUnitState`, `testFieldEditorCapabilities`: tatsächliche native IDs, HP/Leben, Monster/Besitzer, Weltposition, Ankeranzahl/-zellen, Größe, native Trefferzellen, Raw-Grid und Issues. Vollständigkeit und Gesundheit sind getrennte Angaben. Ungültige/fremde Referenzen werden als unvollständig markiert; unsichere native Folgeaufrufe werden vermieden.
- `testFieldPointerButtons` liest den bestehenden SDL-Export ohne Ereignisse zu pumpen oder die konsumierbare Spielmaske zu ändern. Das verhindert, dass deren Maskierung eine gehaltene Taste als neue Press/Release-Folge erscheinen lässt.

LuaLS-Verträge stehen in `coe5.lua` des separaten Checkouts. Der englische lokale Vorschlag steht dort in `PR_DRAFT_SANDBOX_EDITOR.md`; er wurde nicht eingereicht.

### Sandbox

- Neue Integritätsprüfung: vollständige Modell↔Actor-Bijektion, lebende passende Typen/Teams, genau ein Anker, vollständiger Fußabdruck und passende gespeicherte Zauber/Items. Vorhandene tatsächliche HP-/Spell-/Inventarsignaturen werden zusätzlich über jede Mutation verglichen.
- Unique-Duplikate werden auch in Lua vor dem Aufruf verständlich abgelehnt. Ein zurückgegebener bereits verwendeter Handle wird niemals als neuer Actor konfiguriert oder gelöscht.
- Normales Add bewegt bestehende Einheiten nicht unnötig. Nach Resize/Neuaufbau folgt eine globale Endprüfung. Vor Erfolg müssen Modell und native Aufstellung tatsächlich gemeinsam passen.
- Cleanup-Ergebnis, Rollback-Versuch und Rollback-Verifikation sind getrennt. Selbst `remove=false, dead_unit` kann harmlos sein, wenn der eindeutig neue Slot bereits tokenlos/retired und die ganze alte Aufstellung nachweislich identisch ist. Bloße Bool-Rückgaben sind kein Zustandsnachweis.
- Native Trefferprüfung verwendet keine Phantom-Modellanker als Ersatz. Kontext, Edit, Move, Delete, Copy, Memorize und Fight können nach Integritätsverlust keine weiteren Änderungen ausführen; die laufende Formation bricht sofort ab.
- SDL-Buttonzustand bleibt unabhängig von konsumierten Frame-Masken. Während einer gehaltenen Geste wird je neuer Zelle einmal geplant; Loslassen ermöglicht einen bewussten erneuten Versuch. Kontextvorrang und Drag-Formationen bleiben erhalten.

## Sicherer Wiederherstellungsweg

Bei einer unbestätigten Wiederherstellung erscheint **Editing locked** statt weiterlaufender normaler Bearbeitung. Zähler/Sprites werden dann ausdrücklich nicht als verifizierter Zustand präsentiert. Native Controls werden in dieser Ansicht ebenfalls abgefangen.

Die letzte bestätigte Modell-Aufstellung, andernfalls das Modell am ersten Integritätsfehler, bleibt im Speicher und wird unter einem **freien** Namen `recovery-<Sitzung>-<Nummer>.ini` im selben Datenordner gesichert. Keine vorherige Datei wird überschrieben. Ein Schreib-/Quota-Fehler wird als fehlende Datei gekennzeichnet; die In-Memory-Kopie bleibt erhalten.

1. **Export Diagnostics** benutzen. Der erste Integritätsfehler bleibt unabhängig vom 64er-Ring erhalten.
2. **Reopen preserved setup** ausdrücklich wählen. Das alte native Feld wird geschlossen und die unterstützte gespeicherte Konfiguration mit ihren exakten bekannten/memorisierten Zaubern und Items neu aufgebaut und geprüft.
3. Scheitert dies, bleibt die Bearbeitung gesperrt. Es werden weder andere Zufallszauber akzeptiert noch widersprüchliche Unique-Duplikate stillschweigend entfernt.

Das ist ein expliziter Szenario-Neuaufbau, kein bytegenauer Engine-/RNG-Snapshot. Native IDs können dabei wechseln. Bereits früher beschädigte Exporte mit mehreren Modellzeilen für denselben Unique-Typ lassen sich nicht ehrlich als mehrere gleichzeitig lebende native Actors wiederherstellen. Die ursprünglichen Dateien bleiben erhalten; eine automatische Auswahl, welche der verschiedenen gespeicherten Zaubervarianten behalten werden soll, erfolgt nicht.

**Löschen bedeutet:** kein lebender Actor, kein Anker, keine Trefferzelle, kein Modellverweis und kein Sprite. Das native Spiel behält den HP-0-Slot als wiederverwendbaren Tombstone. Es werden keine Indizes verschoben oder Unit-Records unsicher aus der Tabelle entfernt.

## Tests im echten Spiel

CoE5 **5.43**, Steam-Build **26458448**, EXE-SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Getrennte 3.4.0/API-11-Basis `d96f2b784e97e115022a2598da2c821dd9520135`; nur private Builds/Profil. Sichtbare Tests liefen mit DLL `d793b96c0772240ce5da86ecad96bcd9e19c122b686ca527167cced87f5e0d9a`. Der abschließende zusätzliche Schutz gegen einen veralteten Tabellen-Höchststand ergab DLL **`fb595fd545df4d0104178550739e62bbbef9a1dfb9341c7b7fe0761922e44fe7`**, nochmals mit allen neun nativen Gruppen geprüft. Buildkennung: `docs/evidence/placement-2026-11-14/final-build.json` (lokaler Beleg; nicht veröffentlicht).

### Sichtbar bedient

Eine eigene, aus dem bestandenen nativen Test gespeicherte Aufstellung wurde über den **normalen BAT-Start ohne Probe-Mods** geladen; keine gespeicherte Nutzerarmee wurde verwendet oder ersetzt.

| Ablauf | Beobachtung |
|---|---|
| Ausgangsbild | Fünf große blaue Seraphs, zwei unterschiedliche rote Rider-Typen, Spearman/Goblin und konfigurierte Priestess; A7/B3. |
| 1×1 Add/Delete/Re-use | Spearman A platziert: A8/B3; über Kontext gelöscht: A7/B3; dieselbe freie Zelle sofort für B belegt: A7/B4, roter Token sichtbar. |
| 2×2 Delete und innere Zelle | Kontext über eine innere Seraph-Zelle geöffnet; Seraph verschwand vollständig, A6/B4. Eine innere seiner vier Zellen anschließend mit B-Spearman belegt: A6/B5. |
| Konfigurierte Seraph-Kopie | Copy auf einem lebenden Seraph, freie Kartenfläche rechts angeklickt, blauer 2×2-Sprite erschien: A7/B5. |
| Teilüberlappung und Wiederholung | Zwei getrennte Klicks auf eine freie Ankerzelle, deren großer Fußabdruck andere Actors schneidet: genau zwei Ablehnungen, A7/B5 unverändert. Export zeigt je Versuch verifiziertes Cleanup/Rollback und identische vorhandene Zustände. Kein Frame-Spam. |
| Unique-Duplikat | Rider-Vorlage gewählt, freie Fläche angeklickt: `This creature is unique and is already on the field`; kein neuer Token, Zähler unverändert. |
| 3×3 Delete und Re-create | Rider #203 per Fußabdruck-Kontext gelöscht: Sprite weg, B5→B4. Export bestätigt keinen Modell-/Live-Native-/Raw-Anker-Verweis. Gespeicherte Vorlage auf ursprünglicher Fläche neu platziert: B4→B5, 3×3-Sprite wieder vorhanden, exakte Zauber/Item/HP bestätigt. |
| Forest | Gelände gewechselt, große Aufstellung ausdrücklich nativ neu deployed, A7/B5. Seraph am sichtbaren Baum abgelehnt, dann auf freier Waldfläche erfolgreich gesetzt: A8/B5. Export weiterhin vollständige native Query ohne Issues/Aliase. |

Nachweise: Teilüberlappung: `docs/evidence/placement-2026-11-14/ui-rejected-placement.ini` (lokaler Beleg; nicht veröffentlicht), Rider gelöscht: `docs/evidence/placement-2026-11-14/ui-rider-deleted.ini` (lokaler Beleg; nicht veröffentlicht), Rider wieder erzeugt: `docs/evidence/placement-2026-11-14/ui-rider-recreated.ini` (lokaler Beleg; nicht veröffentlicht), Forest: `docs/evidence/placement-2026-11-14/ui-forest-rejected-and-next-success.ini` (lokaler Beleg; nicht veröffentlicht), automatischer Vergleich der Exporte: `docs/evidence/placement-2026-11-14/ui-checks.json` (lokaler Beleg; nicht veröffentlicht). Die konfigurierte Priestess behielt dabei ihre bekannten/memorisierten Zauber, **A Chest Full of Fire** und HP, auch über den expliziten Terrain-Neuaufbau.

### Native API im echten Prozess

Eigene opt-in `ZZSandboxPlacementProbe`, standardmäßig deaktiviert. Abschließender Lauf: `docs/evidence/placement-2026-11-14/regression-final-build.ini` (lokaler Beleg; nicht veröffentlicht): **4/4 Gruppen PASS**.

- Raw Unique-Exists/Count und über beide Seiten doppelter Commander-Typ abgelehnt; vorhandener Zustand unverändert, kein fortgeschrittener Allokationszähler bei den getesteten frühen Add-Ablehnungen.
- Fünf Seraphs, verschiedene Rider-Typen, beide Teams und konfigurierte Priestess. Sechs echte überlappende 3×3-Versuche, jeweils neuer Slot sauber retired und komplette alte Konfiguration unverändert. Delete/Re-use auch über innere Zellen und konfliktfreies anschließendes Add.
- Forest-Objektablehnung und danach erfolgreiche große Platzierung, vorhandene Actors unverändert.
- **Explizit injizierte** Cleanup-Verweigerung im Lua-Testadapter ließ einen tatsächlich neu erzeugten Actor absichtlich stehen. Integritätsprüfung sperrte weitere native Mutationen, schrieb eine Recovery-Kopie und behielt den ersten Fehler. Explizite Wiederöffnung stellte dieselben gespeicherten Priestess-Zauber wieder her. Dies ist ein kontrollierter Fehlerpfad, keine Behauptung, die native Remove-Funktion sei von selbst fehlgeschlagen. Fehlerbericht: `docs/evidence/placement-2026-11-14/injected-cleanup-final-build.ini` (lokaler Beleg; nicht veröffentlicht), bewahrtes Szenario: `docs/evidence/placement-2026-11-14/recovery-final-build.ini` (lokaler Beleg; nicht veröffentlicht).

Die bestehenden Editor-Regressionsfälle wurden mit dem endgültigen Extender ebenfalls wiederholt: **5/5 Gruppen PASS**, zwölf inkrementelle Additions, konfiguriertes Copy/Move/Delete, Spell-Guards, Save/Load, fehlgeschlagener Neuaufbau mit verifizierter Rückkehr, zwei tatsächliche Priestess-Kämpfe mit Reset/Rematch, Plain/Forest und Projektion nach WAIT-next. Ergebnis: `docs/evidence/placement-2026-11-14/existing-editor-regression-final.ini` (lokaler Beleg; nicht veröffentlicht), Kampf 1: `docs/evidence/placement-2026-11-14/priestess-fight-1.ini` (lokaler Beleg; nicht veröffentlicht), Kampf 2: `docs/evidence/placement-2026-11-14/priestess-fight-2.ini` (lokaler Beleg; nicht veröffentlicht).

Eine erste neue Probe hatte zwei **Testskriptfehler**: eine sanitizierte Diagnose-ID wurde als String statt Integer an den strikten C-Getter gegeben; der injizierte Move-Versuch traf einen schon im Lua-Preflight abgelehnten Anker und erreichte den gewünschten Cleanup-Pfad nicht. Beide korrigiert, erster Versuch: `docs/evidence/placement-2026-11-14/regression-01-harness.ini` (lokaler Beleg; nicht veröffentlicht) erhalten. Diese Fehler wurden nicht als Produktdefekte oder erfolgreiche Tests gezählt.

### Außerhalb des Spiels

**20 Modell-/Guardfälle, 10 Editor-/Input-/Privacyfälle, 10 Integritäts-/Vertragsfälle bestanden.** Neue Prüfungen umfassen Alias-/Dead-/Team-/Footprint-/Partial-/Orphan-Zustände, erfolgreiche API-Rückgabe ohne tatsächlichen Move, unbestätigten Cleanup mit echter Sperre und beobachtet harmlosen bereits retired Cleanup. Die Inputprüfung fährt den tatsächlichen WAIT-Wrapper mit wechselnder konsumierter Frame-Maske und separatem gehaltenem physischen Zustand: einmal pro neuer Drag-Zelle, erneuter Versuch erst nach Release/Press. Reale Game-Logik wird dabei nicht simuliert.

Lua-Parser, PowerShell-/Python-Syntax, BAT-Pfade und Diff-Whitespace geprüft. Die früheren Terrain-Parserfälle sind historische Tests und werden hier nicht erneut gezählt.

Der letzte normale BAT-Start mit dem endgültigen Quellstand bestätigte die isolierte Profilumleitung und alle neuen Capability-Angaben, mit genau den drei normalen Mods und ohne Test-Probes: Startnachweis: `docs/evidence/placement-2026-11-14/final-normal-launch.json` (lokaler Beleg; nicht veröffentlicht). Reguläre EXE, installierte Extender-DLL und normales coe5config sind anhand der vorhandenen Vorher-Hashes unverändert: Dateischutzprüfung: `docs/evidence/placement-2026-11-14/normal-files-check.json` (lokaler Beleg; nicht veröffentlicht). Die Wiederherstellung bleibt auch bei bereits geschlossenem nativen Feld im Setup-Menü erreichbar; dieser zusätzliche UI-Pfad wurde offline geprüft.

## Diagnoseverbesserung und Grenzen

Zusätzlich zu früheren Feldern: Modell-ID, native ID und tatsächlicher Typ/Besitzer, HP/Lebensstatus, lokale Feldgeneration (kein nativer Generation-Counter), gespeicherter/aktueller Anker, Größe, Ankeranzahl, native Trefferzellen, Raw-Anker, Alias-Modell-IDs, Operationsphase, API-Ergebnis und unabhängige Rollback-Verifikation. Erster Integritätsfehler bleibt gesondert erhalten. Input-Ereignisse unterscheiden SDL-Zustand und konsumierte Spielmaske.

Exports sind ausdrücklich begrenzt: 64 Aktionen, 24 Modellzeilen, 48 native Zeilen, 256 nichtleere Raw-Zellen, 4096 Zeichen je Wert. Die native Query kann vollständig sein, während der exportierte Ausschnitt gekürzt ist; beide Angaben sind getrennt. Keine Voll-Logs, Schlüssel, Zugangsdaten oder absoluten lokalen Pfade im Inhalt. Exportnamen bleiben eindeutig. Ursprüngliche Nutzerexporte wurden nicht verändert.

Nicht vollständig geprüft: langer physischer Rechtsdrag mit dem Bedienwerkzeug, sämtliche Kamera-/Zoomkombinationen, extreme Armeen/Feldverbreiterung, alle Fremdmods und alle nativen Instanzattribute. Die Sperre/Recovery wurde nativ mit Injektion und die gesperrte UI-Eingabe offline geprüft; ein Recovery-Button-Klick im sichtbaren Spiel wurde nicht künstlich erzwungen. Keine vollständige Engine-/RNG-Transaktion, keine allgemeine Kampagnen-/Multiplayer-/macOS-Freigabe. HP-0-Tombstones bleiben als normale native Slotverwaltung bestehen.

## Selbst mit der BAT testen

1. Vorhandenes Testspiel beenden. `SandboxOfElysium-Testen.bat` im Projektstamm doppelt anklicken. Aktuelle Sandbox wird synchronisiert, separater Build bei Bedarf gebaut. Konsole soll Unique-Schutz, native Zustandsprüfung und SDL-Maustasten als verfügbar melden.
2. Sandbox → Plain/Forest → Prepare. Seraph #206 und verschiedene Rider-Typen wählen; gleiche Unique-ID nur einmal verwenden. Zähler und Teamfarben beobachten.
3. Große Einheit über eine innere Zelle rechts anklicken → Delete. Sofort auf frei gewordener Fläche neu platzieren. Teilüberlappung oder Baum testen: nur klare Ablehnung, bestehende Armee unverändert.
4. Bei Fehler Export Diagnostics. Bei **Editing locked** zuerst exportieren, dann **Reopen preserved setup**. Recovery-Dateien liegen neben den Diagnosen im isolierten Sandbox-Datenordner. Keine beschädigten Dateien löschen oder gespeicherte Zauber manuell austauschen, um eine Prüfung zu umgehen.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
