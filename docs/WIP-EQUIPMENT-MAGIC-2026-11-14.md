# Ausrüstung und Magiestufen — laufende Entwicklung

**Abschlussstand 15.11.2026: editor.6 ist lokal umgesetzt und geprüft.** Maßgeblich sind [der aktuelle Testbericht mit Build-/Sitzungsbindung und Grenzen](TEST-LOADOUT-2026-11-15.md), die README und die separate `SANDBOX_LOADOUT_EXPERIMENT.md`. Die Abschnitte darunter sind erhaltene historische Arbeitsnotizen vom Beginn der Untersuchung; ihre damaligen offenen Tests/Beschränkungen sind keine aktuelle Funktionsliste.

Ausgangspunkt: Sandbox `11c572a`, separater Extender `d96f2b7` mit erhaltenen lokalen Patches. Sicherung von Quellen und sämtlichen vorhandenen Sandbox-Profildaten: privater Pfad in `private/equipment-baseline-path.txt`. Keine Veröffentlichung oder PR beauftragt.

## Bestätigte Quellenbefunde

- Upstream 3.4.0 besitzt in `item_slots.h` / `item_slot_hooks.h` bereits 20 Positionen, monster-/einheitsabhängige Slottypen und native Augen-/Herzprüfungen. Die bisherige Sandbox verwendet nur acht Positionen und Namen, was für mehrfache Slots und doppelte Namen nicht ausreicht.
- Native CoE5 5.43 (`489d0b82…`) speichert die Basismagiestufen in den Zauberangriffszeilen der Monstervorlage. `unitSpellWeaponLevel` liest deren Maximum, `unitPathLevel` addiert den getrennten nativen Bonus. Ein direktes Schreiben der Vorlage würde andere Instanzen verändern und ist ungeeignet.
- Native Kampfaktionen lesen den Zauberangriff durch `UNIT_ATTACK_ROW`, während Karten und Limits `UNIT_PATH_LEVEL` verwenden. Ein möglicher eigener Instanzzustand muss alle relevanten Leser konsistent bedienen und an Testfeldbesitz, Generation und Monsteridentität gebunden sein. Dieser Ansatz ist noch nicht als funktionierend getestet.
- Native Equip-Effekte verändern bei Augen-/Herzimplantaten bleibende Anatomie-/Verletzungsflags. Solche neuen Implantate werden zunächst ausdrücklich abgelehnt, solange deren vollständige Rücknahme nicht verifiziert ist. Normale Slotzuordnung und native Kompatibilität sind davon zu unterscheiden.

## Geplante sichere Umsetzung (noch keine Abnahme)

Atomarer Testfeld-Konfigurationsvertrag für Positions-/Item-ID-Paare, vorhandene Basisschulen, bekannte und memorierte Zauber; native Rückleseprüfung und überprüfter Rollback. Normale Kampagnen bleiben außerhalb des Besitzbereichs. Itemersetzung muss ausdrücklich bestätigt werden, verfluchte Items bleiben geschützt. Alte Szenarien werden erhalten und vorsichtig migriert; neue Konfigurationen benötigen eindeutige Item-IDs mit Namen und Slotposition sowie Schul-IDs mit Namen.

## Erster echter Nachweis — 15.11.2026, noch keine vollständige Abnahme

Nach einem abgewiesenen ersten Hook-Aufbau und einem eingegrenzten Nullzeigerfehler bei der Item-Vorprüfung wurde der native Einstieg korrigiert. Die isolierten Fehlversuche bleiben privat erhalten und werden nicht als PASS gezählt. Kein normaler Spielprozess wurde verwendet.

DLL `084066b4…`, Sitzung `f76d96ac…`: `vertical_item_school_native_readback` besteht im echten Spiel. Druid's Apprentice #594, Druidism #39: Basis 1→2, Bonus 0, effektive Stufe 2, Kapazität 3; Item #214 an Position 6 (Oberfläche: Position 7). Vollständiges Schließen und Wiederaufbauen aus Schema 2 erhält diese Konfiguration.

Anschließend tatsächlich sichtbar über Rechtsklick → Edit bedient: Items, anatomische Positionen, Misc-Filter, Namenssuche `am` (13 Treffer), Auswahl von Amulet of Anti Magic #153, Position 7 und ausdrückliche Bestätigung. Magiemenü: Basis 1→2, Lernen von Briar Cage #350 Stufe 2 ohne automatische Memorierung, dann ausdrückliche Memorierung als dritter Zauber. Die beiden ursprünglichen Zauber Befriend Animal #344 und Vine Arrow #347 bleiben erhalten. Die echte native Karte zeigt Druidism level 2 und 3/3 memorierte Zauber. Rechtsklick auf den belegten nativen Ausrüstungsslot öffnet die echte Itemkarte „Amulet of Anti Magic“, MR +3; die Einheit zeigt MR 11. Inspect anschließend unverändert geschlossen, Diagnosen exportiert und über Main menu/Quit beendet.

Private Belege: `private/equipment-runs/vertical-0840/` und fünf frisch gespeicherte Ansichten unter `private/equipment-ui-captures/`. Ein altes, nicht zuordenbares Bildschirmfoto wird nicht als Nachweis benutzt. Bisherige 97 Offline-Fälle und neun neue Identitäts-/Persistenzfälle bestehen. Ausstehend: vollständige native Fehler-/Mod-/Kampf-/Reset-/Rematch-Matrix und abschließende Abnahme des endgültigen Quellenstands.
