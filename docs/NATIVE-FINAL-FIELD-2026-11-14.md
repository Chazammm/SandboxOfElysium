# Native Grenze für den Nachkampf-Snapshot – 14.11.2026

## Geprüfter Stand und Ursache

Ziel: eigene CoE5-5.43-Windows-x64-EXE, SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Die neuen Nutzerexporte `diagnostics-5bd42749aa2c47d4ba1b-{1,2,3}.ini` zeigen nach echten Kämpfen lebende native Akteure, aber keine belegten Rohzellen und fehlende Anker. Frühere Berichte hielten einzelne Positionen aus `BATTLE_TURN_EFFECTS` fest; das war ausdrücklich keine vollständige Schlussaufnahme. Die frühere Annahme, der offene Feldhandle behalte automatisch das letzte native Einheitenraster, ist widerlegt.

Die passende native Funktion `FIGHT_THE_FIGHT`, RVA `0x0f1cb0`, erklärt den Zustand. Ihr normaler Endpfad enthält folgende Reihenfolge:

| Zeitpunkt | Belegter nativer Vorgang |
|---|---|
| Ende der letzten Kampfrunde | Gewinner wird bestimmt; die Engine führt weitere 75 Nachwirkungs-Ticks aus. Dabei können Zustand und Position weiter wechseln. |
| Callsite `0x0f3839` | Aufruf von `afterFightUpkeep`, RVA `0x0cf010`. Der neue Capture-Hook liest unmittelbar **vor** diesem Aufruf. |
| `0x0f3920` | Behandlung gesunkener Schiffe, RVA `0x0e0e50`; unverändert ausgeführt. |
| `0x0f3925` | `removeTempMen`, RVA `0x1177b0`; entfernt bestimmte temporäre Akteure. Die verwendete Entfernung `0x0f8400` setzt unter anderem HP auf −9999 und Weltkoordinaten auf −1. |
| `0x0f3ac9` | Raster-Reset, RVA `0x0f0800`: alle `0xb4000` Bytes des Kampfzellenrasters werden zurückgesetzt. Das entspricht 1536 Spalten × 20 Zeilen × 24 Bytes. |
| Rückkehr zur Sandbox | Die noch lebenden eigenen Akteure können weiter existieren, ihre Kampfanker sind jedoch gelöscht. |

Ein bloßes Unterdrücken des letzten Raster-Resets würde keine vollständige unveränderte Endszene bewahren: Bereits entfernte temporäre Akteure könnten als veraltete IDs im Raster verbleiben. Auch Nachkampf-Abrechnung und temporäre Einheiten werden deshalb nicht ausgelassen oder rückgängig gemacht.

## Gewählte Darstellung und Vollständigkeit

Die neue native Unterstützung erfasst einen **Einheiten-/Zellen-Snapshot nach den 75 Nachwirkungs-Ticks und vor der Nachkampf-Abrechnung**. Provenienz: `post_aftermath_before_upkeep`. Er liest alle aktuell verfolgten eigenen nativen Generationen, einschließlich Geländeobjekten, und jede Zelle innerhalb der überprüften tatsächlichen Feldbreite. Der native Spielzustand wird dabei nicht geschrieben. Der ursprüngliche `afterFightUpkeep`-Aufruf und alle anschließenden Bereinigungen laufen immer weiter.

`complete=true` bezeichnet vollständig gelesene und überprüfte Einheiten-/Zellendaten an genau dieser Grenze. Es bedeutet weder vollständige Übergangshistorie noch vollständigen Rendererzustand. `sceneComplete=false` bleibt ausdrücklich gesetzt: Projektile, Partikel, laufende Animationen, Sound, Timing und sonstige Effekte werden nicht als wiederherstellbare Szene erfasst. Die spätere Darstellung verwendet die gespeicherten Anker und Monsteridentitäten; sie ist keine Fortsetzung der nativen Simulation.

Nicht belegte Positionen werden nicht aus Ausgangspositionen oder einer früheren Aktion ergänzt. Lebende Akteure ohne Anker haben `status='off_field'`; tote Akteure `dead`, lesbare lebende Akteure mit Anker `on_field`. Eine vollständige Fluchtklassifikation wird nicht behauptet. Der native Flee-Helfer `0x0e4430` schreibt zwar Welt-X −2, aber die Aufnahme beobachtet nicht diesen Aufruf. Deshalb bleibt `routeStatus='not_classified'`; `nativeFleeMarker` meldet lediglich den gelesenen Marker.

Große Akteure erhalten die beiden nativen Kampfmaß-Abfragen und sämtliche durch `battleUnitAt` belegten Trefferzellen. Bei lebenden Akteuren mit genau einem primären Anker wird das vollständige Rechteck geprüft. Ungültige IDs, fehlende Herkunft, unsichere Größen, überlappende beziehungsweise unvollständige Trefferflächen und Akteure im nicht verifizierten Objektlayer ergeben explizite Issues und `complete=false`.

Geländeobjekte besitzen native Objektanker und native Maße. Sie erhalten keine erfundenen `battleUnitAt`-Trefferzellen: Das Objektlayer hat keinen entsprechenden Akteur-Hittest. Ihr `occupied` bleibt leer und `occupiedSource` benennt diese Grenze. Das vollständige Rohzellenraster bleibt zusätzlich verfügbar.

## API-Vertrag und Integration

Separater Extender: `src/lua_test_field_final.h`, nach Unit-State/Preview/Input und vor Inspect einzubinden. Die bestehenden Dateien für Öffnung, Kampf und Schließen integrieren lediglich die folgenden Lebenszykluspunkte:

- `testFieldFinalBegin()` nach erfolgreicher Kampfvorprüfung, vor Setzen von `fighting` und vor dem nativen Kampfaufruf. Installiert den exakt geprüften einzelnen Callsite-Hook und reserviert begrenzte native Speicherbereiche. Keine Erzeugung von Testeinheiten.
- `testFieldFinalFinish()` nach Rückkehr der nativen Simulation und Verlassen des Kampfscopes. Ohne erreichte Capture-Grenze bleibt der Zustand ausdrücklich unvollständig.
- `testFieldFinalReset()` vor Schließen/Neuöffnung; gibt ausschließlich den Snapshot-Speicher frei.
- `testFieldFinalViewActive()` sperrt nach Kampfende die mutierenden Editoroperationen bis zu Schließen oder Neuaufbau. Back/Reset/Rematch bauen die separat bewahrte Originalaufstellung neu auf.

`coe5.testFieldFinalState()` liefert den Snapshot oder `nil,reason`, wenn er für den aktuellen Aufrufer nicht verfügbar ist. Zugriff verlangt passende Engine, Hauptthread, eigenes offenes Testfeld, gleiche Feldsession und beendete Simulation. Ergebnisfelder:

- Kopf: `source`, `phase`, `captured`, `complete`, `sceneComplete`, `coverage`, `session`, `width`, `height`, `round`, `winner`, `issues`, Gesamtzahl und mögliche Kürzung der Issue-Liste.
- `grid`: sämtliche `width*20` Zellen mit `x,y,unit,object,flags,ground,hit`.
- `units`: aktuelle verfolgte native Generationen mit `unit,generation,kind,readable,monster,sprite,owner,team,hp,alive,worldX,worldY,width,height,anchors,anchorCount,occupied,status` und der jeweiligen Datenquelle.
- Herkunft: `createdMonster`, `createdOwner`, `createdDuringFight`, `monsterChanged`, `ownerChanged`. Ein anderer Monster-/Ownerwert ist keine geänderte Generation; eine Transformation oder Konversion allein wird nicht als Handleersatz behandelt.
- Spätere native Rücklesung: `identityMatches,currentHP,currentAlive,currentMonster,currentOwner,inspectable,inspectReason`. Diese Werte gehören zur Zeit nach der nativen Abrechnung; `hp` und `alive` bleiben die gespeicherten Capturewerte.

Die ID-/Generationszuordnung unterscheidet mehrere Unique-Kopien und zwischenzeitlich neu belegte Handles. Die ursprüngliche gespeicherte Aufstellung und bekannte/memorisierte Zauber werden für die Schlussansicht nicht überschrieben. Ein neu erzeugter Akteur ist nur dann als `createdDuringFight` markiert, wenn seine verfolgte Generation bei Beginn noch nicht vorhanden war; dies ist Herkunft während des Kampfscopes, kein pauschaler Beweis einer bestimmten Beschwörungsaktion.

## Native Inspect im Schlussbild

`coe5.inspectTestFieldFinalUnit(unit,{readOnly=true})` öffnet die echte native Karte des **jetzt** noch lebenden passenden eigenen Akteurs. Es ist kein historisches Snapshot-Fenster. Die Oberfläche muss diesen Zeitunterschied ausweisen. Eine nach der Aufnahme nativ entfernte Beschwörung bleibt im Snapshot sichtbar, erhält aber `inspectable=false` und den Grund `removed_after_capture`. Sie wird nicht wiederbelebt.

Die gemeinsame Inspect-Implementierung behält den nativen lesenden Aufrufmodus, Generationserhalt, vollständigen Einheitenrecord-Vergleich und die eng begrenzte Wiederherstellung ausschließlich der beiden inline Zauberarrays. Im Schlussbild wird keine Vorbereitungsphasen-Schulkapazität verlangt: Der Kampf darf Stufen und Auswahl verändert haben. Sichere gültige Spell-IDs, lesbare Items, passende Identität und lebender Datensatz bleiben erforderlich. Andere unerwartete Recordänderungen werden nicht zurückkopiert, sondern verweigert und gemeldet.

## Prüfstand

**Offline bestätigt:** 26 Assertions an tatsächlich aus dem neuen Header extrahierten C-Funktionen. Getrennte vorgegebene native Readbacks prüfen 3×2-Trefferflächen, beide Teams, tote und feldlose Akteure, Geländeobjekte, neue Generation während des Kampfes, ursprüngliche Snapshot-HP gegenüber späterer Entfernung, Fremdaufrufer, ersetzte Generation, Monster-/Ownerwechsel ohne falschen Identitätsverlust, ungültige Raster-IDs ohne unsicheren nativen Hittest, falsche Bounds, fehlende Capture-Grenze und unveränderte native Speicherbytes während der Aufnahme. Dies ist kein Test einer echten CoE-Simulation oder sichtbaren Darstellung.

Die opt-in Probe [tests/final_probe.lua](../tests/final_probe.lua) prüft im tatsächlichen Spiel vollständige Snapshotdaten und Fußabdrücke, abgewiesene Änderungen, unveränderte Rücklesungen, Cleanup und erneutes Öffnen. Zusatzparameter können ausdrücklich einen während des Kampfes neu erzeugten lebenden Akteur beziehungsweise Geländeobjekte verlangen. Die Probe gilt erst nach tatsächlicher Ausführung als bestanden.

**Sichtbar im tatsächlichen Spiel bestätigt:** Ein natürlicher Spearman/Spearman-Kampf zeigt im Schlussbild A1/B0 am erfassten Anker. Rechtsklick öffnet die echte aktuelle Überlebendenkarte mit HP 3/6. Nach deren Schließen bleibt das Schlussbild erhalten. Ein natürlicher Rematch endet regulär; Back stellt die ursprüngliche Aufstellung A1/B1 wieder her; Reset funktioniert. Diese sichtbare Beobachtung wurde vom koordinierenden Laufzeit-/UI-Test gemeldet. Sie belegt diesen kleinen Fall und ersetzt keine Beschwörungs- oder Transformationsprobe.

**Abschließender normaler Build bestätigt:** DLL-SHA256 `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`, Sitzung `54f26dddea5a440db8ffd327e9351cee`. Die vollständige gültige Sechserkopie beendet ihren nativen Kampf Runde16/winner0 mit zwei 3×3-Überlebenden. Der echte Zehneraufbau aus den 5bd-Diagnosen endet Runde7/winner24, mit 17 lebenden positionierten Actors an der Capture-Grenze, davon zwölf während des Kampfes erzeugt und danach nativ entfernt; exakter Wiederaufbau und zweiter natürlicher Kampf bestehen. Eine getrennte Probe mit ausschließlich tatsächlich bekannten Summon-Zaubern erfasst neun lebende Actors, darunter acht neue später entfernte Beschwörungen. Vollständige Capture-/Readonly-/Cleanup-/Wiederöffnungschecks bestehen. Gebundene native Ergebnisse: `docs/evidence/battlefield-2026-11-14/final-54f26ddd/battlefield-results.ini` (lokaler Beleg; nicht veröffentlicht).

Zusätzlich sichtbar bestätigt: zwei vollständige Sechserkämpfe Runde16/winner0, beide mit A2/B0; echte während des Kampfes erzeugte Shades; beide großen Überlebenden im beschrifteten Snapshot; Inspect aus einer inneren Footprint-Zelle öffnet die aktuelle native Karte mit70/161HP und bekannten/memorisierten Listen, danach unverändertes Schlussbild. Back und Reset stellen A3/B3 an gespeicherten Ankern wieder her. [Bericht und Screenshots](TEST-BATTLEFIELD-2026-11-14.md). Konkrete natürliche Transformationen/Konversionen wurden nicht beobachtet; die kontrollierten C-Fälle sind dafür kein Ersatz. Es wird keine vollständige Übergangshistorie oder native Effekt-/Animationsszene behauptet.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
