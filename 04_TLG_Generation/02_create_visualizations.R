# ─────────────────────────────────────────────────────────────────────────────
# Plot 1: AE Severity Distribution by Treatment Arm
# Dataset: ADAE (CDISCPILOT01)
# Variables: TRT01A, AESEV, SAFFL
# ─────────────────────────────────────────────────────────────────────────────

library(ggplot2)
library(dplyr)
library(here)

# ── 1. Load data ──────────────────────────────────────────────────────────────
adae <- pharmaverseadam::adae

# ── 2. Filter: Safety population, non-missing AESEV ──
adae_filt <- adae %>%
  filter(
    SAFFL   == "Y",            # Safety population
    !is.na(AESEV), AESEV != "" # Severity is not missing
  )

# ── 3. Count AEs by treatment arm and severity ────────────────────────────────
ae_counts <- adae_filt %>%
  mutate(
    TRT01A = factor(TRT01A,
                    levels = c("Placebo",
                               "Xanomeline High Dose",
                               "Xanomeline Low Dose")),
    AESEV  = factor(AESEV,
                    levels = c("MILD","MODERATE","SEVERE"))  # MILD stacks on top
  ) %>%
  group_by(TRT01A, AESEV) %>%
  summarise(n = n(), .groups = "drop")

# ── 4. Plot ───────────────────────────────────────────────────────────────────
severity_colours <- c(
  MILD     = "#FA8072",   # salmon-red
  MODERATE = "#228B22",   # forest green
  SEVERE   = "#6495ED"    # cornflower blue
)

severity_plot <- ggplot(ae_counts, aes(x = TRT01A, y = n, fill = AESEV)) +
  geom_bar(stat = "identity", position = "stack", width = 0.9) +
  scale_fill_manual(
    values = severity_colours,
    breaks = c("MILD", "MODERATE", "SEVERE"),
    name   = "Severity/Intensity"
  ) +
  scale_y_continuous(
    breaks = seq(0, 500, by = 100),
    expand = expansion(mult = c(0, 0.05))
  ) +
  labs(
    title = "AE severity distribution by treatment",
    x     = "Treatment Arm",
    y     = "Count of AEs"
  ) +
  theme_grey(base_size = 12) +
  theme(
    plot.title       = element_text(hjust = 0.5, size = 13, face = "plain"),
    legend.position  = "right",
    legend.title     = element_text(size = 10),
    legend.key.size  = unit(0.5, "cm"),
    panel.grid.major = element_line(colour = "white"),
    panel.background = element_rect(fill = "grey92"),
    plot.background  = element_rect(fill = "white", colour = NA)
  )

#View plot
severity_plot

# ── 5. Save ───────────────────────────────────────────────────────────────────
ggsave(
  filename  = here::here("04_TLG_Generation", "ae_severity_by_treatment.png"),
  plot     = severity_plot,
  width    = 7,
  height   = 5,
  dpi      = 150
)

cat("Plot saved.\n")

# ─────────────────────────────────────────────────────────────────────────────
# Plot 2: Top 10 Most Frequent AEs with 95% Clopper-Pearson CIs
# Dataset : ADAE (CDISCPILOT01)
# Variables: USUBJID, TRT01A, AETERM, SAFFL
# Method   : Pooled subject-level incidence (unique subjects with AE / N total)
#            Clopper-Pearson exact binomial 95% CI
# ─────────────────────────────────────────────────────────────────────────────

# ── 1. Denominator: total unique subjects in safety population (pooled) ───────
N_total <- adae %>%
  filter(SAFFL == "Y") %>%
  distinct(USUBJID) %>%
  nrow()
cat("Total N (safety population):", N_total, "\n")

# ── 2. Filter to SAFFL, deduplicate to subject level per AETERM ───────────────
ae_subj <- adae %>%
  filter(SAFFL == "Y") %>%
  distinct(USUBJID, AETERM)   # one row per subject-term (pooled)

# ── 3. Identify top 10 AETERMs overall ───────────────────────────────────────
top10_terms <- ae_subj %>%
  count(AETERM, name = "n_subj") %>%
  arrange(desc(n_subj),desc(AETERM)) %>%
  slice_head(n = 10) %>%
  pull(AETERM)

cat("Top 10 AE terms:\n")
print(top10_terms)

# ── 4. Compute incidence rate + Clopper-Pearson 95% CI (exact binomial) ──────
ae_rates <- ae_subj %>%
  filter(AETERM %in% top10_terms) %>%
  count(AETERM, name = "n_subj") %>%
  mutate(
    N     = N_total,
    rate  = n_subj / N,
    # Clopper-Pearson: exact binomial via qbeta
    lower = qbeta(0.025, n_subj,       N - n_subj + 1),
    upper = qbeta(0.975, n_subj + 1,   N - n_subj),
    # Order: highest frequency at top of y-axis
    AETERM = factor(AETERM, levels = rev(top10_terms))
  )

print(ae_rates[, c("AETERM","n_subj","rate","lower","upper")])

# ── 5. Plot ───────────────────────────────────────────────────────────────────
top10_plot <- ggplot(ae_rates, aes(x = rate, y = AETERM)) +
  geom_point(size = 3, colour = "black") +
  geom_errorbar(
    aes(xmin = lower, xmax = upper),
    height = 0.25, linewidth = 0.7, colour = "black"
  ) +
  scale_x_continuous(
    labels = scales::percent_format(accuracy = 1),
    breaks = seq(0, 0.40, by = 0.10),
    limits = c(0, NA),
    expand = expansion(mult = c(0.02, 0.05))
  ) +
  labs(
    title    = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0("n = ", N_total, " subjects; 95% Clopper-Pearson CIs"),
    x        = "Percentage of Patients (%)",
    y        = NULL
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title      = element_text(hjust = 0.5, size = 12, face = "plain"),
    plot.subtitle   = element_text(hjust = 0.5, size = 10, colour = "grey40"),
    panel.grid.minor  = element_blank(),
    panel.grid.major.y = element_line(colour = "grey88"),
    axis.text.y     = element_text(size = 9),
    plot.background = element_rect(fill = "white", colour = NA)
  )

#View plot
top10_plot

# ── 6. Save ───────────────────────────────────────────────────────────────────
ggsave(
  filename  = here::here("04_TLG_Generation", "ae_top10.png"),
  plot     = top10_plot,
  width    = 8,
  height   = 6,
  dpi      = 150
)
cat("Plot saved.\n")
