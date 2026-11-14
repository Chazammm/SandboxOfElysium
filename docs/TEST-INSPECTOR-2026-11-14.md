# Platzierungsvorschau, natives Inspect und Zauberprüfung – 14.11.2026

## Stand und gesicherte Ausgangsdaten

Die alte Fehlerursache ist im tatsächlichen isolierten CoE5-Prozess reproduziert. Der korrigierte Stand **0.1.0+editor.4** besteht **78 Offline-Lua-Fälle und 13 unterschiedliche native Testgruppen**. Zusätzlich wurden echte native Inspect-Karten, große/nichtquadratische Vorschauen, Forest-Hindernisse und drei vollständige God-Emperor-Kämpfe mit Rückkehr, Reset und Rematch sichtbar bedient. Grenzen und die früher unvollständigen Versuche sind unten getrennt dokumentiert.

Ziel ist die eigene Windows-x64-Kopie von CoE5 5.43, EXE-SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Die Baseline verwendet die eingefrorene bisherige DLL `465ed011d900b1b29edba830744d2788b29befdfcd1643400eb39b3979cc861b` und die dazugehörigen alten Sandbox-Module. Vor Änderungen wurden die drei ursprünglichen Exporte `diagnostics-9df3eae7c90343999f1d-{1,2,3}.ini`, Recovery, Quellen und Profildaten unter `private/inspect-before-85d08c0e65434d599b4093232a941277/` gesichert. Der vollständige gültige Altversuch liegt dort als `baseline-complete.ini`.

Die veröffentlichbare Testevidenz wird getrennt unter evidence/inspector-2026-11-14: `docs/evidence/inspector-2026-11-14` (lokaler Beleg; nicht veröffentlicht) abgelegt. Private native Analyseexports und dekompilierte Referenzen bleiben privat.

## Bestätigte Baseline und Ursache

Die gespeicherte Nutzeraufstellung enthält sechs Akteure: drei God Emperor #141 auf Team A und drei God Emperor of the Underworld #144 auf Team B. Die Laufzeit-Modell-IDs 12 und 14 bezeichnen zwei verschiedene God-Emperor-Instanzen. IDs aus dem neuen Probeprozess sind davon zu unterscheiden; beispielsweise heißt die entsprechende erste God-Instanz dort Modell 4/native 1. Native Handles sind kein beständiger Szenarioschlüssel.

Die ursprüngliche Ereignisfolge belegt die zusätzlichen Auswahlen ausdrücklich:

| Ereignis | Aktion |
|---|---|
| 219/220 | Modell 14 aktiviert #268 Aura of the Sun und #267 Sunbeam. |
| 228/229 | Modell 12 aktiviert #268 Aura of the Sun und #266 Sunlight. |
| 247 | Kampfstart mit sechs Akteuren. |
| 248 | Kampfende, Runde 17, Sieger 24. |

Diese Änderungen erfolgten im bisherigen eigenen Sandbox-Edit-Menü. Ein echtes natives Inspect war in diesem Stand noch nicht vorhanden. Zehn memorisierte Zauber sind hier deshalb keine belegte native Startauswahl.

Vor der Änderung erzeugt die native Engine für den geprüften God Emperor zwölf bekannte Zauber: sechs Air, Pfad 5, und sechs Solar, Pfad 19. Memorisiert sind zunächst vier je Schule, insgesamt acht. Die native Kapazitätsabfrage liefert für beide Schulen vier. Die ausgewählten bekannten Zauber unterscheiden sich zwischen Instanzen; die dokumentierte Instanz hat keine zusätzliche Pfadkapazität durch Items oder einen beobachteten Zufallsbonus.

Die Baseline spielt die vier aufgezeichneten Aktivierungen mit der alten öffentlichen Primitive nach. Danach besitzen die beiden betroffenen Instanzen jeweils Air 4/4 und Solar 6/4, insgesamt zehn. Die getrennte Vergleichsinstanz bleibt bei acht. Der alte Bulksetter verweigert dieselbe Zehnerauswahl mit `memorize_limit`; die alte Integritätsprüfung akzeptiert dagegen einen Modell-/Engine-Abgleich dieses übereinstimmenden, aber überfüllten Zustands. Der vollständige echte Kampf endet regulär nach Runde 17 mit Sieger 24. Der anschließende Neuaufbau scheitert an der Zauberprüfung und sperrt die Bearbeitung. Damit ist der Fehler vor der Korrektur reproduziert; ein abgebrochener oder übersprungener Kampf wird dafür nicht als Beleg verwendet.

### Native Verträge

Die folgenden Identitäten wurden am passenden Binärstand statisch geprüft. Sie erklären die Baseline; der Bericht enthält keinen dekompilierten Spielcode.

| Funktion/RVA | Geprüfter Vertrag |
|---|---|
| `unitPathLevel`, `0x2e6f40` | Native höchste passende Magiestufe der Einheit einschließlich aktuellem Pfadbonus. Die Listen bekannter oder memorisierter Zauber bestimmen diese Stufe nicht. |
| `unitPathBonus`, `0x2e4830` | Berücksichtigt native Monster-, Instanz-, Item- und weitere Spielmodifikatoren. Die neue Prüfung fragt den tatsächlichen Akteur ab. |
| `memorizeAllowance`, `0x2e43e0` | Gesamtkapazität einer Schule: bei positiver nativer Pfadstufe deren Wert plus eins, sonst null. Der Wert bezeichnet keine verbleibenden Plätze. |
| `memorizeSpell`, `0x2e6d70` | Fügt eine ID in die 30er-Liste ein, ohne bekannte Mitgliedschaft, Schule, Stufe oder Schulkapazität zu prüfen. Die Primitive kann Solar 6/4 erzeugen. |
| `chooseMemorized`, `0x2e61c0` | Verändert die Auswahl: entfernt unzulässige Einträge und füllt beziehungsweise kürzt mit Zufallsauswahl. Daher kein Validator für exakte Wiederherstellung. |
| Native Einheitenkarte, `0x1d4290` | Der Aufrufmodus mit `viewer=-1`, `ciok=0` sperrt die geprüften Änderungsaktionen und überspringt die sonst beim Verlassen erfolgende Zaubernormalisierung. |

Der Einheitenrecord enthält 60 bekannte und 30 memorisierte Zauber-IDs. Nur die Einträge bis zum ersten negativen Terminator gehören zur aktiven Liste. Nullbytes hinter diesem Terminator können aus der nativen Initialisierung stammen und sind keine zusätzlichen Zauber.

## Umsetzung

### Vorschau auf der echten Kampfkarte

Die Vorschau nutzt native Kampf-Fußabdrücke. Bei Copy/Move wird die konkrete lebende Instanz abgefragt; bei einer neuen Vorlage gelten die geprüften Monsterregeln. Spritebreite wird nicht als allgemeiner Ersatz für den Kampf-Fußabdruck verwendet. Reihen und Quadrate setzen ihre Anker im Abstand der tatsächlichen Breite/Höhe; die Markierung umfasst sämtliche belegten Zellen. Der native Interior-Hit einer vorhandenen Einheit hat Vorrang vor einer neuen Platzierung und wählt deren konkrete Kopie.

Die Vorschauabfrage erzeugt keine temporäre Einheit. Sie unterscheidet freie, belegte, durch Geländeobjekte blockierte, außerhalb liegende und unbekannte Zellen. Diese begrenzte Vorprüfung wird als solche angezeigt: freie Vorschauzellen garantieren nicht sämtliche nativen Platzierungsregeln. Der eigentliche Platzierungsaufruf und die nachfolgende vollständige Modell-/Engine-Prüfung bleiben maßgeblich.

Quellen: [Vorschaugeometrie](../mod/SandboxOfElysium/sandbox/preview.lua), [Oberfläche](../mod/SandboxOfElysium/sandbox/ui.lua), separater Extender `src/lua_test_field_preview.h`.

### Echtes, ausschließlich lesendes Inspect

Inspect öffnet die native Einheitenkarte des ausgewählten eigenen lebenden Testfeldakteurs. Der Aufruf ist auf den passenden Hauptthread, die eigene Feldgeneration, die Vorbereitungsphase und den nachgewiesenen Battle-Kontext begrenzt. Der eigene UI-Overlay pausiert während des nativen modalen Menüs; Abschlussereignisse und noch gehaltene Eingaben erhalten eine Freigabesperre gegen anschließende unbeabsichtigte Aktionen.

Vor dem Aufruf wird die Zauberauswahl geprüft. Die native Karte läuft mit deaktivierter Änderungs-/Finalisierungsoption. Zusätzlich werden Identität und kompletter Einheitenrecord vor/nach dem Aufruf verglichen. Falls der vorhandene Feeblemind-Fanpatch ausschließlich die beiden inline Zauberarrays normalisiert, dürfen nur diese Arrays nach unveränderter Identität und unveränderten übrigen Recordbytes exakt zurückgesetzt werden. Es wird kein kompletter Akteurrecord zurückkopiert. Andere Änderungen oder nicht bestätigte Rücklesung ergeben einen Fehler und eine Integritätssperre. Die Lua-Ebene verlangt ausdrücklich `readOnly=true` und `verified=true`; eine teilweise gesunde allgemeine Feldabfrage ersetzt diese Bestätigung nicht.

Quellen: [Runtime](../mod/SandboxOfElysium/sandbox/runtime.lua), [Integritätsprüfung](../mod/SandboxOfElysium/sandbox/integrity.lua), separater Extender `src/lua_test_field_inspect.h`.

### Strikte Zauberprüfung und ausdrückliche Reparaturkopie

`testFieldSpellState(unit)` liest bekannte/memorisierte IDs und pro Schule native Stufe, Bonus, Gesamtkapazität sowie tatsächliche Anzahlen. `complete` und `valid` sind getrennte Aussagen. Die Prüfung erlaubt bekannte Zauber oberhalb einer vorübergehend gesenkten Stufe; memorisierte Zauber müssen bekannt, ausreichend niedrigstufig und innerhalb ihrer Schulkapazität sein. Doppelte oder ungültige IDs ergeben konkrete Diagnosegründe.

`memorizeTestFieldSpell(unit,spell,on)` prüft eine einzelne Auswahl vor der Änderung und liest sie anschließend exakt zurück. Eine abgewiesene Aktivierung verändert weder die Listen noch HP, Items oder Position. Der Bulk-Restore prüft dieselben nativen Grenzen und gibt Details wie Pfad, tatsächliche Anzahl, erlaubte Anzahl und Prüfphase zurück. Die zuvor ungeprüfte öffentliche Primitive wird nicht zur Umgehung einer Ablehnung verwendet. `chooseMemorized` wird nicht aufgerufen.

Die ursprüngliche Solar-6/4-Recovery lässt sich unter diesen Regeln nicht unverändert als gültige Auswahl wiederherstellen. Sie bleibt deshalb als ursprüngliches Beweismittel erhalten. Der Nutzer bearbeitet ausdrücklich eine Kopie der gespeicherten Auswahl; bekannte Zauber und andere Instanzdaten werden dabei nicht automatisch ersetzt. Erst der bestätigte Neuaufbau der gewählten Kopie gestattet einen getrennten Export mit neuem kollisionsfreiem `repaired-…`-Namen. Der Export vermerkt die ursprüngliche Recovery und dass dies eine ausdrückliche Korrektur ist. Ein gescheiterter Versuch behält das Original und die abgewiesene Auswahl. Wird ein neuer fehlerhafter Kandidat bei Wiederherstellung eines vorher gesunden Felds abgelehnt, bleiben dessen eigene Diagnose und Reparaturkopie verfügbar.

Es gibt kein automatisches Kürzen auf acht und keine Substitution von Zaubern. Die vier aufgezeichneten Zusatzaktivierungen erklären die Ursache; sie legen keine stillschweigende Auswahlentscheidung für den Nutzer fest.

Quellen: [Runtime](../mod/SandboxOfElysium/sandbox/runtime.lua), [Diagnose/Export](../mod/SandboxOfElysium/sandbox/diagnostics.lua), [Modell/INI](../mod/SandboxOfElysium/sandbox/model.lua), separater Extender `src/lua_test_field_caster.h` und `src/lua_test_unit_state.h`.

## Offline-Prüfungen

**78 Lua-Fälle bestanden:** 20 Modell-, zehn Editor-, elf Integritäts-, 14 Interface-, 15 Vorschau-/Inspect-/Reparatur- und acht Caster-Vertragsfälle. Die tatsächlichen Lua-Module werden mit kontrollierten API-Rückgaben geprüft; dies ist keine Simulation der CoE-Engine. Alle verteilten Lua-Dateien und Probes parsen; PowerShell-Parser und BAT-`-CheckOnly` sind ebenfalls erfolgreich.

Die acht neuen [Caster-Vertragsprüfungen](../tests/caster_spec.lua) decken ab: verweigerte einzelne Aktivierung ohne Mutation oder ungeprüften Primitive-Aufruf; Schulgrenze im alten API-Fallback; exakte Bulk-Ablehnung mit Schuldiagnose; Inspect-Sperre bei `verified=false` trotz gesunder Teilansicht; unverändertes erfolgreiches Inspect; exakt gewählte Reparatur mit neuem INI-Namen und Decode-Rücklesung; gescheiterte Reparatur ohne Originalüberschreiben; bewahrter fehlerhafter Kandidat bei wiederhergestelltem gesundem Altbestand.

Getrennte C-Prüfungen an extrahierten tatsächlichen Helfern bestanden: **19 Caster-, 20 Vorschau- und 21 Inspect-Assertions**. Sie prüfen unter anderem getrennte Instanzkapazitäten, inaktive Listentails, bekannte höhere gegenüber memorisierten höheren Zaubern, ungültige Items vor nativen Zugriffen und unverifizierte Änderungen. Stub-Aufrufe beweisen keine sichtbare native Menübedienung oder Renderausgabe. Syntaxprüfung ist von Funktionstests zu unterscheiden.

## Tatsächliche native Laufzeitprüfungen

Getestet ist die getrennte DLL **3.4.0**, SHA256 `e08b5a56b0e2e5eac7bcbe6d09fe2b798cd585950955fcdff1c92e1fc29ff9af`, mit der oben gebundenen CoE5-5.43-Kopie. Build und Synchronisierung erfolgten über die vorhandenen Werkzeuge; die BAT wurde tatsächlich gestartet. Eine neue Startkennung wurde vom laufenden Spiel im isolierten Profil bestätigt. Letzte Startidentität: `docs/evidence/inspector-2026-11-14/final-launch-identity.json` (lokaler Beleg; nicht veröffentlicht) dokumentiert Spiel-/Pluginhash und die drei normalen Testmods. Probe-Mods sind beim normalen BAT-Start deaktiviert; ihre Dateien wurden nicht gelöscht.

| Native API-Prüfung im wirklichen Spielprozess | Ergebnis und Beleg |
|---|---|
| Fünf bestehende Editorgruppen | **5/5 PASS:** inkrementelle Priestess auf beiden Teams, konfigurierte Copy/Move, exakte Save/Load-/Rollback-/Reset-/Rematch-Zustände, zwei echte kleine Kämpfe, Terrain/Projektion, Diagnoseexport. Ergebnis: `docs/evidence/inspector-2026-11-14/editing-regression.ini` (lokaler Beleg; nicht veröffentlicht). |
| Vier bestehende Platzierungsgruppen | **4/4 PASS:** 1×1/2×2/3×3, große Delete/Reuse, wiederholt abgewiesene Platzierung ohne Phantom, Unique-Schutz vor Mutation, Forest und absichtlich injizierter Cleanup-Fehler mit Sperre/ausdrücklicher Recovery. Ergebnis: `docs/evidence/inspector-2026-11-14/placement-regression.ini` (lokaler Beleg; nicht veröffentlicht). |
| Ungültiges Original und explizite Reparaturkopie | **PASS:** beide Solar-6/4-Instanzen erkannt. Nur in der Testkopie Modell 4: #266/#268 und Modell 6: #267/#268 abgewählt. Alle bekannten Zauber bleiben erhalten. Das Original bleibt unverändert. Ergebnis: `docs/evidence/inspector-2026-11-14/inspector-regression-subset.ini` (lokaler Beleg; nicht veröffentlicht). |
| Einzelne Zauberänderung, unabhängige Unique-Kopien, Item und Save/Load | **PASS:** fünfter Solar-/neunter Gesamtzauber verweigert, Arrays und Instanzzustand unverändert; zulässiger expliziter Solar-Tausch funktioniert. Andere God-Instanz unverändert. `A Chest Full of Fire` und exakt gewählte Listen über Save/Load erhalten. Ergebnis: `docs/evidence/inspector-2026-11-14/inspector-regression-subset.ini` (lokaler Beleg; nicht veröffentlicht). |
| Zwei vollständige Sechs-Einheiten-Kämpfe und Wiederaufbau | **PASS:** beide natürlich beendet, Runde 16, Sieger 0/Team A. Ausschließlich native Geschwindigkeitsänderung, kein Skip/Stop. Cleanup jeweils vollständig: sämtliche 38 erfassten Akteure einschließlich beschworener Einheiten und Feldobjekte stillgelegt; danach exakte gültige Ausgangskopie mit unabhängigen Listen wieder aufgebaut. Ergebnis: `docs/evidence/inspector-2026-11-14/inspector-regression-battle-footprints.ini` (lokaler Beleg; nicht veröffentlicht). |
| Fußabdruck-/Zellabfrage im echten Draw-Kontext | **PASS:** Instanzen #13=1×1, #206=2×2, #201/#141=3×3; jede Zelle, Self-ignore nur bei Move, ursprüngliche Einheit blockiert Copy, Forest-Objekte sowie neun projizierte Randzellen mit acht außerhalb geprüft. 1851 Vorlagen ohne Akteurerzeugung gemessen. Die fünf nichtquadratischen Vorlagen sind Bog Beast 2×1, Bramble Gate 1×2, Cave Cow 2×1, Cloud Gate 1×2 und Crocodile 2×1. Der Katalogscan selbst erzeugt keine dieser Instanzen. Ergebnis: `docs/evidence/inspector-2026-11-14/inspector-regression-battle-footprints.ini` (lokaler Beleg; nicht veröffentlicht). |

Die letzte Vorschaugruppe wurde zweimal ausgeführt und zählt nur einmal: fünf plus vier plus vier ergeben **13 unterschiedliche bestandene Gruppen**. Die native Kartenbedienung ist separat im nächsten Abschnitt belegt.

Frühere Hintergrundläufe brachen die Ergebnisaufzeichnung vor Ende der langen God-Kämpfe ab; sie sind unter `first-native-run-incomplete-background.ini` und `native-fast-run-incomplete-background.ini` erhalten und zählen nicht als Erfolg. Ein früher kombinierter Platzierungslauf erreichte beim aufwendigen Diagnoseexport das native Lua-Schrittbudget; `placement-regression-budget-incomplete.ini` bleibt als unvollständiger Versuch erhalten. Daraufhin wurden die Datenschutzmuster einmalig vorbereitet und die Zauber-IDs kompakt pro Schule statt in vielen einzelnen Zeilen exportiert. Das Schrittbudget wurde nicht erhöht. Der vollständige anschließende Platzierungslauf und beide vollständigen God-Kämpfe sind die obigen erfolgreichen Nachweise.

## Sichtbar bediente Spieloberfläche

Hauptprüfung mit Fenstergröße 1704×900 und nativer UI 1136×600; zusätzlicher normaler BAT-Start bei Standardgröße 1200×900/UI 800×600. Die Screenshots stammen aus dem echten isolierten Spielfenster. Es wurden keine Bildmontagen oder vereinfachten Karten als native Ansicht verwendet.

| Sichtbarer Ablauf | Beobachtung |
|---|---|
| Inspect Spearman, Strange Seraph, zwei God-Emperor-Kopien und Team-B-God-Emperor of the Underworld | Echte native Karten mit Stats, HP, Waffen, Fähigkeiten, Beschreibung und instanzspezifischen Known-/Memorized-Listen. Aufruf über eine innere Zelle des Seraph-Fußabdrucks sowie der 3×3-Gods funktioniert. Unterschiedliche Listen beider God-Kopien bleiben unterscheidbar. Beispiele: Seraph (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), erste Kopie (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), zweite Kopie (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Team B (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Inspect Read-only und Rückkehr | Klick auf memorisiertes Incinerate verändert weder Stern noch 4/4-Auswahl. Scrollen und Exit kehren sauber zurück; Zähler/Sprites bleiben erhalten, kein unabsichtliches Platzieren. Spearman erneut im Standardfenster geprüft. Rückkehr (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Ausgerüsteter God Emperor | Zusätzliche eigene QA-Kopie mit `A Chest Full of Fire` und zuvor explizit getauschter Solar-Auswahl geladen. Native Karte zeigt Stärke 11, Itemslot und die konkreten Listen; Rechtsklick auf das Item öffnet die echte Itembeschreibung (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). Nach Schließen bleiben alle sechs Instanzen einschließlich Item/Zaubern unverändert. Export: `docs/evidence/inspector-2026-11-14/visible-equipped-inspect.ini` (lokaler Beleg; nicht veröffentlicht). |
| Original laden und Reparaturdialog | Ungültiges Szenario wird abgewiesen; bestehende dreiköpfige Testarmee bleibt erhalten. Beide God-Kopien werden mit Solar 6/4 erklärt. Die vier oben genannten Ergänzungen wurden ausdrücklich in der Kopie abgewählt; Verify speichert separat `repaired-5d092932caf74c588295-1.ini`. Ablehnung (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Dialog (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), gespeicherte Kopie: `docs/evidence/inspector-2026-11-14/visible-explicit-repaired-copy.ini` (lokaler Beleg; nicht veröffentlicht). |
| Kampf → Bericht → Back → Reset → Kampf → Rematch → Back → Load/Prepare | **Drei vollständige natürliche Kämpfe**, jeweils Runde 16, Team A gewinnt mit zwei Überlebenden; Team B verliert drei. Gemessene Wandzeiten 38,844 / 37,015 / 130,313 Sekunden. Im dritten Lauf wurde die native Geschwindigkeit mit `s` erhöht; kein Überspringen/Abbruch. Alle Rückwege gelingen, sechs Einheiten wieder vorhanden. Berichte: `docs/evidence/inspector-2026-11-14/visible-battle-first.ini` (lokaler Beleg; nicht veröffentlicht), zweiter: `docs/evidence/inspector-2026-11-14/visible-battle-2.ini` (lokaler Beleg; nicht veröffentlicht), Rematch: `docs/evidence/inspector-2026-11-14/visible-battle-3.ini` (lokaler Beleg; nicht veröffentlicht). |
| Exakte wiederhergestellte Kopie | Export nach erneutem Laden/Prepare mit sechs unterschiedlichen lebenden nativen IDs, korrekten Teams, vollen 161/141 HP, neun belegten Zellen pro Instanz, ursprünglichen Ankern sowie exakt gleichen Known-/Memorized-/Itemlisten. Keine Sperre, keine nativen Belegungsprobleme. Export: `docs/evidence/inspector-2026-11-14/visible-diagnostics-2.ini` (lokaler Beleg; nicht veröffentlicht). |
| 1×1 / 2×2 / 3×3 und überlappende Vorschau | Spearman eine, Seraph vier (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), God neun (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg) markierte Zellen. Belegte Teile separat eingefärbt; klar als begrenzte Vorprüfung bezeichnet. |
| Große Formationen | Horizontale Reihe mit zwei 3×3-Kopien: 18 Zellen, beide platziert, Zähler 3→5. Quadrat mit vier Kopien: 36 Zellen, alle platziert, Zähler 5→9. Vertikale Reihe mit zwei Kopien: 18 Zellen sichtbar geprüft, nicht zusätzlich platziert. Reihe (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Quadrat (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Platzierung (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Fehler, Delete und sofortige Wiederverwendung | Wiederholter Randversuch für 3×3 abgewiesen; 12 vorhandene Einheiten bleiben gesund. Neue Allokation entfernt, `rollback_verified=1`, exakte alte Zustände bestätigt. Eine zusätzliche große Testkopie gelöscht: Zähler 9→8, Sprite und Hit verschwinden; neue Kopie auf denselben neun Feldern sofort platziert, Zähler wieder 9. Fehlerexport: `docs/evidence/inspector-2026-11-14/visible-diagnostics-3.ini` (lokaler Beleg; nicht veröffentlicht), Delete/Reuse: `docs/evidence/inspector-2026-11-14/visible-diagnostics-4.ini` (lokaler Beleg; nicht veröffentlicht). |
| Forest und echte nichtquadratische Instanzen | Eigene QA-Aufstellung mit Spearman, Seraph, Rider, Bog Beast und Crocodile nativ auf Forest verteilt. Bog/Crocodile werden als 2×1 gerendert und tatsächlich belegt. Crocodile über die zweite Zelle gewählt, zwei Vorschauzellen und erfolgreiche Team-B-Kopie bestätigt. Rider-Fläche markiert Waldobjekte; Platzierung abgewiesen und Altbestand unverändert. 2×1-Vorschau (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Waldhindernis (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Export: `docs/evidence/inspector-2026-11-14/visible-forest-diagnostics.ini` (lokaler Beleg; nicht veröffentlicht). |
| Live-Suche und normaler BAT-Start | `c`→`cr`→`cro`→`croc` filtert direkt auf 525→31→16→2 Treffer ohne Dialog; keine Platzierung beim Texteingeben. Gefittete große und breite Listensprites bleiben in ihren Zeilen. Normaler BAT-Start mit drei Mods bestätigt Profilumleitung und öffnet Sandbox/Editor sowie native Karte auch in Standardauflösung. Suche (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), BAT/Editor (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |

Sieben abgeschlossene native Kartenaufrufe sind in native-inspect-events.txt: `docs/evidence/inspector-2026-11-14/native-inspect-events.txt` (lokaler Beleg; nicht veröffentlicht) protokolliert: passende Identität, `read_only=1`, keine Änderung an HP, Items, Zauberarrays oder übrigen Recordbytes, `verified=1`. Das schließt die Item-Unterkarte ein. Die unabhängige Rücklesung der exportierten Daten: `docs/evidence/inspector-2026-11-14/final-evidence-readback.json` (lokaler Beleg; nicht veröffentlicht) prüft zusätzlich Listen, native IDs, Leben, Teams, Anker und vollständige belegte Flächen. Begrenzte Rohzellen-/Aktionsauszüge werden dabei nicht als vollständiger Engine-Snapshot ausgegeben.

Die reguläre EXE, der regulär installierte CoE5SE und dessen normale CoE5-Konfiguration sind per SHA256 unverändert. Ebenso die drei ursprünglichen Nutzerdiagnosen und die Original-Recovery. Sandbox-Dateien in der normalen isolierten Testkopie stimmen mit den aktuellen Modquellen überein. Hashvergleich: `docs/evidence/inspector-2026-11-14/protected-files-check.json` (lokaler Beleg; nicht veröffentlicht). Kein Git-Reset, keine Dateilöschung, kein PR und keine Veröffentlichung; alle experimentellen Binärdateien bleiben privat und getrennt von der Mod. Die Testspiele wurden beendet.

## Selbst testen

1. `SandboxOfElysium-Testen.bat` im Projektordner doppelt anklicken, dann **Sandbox** öffnen.
2. Für die bereits geprüfte Auswahl **Load scenario → repaired-5d092932caf74c588295-1** wählen. Dies ist eine gekennzeichnete Testkorrektur; die ursprüngliche Recovery bleibt separat erhalten. Alternativ das Original laden und in **Repair saved spell selection (copy)** selbst maximal vier Solar-Zauber pro betroffener Instanz wählen.
3. **Prepare battlefield (keep positions)**, dann Rechtsklick auf eine vorhandene Einheit → **Inspect**. Bei großer Fläche funktioniert eine innere Zelle. Mit Exit zurückkehren.
4. **Start battle**; im Bericht **Back to Sandbox** oder **Rematch**. Für breitere Kartenansicht unterstützt die BAT zusätzlich `-WindowWidth 1704 -WindowHeight 900`.

## Prüfgrenzen

Die bestätigte Ursache betrifft die dokumentierte Auswahl und den geprüften CoE5-5.43-Binärstand. Andere Monster, Pfadboni, Fremdmods oder Kampagnenzustände werden daraus nicht pauschal freigegeben. Die neue Abfrage misst native Kapazitäten pro Instanz, ersetzt aber keinen Test aller Spielmodifikatoren. Read-only Inspect wird nur im eigenen isolierten Testfeld angeboten. Die originale Solar-6/4-Auswahl bleibt ungültig; die erfolgreichen Kämpfe verwenden die ausdrücklich korrigierte Kopie.

Nicht sichtbar vollständig geprüft: gehaltenes Rechtsziehen über mehrere große Formationskacheln, sämtliche Kamerazooms/-bewegungen, 1×2-Gate-Instanzen und Transformationen. Für Rechtsziehen sind Abstände, gehaltene Eingaben und Einmal-Auslösung pro Kachel offline abgedeckt. 1×2-Gates wurden nur im nativen Vorlagen-Scan gemessen. Der Scrollversuch auf der Karte scrollte den nativen Kampftext und beweist keinen Zoomwechsel. Teile einer Randvorschau können von den festen Bedienleisten verdeckt sein; deren Gesamtzählung und projizierte Außenkoordinaten wurden separat geprüft. Bei schmalem Standardfenster verdeckt die rechte Leiste einen Teil der nativen Karte; dies ist keine vollständige Ansicht sämtlicher Akteure. Die breitere Testauflösung wurde deshalb für beide Teams verwendet. Alte native Kampftexte bleiben teilweise nach Rückkehr sichtbar und sind keine neue Zustandsaufnahme. Die neue Vorschau bleibt eine begrenzte Geometrie-/Belegungsprüfung, keine Garantie aller Boden-/Sonderregeln oder künftiger Spawnvarianten. Keine vollständige Kampftelemetrie, kein allgemeiner Kampagnen-/Multiplayer-Nachweis.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
