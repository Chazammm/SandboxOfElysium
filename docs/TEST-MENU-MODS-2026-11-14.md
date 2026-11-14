# Battlefield-Menü und aktive Mod-Einheiten — 14.11.2026

## Änderung und Umfang

Das Feedback von musical_pianist betraf die Vermischung von Status und Aktionen. Das bestehende native Menü verwendet jetzt vier getrennte, beschriftete Abschnitte mit eigenen Rahmen:

- **Current setup:** ausgewählte Karte, A-/B-Zahlen und Farben sowie Unique-Option. Nur tatsächlich änderbare Angaben sind anklickbar.
- **Battlefield:** häufige Aktion „Open battlefield / edit (keep positions)“ und die ausdrücklich neu positionierende native Variante.
- **Scenarios:** Load, Save und nach vorhandenem Kampf Reset.
- **Tools:** Diagnostics, Terrain-Katalog, kleine native Kampfprüfung und API-Grenzen; die explizite Zauber-Reparatur erscheint nur bei Bedarf.

**Main menu** steht in einer eigenen unteren Buttonzeile. Zusätzliche Statusmeldungen bleiben beim aktuellen Aufbau. Bei einer Integritätssperre heißt der Statusbereich **Preserved setup** und ist schreibgeschützt; Recovery, Diagnostics, gegebenenfalls Repair und Navigation bleiben erreichbar. Terrain-/Farb-/Unique-Änderungen und normale Vorbereitung sind dann gesperrt. Es wurden keine weiteren Untermenüs eingeführt und keine bisherigen Aktionen entfernt.

## Sichtbare Prüfung des aktuellen Builds

Getestet wurde Sandbox **0.1.0+editor.5** mit dem normalen separaten lokalen Extender **3.4.0**, SHA-256 `63b293fb0a694cf6a528cbf66d9aa2e561c80b38337f1fb7e40b154ba64a8bdd`. Der private Launcher wurde über die BAT tatsächlich gestartet und bestätigte das eigene Profil. Die normale Auflösung dieses Starters ist `--winres=1200*900`; zusätzlich wurde mit `1704*900` geprüft.

Die vier Abschnitte, ihre Überschriften, alle Aktionen und die untere Navigation waren bei der normalen Auflösung vollständig lesbar und sichtbar. Nach dem Kampf passten auch Ergebnisstatus und Reset in denselben Bildschirm. Load, Save, Öffnen/Bearbeiten, Inspect, Diagnostics, Rückkehr nach dem Kampf und Main menu wurden tatsächlich bedient. Normales Menü (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Menü nach Kampf mit Reset (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). Die gesperrte Variante wurde zusätzlich durch Offline-Aktions-/Navigationsverträge geprüft; kein echter Nutzerzustand wurde für ein Bildschirmfoto absichtlich beschädigt.

Der abschließende reine Standardaufruf ohne Prüfschalter bestätigte denselben finalen Sandbox-Quellhash `409c10230c2853cd68a2227c2a345d5a001e30637cd720f66240cd2465c796ed`, genau drei aktive Testmods und das vollständige Menü erneut bei normaler Auflösung. Launcher-/Quellbindung: `docs/evidence/menu-mods-2026-11-14/default-final` (lokaler Beleg; nicht veröffentlicht). Über Main menu/Quit sauber beendet.

Für die Veröffentlichung wurden Menü, Ranged und native Shellback-Karte frisch aufgenommen und die gespeicherten Dateien visuell gegengeprüft. [Neuaufnahme des Menüs bei normaler Auflösung](public-evidence/menu-mods-2026-11-14/visible-grouped-setup-default-final.png): In dieser Bildsitzung war CrabCult zusätzlich aktiv, insgesamt vier Testmods. Die Lua-Runtime ist unverändert; nach der Versions-/Beschreibungsanpassung beträgt der Mod-Dateihash `272fcca5bf2aeab186eff74cf405c8888493ea1fb4b984ca92c0799c5ab1a6c3`. Danach wurde die Standard-BAT ohne CrabCult erneut erfolgreich gestartet und das Spiel sauber beendet. Die drei Bilder belegen keine erneuten Kämpfe; die früheren Kampfresultate sind getrennte Livebeobachtungen und native Exporte.

## Aktive Mods: Implementierung und aktueller Nachweis

`Catalog.read` durchläuft den gesamten vom Spiel geladenen Monsterbestand bis `monsterLastIndex`. Die alphabetische Suche und Filter arbeiten auf diesen tatsächlichen Einträgen. Auswahl, native Zeichnung und Platzierung verwenden die geladenen IDs; es gibt keine Vanilla-ID-Grenze. Einheiten werden nicht anhand ihrer Nummer als Mod-Inhalt klassifiziert.

Für diesen Test wurde ausschließlich die bereits vorhandene private **CrabCult**-Installation verwendet. Die genaue Definition von **Shorebound Initiate** und **Abyssal Shellback** wurde in ihrer vorhandenen `CrabCult.c5m` nachgelesen und anschließend mit geladenem Namen/ID zurückgeprüft. Dateifingerprint: `4904be0f2c659075e8449f32cd3024f5429b9a24ea2aaef1b9207685bb1ba5a1`. Das ist Herkunftsnachweis für diese beiden Definitionen, keine allgemeine Herkunfts-API. Keine CrabCult-Datei wird unter `mod/` oder im Release mitgeliefert.

| Prüfung | Aktuelle Beobachtung |
|---|---|
| Suche und Liste | `aby` liefert genau Abyssal Shellback; dessen eigene Grafik erscheint maßhaltig im Treffer. Suchtreffer (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Select / Rechtsklick | Shellback ausgewählt und auf Plain hinzugefügt, Team A steigt von 1 auf 2. Native Kontextauswahl erkennt dieselbe Instanz. Platzierung (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Grafik und relevante Daten | Echte native Karte zeigt CrabCult-Grafik, 70/70 HP, Stärke 12, Moral 8, MR 5, Rüstung 5 und Crushing Pincer; das stimmt mit den gelesenen Mod-Definitionen überein. [Native Karte](public-evidence/menu-mods-2026-11-14/visible-mod-native-inspect.png). |
| Sichtbarer Kampf | Spearman + Shellback gegen Goblin, natürlich beendet: **Runde 3, Sieger A, A2 überlebt/B0**. Keine Stop-/Skip-Aktion. Bericht (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Schlussbild / Rückkehr | Shellback und Spearman erscheinen mit eigenem Sprite am erfassten Endanker; Snapshot A2/B0. Back stellt A2/B1 an den gespeicherten Positionen wieder her. Snapshot (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). |
| Native API-Matrix | Shorebound Initiate und Abyssal Shellback gegen drei Goblins: **PASS**, natürlicher Kampf Runde **4**, Sieger A, beide Mod-Akteure überleben; vollständige Schlussaufnahme, geprüfter Cleanup und exakter Wiederaufbau. |
| Mod fehlt | `qmc5.ini` gespeichert, neu ohne aktiviertes CrabCult gestartet, Load verweigert; A1/B1 bleibt unverändert. Diagnosegrund **Required active mod missing: CrabCult**, `restored=unchanged`. Die Oberfläche wurde anschließend verbessert, damit sie diesen Grund direkt im Hinweis nennt. |

Die API-Matrix und die sichtbare erste Mod-Sitzung sind an Sitzung `6f2f739f6e4743e6b2538ce851cd76ac` gebunden. Launcher und Rohresultate: `docs/evidence/menu-mods-2026-11-14/normal-6f2f739f` (lokaler Beleg; nicht veröffentlicht). Die echte Ablehnung ohne Mod ist in diagnostics-b336…-1: `docs/evidence/menu-mods-2026-11-14/diagnostics-b336a18090da41608030-1.ini` (lokaler Beleg; nicht veröffentlicht) erhalten. Fehleranzeigen und native Tests werden nicht nachträglich als ein anderer Build ausgegeben.

Der verbesserte Hinweis wurde anschließend im endgültigen Quellstand der Sitzung `54f26dddea5a440db8ffd327e9351cee` tatsächlich bedient: **Could not load scenario: Required active mod missing: CrabCult. Current setup kept.** Die zuvor geladene gültige Sechseraufstellung bleibt dabei A3/B3 mit unveränderter Unique-Option. Namentliche Meldung (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg), Aufbau danach (frühere Bilddatei nicht zuverlässig zuordenbar; kein veröffentlichter Bildbeleg). Das normale Feld war vorher verifiziert geschlossen; kein neues natives Feld oder Ersatzmonster wurde für den abgewiesenen Load erzeugt.

## Ranged und andere Filter

Der frühere vollständig leere Ranged-Filter entstand, weil `monsterHasRanged` beim Kataloglesen im Hauptmenü mit `no_game` abgewiesen wurde. Der separate Extender erlaubt nun ausschließlich diese nachgewiesen Template-lesende native Funktion dort. Lua unterscheidet `nil` von einem echten `false`; ältere Builds erhalten eine Unverfügbarkeitskennzeichnung.

Ohne CrabCult: 1851 Einträge, Ranged **714**, identische boolesche Klassifikation sämtlicher Monster vor/nach Feldöffnung. Mit CrabCult: 1879 Einträge, Ranged **721**. Sichtbar durchgeschaltet wurden All, human **443**, animal **157**, undead **198**, demonic **60**, flying **233**, ranged **721**; alle lieferten passende Listen und Sprites. [Ranged sichtbar](public-evidence/menu-mods-2026-11-14/visible-ranged-721-results.png). Die native Definition umfasst Fernkampf **und Zauberangriffe** mit ihrer nativen Rank-Regel, keinen ausschließlich physischen Reichweitenfilter.

## Grenzen und Nutzung

Der ältere CrabCult-Nachweis vom 13.11. in [TEST-RESULTS](TEST-RESULTS.md) bleibt historische Evidenz. Er wurde hier nicht als neuer Test gezählt. Aktuell geprüft sind die beiden genannten Einheiten und ihre normalen nativen Feld-/Kampfpfade. Beliebige Mod-Skripte, Fraktions-/Kampagnenmechaniken, andere Spiele-Versionen oder jede mögliche Mod-Kombination sind nicht pauschal unterstützt. Die native Simulation entscheidet weiterhin über Gelände, Footprints und Fähigkeiten. Eine zuverlässige Kategorie „Modded Units“ bleibt mangels Herkunftsmetadaten offen.

Szenarien verlangen vorsichtshalber sämtliche beim Speichern aktiven Mods. Zusätzlich werden Einheitennamen/-IDs sowie unterstützte Spell-/Itemdaten geprüft. Gleiche Namen und IDs mit nachträglich verändertem Inhalt sind keine vollständigen Inhaltsfingerprints. Fehlende Mods ersetzen keine Einheiten und ändern nicht stillschweigend die Aufstellung.

Für den vorhandenen lokalen Testbestand: `SandboxOfElysium-Testen.bat -CrabCult`. Der Schalter nutzt nur `private/lab/profile/mods/CrabCult`, überprüft vorhandene abweichende Ziel-Dateien und aktiviert die Kopie ausschließlich im isolierten Profil. Ein normaler BAT-Start aktiviert die drei normalen Sandbox-Testmods; vorhandene CrabCult-Dateien und alle Szenarien bleiben erhalten. Kein Download, keine Weitergabe, keine Aktualisierung der regulären Spielinstallation und kein PR/Kontakt.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
