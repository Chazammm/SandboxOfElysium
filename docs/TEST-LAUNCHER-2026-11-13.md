# Lokaler BAT-Teststarter — 2026-11-13

**Späterer Editor-Stand:** Derselbe Starter wurde mit dem getrennten lokalen Editor-Extender erneut über die BAT gestartet, inklusive frischer Profilbestätigung, sichtbarem Sandbox-Eintrag, Plain-Kampf und Diagnoseexport. Aktueller Build, Nachweise und Grenzen stehen im [Editor-Testbericht](TEST-EDITOR-2026-11-13.md). Die folgenden Hashes/Tabellen dokumentieren den vorangegangenen Terrain-/Starter-Stand.

Datei: `SandboxOfElysium-Testen.bat` im Projektstamm. Lokaler Entwicklungsstarter, keine Installation und keine Veröffentlichung. Vorhandene ungesicherte Sandbox- und Extender-Änderungen wurden beibehalten.

## Ablauf und Isolation

Die BAT ruft die Windows-PowerShell mit `tools/test-development.ps1` auf. Die Ausführungsrichtlinie gilt nur für diesen Prozess. Der Starter prüft zuerst Dateien, die beiden vorhandenen Lab-Konfigurationen, exakte Profil-/Datenpfade, Junctions/Symlinks, den bekannten Spiel-Build und bereits laufende Prozesse dieser Testkopie. Das Zielprofil ist fest `private/terrain-lab/profile`; eine abweichende Identitätsdatei wird vor Vorbereitung oder Start abgelehnt.

Der Extender bleibt im separaten Checkout. `tools/build-upstream.ps1 -OutputDirectory ...` baut ausschließlich in einen privaten Ausgabeordner. Ein Manifest enthält den Hash der tatsächlichen Quelldateien, Ressourcen, Build-Skripts und Compiler sowie aller verwendeten Extender-Dateien. Ein geänderter oder unvollständiger Stand löst einen Build aus. Der normale Aufruf übergibt keine Fault-Injection-Flags. Fehlgeschlagene Builds werden nicht gestartet; nur der vorhandene, anhand des Plugin-Hashes bekannte 3.3.0-Ersatz ist als Plain-Fallback zugelassen.

`tools/prepare-terrain-lab.py --launcher-nonce ...` übernimmt die aktuellen Sandbox-Dateien ohne Löschoperation. Zusätzliche alte Dateien im Ziel-Mod führen zum Abbruch. Der Starter vergleicht danach die kopierten Sandbox-Dateien byteweise über Hashes. Im privaten Profil werden nur CoE5SE, SandboxOfElysium und ein kleiner eigener Startprüf-Mod aktiviert. Der frühere TerrainProbe bleibt vorhanden, ist dabei deaktiviert und startet keine automatischen Kämpfe.

`tools/launch-terrain-lab.ps1` setzt `COE5_SAVE` und `COE5_DATA` ausdrücklich am neuen Spielprozess und startet die private EXE. Der Startprüf-Mod liest eine neue zufällige Kennung aus seinem privaten Datenordner und schreibt die Antwort durch die tatsächliche CoE5SE-Datei-API dorthin zurück. Erst die neue passende Antwort unter dem erwarteten Profil und der Sandbox-Ladeeintrag im aktuellen Spielprotokoll bestätigen den Start. Ohne Bestätigung wird nach spätestens 45 Sekunden nur der gerade gestartete Testprozess beendet. Vorhandene Antworten früherer Starts genügen nicht.

Die Laufzeitprüfung liest `testFieldTerrains()` sowie die geladenen Namen Plain/Forest. Sie öffnet keine Felder und simuliert keine Kämpfe. Deshalb unterscheidet die Konsole eine API-Rückmeldung ausdrücklich von einem neuen Kampffunktionstest. Der unten dokumentierte sichtbare Kampf ist ein eigener Test.

## Tatsächlich geprüft

| Prüfung | Ergebnis / Nachweis |
|---|---|
| Syntax | Alle drei PowerShell-Skripte geparst; Python-Vorbereitung geparst; ausgelieferte Lua-Dateien einschließlich Startprüf-Mod geparst |
| BAT und Pfade | Echter Aufruf der BAT über `cmd.exe`, auch aus einem anderen Arbeitsordner; `-CheckOnly` beendet ohne Build, Synchronisierung oder Spielstart |
| Neubau | Erster BAT-Start baute den aktuellen experimentellen Quellstand erfolgreich in einen neuen privaten Ordner |
| Build-Wiederverwendung | Zweiter BAT-Start meldete einen passenden vorhandenen Build und erzeugte eine neue erfolgreiche Profilantwort |
| Aktuelle Sandbox | Alle aktuellen Mod-Dateien wurden kopiert und ihre Hashes vor dem Start verglichen |
| Profilumleitung | Drei echte Prozesse lieferten unterschiedliche passende Startkennungen im privaten Profil; kein alter Status wurde akzeptiert |
| Sichtbares Spiel | Spielhauptmenü und Sandbox-Eintrag erschienen; Sandbox geöffnet |
| Geländeauswahl | Plain → Forest → Plain über den sichtbaren Battlefield-Eintrag gewechselt |
| Forest-Vorbereitung | Den tatsächlichen Button „Prepare with native deployment“ angeklickt; Editor mit beiden Einheiten geöffnet; native Ansicht zeigte grüne Waldvegetation |
| Testkampf | Über „Start battle“ echter Spearman-gegen-Goblin-Kampf; Bericht: Team A gewinnt, letzte Runde 3, Spearman überlebt, Goblin fällt; erzeugter Bericht: `docs/evidence/launcher-2026-11-13/forest-battle.ini` (lokaler Beleg; nicht veröffentlicht) |
| Plain-Vorbereitung | Danach Plain ausgewählt, erneut nativ vorbereitet und im nativen Bild als Grasfeld mit wenigen Objekten geprüft; kein weiterer Plain-Kampf in dieser Starter-Sitzung |
| Falsches Profil | In der privaten Identitätsdatei vorübergehend ein anderes Profil eingetragen: BAT brach vor jeder Vorbereitung mit „Unsicherer Profilpfad“ und Exitcode 1 ab. Originalbytes im `finally` wiederhergestellt; normales Profil wurde nicht benutzt |
| Fehlendes Hilfsskript | Unveränderte BAT in einem privaten Test-Unterordner ohne `tools`: verständliche deutsche Fehlermeldung, Exitcode 1 |
| Fehlerfenster | Fehlender-Helfer-Fall zusätzlich in interaktiver Konsole: „Drücken Sie eine beliebige Taste ...“ blieb stehen; erst gesendeter Tastendruck beendete den Prozess |
| Doppelstart | Während die zweite Testkopie lief: neuer BAT-Aufruf verweigerte den Start mit „Diese isolierte Testkopie laeuft bereits“ |
| Normales Beenden | Erster und letzter Start mit wartender BAT: Spiel über Fensterkreuz beendet, Spiel-/Starter-Rückkehr erfolgreich; finaler BAT-Exitcode 0. Zweite kurze Cache-Sitzung gezielt anhand ihrer eigenen PID beendet |
| Reguläre Dateien | Hashes des normalen `coe5config`, des regulär installierten Extender-Plugins und der installierten CoE5.exe vor/nach den tatsächlichen Teststarts unverändert |

Spiel: **CoE5 5.43 / Steam-Build 26458448**. Verifizierter Basiscommit des Extenders: **d96f2b784e97e115022a2598da2c821dd9520135**, lokale Terrain-Änderungen, DLL-Metadaten **3.4.0**. Der neue Build ergab erneut Plugin-SHA256 `6b858c285c78a66985314b622df8b34f73b510d2de318804e0433f3dfff98bf7`. Spiel-SHA256 `489d0b82fa790ec36e69a23e2335d0c2048fa57f4051fe8159c64f2d33508e55`.

Damit ist auch der im früheren [Geländebericht](TERRAIN-EXPERIMENT-2026-11-13.md) noch offene sichtbare Button-bis-Editor-Durchlauf jetzt nachgeholt. Dort dokumentierte Grenzen der Gelände-API gelten weiter.

## Grenzen

- Der Fallback nach tatsächlich absichtlich erzeugtem Compilerfehler sowie ein Start ganz ohne experimentellen Checkout wurden in dieser Sitzung nicht vollständig im Spiel durchgespielt. Der vorhandene Ersatz stammt aus den früheren echten 3.3.0-Tests; sein Plugin-Hash wird geprüft.
- Kein absichtlich ignoriertes `COE5_SAVE`, Prozessabsturz, 45-Sekunden-Timeout oder Junction-Angriff wurde im laufenden Spiel erzwungen. Der falsche Profilpfad wurde tatsächlich abgefangen; weitere Pfad-/Timeout-Abbrüche wurden im Code geprüft, jedoch nicht als native Fehlerexperimente ausgeführt.
- Der Spielprozess gab beim Schließen der wartenden privaten Sitzungen `Steam init failed` auf stdout aus. Menü, native Felder und Offline-Kampf funktionierten; der finale Starter meldete Exitcode 0. Steam-Online-/Cloud-Funktionen wurden nicht getestet.
- Für unbekannte Spiel-EXE-Hashes bricht der Starter ab, statt eine unbestätigte Profilumleitung zu behaupten. Keine allgemeine Freigabe für weitere Spielversionen.
- Normale Spielstände wurden nicht geladen oder bearbeitet. Es wurde nichts gelöscht, kein Git-Stand verworfen, kein PR angelegt und keine Binärdatei veröffentlicht.

Private Build-Manifeste, vollständige Startantworten, Kennungen und lokale Protokolle bleiben unter `private/terrain-lab`; im Projekt-Nachweis liegen nur eigene Testausgaben. Die BAT und Hilfsskripte enthalten keine Extender-Binärdateien und ändern die Veröffentlichungs-Allowlist nicht.

Veröffentlichungshinweis: [Bereinigte Testzusammenfassung und drei frisch geprüfte Bildschirmaufnahmen](public-evidence/README.md). Frühere Bilddateien waren ihren Dateinamen nicht zuverlässig zuordenbar und dienen nicht als Bildnachweis. Livebeobachtungen und numerische native Exporte werden getrennt davon bewertet. Rohdiagnosen bleiben lokal.
