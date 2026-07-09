# =============================================================================
# PROJECT: Treatment Emergent Adverse Event Summary Table
# PURPOSE: Generate TEAE summary table sorted by descending frequency and
#          alphabetical tie-breaking at AETERM.
# OUTPUTS: 1. gtsummary/gt version   (Primary HTML)  -> 04_TLG_Generation/ae_summary_table.html
#          2. rtables/tern version   (Validation PDF) -> 04_TLG_Generation/ae_summary_table.pdf
# =============================================================================

# ── 0. LOAD LIBRARIES ────────────────────────────────────────────────────────
library(here)
library(pharmaverseadam)
library(gtsummary)
library(gt)
library(rtables)
library(tern)
library(dplyr)
library(tidyr)


adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae


# #############################################################################
# METHOD 1 — gtsummary / gt  ->  HTML
# #############################################################################

# ── 1. DATA PREPARATION & SORTING LOGIC ─────────────────────────────────────
adsl_saf   <- adsl %>% filter(SAFFL == "Y")
adae_teae1 <- adae %>% filter(SAFFL == "Y", TRTEMFL == "Y")

# Arm totals (Placebo=86, High=72, Low=96, All Patients=254)
arm_totals     <- table(adsl_saf$ACTARM)
total_patients <- nrow(adsl_saf)

# Pre-calculate sorting frequencies (descending, ties broken alphabetically)
aesoc_freq_1 <- adae_teae1 %>%
  group_by(AESOC) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(desc(n_subj))

aeterm_freq_1 <- adae_teae1 %>%
  group_by(AESOC, AETERM) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(AESOC, desc(n_subj), AETERM)

# Event counts & percentages by treatment arm
ae_counts <- adae_teae1 %>%
  group_by(AESOC, AETERM, ACTARM) %>%
  summarise(n_unique = n_distinct(USUBJID), .groups = "drop") %>%
  mutate(
    denom      = as.numeric(arm_totals[ACTARM]),
    pct        = (n_unique / denom) * 100,
    cell_value = paste0(n_unique, " (", format(round(pct, 1), nsmall = 1), "%)")
  )

# Event counts & percentages for "All Patients" column
ae_overall <- adae_teae1 %>%
  group_by(AESOC, AETERM) %>%
  summarise(n_unique = n_distinct(USUBJID), .groups = "drop") %>%
  mutate(
    ACTARM     = "All Patients",
    denom      = total_patients,
    pct        = (n_unique / denom) * 100,
    cell_value = paste0(n_unique, " (", format(round(pct, 1), nsmall = 1), "%)")
  )

# Pivot into wide grid
final_grid <- bind_rows(ae_counts, ae_overall) %>%
  select(AESOC, AETERM, ACTARM, cell_value) %>%
  pivot_wider(names_from = ACTARM, values_from = cell_value, values_fill = "0 (0.0%)")

final_grid <- final_grid %>%
  mutate(
    AESOC  = factor(AESOC,  levels = aesoc_freq_1$AESOC),
    AETERM = factor(AETERM, levels = aeterm_freq_1$AETERM)
  ) %>%
  arrange(AESOC, AETERM)

# Build gt table
gt_final <- final_grid %>%
  select(AESOC, AETERM, Placebo, `Xanomeline High Dose`, `Xanomeline Low Dose`, `All Patients`) %>%
  group_by(AESOC) %>%
  gt() %>%
  tab_style(
    style     = cell_text(indent = px(15)),
    locations = cells_body(columns = AETERM)
  ) %>%
  row_group_order(groups = aesoc_freq_1$AESOC) %>%
  tab_style(
    style     = cell_text(weight = "bold"),
    locations = cells_row_groups()
  ) %>%
  cols_align(align = "left", columns = AETERM) %>%
  cols_align(
    align   = "center",
    columns = c(Placebo, `Xanomeline High Dose`, `Xanomeline Low Dose`, `All Patients`)
  ) %>%
  cols_label(
    AETERM  = html("Primary System Organ Class<br>Reported Term for the Adverse Event"),
    Placebo = html(paste0("Placebo<br>(N=", arm_totals["Placebo"], ")")),
    `Xanomeline High Dose` = html(paste0("Xanomeline High Dose<br>(N=", arm_totals["Xanomeline High Dose"], ")")),
    `Xanomeline Low Dose`  = html(paste0("Xanomeline Low Dose<br>(N=", arm_totals["Xanomeline Low Dose"], ")")),
    `All Patients` = html(paste0("All Patients<br>(N=", total_patients, ")"))
  ) %>%
  tab_options(
    table.font.size            = pct(85),
    column_labels.font.weight  = "bold",
    row_group.font.weight      = "bold"
  )

# View Result
gt_final

# Save HTML (portable path)
gtsave(gt_final, filename = here::here("04_TLG_Generation", "ae_summary_table.html"))
cat("Method 1 (gt/HTML) compiled successfully.\n")


# #############################################################################
# METHOD 2 — rtables / tern  ->  PDF
# #############################################################################

# ── 2. DATA CLEANING & INGESTION ────────────────────────────────────────────
adsl_saf2 <- adsl %>%
  df_explicit_na() %>%
  filter(SAFFL == "Y")

adae_teae2 <- adae %>%
  df_explicit_na() %>%
  filter(SAFFL == "Y", TRTEMFL == "Y") %>%
  var_relabel(
    AESOC  = "Primary System Organ Class",
    AETERM = "Reported Term for the Adverse Event"
  )

# Capture labels before factor conversion
aesoc_label  <- obj_label(adae_teae2$AESOC)
aeterm_label <- obj_label(adae_teae2$AETERM)

# AESOC: sorted by descending frequency
aesoc_freq_2 <- adae_teae2 %>%
  group_by(AESOC) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(desc(n_subj))

# AETERM: sorted by descending frequency, ties broken alphabetically
aeterm_freq_2 <- adae_teae2 %>%
  group_by(AETERM) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(desc(n_subj), AETERM)

adae_teae2 <- adae_teae2 %>%
  mutate(
    AESOC  = factor(AESOC,  levels = aesoc_freq_2$AESOC),
    AETERM = factor(AETERM, levels = aeterm_freq_2$AETERM)
  )

# Restore labels after factor conversion
obj_label(adae_teae2$AESOC)  <- aesoc_label
obj_label(adae_teae2$AETERM) <- aeterm_label

split_fun <- drop_split_levels

# Build Table
lyt <- basic_table(show_colcounts = TRUE) %>%
  split_cols_by(var = "ACTARM") %>%
  add_overall_col(label = "All Patients") %>%
  analyze_num_patients(
    vars    = "USUBJID",
    .stats  = c("unique", "nonunique"),
    .labels = c(
      unique    = "Total number of patients with at least one TEAE",
      nonunique = "Total number of TEAEs"
    )
  ) %>%
  split_rows_by(
    var          = "AESOC",
    child_labels = "visible",
    nested       = FALSE,
    split_fun    = split_fun,
    label_pos    = "topleft",
    split_label  = aesoc_label
  ) %>%
  summarize_num_patients(
    var     = "USUBJID",
    .stats  = c("unique", "nonunique"),
    .labels = c(
      unique    = "Total number of patients with at least one TEAE",
      nonunique = "Total number of events"
    )
  ) %>%
  count_occurrences(
    vars         = "AETERM",
    .indent_mods = -1L
  ) %>%
  append_varlabels(adae_teae2, "AETERM", indent = 1L)

result <- build_table(
  lyt,
  df            = adae_teae2,
  alt_counts_df = adsl_saf2
)

result_sorted <- result %>%
  sort_at_path(
    path       = c("AESOC", "*", "AETERM"),
    scorefun   = score_occurrences,
    decreasing = TRUE
  )

# View Result
result_sorted

# ── Export to PDF (portable path) ───────────────────────────────────────────
export_as_pdf(
  result_sorted,
  file      = here::here("04_TLG_Generation", "ae_summary_table.pdf"),
  landscape = TRUE,
  font_size = 8,     # reduce font to fit all columns
  cpp       = 200    # characters per page width
)
cat("Method 2 (rtables/PDF) compiled successfully.\n")

cat("\nBoth outputs written to:", here::here("04_TLG_Generation"), "\n")
