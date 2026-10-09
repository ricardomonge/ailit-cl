# ailit-cl: AI Literacy Scale Validation in Chile

> Reproducible R pipeline for the cross-cultural adaptation and psychometric validation of the *Artificial Intelligence Literacy Scale* (AILS) among Chilean university students, with mixed-methods triangulation of AI-use narratives.

[![R](https://img.shields.io/badge/R-%3E%3D4.3-blue)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Description

This repository contains the analysis code (R Markdown) for the study *"Artificial intelligence literacy in Chilean university students: Scale validation, latent profiles of use, and the paradox of ethical awareness."*

The study adapts and validates the AILS of Han & Zhang (2025) for the Chilean Spanish-speaking context in a sample of 948 university students, using a **convergent mixed-methods design**:

1. **Content validity** — expert judgment by 14 raters (Aiken's V).
2. **Psychometric validation** — EFA/CFA with the WLSMV estimator (ordinal data), reliability, convergent/discriminant validity, measurement invariance by sex.
3. **AI-assisted qualitative analysis** — deductive coding of open-ended responses with a locally run language model (Llama 3.1 8B Instruct), latent class analysis (LCA), and qualitative–quantitative triangulation.

Full results are reported in the associated article (see [Citation](#citation)).

## Repository structure

```
ailit-cl/
├── README.md
├── LICENSE
├── .gitignore
├── project.Rproj
└── scripts/
    ├── 01_content_validity.Rmd          # Content validity (Aiken's V, N = 14 judges)
    ├── 02_psychometric_validation.Rmd   # EFA/CFA, reliability, invariance (WLSMV)
    ├── 03_qualitative_analysis.Rmd      # LCA, kappa/PABAK, triangulation
    └── exploratory/
        └── ai_coding_claude_api_EXPLORATORY.R
```

> This repository includes **code only**. No data, result tables, or figures are distributed (see [Data policy](#data-policy)).

## Scripts

| Script | Content | Corresponds to |
|---|---|---|
| `01_content_validity.Rmd` | Computation of Aiken's V (relevance and wording) and asymmetric 95% CIs, by item and by judges | Manuscript §2.3, §3.1 |
| `02_psychometric_validation.Rmd` | EFA/CFA split (seed = 2024), EFA (parallel analysis, Promax), CFA (WLSMV, `ordered = TRUE`), reliability (ordinal alpha, categorical omega, CR), convergent/discriminant validity (AVE, Fornell-Larcker, HTMT), invariance by sex (WLSMV, theta parameterization, Wu & Estabrook, 2016 identification) | Manuscript §2.5–§2.8, §3.2–§3.5 |
| `03_qualitative_analysis.Rmd` | Loading of deductive codings (20 categories), inter-rater reliability (Cohen's κ + PABAK), point-biserial correlations with FDR correction, latent class analysis (poLCA, 2–5 classes, BIC/entropy), triangulation table | Manuscript §2.10, §3.7 |
| `scripts/exploratory/ai_coding_claude_api_EXPLORATORY.R` | **Exploratory** test of deductive coding via the Claude API. **Does not correspond to the method reported in the manuscript** (which used Llama 3.1 8B Instruct run locally); kept only as a record of an alternative approach evaluated during development | — |

`03_qualitative_analysis.Rmd` expects as input a codings file (one row per response, columns B1–B6/L1–L5/E1–E5/D1–D4) produced by the local Llama coding pipeline, which is not distributed in this repository.

## Software requirements

```r
packages <- c(
  # Content validity and psychometrics
  "tidyverse", "psych", "lavaan", "semTools", "GPArotation",
  "parameters", "correlation", "ggplot2", "corrplot", "knitr",
  "openxlsx", "moments", "mice", "naniar", "MVN", "car",
  # Qualitative analysis
  "irr", "poLCA", "patchwork", "ggrepel"
)
```

R ≥ 4.3.0.

## Key methodological decisions

- **CFA estimator — WLSMV.** Ordinal items (5-point Likert) with severe multivariate non-normality (Mardia, p < .001); WLSMV with `ordered = TRUE` is the recommended standard for this type of data.
- **Invariance by sex — WLSMV, theta parameterization.** Followed the identification approach of Wu & Estabrook (2016) via `semTools::measEq.syntax()`. One item with an empty category by sex (IA.A08) was collapsed with the adjacent category before multigroup estimation. Criterion: |ΔCFI| ≤ .010 and |ΔRMSEA| ≤ .015 (Chen, 2007; Putnick & Bornstein, 2016).
- **Multiple-comparison correction — FDR.** All families of simultaneous correlations are corrected with Benjamini-Hochberg (1995).
- **Qualitative coding — Llama 3.1 8B Instruct (local).** Deductive coding of the 764 open-ended responses was performed with a locally run language model, with inter-rater reliability verification (Cohen's κ and PABAK) against a human rater on a 20% subsample (n = 97).
- **LCA — exploratory.** The decision-of-use categories (D1–D4) are mutually exclusive by design, which may affect the local-independence assumption; the 4-class solution is reported as exploratory (Masyn, 2013).

## Reproducibility

All stochastic analyses use a fixed seed `set.seed(2024)`: EFA/CFA split, parallel analysis, and LCA (`nrep = 20`, `maxiter = 1000`). The inter-rater reliability subsample selection also uses `seed = 2024`.

## Data policy

The dataset (Likert responses, sociodemographic data, and open-ended free-text responses) **is not included in this repository** to protect participant privacy, in accordance with the study's informed consent. Researchers interested in controlled access to the quantitative data may contact the corresponding author.

## Citation

```bibtex
@article{mongerogel2026ailit,
  author  = {Monge-Rogel, Ricardo and Pérez-Aguilera, Sebastián and Sáez-Valdés, Loreto},
  title   = {Artificial intelligence literacy in Chilean university students:
             Scale validation, latent profiles of use, and the paradox of
             ethical awareness},
  journal = {[Journal]},
  year    = {2026},
  doi     = {[DOI pending]}
}
```

### Original instrument

Han, S., & Zhang, Y. (2025). Developing a validated assessment of artificial intelligence literacy for Chinese university students based on educational objectives taxonomy. *Journal of Research on Technology in Education*. https://doi.org/10.1080/15391523.2025.2456051

## License

The code in this repository is available under the [MIT](LICENSE) license. Data is not included.
