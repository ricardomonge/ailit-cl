# ailit-cl: Validación de la Escala de Alfabetización en IA en Chile

> Pipeline reproducible en R para la adaptación transcultural y validación psicométrica de la *Artificial Intelligence Literacy Scale* (AILS) en estudiantes universitarios chilenos, con triangulación de métodos mixtos sobre el uso real de IA.

[![R](https://img.shields.io/badge/R-%3E%3D4.3-blue)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Descripción

Este repositorio contiene el código (R Markdown) del pipeline de análisis del estudio *"Artificial intelligence literacy in Chilean university students: Scale validation, latent profiles of use, and the paradox of ethical awareness"*.

El estudio adapta y valida al español chileno la AILS de Han & Zhang (2025) en una muestra de 948 estudiantes universitarios, mediante un **diseño mixto convergente**:

1. **Validez de contenido** — juicio de 14 expertos (V de Aiken).
2. **Validación psicométrica** — AFE/AFC con estimador WLSMV (datos ordinales), confiabilidad, validez convergente/discriminante, invarianza de medición por sexo.
3. **Análisis cualitativo asistido por IA** — codificación deductiva de respuestas abiertas con un modelo de lenguaje ejecutado localmente (Llama 3.1 8B Instruct), análisis de clases latentes (LCA) y triangulación cuali-cuantitativa.

Los resultados completos se reportan en el artículo asociado (ver [Citación](#citación)).

## Estructura del repositorio

```
ailit-cl/
├── README.md
├── LICENSE
├── .gitignore
├── project.Rproj
└── scripts/
    ├── 01_content_validity.Rmd          # Validez de contenido (V de Aiken, N = 14 jueces)
    ├── 02_psychometric_validation.Rmd   # AFE/AFC, confiabilidad, invarianza (WLSMV)
    ├── 03_qualitative_analysis.Rmd      # LCA, kappa/PABAK, triangulación
    └── exploratory/
        └── ai_coding_claude_api_EXPLORATORY.R
```

> Este repositorio incluye **solo código**. No se distribuyen datos, tablas de resultados ni figuras (ver [Política de datos](#política-de-datos)).

## Scripts

| Script | Contenido | Corresponde a |
|---|---|---|
| `01_content_validity.Rmd` | Cálculo de V de Aiken (relevancia y redacción) e IC asimétricos al 95%, por ítem y por jueces | Manuscrito §2.3, §3.1 |
| `02_psychometric_validation.Rmd` | División AFE/AFC (seed = 2024), AFE (paralelo, Promax), AFC (WLSMV, `ordered = TRUE`), confiabilidad (alfa ordinal, omega categórico, CR), validez convergente/discriminante (AVE, Fornell-Larcker, HTMT), invarianza por sexo (WLSMV, parametrización theta, identificación de Wu & Estabrook, 2016) | Manuscrito §2.5–§2.8, §3.2–§3.5 |
| `03_qualitative_analysis.Rmd` | Lectura de codificaciones deductivas (20 categorías), fiabilidad inter-jueces (κ de Cohen + PABAK), correlaciones biseriales puntuales con corrección FDR, análisis de clases latentes (poLCA, 2–5 clases, BIC/entropía), tabla de triangulación | Manuscrito §2.10, §3.7 |
| `scripts/exploratory/ai_coding_claude_api_EXPLORATORY.R` | Prueba **exploratoria** de codificación deductiva vía API de Claude. **No corresponde al método reportado en el manuscrito** (que usó Llama 3.1 8B Instruct local); se conserva solo como referencia de un enfoque alternativo evaluado durante el desarrollo | — |

`03_qualitative_analysis.Rmd` espera como insumo un archivo de codificaciones (una fila por respuesta, columnas B1–B6/L1–L5/E1–E5/D1–D4) producido por el pipeline local de codificación con Llama, el cual no se distribuye en este repositorio.

## Requisitos de software

```r
paquetes <- c(
  # Validez de contenido y psicometría
  "tidyverse", "psych", "lavaan", "semTools", "GPArotation",
  "parameters", "correlation", "ggplot2", "corrplot", "knitr",
  "openxlsx", "moments", "mice", "naniar", "MVN", "car",
  # Análisis cualitativo
  "irr", "poLCA", "patchwork", "ggrepel"
)
```

R ≥ 4.3.0.

## Decisiones metodológicas clave

- **Estimador AFC — WLSMV.** Ítems ordinales (Likert de 5 puntos) con no-normalidad multivariada severa (Mardia, p < .001); WLSMV con `ordered = TRUE` es el estándar recomendado para este tipo de datos.
- **Invarianza por sexo — WLSMV, parametrización theta.** Se siguió la identificación de Wu & Estabrook (2016) vía `semTools::measEq.syntax()`. Un ítem con categoría vacía por sexo (IA.A08) se colapsó con la categoría adyacente antes de la estimación multigrupo. Criterio: |ΔCFI| ≤ .010 y |ΔRMSEA| ≤ .015 (Chen, 2007; Putnick & Bornstein, 2016).
- **Corrección por comparaciones múltiples — FDR.** Todas las familias de correlaciones simultáneas se corrigen con Benjamini-Hochberg (1995).
- **Codificación cualitativa — Llama 3.1 8B Instruct (local).** La codificación deductiva de las 764 respuestas abiertas se realizó con un modelo de lenguaje ejecutado localmente, con verificación de fiabilidad inter-jueces (κ de Cohen y PABAK) contra un evaluador humano en una submuestra del 20% (n = 97).
- **LCA — exploratorio.** Las categorías de decisión de uso (D1–D4) son mutuamente excluyentes por diseño, lo que puede afectar el supuesto de independencia local; la solución de 4 clases se reporta como exploratoria (Masyn, 2013).

## Reproducibilidad

Todos los análisis estocásticos usan semilla fija `set.seed(2024)`: división AFE/AFC, análisis paralelo, y LCA (`nrep = 20`, `maxiter = 1000`). La selección de la submuestra de fiabilidad inter-jueces también usa `seed = 2024`.

## Política de datos

El dataset (respuestas Likert, datos sociodemográficos y respuestas abiertas de texto libre) **no se incluye en este repositorio** para proteger la privacidad de los participantes, conforme al consentimiento informado del estudio. Investigadores interesados en acceso controlado a los datos cuantitativos pueden contactar al autor de correspondencia.

## Citación

```bibtex
@article{mongerogel2026ailit,
  author  = {Monge-Rogel, Ricardo and Pérez-Aguilera, Sebastián and Sáez-Valdés, Loreto},
  title   = {Artificial intelligence literacy in Chilean university students:
             Scale validation, latent profiles of use, and the paradox of
             ethical awareness},
  journal = {[Revista]},
  year    = {2026},
  doi     = {[DOI pendiente]}
}
```

### Instrumento original

Han, S., & Zhang, Y. (2025). Developing a validated assessment of artificial intelligence literacy for Chinese university students based on educational objectives taxonomy. *Journal of Research on Technology in Education*. https://doi.org/10.1080/15391523.2025.2456051

## Licencia

El código de este repositorio está disponible bajo la licencia [MIT](LICENSE). Los datos no se incluyen.
