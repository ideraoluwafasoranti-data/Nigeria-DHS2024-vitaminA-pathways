# ==============================================================================
# Household Access Pathways to Vitamin A Adequacy in Nigeria
# 2024 NDHS | Ideraoluwa Fasoranti | 2026
# Full documentation: see README.md
# ==============================================================================

library(tidyverse)
library(haven)
library(janitor)
library(survey)
library(ggplot2)
library(gtsummary)
library(webshot2)

# ------------------------------------------------------------------------------
# STEP 1: Load and merge KR (child) and IR (woman) files
# ------------------------------------------------------------------------------
kr_raw <- read_dta("data/NGKR8BFL.DTA",
                   col_select = c(caseid, v003, v001, v005, v021, v022,
                                  hw1, b4,
                                  v414i, v414j, v414k,  # Vit A-rich food group
                                  h34,                  # Vit A supplementation
                                  v190, v024, v025, v149)) %>%
  clean_names()

ir_raw <- read_dta("data/NGIR8BFL.DTA",
                   col_select = c(caseid, v743a, v743b, v743d, v743f,
                                  m14_1,          # ANC visit count
                                  v218,           # Number living children
                                  v012)) %>%      # Maternal age
  clean_names()

merged <- kr_raw %>% left_join(ir_raw, by = "caseid")

# ------------------------------------------------------------------------------
# STEP 2: Filter to analytic sample: children 6-23 months
# ------------------------------------------------------------------------------
df <- merged %>%
  filter(hw1 >= 6 & hw1 <= 23)

nrow(df)

# ------------------------------------------------------------------------------
# Outcome 1: Dietary Vitamin A (consumed VA-rich fruit/veg, prior day)
# ------------------------------------------------------------------------------
df <- df %>%
  mutate(
    vita_diet = if_else(v414i == 1 | v414j == 1 | v414k == 1, 1, 0, missing = 0)
  )

mean(df$vita_diet, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Outcome 2: Vitamin A supplementation (h34: dose in last 6 months)
# h34 codes: 1 = yes, 0 = no, 8 = don't know is treated as not received
# ------------------------------------------------------------------------------
df <- df %>%
  mutate(
    vita_supp = case_when(
      as.numeric(h34) == 1 ~ 1,
      as.numeric(h34) %in% c(0, 8) ~ 0,
      TRUE ~ NA_real_
    )
  )

mean(df$vita_supp, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Step 3: Maternal autonomy composite 
# ------------------------------------------------------------------------------
df <- df %>%
  mutate(
    aut_a = case_when(
      v743a == 1 ~ 1,
      v743a %in% c(2, 3)    ~ 0.5,
      v743a %in% c(4, 5, 6) ~ 0,
      TRUE ~ NA_real_
    ),
    aut_b = case_when(
      v743b == 1 ~ 1,
      v743b %in% c(2, 3)    ~ 0.5,
      v743b %in% c(4, 5, 6) ~ 0,
      TRUE ~ NA_real_
    ),
    aut_d = case_when(
      v743d == 1 ~ 1,
      v743d %in% c(2, 3)    ~ 0.5,
      v743d %in% c(4, 5, 6) ~ 0,
      TRUE ~ NA_real_
    ),
    aut_f = case_when(
      v743f == 1 ~ 1,
      v743f %in% c(2, 3)    ~ 0.5,
      v743f %in% c(4, 5, 6) ~ 0,
      TRUE ~ NA_real_
    ),
    autonomy_score = rowMeans(cbind(aut_a, aut_b, aut_d, aut_f), na.rm = TRUE),
    autonomy_n = rowSums(!is.na(cbind(aut_a, aut_b, aut_d, aut_f)))
  )

summary(df$autonomy_score)
table(df$autonomy_n, useNA = "always")
# ----------------------------------------------------------------------------------- 
# 3.1 ANC visits (m14_1) 98/99 are Don't know/missing codes in DHS, not valid counts
# -----------------------------------------------------------------------------------
df <- df %>%
  mutate(
    anc_visits = case_when(
      as.numeric(m14_1) %in% c(98, 99) ~ NA_real_,
      TRUE ~ as.numeric(m14_1)
    )
  )

summary(df$anc_visits)

# ------------------------------------------------------------------------------
# 3.2 Wealth, education, number of living children (v190, v149, v218)
# ------------------------------------------------------------------------------
table(df$v190, useNA = "always")
table(df$v149, useNA = "always")
summary(df$v218)

# ------------------------------------------------------------------------------
# STEP 4: Factor conversion
# ------------------------------------------------------------------------------
df$v024 <- as.factor(as.integer(df$v024))
df$v149 <- as.factor(as.integer(df$v149))
df$v190 <- as.factor(as.integer(df$v190))
df$v025 <- as.factor(as.integer(df$v025))
df$vita_diet <- as.factor(vita_diet <- df$vita_diet)
df$vita_supp <- as.factor(df$vita_supp)

# ------------------------------------------------------------------------------
# 4.1 Survey design
# ------------------------------------------------------------------------------
dhs_design <- svydesign(
  id      = ~v021,
  strata  = ~v022,
  weights = ~I(v005 / 1000000),
  data    = df,
  nest    = TRUE
)

# ------------------------------------------------------------------------------
# 4.2 Model A - Dietary pathway: wealth + education + household size 
#               predict vita_diet
# ------------------------------------------------------------------------------
modelA <- svyglm(
  vita_diet ~ v190 + v149 + v218 + v024 + v025 + v012,
  design = dhs_design,
  family = quasibinomial(link = "logit")
)

summary(modelA)

# ------------------------------------------------------------------------------
# 4.3 Model B - Supplementation pathway: ANC contact + autonomy predict 
#                vita_supp
# ------------------------------------------------------------------------------
modelB <- svyglm(
  vita_supp ~ anc_visits + autonomy_score + v024 + v025 + v012,
  design = dhs_design,
  family = quasibinomial(link = "logit")
)

summary(modelB)

# ------------------------------------------------------------------------------
# STEP 5: Double-gap comparison: overlap between dietary and 
#         supplementation adequacy
# ------------------------------------------------------------------------------
df <- df %>%
  mutate(
    gap_group = case_when(
      vita_diet == 1 & vita_supp == 1 ~ "Both adequate",
      vita_diet == 1 & vita_supp == 0 ~ "Diet only",
      vita_diet == 0 & vita_supp == 1 ~ "Supplementation only",
      vita_diet == 0 & vita_supp == 0 ~ "Double gap",
      TRUE ~ NA_character_
    )
  )

table(df$gap_group, useNA = "always")
prop.table(table(df$gap_group))

# Rebuild design to include gap_group
dhs_design <- svydesign(
  id      = ~v021,
  strata  = ~v022,
  weights = ~I(v005 / 1000000),
  data    = df,
  nest    = TRUE 
)

# Survey-weighted proportions (more accurate than raw table above)
svymean(~as.factor(gap_group), dhs_design, na.rm = TRUE)

# ==============================================================================
# STEP 6: VISUALIZATION
# ==============================================================================
dir.create("outputs", showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 6.1 Vitamin A pathway coverage - the headline chart
# ------------------------------------------------------------------------------
gap_plot <- df %>%
  filter(!is.na(gap_group)) %>%
  count(gap_group) %>%
  mutate(pct = n / sum(n) * 100,
         gap_group = factor(gap_group, levels = c("Both adequate", "Diet only",
                                                  "Supplementation only", 
                                                  "Double gap")))

ggplot(gap_plot, aes(x = gap_group, y = pct, fill = gap_group)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("#2ECC71", "#3498DB", "#F39C12", "#E74C3C")) +
  labs(
    title = "Vitamin A Pathway Coverage Among Children 6-23 Months",
    subtitle = "2024 Nigeria Demographic and Health Survey",
    x = NULL, y = "Percentage of Children (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 20, hjust = 1))

ggsave("outputs/gap_group_coverage.png", width = 8, height = 6, dpi = 300)

# ------------------------------------------------------------------------------
# 6.2 Predictors of each pathway - dietary vs supplementation
# ------------------------------------------------------------------------------
diet_supp_plot <- df %>%
  group_by(v190) %>%
  summarise(
    Diet = mean(as.numeric(as.character(vita_diet)), na.rm = TRUE) * 100,
    Supplementation = mean(as.numeric(as.character(vita_supp)), na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  pivot_longer(cols = c(Diet, Supplementation), names_to = "Pathway", values_to = "Prevalence") %>%
  mutate(wealth_label = factor(v190, levels = 1:5,
                               labels = c("Poorest","Poorer","Middle","Richer","Richest")))

ggplot(diet_supp_plot, aes(x = wealth_label, y = Prevalence, fill = Pathway)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("#3498DB", "#F39C12")) +
  labs(
    title = "Dietary vs. Supplementation Coverage by Wealth Quintile",
    subtitle = "2024 Nigeria Demographic and Health Survey",
    x = "Wealth Quintile", y = "Prevalence (%)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

ggsave("outputs/pathways_by_wealth.png", width = 8, height = 6, dpi = 300)


# ------------------------------------------------------------------------------
# STEP 7: Descriptive summary table
# ------------------------------------------------------------------------------
df_table <- df %>%
  mutate(
    zone = case_when(
      v024 == 1 ~ "North West", v024 == 2 ~ "North East", v024 == 3 ~ "North Central",
      v024 == 4 ~ "South East", v024 == 5 ~ "South South", v024 == 6 ~ "South West"
    ),
    vita_diet_label = factor(vita_diet, levels = c(0,1), labels = c("No","Yes")),
    vita_supp_label = factor(vita_supp, levels = c(0,1), labels = c("No","Yes")),
    gap_group       = factor(gap_group, levels = c("Both adequate","Diet only",
                                                   "Supplementation only","Double gap")),
    sex             = factor(b4, levels = c(1,2), labels = c("Male","Female")),
    residence       = factor(v025, levels = c(1,2), labels = c("Urban","Rural")),
    wealth          = factor(v190, levels = c(1,2,3,4,5),
                             labels = c("Poorest","Poorer","Middle","Richer","Richest"))
  )

table1 <- df_table %>%
  select(zone, vita_diet_label, vita_supp_label, gap_group,
         autonomy_score, anc_visits, v218, hw1, sex, residence, wealth) %>%
  tbl_summary(
    by = zone,
    label = list(
      vita_diet_label ~ "Dietary Vitamin A adequacy",
      vita_supp_label ~ "Vitamin A supplementation",
      gap_group       ~ "Pathway coverage group",
      autonomy_score  ~ "Autonomy score (mean)",
      anc_visits      ~ "ANC visits (mean)",
      v218            ~ "Number of living children",
      hw1             ~ "Child age in months",
      sex             ~ "Child sex",
      residence       ~ "Residence",
      wealth          ~ "Wealth index"
    ),
    statistic = list(all_continuous() ~ "{mean} ({sd})", all_categorical() ~ "{n} ({p}%)"),
    missing = "no"
  ) %>%
  add_overall() %>%
  modify_caption("**Table 1. Sample characteristics by geopolitical zone, Nigeria 2024 DHS**") %>%
  bold_labels()

table1

table1 %>% as_gt() %>% gt::gtsave("outputs/table1_descriptive.html")
table1 %>% as_gt() %>% gt::gtsave("outputs/table1_descriptive.png")

# ------------------------------------------------------------------------------
# STEP 8: Predicted supplementation coverage - autonomy percentiles, by zone
# ------------------------------------------------------------------------------
modal_zone <- names(sort(table(dhs_design$variables$v024), 
                         decreasing = TRUE))[1]
modal_residence <- names(sort(table(dhs_design$variables$v025), 
                              decreasing = TRUE))[1]

# Autonomy distribution is concentrated at low values in this sample:
# 25th/75th percentiles are 0.00/0.50, used as the two prediction points below
autonomy_pctiles <- quantile(dhs_design$variables$autonomy_score, 
                             probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
autonomy_pctiles

# ------------------------------------------------------------------------------
# 8.1 By autonomy percentile (national, modal zone/residence held constant)
# 0.00 = 25th percentile, 0.50 = 75th percentile of autonomy_score in this sample
# ------------------------------------------------------------------------------
newdata <- data.frame(
  autonomy_score = c(0.00, 0.50),
  anc_visits = mean(dhs_design$variables$anc_visits, na.rm = TRUE),
  v024 = factor(modal_zone, levels = levels(dhs_design$variables$v024)),
  v025 = factor(modal_residence, levels = levels(dhs_design$variables$v025)),
  v012 = mean(dhs_design$variables$v012, na.rm = TRUE)
)

preds <- predict(modelB, newdata = newdata, type = "response", se = TRUE)
data.frame(
  autonomy_level = c("25th pct (0.00)", "75th pct (0.50)"),
  predicted_prob = as.numeric(preds),
  se = sqrt(attr(preds, "var"))
)

# ------------------------------------------------------------------------------
# 8.2 By zone (autonomy fixed at sample mean, 0.286) for a single representative 
# estimate per zone
# ------------------------------------------------------------------------------
zone_labels <- c("1"="North West", "2"="North East", "3"="North Central",
                 "4"="South East", "5"="South South", "6"="South West")

all_zone_preds <- lapply(names(zone_labels), function(z) {
  nd <- data.frame(
    autonomy_score = 0.286,  # sample mean, or use median autonomy 
                             # for a single representative estimate
    anc_visits = mean(dhs_design$variables$anc_visits, na.rm = TRUE),
    v024 = factor(z, levels = levels(dhs_design$variables$v024)),
    v025 = factor(modal_residence, levels = levels(dhs_design$variables$v025)),
    v012 = mean(dhs_design$variables$v012, na.rm = TRUE)
  )
  p <- predict(modelB, newdata = nd, type = "response", se = TRUE)
  data.frame(zone = zone_labels[z], predicted_prob = as.numeric(p), se = sqrt(attr(p, "var")))
})

do.call(rbind, all_zone_preds)

# ------------------------------------------------------------------------------
# 8.3 Observed zone-level values (gap_group prevalence, ANC visits, autonomy)
# ------------------------------------------------------------------------------
gap_by_zone <- svyby(~gap_group, ~v024, dhs_design, svymean, na.rm = TRUE)
gap_by_zone$zone <- zone_labels[as.character(gap_by_zone$v024)]
gap_by_zone

anc_by_zone <- svyby(~anc_visits, ~v024, dhs_design, svymean, na.rm = TRUE)
anc_by_zone$zone <- zone_labels[as.character(anc_by_zone$v024)]
anc_by_zone

autonomy_by_zone <- svyby(~autonomy_score, ~v024, dhs_design, svymean, 
                          na.rm = TRUE)
autonomy_by_zone$zone <- zone_labels[as.character(autonomy_by_zone$v024)]
autonomy_by_zone