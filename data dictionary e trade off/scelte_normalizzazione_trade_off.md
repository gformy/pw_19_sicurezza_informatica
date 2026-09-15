# Scelte di normalizzazione e trade-off

Schema DB NIS2/ACN — completa `data_dictionary.md` con la motivazione delle
decisioni di modellazione prese, le alternative valutate e scartate, e i
compromessi accettati consapevolmente. Fa riferimento ai pattern già
introdotti nelle convenzioni del data dictionary (Pattern A/B, ISA,
Opzione B).

---

## 1. Normalizzazione applicata

Lo schema è stato portato alla terza forma normale, verificata ad ogni
passaggio della ristrutturazione, non dichiarata a posteriori.

**Prima forma normale** — eliminazione di ogni attributo multivalore
prima ancora di tradurre lo schema in tabelle. I codici CPV di un
fornitore, potendo essere più di uno per lo stesso fornitore, non sono
stati modellati come attributo ripetuto ma spostati in `CodiceCPV`,
collegata tramite la tabella ponte `FornitoreCPV`; lo stesso vale per gli
Stati membri in cui un servizio è offerto (`ServizioStatoMembro`).

**Seconda forma normale** — verificata sulle tabelle a chiave composta.
Negli attributi propri di `Dipendenza` (criterio di rilevanza, tipologia
di fornitura), la dipendenza funzionale è sempre dall'intera coppia
fornitore–elemento critico, mai da una sola delle due componenti.

**Terza forma normale** — evitata ogni dipendenza transitiva tra
attributi non chiave. Esempio: `Fornitore` non memorizza dati derivabili
dal Paese della sede legale (che introdurrebbe una dipendenza transitiva
via `paese_sede_legale`); i dati anagrafici del soggetto NIS non sono
ripetuti in nessuna tabella che vi fa riferimento, solo referenziati
tramite `soggetto_nis_id`.

---

## 2. Trade-off 1 — Applicabilità normativa differenziata (essenziale/importante)

**Problema**: misure di sicurezza, documenti di governance e tipi di
incidente si applicano in modo differenziato ai soggetti essenziali e
importanti (es. Allegato 2 ha 43 misure/116 requisiti contro i 37/87
dell'Allegato 1; il codice incidente IS-4 è previsto solo per gli
essenziali).

**Alternative valutate**:
| Opzione | Descrizione | Motivo di scarto |
| Colonne booleane ripetute | `applicabile_essenziali`, `applicabile_importanti` su ogni entità | Duplicazione strutturale dello stesso concetto su più tabelle |
| Associazione polimorfica | Tabella `Applicabilita` con `entita_tipo` testuale + `entita_id` generico | `entita_id` non è una FK verificabile: nulla impedisce riferimenti a record inesistenti |

**Scelta adottata**: lookup unica `TipoSoggettoNIS` (2 righe) + tabella
ponte dedicata per ciascuna entità classificabile (`MisuraApplicabilita`,
`DocumentoGovernanceApplicabilita`, `IncidenteApplicabilita`), ciascuna
con FK vere su entrambi i lati.

**Trade-off accettato**: tre tabelle invece di una, ma ciascuna minima
(due sole FK) e con integrità verificata dal motore relazionale, non
dalla sola logica applicativa. Giustificato dal fatto che il dominio
delle entità classificabili è chiuso e noto a priori — non cresce nel
tempo — quindi il vantaggio di flessibilità di un registro polimorfico
non si materializza, mentre il suo costo (perdita di FK verificabile)
resta intero.

---

## 3. Trade-off 2 — Generalizzazione Asset/Servizio (ElementoCritico)

**Problema**: un fornitore può rendere il soggetto NIS dipendente sia da
un asset sia da un servizio. Collegarli a `Dipendenza` con due FK
separate avrebbe richiesto un vincolo di esclusione reciproca (una sola
delle due valorizzata) e non avrebbe scalato in presenza di un terzo tipo
di elemento dipendente.

**Alternative valutate**:
| Opzione | Descrizione | Motivo di scarto |
|---|---|---|
| Due FK nullable su `Dipendenza` | `asset_id`, `servizio_id`, con CHECK di esclusione reciproca | Vincolo aggiuntivo da mantenere, non scala oltre due tipi |
| Generalizzazione ISA (adottata) | `ElementoCritico` come superclasse, chiave primaria condivisa | — |

**Scelta adottata**: `Asset` e `Servizio` come sottoclassi di
`ElementoCritico` tramite class-table inheritance a chiave condivisa
(sequenza `seq_elemento_critico`).

**Criterio di scelta, generalizzabile**: la generalizzazione ISA è
giustificata solo quando i tipi coinvolti condividono una natura
semantica reale nel dominio — qui, "cose da cui il soggetto NIS può
dipendere da un fornitore esterno" — non come mero espediente tecnico.
È lo stesso criterio che ha escluso la stessa soluzione per il caso di
§2 (Applicabilità), dove i tipi (misure, documenti, incidenti) sono
semanticamente slegati tra loro.

**Trade-off accettato**: costo implementativo concreto, perché Oracle
(come PostgreSQL) non supporta nativamente questo tipo di ereditarietà
tra tabelle. Servono: una sequenza condivisa, due viste aggiornabili
(`AssetCompleto`, `ServizioCompleto`) con trigger `INSTEAD OF INSERT`, e
il blocco del `DELETE` fisico su tutte e tre le tabelle coinvolte.
Beneficio: ogni relazione verso un elemento critico, ovunque nello
schema (`Dipendenza`, `IncidenteElementoCritico`,
`DocumentoGovernanceElementoCritico`), usa un'unica colonna di FK invece
di due.

---

## 4. Trade-off 3 — Due pattern di storicizzazione distinti

**Problema**: alcuni dati cambiano raramente e solo per atto ufficiale
esterno (es. una nuova Determinazione ACN); altri cambiano con frequenza
imprevedibile per iniziativa interna dell'azienda. Un unico meccanismo
uniforme di storicizzazione non è adatto a entrambi i casi.

| Pattern | Applicato a | Meccanismo |
|---|---|---|
| **A — validità semplice** | `RequisitoMisura`, `MisuraSicurezza`, `TipoIncidente`, `TipoDocumentoGovernance`, `CategoriaIncidente` | Nuova riga alla revisione, nessun trigger: il cambiamento è un atto deliberato, mai un effetto collaterale automatico |
| **B — storicizzazione piena** | `SoggettoNIS`, `Fornitore`, `ElementoCritico`, `DocumentoGovernance`, `StatoAdempimentoRequisito`, `AccordoCondivisioneInformazioni`, `Dipendenza`, `AssetServizio`, `DocumentoGovernanceElementoCritico` | Tabella `*Storico` gemella, popolata da trigger `BEFORE UPDATE` automatico e incondizionato |

**Motivazione della dualità**: la struttura tecnica rispecchia la
struttura giuridica della fonte del cambiamento. Per i dati normativi, un
meccanismo automatico sarebbe concettualmente sbagliato, non solo
superfluo — un cambiamento normativo non dovrebbe mai poter avvenire come
effetto collaterale silenzioso di un `UPDATE` qualunque. Per i dati
operativi, l'automatismo incondizionato è invece necessario: affidarsi
alla disciplina di chi esegue l'`UPDATE` per ricordarsi di storicizzare
manualmente introdurrebbe un rischio di omissione che il meccanismo
automatico elimina strutturalmente.

**Trade-off accettato**: la compresenza di due meccanismi aumenta il
carico cognitivo per chi manterrà lo schema in futuro, che deve
riconoscere quale pattern si applica a quale tabella. Mitigato dalla
distinzione esplicita nelle convenzioni del data dictionary.

**Nota tecnica di conversione**: in Oracle il confronto tra valori
vecchi e nuovi nei trigger di storicizzazione richiede
`SELECT DECODE(...) INTO v_cambiato FROM DUAL` seguito da
`IF v_cambiato > 0`, perché `DECODE` è una funzione SQL non utilizzabile
direttamente in una condizione `IF` di puro PL/SQL (vedi
`readme/ERRORI_RISOLTI.md`).

---

## 5. Trade-off 4 — Registro di audit a riferimento debole

**Decisione**: `LogEstrazione` referenzia il record d'origine tramite
`registro_tabella_id` (FK vera verso `RegistroTabelle`) e `record_id`
(riferimento debole, non FK).

**Motivazione**: un log di audit deve poter sopravvivere anche a una
modifica o rimozione del dato che descrive — un vincolo di integrità
rigido lo impedirebbe. È lo stesso pattern "a registro" scartato per il
caso di §2, ma qui è la scelta corretta: la differenza sta nel ruolo che
l'entità gioca nel dominio, non nel pattern tecnico in sé stesso, che può
essere adatto o inadatto a seconda del contesto.

---

## 6. Trade-off 5 — Nessuna distinzione tra attestazione automatica e manuale

**Problema iniziale considerato**: distinguere i requisiti di sicurezza
verificabili "in automatico" dai dati già presenti nello schema (es.
dedurre l'adempimento dell'inventario fornitori dalla sola esistenza di
righe in `Fornitore`) da quelli verificabili solo manualmente.

**Decisione finale**: nessuna distinzione. `StatoAdempimentoRequisito`
tratta ogni attestazione allo stesso modo — una dichiarazione esplicita,
con responsabile e data, con un'evidenza opzionale collegata tramite FK
diretta a `DocumentoGovernance`.

**Motivazione**: molti requisiti restano di natura procedurale e non
deducibile dai soli dati. Un'eventuale automazione di alcuni controlli
resta possibile in un secondo momento come livello di reportistica
opzionale (es. una vista che confronta lo stato dichiarato con il
conteggio di righe correlate), senza che questo comprometta la coerenza
del modello dichiarativo di base.

**Granularità scelta**: l'attestazione è registrata a livello di singolo
requisito numerato (`RequisitoMisura`), non della misura nel suo
complesso (`MisuraSicurezza`), perché una stessa misura può contenere
più requisiti e un'azienda può averne attuati solo alcuni.

---

## 7. Confini di scope esplicitamente motivati

Decisioni di esclusione, non di modellazione — incluse per completezza
della documentazione.

- **Classificazione del dato secondo ISO/IEC 27001:2022 (controllo
  A.5.12)**: valutata e scartata. Non deriva da alcuna fonte del corpus
  documentale del progetto (D.Lgs. 138/2024, Allegati ACN) — sarebbe
  stata un'estensione esterna allo scope della traccia.
- **`SedeUE`, `RappresentanteNIS`** (art. 7 c.5, art. 5 c.1 lett. b
  D.Lgs. 138/2024): escluse perché applicabili solo a sottoinsiemi
  specifici di soggetti NIS, non alla generalità — scope ridotto
  rispetto al nucleo "asset, servizi, dipendenze, responsabilità"
  indicato dalla traccia.

---

## 8. Limiti riconosciuti (non risolti nello schema attuale)

- I trigger concentrano logica applicativa importante dentro il
  database, non visibile a chi legge solo il livello applicativo — una
  scelta corretta per garantire l'incondizionalità del Pattern B, ma con
  un costo reale di manutenibilità.
- Le tabelle `*Storico` e `LogEstrazione`, pensate per non cancellare mai
  nulla, sono in tensione con gli obblighi di cancellazione e
  limitazione della conservazione dei dati personali (GDPR), dato che
  alcune tabelle coinvolte (`PersonaleGovernance`, `PuntoDiContatto`,
  `OrganoAmministrazione`) contengono nomi di persone fisiche.
- Manca una distinzione esplicita tra il soggetto NIS a cui un elemento
  critico appartiene e la persona fisica internamente responsabile della
  sua gestione (prassi ISO/IEC 27001 controllo A.5.9) — non inclusa per
  restare aderenti alle fonti normative dirette del progetto.
