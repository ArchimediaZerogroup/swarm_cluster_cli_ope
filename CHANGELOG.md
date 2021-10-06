## Changelog

# 0.7
- riconoscimento delle immagini durante rsync per installare correttamente pacchetto, 
  viene riconosciuto ubuntu ed alpine

# 0.6
- sync con MongoDB

# 0.5.6
- correzione parsing variabili ambiente con '=='

# 0.5.5
- correzione utilizzo e configurazione variabili ambiente nelle configurazioni.
- controllo di non installare rsync e killall nel caso siano già presenti.

# 0.5.4
- bug permessi sul file password dell'rsync

# 0.5.3
- bug selezione pod, ora filtra solamente per i containers che sono attivi 

# 0.4
- implementazione push pull con il comando **stacksync** di pg
- controllo di versione sul file caricato rispeto a gemma, con conseguente warning 

# 0.3
- implementazione push pull con il comando **stacksync** di mysql

# 0.2
- implementazione comando **stacksync** con configurazioni nello stack per eseguire rsync di files e dump di sqlite3

# 0.1.0
- rsync dei files da/verso cluster su cartella condivisa
- copia files direttamente in container
- shell in servizio
- mc in servizio
- configurazioni globali
- configurazioni di progetto
