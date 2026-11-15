# Verfluchte Items entfernen — 15.11.2026, editor.8

Die ausdrückliche Entfernung funktioniert jetzt auch beim Crystal Heart aus der tatsächlich exportierten Diagnose. **Cancel** behält das Item; **Remove cursed item** entfernt genau das bestätigte Item aus genau der gebundenen Instanz. Die globale Flucheigenschaft bleibt bestehen. Sandbox und experimenteller Extender bleiben getrennte lokale Projekte; keine Extender-DLL wird mit der Mod verteilt. Kein PR, Push, Release oder Kontakt.

## Tatsächliche Diagnose und Ursache

Gelesen wurde die private `diagnostics-5b0a36e7cc244d528769-1.ini` aus dem bestehenden terrain-lab-Profil. Der begrenzte Export enthält 64 letzte Aktionen. Aktion061 protokolliert `Configuration refused: cursed_item`, Operation `equipment_change`, Sequenz151. Der Fehlerkontext nennt Modell5, native Einheit8, **Arcane Frost Dragon #1830**, Validierungsstufe `validate` und `rollback_verified=true`. Die vorherige Konfiguration wurde bestätigt erhalten, nicht erfolgreich entfernt. Der aktuelle Snapshot enthält sechs Modell-/Nativeinträge ohne gemeldete Integritätsprobleme.

Der betroffene gespeicherte Datensatz hat **Crystal Heart #185 an Position6** (nullbasiert; Oberfläche **#7 Misc**), 3×3 Fußabdruck bei Anker6,6. Frost Magic #27 Basis2; bekannte Zauber in Reihenfolge `91:Icicle|88:Freeze|98:Winter Ward|96:Hail Storm`, memoriert `98:Winter Ward|96:Hail Storm|88:Freeze`. Der begrenzte Verlauf beweist weder frühere Ausrüstungsschritte noch den exakten vorausgehenden Klick oder Remove gegenüber Replace. Andere Drachen und Gegenstände im Export sind kein Beleg für diesen Ablauf.

Die vorhandene native Konfigurationstransaktion schützte sämtliche verfluchten Items. Crystal Heart ist zusätzlich ein permanentes Herzimplantat. Ein bloßes Abschalten der Fluchsperre wäre deshalb unzureichend: Die native Ausrüstung setzt dauerhafte Organverletzungsbits, die Entfernen nicht rückgängig macht. Die neue Ausnahme autorisiert nur das konkret bestätigte Entfernen; neue Implantate bleiben gesperrt.

## Änderung und Sicherheit

- **Sandbox:** `Edit → Items → Remove` zeigt bei Fluch **Remove cursed item**, bei Implantaten zusätzlich den Hinweis, dass permanente Verletzungen nicht geheilt werden. Zielinstanz, Generation, Position und erwartete Item-ID bleiben gebunden. Direktes Ersetzen eines Fluchitems bleibt geschützt: zuerst entfernen, dann neu ausrüsten.
- **Separater Extender:** Capability `cursedRemoval=1` und strikte optionale `removeCursed={position,item}`-Anforderung. Nur dieser Platz darf leer werden; alle anderen Items, Basis-Schulen und geordneten Zauberlisten müssen unverändert sein. Falsche/alte IDs und kombinierte Änderungen werden abgewiesen. Ownership, lebende Generation, native Kompatibilität, Level-/Kapazitätsprüfung, Readback und Rollback bleiben aktiv.
- **Lebende Instanz:** Remove erzeugt keine neue Einheit. Organverletzungsmaske vor/nach Erfolg und Rücknahme wird geprüft und nicht geschrieben. Unverifizierte Rücknahme sperrt die Bearbeitung und verwendet die vorhandene bewahrte Aufstellung für eine ausdrücklich geprüfte Wiederherstellung. Es wird kein Zufallszauber gewählt oder stillschweigend abgewählt.
- **Save/Load/Reset:** Neue native Einheiten können zufällige verfluchte Startitems erhalten, die im gespeicherten Aufbau nicht vorkommen. Nur beim Aufbau frisch erzeugter Instanzen werden diese mit einzelnen geprüften Entfernungstransaktionen entfernt, bevor die exakte gespeicherte unterstützte Konfiguration übernommen wird. Deren anfängliche zufällige Memorierung ist nur eine Zwischenstufe dieser neuen Instanz; eine bestehende Editorinstanz folgt diesem Pfad nicht. Bereits gehaltene identische Implantate dürfen bei gleicher Anzahl zur gespeicherten Position umgeordnet werden, es wird keines hinzugefügt. Der Override wird nicht im Szenario gespeichert.
- Fehlerrückmeldungen enthalten angeforderte Position/Item-ID und die vorhandenen Konfigurations-/Rollbackdetails. Native Logs unterscheiden den expliziten Override. Exporte bleiben begrenzt und zeigen nicht den vollständigen nativen Zustand.

## Build und native Tests im echten Spiel

CoE5 **5.43 Windows x64**, EXE SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`. Separater lokaler CoE5SE **3.4.0** auf Basis `d96f2b784e97e115022a2598da2c821dd9520135`, nicht der kleine offizielle 3.4.4-Beitragscheckout. Erfolgreicher Build4 mit vorhandener llvm-mingw-Toolchain; DLL SHA256 **`ba4d614289d0eff8dcac5ada2b58521290de8251c18e50dc630a6e02de6a2c5a`**. Sandbox editor.8 Quellhash **`3c2f2d2a16f735b09e596499fad297b80726229624c8e668314c88eed84328d3`**. Spätere Dokumentationsänderungen ändern diese getesteten Produktquellen nicht.

Alle neuen Versuche verwendeten eine **zusätzliche** private Spielkopie `private/cursed-lab/runtime` mit eigenem `private/cursed-lab/profile`, frischer Sitzungskennung und Profilrückmeldung. Das bereits laufende terrain-lab-Spiel des Nutzers wurde nicht beendet oder aktualisiert.

Sitzung **`f60fa3de8376498e9ae773fe27aece72`**: zwei neue native Gruppen **PASS** und 14 bestehende native Gruppen **PASS** (7 Loadout, 5 Empty-Editor, 2 Filter/aktive Mods). Ergebnisse und Logs sind privat unter `private/cursed-lab/accepted-f60f/` archiviert. Testcode lief im echten Spiel, diese automatisierten Abfragen sind keine Mausbedienung.

| Native Prüfung | Ergebnis |
| --- | --- |
| Tatsächlich gespeicherter Frost-Dragon-Zielzustand: Crystal Heart185/Position6, 3×3, Anker6,6, Basis und geordnete bekannte/memorierte Zauber | Erfolgreich vorbereitet; eigene QA-Mitspieler Druid's Apprentice und Goblin, nicht die gesamte Sechsereinheitenszene des Nutzers |
| Gewöhnlicher API-Aufruf ohne Override | Weiterhin `cursed_item`, unverändert |
| Falsche erwartete ID und zusätzliche Itemänderung | Verweigert, kompletter geprüfter Vorzustand erhalten |
| Explizites Entfernen, Wiederholungsversuch mit altem Slot und erneutes Entfernen nach privatem Wiedergeben | Erfolg bzw. verifizierte Ablehnung; globale Flucheigenschaft bleibt gesetzt |
| Lebender nativer Handle/Generation, alle anderen Slots, Basis-Schulen und geordneten Zauber; anderer Druid | Unverändert; der Zielplatz wird leer |
| Datei speichern, schließen, neu laden und aufbauen | Unterstützte Konfiguration exakt; entfernte Startitems kommen nicht wieder |
| CrabCult **Shell Priest #2009**, **Abyss Fragment #300**, Hydro-Basis1/Bonus1/Effektiv2 | Entfernen bei memoriertem Level2-Zauber428 mit `spell_level` unverändert verweigert; nach ausdrücklichem Abwählen entfernt, Basis1/Bonus0/Effektiv1; höherer bekannter Zauber erhalten; Save/Load erfolgreich |
| Bestehende Ausrüstungs-/Zauber-/Copy-/Move-/Save-/Load-/Kampf-/Reset-/Rematch-, Empty-/Unique-/Filter-/Modtests | Alle 14 ausgewählten Gruppen PASS, natürliche Kämpfe eingeschlossen; nicht sämtliche früheren Platzierungs-/Waldgruppen neu ausgeführt |

Native frische Drachen hatten Crystal Heart zunächst auf Position7 und ein weiteres zufälliges Startitem (im Hauptlauf Magic Lamp; in der zweiten Sitzung Thousand Medicine Bowl). Die private Fixture stellt anschließend genau die diagnostizierte unterstützte Zielkonfiguration auf Position6 her. Das ist **keine** Behauptung über die unbekannten früheren Aktionen des Nutzers. Modell-/Native-IDs aus seinem Export sind Beweiszuordnungen, keine Behauptung identischer IDs im frischen Test.

Eine unabhängige frische Sitzung **`eb4a1ca2371f48d3994b5ef87eeeb81f`** mit denselben Produktquellen/DLL wiederholt beide neuen nativen Gruppen erfolgreich und registriert eine nur private Starttaste für den sichtbaren Nachbau.

## Selbst sichtbar geprüft

In dieser zweiten Sitzung öffnete **Cursed diagnostic editor (private)** den echten produktiven Sandbox-Editor mit der diagnostizierten Zielkonfiguration und eigenen QA-Mitspielern. Kein schreibgeschützter Ersatzeditor: tatsächliches `config_window`, `loadout` und experimentelles Runtime-Backend. Die private Zusatzstarttaste wird durch die normale BAT nicht aktiviert.

1. Rechtsklick auf die innere Zelle des großen Frost Dragon → Kontext **Edit**. Fenster zeigt **#7 Misc: Crystal Heart [cursed]**, Teamzähler A2/B1.
2. **Remove** zeigt die ausdrückliche Bestätigung und den lesbaren Hinweis **Removes the item; permanent injuries are not healed.** **Cancel** lässt Crystal Heart und Zähler unverändert.
3. **Remove → Remove cursed item**: Platz wird **empty**, Meldung **Updated; exact native configuration verified.** Sprite und Teamzähler bleiben erhalten.
4. **Export Diagnostics** tatsächlich betätigt. Neue private Datei `ZZSandboxBattlefieldProbe/diagnostics-eb4a1ca2371f48d3994b-1.ini`: drei Modell-/Nativeinträge, `native_issues=0`, Zielposition6 tatsächlich -1, gespeicherte Ausrüstung ebenfalls leer. Der Probe-Mod ist hier der ausführende Datenbesitzer; im normalen Sandbox-Start liegen Exporte unter SandboxOfElysium.
5. **Select** beim Strange Seraph zweimal: erst ausgewählt, dann wieder **Select a unit below / Unit selection cleared**. Anschließend dasselbe mit CrabCults **Abyss Fragment**: erst Itemauswahl, dann wieder **Choose an item below**. Keine neue Einheit und keine Ausrüstungsaktion ausgelöst.

Frische Beweisbilder bleiben privat in `private/cursed-ui-captures/`: `01-confirm-injury-warning.png`, `02-removed-verified.png`. Die sichtbare Fensteraufnahme hatte 962×751 Pixel, der native Editor meldete 800×600 Zeichenkoordinaten; keine Behauptung eines zusätzlich getesteten Vollbild-/Zoomrasters. Save/Load, Bonusfehler und vollständige Zaubervergleiche wurden nativ getestet, nicht nochmals komplett per Maus bedient.

## Offline-Prüfungen und fehlgeschlagene Kandidaten

Alle **127 bestehenden Offline-Fälle** und Syntaxprüfung sämtlicher verteilter Lua-/Probe-Dateien bestanden nach den finalen Produktänderungen. Zwei alte Platzierungstest-Fixtures wählen jetzt ihre beabsichtigte Einheit ausdrücklich aus; die gewollte Select-zum-Abwählen-Funktion bleibt erhalten. Es wurden keine Tests hinzugefügt, die nur dieselben Zuweisungen nacherzählen. Die beiden neuen nativen Gruppen prüfen reale API-Nebenwirkungen und Persistenz.

Frühere Versuche sind nicht als Erfolg umetikettiert: Sitzungen `7fbc8e0d…` und `d0e5706e…` scheiterten an der zuvor pauschal geschützten Implantat-Neuanordnung; ein Fehlertext im privaten Probe-Skript hatte zusätzlich eine nil-Verkettung und wurde korrigiert. `6351e4b6…` setzte fälschlich einen leeren Misc-Platz voraus. `482e6782…` bestand auf Position7, war deshalb noch **kein** exakter Nachbau von Position6. Ein Zwischenbuild scheiterte nach falsch platzierter Diagnosezeile beim Kompilieren; korrigiert, nie gestartet. Rohdaten/Buildlogs bleiben privat erhalten. Maßgeblich sind die beiden vollständigen oben gebundenen finalen Sitzungen.

## Verbleibende Grenzen

**Live-Entfernen heilt keine permanente Verletzung.** Im echten Crystal-Heart-Test blieb die partielle Organmaske vor/nach Remove **4194304 → 4194304**. Die derzeitige Szenariodatei speichert jedoch **keine vollständigen nativen Verletzungen, HP oder sonstigen undurchsichtigen Instanzattribute**. Der neu aufgebaute Drachenaktor hatte Maske **0**. Das ist ausdrücklich keine vollständige Verletzungs-/Instanzzustandswiederherstellung und darf nicht als solche ausgegeben werden. Unterstützte Ausrüstung, Basis-Schulen und bekannte/memorierte Zauber waren exakt. Neue Implantate, macOS, beliebige andere Mods und andere Spielversionen sind nicht abgenommen. Eine verifizierte Live-Entfernung und späterer Neuaufbau sind getrennte Operationen.

## Selbst über die bestehende BAT testen

1. Das bisher laufende eigene Testspiel selbst beenden. Im Projektordner **SandboxOfElysium-Testen.bat** starten; aktuelle Sandbox-Dateien und der separat neu gebaute passende Extender werden übernommen. Der alte bereits laufende Prozess erhält kein Hot-Update. Die BAT wurde für editor.8 nicht ein zweites Mal parallel zum Nutzerprozess gestartet; getestet wurde die zusätzliche isolierte Kopie mit denselben Produktquellen und Buildwerkzeugen.
2. **Sandbox → Battlefield → Open with native deployment (reposition units)**. Aufstellung öffnen oder Arcane Frost Dragon setzen. Ohne aktive Itemauswahl rechts auf die Einheit → **Edit → Items**.
3. Beim verfluchten Gegenstand **Remove → Remove cursed item** wählen oder mit **Cancel** abbrechen. Bei einer Bonus-/Zauberablehnung die betroffenen memorierten Zauber selbst abwählen und erneut versuchen. Für direkten Ersatz zuerst entfernen.
4. Je mindestens eine Einheit pro Team setzen, **Start battle**. Berichte, Reset und Rematch verwenden weiterhin die unterstützte gespeicherte Konfiguration; die Verletzungsgrenze oben beachten.

Abschließend bestätigte der Hashvergleich alle **88** ursprünglichen Sandbox-Profildateien und alle drei regulären Installations-/Profilkontrollen unverändert. Im Mod-Ordner liegt keine DLL/EXE. Das eigene Testspiel wurde über Quit beendet, die anschließende Fensterinventur war leer. Die ursprüngliche Diagnose und Szenarien bleiben erhalten.

Der Nutzer hat anschließend das GitHub-Update der Mod-Quellen mit Installationsanleitung beauftragt. Ein gewünschtes Komplettpaket mit experimentellem Extender wurde nach Prüfung der fehlenden Weitergabefreigabe zurückgenommen. Extender-Dateien bleiben lokal. Der kleine offizielle Ranged-Beitrag liegt weiterhin in einem eigenen Checkout und enthält keine dieser experimentellen Änderungen.
