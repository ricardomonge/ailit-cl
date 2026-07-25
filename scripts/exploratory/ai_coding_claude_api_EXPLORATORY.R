# =============================================================================
# ai_coding_claude_api_EXPLORATORY.R
#
# *** IMPORTANT NOTE ***
# This script was an EXPLORATORY test of deductive coding using the Claude
# (Anthropic) API. It is NOT the method reported in the published manuscript:
# the final qualitative coding was performed with Llama 3.1 8B Instruct run
# LOCALLY (script not included in this repository).
# It is kept here only for transparency and as a record of an alternative
# approach evaluated during the development of the project.
#
# Run ONCE to code the responses via the Claude API.
# Saves: resultados_codificacion_api.xlsx
# =============================================================================

library(httr)
library(jsonlite)
library(openxlsx)

# --- API KEY -----------------------------------------------------------------
# NEVER hardcode the key in the script or push it to a repository.
# Define the ANTHROPIC_KEY environment variable (e.g. in your local .Renviron,
# which must be listed in .gitignore) and this script will read it from there.
CLAUDE_API_KEY <- Sys.getenv("ANTHROPIC_KEY")
if (identical(CLAUDE_API_KEY, "")) {
  stop("Missing environment variable ANTHROPIC_KEY. Set it before running this script, ",
       "e.g. with Sys.setenv(ANTHROPIC_KEY = 'your-key') in the R console, ",
       "or in a .Renviron file (not version-controlled).")
}

# --- DATA --------------------------------------------------------------------
datos_raw <- read.csv("data/dataframe.csv",
                      stringsAsFactors = FALSE,
                      fileEncoding     = "UTF-8",
                      sep              = ";")

datos_txt <- datos_raw[datos_raw$Consentimiento %in% c("Si", "Si"), ]
datos_txt <- datos_txt[!is.na(datos_txt$experiencia) &
                         nchar(trimws(datos_txt$experiencia)) > 10, ]
datos_txt$id_respuesta <- seq_len(nrow(datos_txt))

cat(sprintf("Responses to code: %d\n", nrow(datos_txt)))

# --- CODING SCHEME (prompt) ---------------------------------------------------
# NOTE: left in Spanish on purpose — this is the actual prompt used to code the
# Spanish-language open-ended survey responses. Translating it would not reflect
# what was actually run.
CODING_SCHEME <- "
Eres un asistente de investigacion especializado en analisis cualitativo de
respuestas abiertas sobre uso de inteligencia artificial en contextos educativos.

Tu tarea es codificar la siguiente respuesta de un estudiante universitario
chileno segun el esquema deductivo indicado. La respuesta fue dada a esta
pregunta: Podrias describir una situacion en la que hayas utilizado ChatGPT
para un proposito academico o profesional y reflexionar sobre los beneficios,
limitaciones y consideraciones eticas que enfrentaste?

CATEGORIAS DE CODIFICACION (basadas en el marco de AI Literacy de Han & Zhang, 2025):

BENEFICIOS mencionados:
  B1 - Apoyo en redaccion/estructura de textos academicos
  B2 - Sintesis y comprension de informacion compleja
  B3 - Resolucion de problemas o tareas especificas
  B4 - Eficiencia y ahorro de tiempo
  B5 - Aprendizaje y comprension de conceptos
  B6 - Otros beneficios

LIMITACIONES mencionadas:
  L1 - Informacion inexacta o desactualizada
  L2 - Dependencia excesiva o sustitucion del pensamiento propio
  L3 - Falta de profundidad o especificidad
  L4 - Dificultad para verificar la informacion
  L5 - Otras limitaciones

CONSIDERACIONES ETICAS mencionadas:
  E1 - Preocupacion por plagio o integridad academica
  E2 - Uso responsable y transparencia
  E3 - Privacidad o datos personales
  E4 - Reconoce reflexion etica sin especificar
  E5 - No menciona aspectos eticos

DECISION DE USO:
  D1 - Usa IA con criterio propio (uso reflexivo)
  D2 - Usa IA sin reflexion critica (uso instrumental)
  D3 - Limita o evita el uso por preocupaciones eticas
  D4 - Actitud ambivalente hacia el uso

RESPUESTA A CODIFICAR:
{RESPONSE}

INSTRUCCIONES:
- Asigna TODAS las categorias que apliquen (puede ser mas de una por bloque)
- Si una categoria no aplica, no la incluyas
- Responde SOLO con JSON valido, sin texto adicional
- Formato exacto requerido:

{
  \"benefits\": [\"B1\", \"B4\"],
  \"limitations\": [\"L2\"],
  \"ethics\": [\"E1\"],
  \"decision\": [\"D1\"],
  \"confidence\": 0.85,
  \"notes\": \"breve nota si hay ambiguedad\"
}

Si la respuesta es muy corta, irrelevante o incomprensible, devuelve:
{\"error\": \"respuesta_insuficiente\"}
"

# --- API FUNCTION --------------------------------------------------------------
call_claude <- function(text, api_key, model = "claude-sonnet-4-20250514",
                        max_retries = 3) {
  prompt <- gsub("{RESPONSE}", text, CODING_SCHEME, fixed = TRUE)
  for (attempt in 1:max_retries) {
    Sys.sleep(0.5)
    resp <- tryCatch(
      POST(url = "https://api.anthropic.com/v1/messages",
           add_headers("x-api-key" = api_key,
                       "anthropic-version" = "2023-06-01",
                       "content-type" = "application/json"),
           body = toJSON(list(model = model, max_tokens = 500,
                              messages = list(list(role = "user",
                                                   content = prompt))),
                         auto_unbox = TRUE),
           encode = "raw"),
      error = function(e) NULL)
    if (is.null(resp)) next
    if (status_code(resp) == 200) {
      txt <- content(resp, "parsed")$content[[1]]$text
      txt <- trimws(gsub("```json|```", "", txt))
      res <- tryCatch(fromJSON(txt), error = function(e) NULL)
      if (!is.null(res)) return(res)
    } else if (status_code(resp) == 429) {
      cat(sprintf("  Rate limit - waiting 30s (attempt %d)...\n", attempt))
      Sys.sleep(30)
    } else {
      cat(sprintf("  API error %d (attempt %d)\n", status_code(resp), attempt))
      Sys.sleep(5)
    }
  }
  list(error = "api_failure")
}

# --- CODING ----------------------------------------------------------------
cat(sprintf("Starting coding of %d responses...\n", nrow(datos_txt)))
all_cats <- c("B1","B2","B3","B4","B5","B6",
              "L1","L2","L3","L4","L5",
              "E1","E2","E3","E4","E5",
              "D1","D2","D3","D4")

filas <- list()
for (i in seq_len(nrow(datos_txt))) {
  if (i %% 50 == 0) cat(sprintf("  %d / %d...\n", i, nrow(datos_txt)))
  r   <- call_claude(datos_txt$experiencia[i], CLAUDE_API_KEY)
  err <- if (!is.null(r$error)) r$error else ""
  ben <- if (!is.null(r$benefits))    as.character(unlist(r$benefits))    else character(0)
  lim <- if (!is.null(r$limitations)) as.character(unlist(r$limitations)) else character(0)
  eth <- if (!is.null(r$ethics))      as.character(unlist(r$ethics))      else character(0)
  dec <- if (!is.null(r$decision))    as.character(unlist(r$decision))    else character(0)
  filas[[i]] <- data.frame(
    id_respuesta = datos_txt$id_respuesta[i],
    texto        = datos_txt$experiencia[i],
    error        = err,
    B1=as.integer("B1"%in%ben), B2=as.integer("B2"%in%ben),
    B3=as.integer("B3"%in%ben), B4=as.integer("B4"%in%ben),
    B5=as.integer("B5"%in%ben), B6=as.integer("B6"%in%ben),
    L1=as.integer("L1"%in%lim), L2=as.integer("L2"%in%lim),
    L3=as.integer("L3"%in%lim), L4=as.integer("L4"%in%lim),
    L5=as.integer("L5"%in%lim),
    E1=as.integer("E1"%in%eth), E2=as.integer("E2"%in%eth),
    E3=as.integer("E3"%in%eth), E4=as.integer("E4"%in%eth),
    E5=as.integer("E5"%in%eth),
    D1=as.integer("D1"%in%dec), D2=as.integer("D2"%in%dec),
    D3=as.integer("D3"%in%dec), D4=as.integer("D4"%in%dec),
    confianza = if (!is.null(r$confidence)) as.numeric(r$confidence) else NA,
    notas     = if (!is.null(r$notes))     as.character(r$notes)    else "",
    stringsAsFactors = FALSE
  )
}

codificaciones <- do.call(rbind, filas)
cat(sprintf("Successful: %d | Errors: %d\n",
            sum(codificaciones$error == ""),
            sum(codificaciones$error != "")))

# --- IRR EXCEL EXPORT ------------------------------------------------------------
valid_codes <- codificaciones[codificaciones$error == "", ]
n_valid     <- nrow(valid_codes)
set.seed(2024)
n_irr       <- max(20, round(n_valid * 0.20))
idx_irr     <- sample(seq_len(n_valid), n_irr)
muestra_irr <- valid_codes[idx_irr, ]

irr_export  <- muestra_irr[, c("id_respuesta","texto",all_cats,"confianza","notas")]
for (cat in all_cats) irr_export[[paste0("humano_", cat)]] <- NA_integer_

code_dictionary <- data.frame(
  Code = all_cats,
  Description = c(
    "Support for writing/structuring academic texts",
    "Synthesis and comprehension of complex information",
    "Solving specific problems or tasks",
    "Efficiency and time savings",
    "Learning and understanding concepts",
    "Other benefits",
    "Inaccurate or outdated information",
    "Excessive reliance / substitution of one's own thinking",
    "Lack of depth or specificity",
    "Difficulty verifying the information",
    "Other limitations",
    "Concern about plagiarism or academic integrity",
    "Responsible use and transparency",
    "Privacy or personal data",
    "Acknowledges ethical reflection without specifying",
    "Does not mention ethical aspects",
    "Uses AI with own judgment (reflective use)",
    "Uses AI without critical reflection (instrumental use)",
    "Limits or avoids use due to ethical concerns",
    "Ambivalent attitude toward use"),
  Instruction = "Write 1 if it applies, 0 if it does not apply",
  stringsAsFactors = FALSE)

instructions <- data.frame(Instructions = c(
  "INSTRUCTIONS FOR HUMAN CODING",
  "1. Read each response in the texto column",
  "2. Columns B1-D4 show what the model coded (reference only)",
  "3. In the humano_* columns write 1 if it applies, 0 if it does not apply",
  "4. You may disagree with the model - that is the validation",
  "5. Use the Diccionario_codigos sheet to see the meaning of each code",
  "",
  paste0("Total to code: ", n_irr),
  "Save the completed file as: muestra_para_codificacion_humana_COMPLETADA.xlsx"))

wb <- createWorkbook()
addWorksheet(wb, "Codificaciones");     writeData(wb, "Codificaciones",    codificaciones)
addWorksheet(wb, "Muestra_IRR");        writeData(wb, "Muestra_IRR",       irr_export)
addWorksheet(wb, "Instrucciones");      writeData(wb, "Instrucciones",     instructions)
addWorksheet(wb, "Diccionario_codigos");writeData(wb, "Diccionario_codigos",code_dictionary)

saveWorkbook(wb, "resultados_codificacion_api.xlsx", overwrite = TRUE)
cat("\nDone: resultados_codificacion_api.xlsx\n")
cat(sprintf("  Codificaciones sheet: %d rows\n", nrow(codificaciones)))
cat(sprintf("  Muestra_IRR sheet:    %d rows for human validation\n", n_irr))
