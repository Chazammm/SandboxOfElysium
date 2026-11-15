# Battlefield-Fenster, Items und Mod-Schulen — 2026-11-15

**Nachtrag: Select abwählen.** Der spätere UI-Quellstand schaltet beim erneuten Select-Klick auf dieselbe Einheit/dasselbe Item die Auswahl aus. Ohne gewählte Einheit gibt es keine Vorschau/Platzierung; das Kontextmenü vorhandener Einheiten bleibt nutzbar. 46 bestehende Interface-/Panel-/Vorschauprüfungen und Syntax bestanden erneut. Die bereits laufende Testspiel-Sitzung wurde nicht beendet; der neue Toggle ist noch nicht sichtbar im Spiel geprüft und wird beim nächsten BAT-Start synchronisiert. Die folgenden Hashes und Sichtprüfungen gehören zur vorherigen vollständigen Fenster-Abnahme, nicht zu diesem Nachtrag.

Lokaler Entwicklungsstand **0.1.0+editor.7**. Die separate experimentelle CoE5SE-Erweiterung ist erforderlich; keine DLL liegt im Mod-Paket. Kein Commit/Push, PR, Release oder Kontakt wurde für diese Aufgabe erstellt. Bereits vorhandene uncommittete Arbeit aus editor.6 und früher blieb erhalten.

## Bindung der Ergebnisse

- Sandbox-Basis: `11c572a4d441a1e283d14bedb0d1d5540c7ccb45`, mit vorhandenen lokalen Änderungen und den hier beschriebenen Ergänzungen.
- Extender-Basis: `d96f2b784e97e115022a2598da2c821dd9520135`, separater Branch `sandbox-test-field-terrain-3.4`, vorhandene lokale Änderungen erhalten.
- Spiel: Windows x64 CoE5 5.43 / Steam-Build 26458448, EXE SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`.
- Abgenommene lokale DLL: SHA256 `b0b75e0b69c7c6d16a7c6f4d1c92b7c4452189d347f2a4728120e00d6ea681ec`.
- Finaler verteilter Mod-Quellbaum: `043bf667c5015597591fcf1dc98d59c7d6921415f6133e2c5414345e0f4ea955` laut frischem Laufzeitkontext. Der Wert bindet den Mod, nicht sämtliche Dokumente oder private Prüfscripte.
- Ausschließlich eigene Spielkopie `private/terrain-lab/runtime`, Profil `private/terrain-lab/profile`; jeder BAT-Start verlangt eine neue vom Spiel zurückgeschriebene Startkennung.

| Lauf | Zweck und tatsächlich geprüfter Umfang |
|---|---|
| `29cccc380d00435da078ddcc71fbdc4d` | Erster vollständiger nativer Panel-Pass: fünf neue Gruppen plus acht Loadout-Gruppen, vor der abschließenden Anpassung der Standardfenstergröße. Mod-Quellhash damals `4f0bb1e8992cd5763706a5767542d009ee0bb1e876ea774728090b04ff0a9da9`. |
| `ca5978b2fd9c4115a609879e2d2283f4` | Frischer, nicht automatisch kämpfender sichtbarer UI-Test bei BAT-Standardgröße 1200×900. Eigene Testaufstellung, CrabCult und ausdrückliche private Fixture aktiviert. Finaler Mod-Quellhash wie oben. |
| `423d0cdf8c5f4c1bae1a81564b949126` | Sechs neue Panel-Gruppen und acht bestehende Loadout-/Fixture-Gruppen PASS; enthält zusätzlich tatsächliche native Auswahl eines Mod-Schulzaubers im natürlichen Kampf. |
| `51871744ff7f436cb6cd33dded8cfd04` | 21 bisherige native Gruppen PASS ohne private Inhalts-Fixture: sieben Loadout, fünf Leerfeld, vier Placement, drei Inspector/Caster/Repair, zwei Filter/CrabCult. |
| `9cb6d51f5fba4c11932d7b87a789aea6` | Frischer sichtbarer Test mit angeforderter Größe 1704×900: eigene UI-Speicherung geladen, Ausrüstung/Schulen/Mod-Itemkarte, Fluchschutz und verschobenes Fenster. |
| `dbcc4aa5ef574611a7ccc50e8e411eeb` | Normaler BAT-Start mit drei Standardmods, ohne CrabCult, Fixture oder automatische Prüfläufe. Sandbox, Standardfeld, weiterhin funktionierende Einheiten-Livesuche und neuer Itemkatalog sichtbar geöffnet, Feld über Back geschlossen und Spiel über Quit beendet. |

Die Gruppenzahlen verschiedener Läufe überlappen und sind keine Summe unabhängiger Tests. Private Rohdaten liegen unter `private/panel-runs/`, Bilder unter `private/panel-ui-captures/`. Die Sitzungskennung des jeweiligen Ergebnisses beziehungsweise des daneben archivierten `launcher-context.ini` ist maßgeblich; ältere Ergebnisdateien allein gelten nicht als neuer Test.

## Umsetzung und Grenzen der nativen Schnittstelle

`config_window.lua` ersetzt den öffentlichen Edit-Einstieg durch ein Fenster auf der Karte. Die alten Hilfsfunktionen bleiben kompatibel im Quellbaum. Rechts stehen Units/Items, unabhängige Live-Suchen, Item-Icons, Slot- und Herkunftsfilter sowie Select/Inspect bereit. Aktive Itemauswahl wird angezeigt und kann beendet werden. Rechte Klicks verwenden die tatsächliche Instanz und native Fußabdruckzuordnung. Mehrere passende Slots verlangen eine anatomische Auswahl; belegte Slots eine zweite ausdrückliche Ersetzungsbestätigung mit bisherigem Item. Remove ist ebenfalls ausdrücklich. Alle Änderungen verwenden den bestehenden nativen Konfigurationstransaktions- und Rücklesepfad.

Das Fenster ist an Modell-ID, native ID und Generation gebunden. Titelziehen, Größenänderung, Randbegrenzung, X und Zielwechsel sind getrennt von Karteneingaben. Textfokus gehört entweder Einheiten-, Item-, Zaubersuche oder Anzeigename. Ein Schließen oder Modalrücksprung konsumiert die zugehörige Eingabe, statt eine Einheit zu platzieren. Die Fensterhöhe berücksichtigt die tatsächliche Slotanzahl; manuell geänderte Größen werden erhalten.

Die echte native Itemkarte wurde anhand der eigenen EXE untersucht und separat angebunden. Sie zeigt geladene native/modifizierte Icons und Beschreibungen. Die native Einheitenkarte bleibt tatsächlich nativ und ausdrücklich schreibgeschützt. Ihr editierbarer Abschluss kann `chooseMemorized` aufrufen und zufällige Auswahlen verändern. Ausrüstung und Memorierung werden deshalb deterministisch im Fenster geändert; nach Rückkehr aus Inspect wird der unterstützte Feld-/Einheitenzustand geprüft. Bei langen nativen Einheitenkarten ist die Zeile **Exit** am unteren Kartenende zu verwenden.

Magieschulen zeigen Basis, Bonus, effektive Stufe und Kapazität getrennt. Existierende native Basisschulen dürfen auf 1–3 geändert werden. Unlock lernt alle geeigneten Zauber bis zur ausgewählten Basisstufe, zusätzlich durch eine gegebenenfalls niedrigere effektive Stufe begrenzt; es memoriert nichts. Learn bleibt einzeln möglich. Höhere bereits bekannte Zauber bleiben beim Senken erhalten. Passt die aktuelle Memorierung danach nicht mehr, wird der gesamte Vorgang unverändert abgelehnt. Keine zufällige Neuauswahl oder stille Entfernung.

Die Untersuchung fand zwei relevante native Details: Der effektive Aggregatleser für Pfad −1 scannt direkt die Template-Zeilen und musste bei abgesenkten Instanzstufen ebenfalls korrekt angepasst werden. Beim Wiederaufbau eines abgesenkten Magiers kann ein gültiger höherer bekannter Zauber oberhalb seiner jetzigen Stufe liegen. Dafür gibt es den ausdrücklichen Wiederherstellungspfad `restoreKnown`; interaktives Learn und jede Memorierung bleiben aktuell stufen-/kapazitätsgeprüft. Modell und native Daten werden nach Änderung und Rollback geprüft. Ein nicht verifizierter Rollback sperrt den Editor, behält das bestätigte Szenario und verlangt Diagnoseexport sowie ausdrückliches Wiederöffnen. Er wird nicht als Erfolg gemeldet.

Der leere native Editor erzeugt normale Akteure ohne Commander. Ihre nativen Namen werden aus Monster/Effekten abgeleitet; ein verifiziertes individuelles natives Namensfeld steht hier nicht zur Verfügung. **Name** ist daher ausdrücklich ein **Sandbox display label**: höchstens 48 gültige Unicode-Zeichen, keine Steuerzeichen, leer stellt die Typanzeige wieder her. Native Identität, native Karte und native Kampfmeldungen behalten den Spielnamen. Szenario, Titel und Sandbox-Bericht führen den Anzeigenamen separat.

## Mod-Items, Mod-Schulen und Herkunft

Die Kataloge lesen den geladenen Bestand und unterstützen aktive Mod-Items/Schulen/Zauber. `loadedContentOrigin` im separaten Extender beobachtet tatsächliche akzeptierte C5M-Schreibvorgänge sowie Schul-/Zauberregistrierung und bindet die Zuordnung an die aktuellen Metadaten. **Modded Items** filtert beobachtete neue/geänderte Itemdefinitionen. **Modded schools** umfasst beobachtete neue/geänderte Schulen und vorhandene Schulen mit nachgewiesenen Mod-Zaubern. Eine Einheit erhält dadurch keine neue Basisschule.

Es wird keine Herkunft aus einer ID-Nummer oder einem Namen geraten. **Unknown origin** bleibt separat; All behält solche Inhalte. `baseline` bezeichnet unveränderte erfasste Metadaten und beweist keine vollständig unveränderten Vanilla-Assets. Reine Grafik-/Beschreibungsänderungen außerhalb der erfassten Daten, wertgleiche Befehle und eine vollständige Mod-Historie sind nicht abgedeckt. Fehlende API wird als unbekannte Herkunft behandelt.

- Tatsächliche Fremdmod: vorhandene private **CrabCult**-Kopie. Item **Abyss Fragment #300**, durch die beobachtete Definition ausdrücklich CrabCult zugeordnet; Symbol, native Karte, Auswahl/Equip, Save/Load und verweigerte Entfernung des verfluchten Items sichtbar geprüft. Native Shell Priest #2009 prüft zusätzlich Basis1/Bonus1/Effektiv2, Anheben und genaue Wiederherstellung. IDs sind hier Testergebnisse, keine allgemeine Herkunftsregel.
- Eigene ausdrücklich aktivierte QA-Mod **ZZZSandboxLoadoutFixture20261115**: Druid's Apprentice mit 20 Slots und bestehender Schule **Sandbox QA #70**, zwei gleichnamige **Sandbox Echo #1029/#1030** auf Stufe1/2. Herkunft, unabhängige Identität, Learn/Unlock/Mem, Speicherung und native Kampfzauberauswahl geprüft. Die Fixture ist eigene Testdefinition, kein Beweis für jede beliebige Fremdmod.
- Der normale BAT-Start aktiviert weder CrabCult noch Fixture. Die vorhandene lokale CrabCult-Kopie ist mit `SandboxOfElysium-Testen.bat -CrabCult` gezielt testbar; Dateien werden nicht verteilt. Die private Fixture benötigt ausdrücklich den Entwickler-Prüfmodus. Die eigene Datei `p7a.ini` hängt von diesen Testmods ab und ist kein Standardbeispiel für einen modfreien Start.
- Ein Szenario mit fehlenden erforderlichen aktiven Mods wird vor dem Feldwechsel abgelehnt; der bisherige Aufbau bleibt bestehen. Gleiche ID und gleicher Name allein erkennen weiterhin nicht jede nachträgliche inhaltliche Änderung einer Mod.

## Sichtbare Prüfungen

| Prüfschritt | Selbst im Spiel beobachtet |
|---|---|
| Live-Itemsuche | Direkt `f`, dann `fr` eingegeben; Treffer änderten sich sofort, Frost Brand erschien. Keine zusätzliche Suchmaske. `type_text` der Automatisierung erzeugte in diesem Spiel keine Texteingabe; normale einzelne Spieltasten funktionierten. |
| Geben / große Instanz | Frost Brand per Select und Rechtsklick in eine innere Zelle des großen God Emperor gegeben. Zähler A2/B2 unverändert; Rücklesemeldung erfolgreich. |
| Inkompatibilität | Helm auf God Emperor ohne Helmposition abgelehnt: verständliche Meldung, vorherige Konfiguration unverändert. Danach Diagnose exportiert: `diagnostics-ca5978b2fd9c4115a609-1.ini`. |
| Ersetzen / Abbrechen | Ward of Frost auf belegtem Waffenslot verlangte Bestätigung mit Frost Brand als bisherigem Item. Cancel; erneutes Öffnen zeigte weiterhin Frost Brand. Bestätigen ersetzte es, Fenster zeigte Ward of Frost. |
| Inspect / Entfernen | Echte Ward-of-Frost-Karte mit Stats/Zaubereffekt geöffnet, OK zurück ins gleiche Fenster. Remove zeigte eigene Abfrage; Bestätigen leerte nur den Slot. |
| Anatomische Auswahl / Mod-Item | Beim Testdruiden Auswahl mehrerer Misc-Positionen; bestehendes Amulet of Anti Magic sichtbar, freien Slot4 gewählt. Abyss Fragment wurde ausgerüstet und blieb nach eigenem Save und späterem Load sichtbar erhalten. |
| Verfluchtes Mod-Item | Native Karte mit eigenem Symbol, Hydromancy+1, Dark Magic+1 und Cursed Item. Remove ausdrücklich versucht; verständliche Verweigerung, Inventar unverändert. |
| Fenster | Auf der Karte geöffnet, Titel gezogen, X geschlossen, andere Instanz geöffnet. Größe über Griff über den Rand hinaus angefordert und begrenzt. Auch beim größeren Start verschoben; alle drei Tabs/Native Inspect erreichbar, Karte/Zähler bleiben sichtbar. |
| Magie / native Karte | God Emperor Storm Magic1→2→3→2, zwei bestehende Schulen aufklappbar. Bei2 Unlock, anschließend Shock gezielt memoriert. Native Karte: Storm2, Solar1, Shock markiert und 1/3 memoriert; Rückkehr verifiziert. God hatte bereits höhere bekannte Originalzauber; deren Anzeige ist kein Beweis für neu freigeschaltete Stufe3-Zauber. |
| Modded schools | Beim Testdruiden Druidism und Sandbox QA vorhanden, eigener Filter zeigte nur Sandbox QA. Gleichnamige Zauber mit getrennten IDs sichtbar; auf2 erhöht, Unlock ließ den zweiten Zauber unmemoriert, erst Mem wählte ihn. Senken auf1 danach verweigert und beide gewählten Zauber/Stufe2 blieben erhalten. Live-Zaubersuche nach `z` blendete die Zauberzeilen aus. |
| Anzeigename / zweite Instanz | Bärensäule auf A#1 geladen, direkt `x` angehängt: Titel/Feld sofort Bärensäulex. Team-B-God blieb God Emperor B#2. Native Karte hieß weiter God Emperor. Speichern als neue eigene Datei `p7a`; später erfolgreich geladen. |
| Standardstart / Navigation | BAT ohne Extras: normales Hauptmenü ohne Prüfknopf, Sandbox→Feld, A1/B1, native Einheiten-Icons, Einheiten-Livesuche `z` mit53 Treffern; Wechsel zu Items zeigte reguläre Icons/Namen. Back→Main menu→Quit. Anschließend kein isoliertes Spielfenster mehr vorhanden. |

Die BAT-Größen sind die angeforderten Startparameter. Die erfassten Fensterbilder hatten bei der aktuellen Windows-Skalierung 962×752 beziehungsweise 1365×752 Pixel; daraus wird keine ungeprüfte interne Auflösung abgeleitet.

## Native API-Tests und Offline-Prüfungen

Sechs neue Panel-Gruppen PASS im realen Prozess:

1. Beobachtete Herkunft und Produktionsfilter für CrabCult-Item, QA-Schule und gleichnamige Mod-Zauber.
2. Druidism2 Unlock: **14** passende Stufe1/2-Zauber bekannt, **fünf** Stufe3-Zauber weiterhin unbekannt, Memorierung unverändert. Höheren Zauber gezielt lernen/memorieren; ungültiges Senken exakt abgelehnt. Nach ausdrücklichem Abwählen erfolgreich gesenkt, höherer bekannter Zauber erhalten.
3. Zwei God-Instanzen mit unabhängigen Schulen, native Aggregatstufen nach Senken auf1, andere Instanz unverändert, Sandbox-Labels und genauer Dateirundlauf einschließlich höherer bekannter Zauber.
4. Konfigurierter Bärenwächter: Copy/Move, tatsächliche Datei Save/Load, zweimal echter `U.fight` und `U.reset` mit natürlichen Kämpfen Runde4/SiegerA; exakte Items, Schulen und bekannte/memorierte Reihenfolge einschließlich Label nach Reset/Rematch. Bericht enthält separaten Anzeigenamen.
5. Eigene Mod-Schule im echten Kampf: natürlicher Abschluss Runde1/SiegerA; native Auswahl für Pfad70 gab einmal einen der tatsächlich ausgewählten QA-Zauber zurück. Danach genaue Wiederherstellung. Das ist keine vollständige Wirkungs-/Schadensspur.
6. Tatsächliche native Item-Sprite-Quads für Frost Brand und Amulet of Anti Magic vollständig innerhalb ihrer Rechtecke.

Der normale Datenlauf besteht sämtliche 21 oben aufgeschlüsselten bestehenden Gruppen: große Fußabdrücke, Löschen und sofortige Zellwiederbelegung, wiederholte Ablehnungen, Waldhindernisse, vorherige Zufallszauber/Items, Unique-Schutz, Originalfehler/ausdrückliche Reparatur, Memoriergrenzen, leere/einseitige Speicherung, verweigerter Kampfstart, gültiger Kampf/Reset/Rematch, Ranged und aktive CrabCult-Einheiten. Ein injizierter fehlgeschlagener Cleanup wird gesperrt und nur ausdrücklich mit genauer Zauberwiederherstellung geöffnet.

**127 Offline-Verträge PASS**, verteilt auf Modell20, Editor10, Integrität13, Interface18, Vorschau15, Caster9, Battlefield13, Loadout16, Panel13. Zusätzlich alle Mod-/Prüf-Lua-Dateien syntaktisch lesbar, PowerShell- und Python-Parser PASS, Git-Whitespace-Prüfung beider Arbeitsbäume PASS. Offline-Tests beweisen keine native Kompatibilität oder sichtbare Grafik.

## Aufbewahrte Fehlschläge und nicht vollständig geprüfte Fälle

Frühe Kandidaten sind unter `private/panel-runs/first-3a73` und `second-cd66` erhalten: der erste behielt eine zu hohe effektive Aggregatstufe, der nächste konnte höhere bekannte Zauber eines abgesenkten Magiers noch nicht exakt rekonstruieren. Beide Produktfehler wurden vor der erfolgreichen Abnahme korrigiert. `third-6537` enthält einen unterbrochenen Panel-Test, weil der private INI-Export Boolean-Diagnosewerte ablehnte. Der Export wurde korrigiert, der unvollständige Lauf zählt nicht als PASS. Erste Screenshots nach automatischen Kämpfen hatten alte native Kampftexte im Hintergrund; abschließende UI-Tests verwendeten frische Starts ohne automatische Kämpfe.

Nicht neu vollständig per Maus durchgeklickt: sämtliche Slotfilterkombinationen, alle Schul-/Zauberseiten und Sprachglyphen, lange gehaltenes Formation-Dragging über jede Kamerastufe, komplette Copy/Move/Reset/Rematch- und Berichtsnavigation mit dem neuen Fenster. Deren jeweilige Produktionspfade sind nativ/offline und, wo angegeben, in früheren sichtbaren Berichten geprüft; sie werden hier nicht als neue sichtbare Vollabnahme bezeichnet. Leerer/überlanger/ungültiger Unicode-Name wurde offline geprüft, nicht jede Variante sichtbar getippt. Neue Augen-/Herzimplantate, beliebige zusätzliche Basisschulen, freie Stufen über3, jede Fremdmod, sämtliche nativen Instanzeigenschaften/Transformationen, Kampagnen-/Multiplayer-Kontext und eine vollständige Szene nach Kampf sind weiterhin nicht zugesagt.

## Datenprüfung und selbst testen

Vorherige Arbeitsbäume und **83** vorhandene Sandbox-Profildateien wurden unter der über `private/panel-baseline-path.txt` bezeichneten Sicherung erhalten. Nachher: keine davon fehlt; ausschließlich die erzeugte `launcher-context.ini` trägt erwartungsgemäß die neue Startkennung. Szenarien, Diagnosen, Recoveries und frühere Berichte unverändert. Die drei Kontrollhashes von normaler Spielkonfiguration, installiertem Spiel und regulärer Extender-DLL stimmen unverändert. Keine DLL/EXE im Mod-Auslieferungsbaum, keine Git-Änderungen verworfen/gestaged. Ergebnis: `private/panel-preservation-audit.json`.

1. Im Projektordner `SandboxOfElysium-Testen.bat` doppelklicken. Der Starter synchronisiert aktuelle lokale Dateien und verwendet nur das isolierte Profil.
2. **Sandbox → Open with native deployment** oder eigenen Aufbau mit **Open battlefield / edit (keep positions)** öffnen.
3. Unter **Items** suchen → Inspect/Select → Einheit rechts anklicken. Für das normale Kontextmenü **Cancel item selection** verwenden; dort **Edit** öffnen.
4. Im Fenster Items/Schulen/Anzeigename konfigurieren; Learn/Unlock und Mem bewusst getrennt bedienen. Save unter eigenem neuen Namen.
5. Mindestens eine Einheit je Team aufstellen und **Start battle** wählen; danach Bericht/Reset/Rematch wie bisher. Bei unbekanntem Zustand Diagnose exportieren und die ausdrückliche Wiederherstellung verwenden.

Die separaten Extender-API-Details stehen in dessen `SANDBOX_PANEL_EXPERIMENT.md` und aktualisierter `coe5.lua`; dieses Dokument ersetzt keinen öffentlichen Extender-Release.
