# ─────────────────────────────────────────────────────────────────────────────
# Listing: Treatment-Emergent Adverse Events by Subject
#          Excluding Screen Failure Patients
# Dataset : pharmaverseadam::adae (CDISCPILOT01)
# Variables: USUBJID, TRT01A, AETERM, AESEV, AEREL, ASTDT, AENDT,
#            TRTEMFL, SAFFL
# Tool    : {gt} — the table engine that {gtsummary} wraps and re-exports
# Output  : ae_listing.png
# ─────────────────────────────────────────────────────────────────────────────

library(dplyr)
library(gt)
library(gtsummary)
library(here)

# ── 1. Load data ──────────────────────────────────────────────────────────────

adae <- pharmaverseadam::adae

# ── 2. Filter & prepare ───────────────────────────────────────────────────────

ae_listing <- adae %>%
  filter(SAFFL == "Y",          # SAFFL == "Y"    → excludes screen failure patients
         TRTEMFL == "Y") %>%    # TRTEMFL == "Y" →  treatment-emergent AEs only
  
  arrange(USUBJID, ASTDT) %>%   #Sorted by SubjectID and Event Date 
  
  # ── Carryover suppression ──────────────────────────────────────────────────
  # TRT01A : show only on first row per subject
  group_by(USUBJID) %>%
  mutate(
    TRT01A = ifelse(row_number() == 1, TRT01A, "")
  ) %>%
  
  # AETERM : show only on first row per subject+term combination
  group_by(USUBJID, AETERM) %>%
  mutate(
    AETERM = ifelse(row_number() == 1, AETERM, "")
  ) %>%
  ungroup() %>%
  
  # ── USUBJID: show only on first row per subject 
  mutate(
    USUBJID = ifelse(USUBJID != lag(USUBJID, default = ""), USUBJID, "")
  ) %>%
  
  # Convert Date columns to character strings to show "NA" 
  mutate(
    ASTDT = if_else(is.na(ASTDT), "NA", as.character(ASTDT)),
    AENDT = if_else(is.na(AENDT), "NA", as.character(AENDT))
  ) %>%
  
  #Arranging Column Sequence
  select(
    USUBJID,
    TRT01A,
    AETERM,
    AESEV,
    AEREL,
    ASTDT,
    AENDT
  )

cat("Rows in listing:", nrow(ae_listing), "\n")
cat("Unique subjects:", n_distinct(ae_listing$USUBJID), "\n")



# ── 3. Build gtsummary listing ────────────────────────────────────────────────

ae_gtlist <- ae_listing %>%
  #Ingest into the gtsummary framework
  gtsummary::as_gtsummary() %>%
  
  # Assign column headers using a native named list
  gtsummary::modify_header(
    USUBJID ~ "Unique Subject Identifier",
    TRT01A  ~ "Description of Actual Arm",
    AETERM  ~ "Reported Term for the Adverse Event",
    AESEV   ~ "Severity/Intensity",
    AEREL   ~ "Causality",
    ASTDT   ~ "Start Date/Time of Adverse Event",
    AENDT   ~ "End Date/Time of Adverse Event"
  ) %>%
  
  #  Left-align all columns natively within gtsummary
  gtsummary::modify_column_alignment(everything(), align = "left") %>%
  
  #  Bridge over to the gt engine to apply final clinical display styling
  as_gt() %>%
  
  # ── Title & subtitle ────────────────────────────────────────────────────────
  tab_header(
    title    = "Listing of Treatment-Emergent Adverse Events by Subject",
    subtitle = "Excluding Screen Failure Patients"
  ) %>%
  
  # ── Column widths ────────────────────────────────────────────────────────────
  cols_width(
    USUBJID ~ px(140),
    TRT01A  ~ px(140),
    AETERM  ~ px(240),
    AESEV   ~ px(110),
    AEREL   ~ px(100),
    ASTDT   ~ px(130),
    AENDT   ~ px(130)
  ) %>%
  
  # ── Font: monospace to match clinical listing style ─────────────────────────
  tab_style(
    style = cell_text(font = "Courier New", size = px(11)),
    locations = list(cells_body(), cells_column_labels())
  ) %>%
  
  # ── Title styling ────────────────────────────────────────────────────────────
  tab_style(
    style = cell_text(font = "Courier New", size = px(11), weight = "normal", align = "left"),
    locations = cells_title(groups = c("title", "subtitle"))
  ) %>%
  
  # ── Column header styling ────────────────────────────────────────────────────
  tab_style(
    style = list(
      cell_text(weight = "bold", size = px(11)),
      cell_borders(sides = "bottom", color = "#555555", weight = px(1.5))
    ),
    locations = cells_column_labels()
  ) %>%
  
  # ── Remove row striping; keep clean white background ─────────────────────────
  tab_options(
    table.font.size                  = px(11),
    table.width                      = pct(100),
    row.striping.include_table_body  = FALSE,
    column_labels.border.top.width   = px(1),
    column_labels.border.top.color   = "#AAAAAA",
    table_body.border.bottom.color   = "#AAAAAA",
    data_row.padding                 = px(2),
    heading.border.bottom.color      = "#AAAAAA",
    heading.align                    = "left"
  )


#View plot
ae_gtlist

# ── 4. Save ───────────────────────────────────────────────────────────────────

gtsave(
  ae_gtlist, 
  filename = here::here("04_TLG_Generation", "ae_listings.html")
)
cat("Listing saved.\n")