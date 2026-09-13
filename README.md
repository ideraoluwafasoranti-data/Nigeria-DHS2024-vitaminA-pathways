# Vitamin A Pathways Among Nigerian Children Aged 6–23 Months: Associated Factors and a Large Coverage Gap

## About This Project

This is an independent secondary data analysis I did using the 2024 
Nigeria Demographic and Health Survey (NDHS), as a follow-up to my earlier 
analysis on maternal autonomy, dietary diversity, and malnutrition using the 
same dataset and children.

A child can obtain Vitamin A through two pathways: by consuming 
Vitamin A-rich foods, or by receiving a high-dose Vitamin A supplement, 
usually given through a health facility visit or a campaign. Most studies 
looking at Vitamin A treat these as one combined outcome. I wanted to look at 
them separately instead, to see how many children are missing out on both at 
once, and whether the same factors that mattered in my earlier analysis 
(wealth, autonomy) also matter here.

## Research Questions

1. What proportion of children aged 6-23 months ate Vitamin A-rich foods 
   the day before the survey, and what household factors predict this?
2. What proportion of children received Vitamin A supplementation, and does 
   maternal autonomy predict this after accounting for antenatal care (ANC) visits?
3. How much overlap is there between the two, how many children get neither (the "double gap")?
4. Does the double gap differ by geopolitical zone, and does it follow the 
   same north-south pattern I found in my earlier autonomy analysis?

## Data

**Source:** 2024 Nigeria Demographic and Health Survey (NDHS)

**Files:** Kids Recode (KR) and Individual Recode (IR), Stata format

**Access:** Requested and obtained through dhsprogram.com for academic research purposes

**Sample:** Children aged 6-23 months with resident mothers (n = 3,100)

**Ethics:** Data was obtained under the DHS Program data access agreement and 
            used strictly for academic research. 
            No individual or household can be identified from this data.

## Methods

**Software:** R
**Packages:** tidyverse, haven, janitor, survey, ggplot2, gtsummary, webshot2

### Outcome Variables

**Vitamin A-rich food consumption**: In the DHS, mothers are asked whether their
child ate specific foods in the 24 hours before the interview. I defined a child 
as having consumed Vitamin A-rich food if they ate at least one of three DHS food-group items:
- **V414I** - pumpkin, carrots, squash, or sweet potatoes that are yellow or orange inside
- **V414J** - dark green leafy vegetables
- **V414K** - mangoes, papayas, or other Vitamin A-rich fruits

A child was coded as 1 (consumed) if they ate any one of these three, and 0 if they ate none. 
I am calling this "consumption," not "adequacy," because a single day's recall 
only tells us what a child ate that one day. It can not tell us whether their 
usual diet meets a nutrient requirement.

**Vitamin A supplementation**: DHS asks mothers whether their child received 
a Vitamin A dose (usually a capsule) in the last 6 months, coded in **H34**. 
I coded this as:
- 1 (received) if the mother answered yes
- 0 (not received) if the mother answered no, or answered "don't know",
since "don't know" can not be counted as confirmed receipt, it was treated the same as no.

### Exposure Variables

**Maternal Autonomy Composite Score** - built the same way as in my earlier 
analysis, using four DHS decision-making questions (V743A, V743B, V743D, V743F), 
scored 1 (mother decides alone), 0.5 (jointly), 0 (husband or someone else decides), 
then averaged. 
Same limitation applies here as before: V743E, the question about 
who decides what food is cooked daily, was not asked in the 2024 NDHS, 
so this score shows only general household decision-making.

**ANC visits** (M14_1): number of antenatal care visits during pregnancy, 
used as a stand-in for contact with the health system. Codes 98 and 99 (don't know/missing) 
were recoded as missing.

**Other variables:** wealth quintile (V190), maternal education (V149), 
number of living children (V218), maternal age (V012), zone (V024), urban/rural residence (V025).

### Statistical Approach

Survey-weighted logistic regression using the `survey` package, accounting for 
DHS sampling design (primary sampling units, strata, and weights).

Two separate models were run, one for each pathway:

- **Model A (food pathway):** Vitamin A-rich food consumption ~ wealth + education 
                              + number of living children + zone + residence + maternal age
- **Model B (supplementation pathway):** Vitamin A supplementation ~ ANC visits 
                                         + maternal autonomy + zone + residence + maternal age

I modeled the two pathways separately, instead of combining them into one outcome, 
because they are driven by different factors. Food consumption by household resources, 
supplementation by contact with the health system. Using one model for both would blur that distinction.

## Results

### Descriptive

- 32.9% of children ate Vitamin A-rich food the day before the survey, 42.8% had received supplementation. 
  Supplementation coverage is higher, which makes sense since it is often delivered through campaigns 
  that reach a lot of children at once, rather than needing sustained dietary change.
- Putting both together: 14.7% of children got both, 18.6% got food only, 25.1% got supplementation only, 
  and **41.6% got neither, this is the largest group by far.**
- The double gap ranged from 19.8% in South South (lowest) to 51.7% in North East (highest). 
  This is about 2.6 times higher in the worst-off zone. North West was close behind at 51.5%, 
- ANC visits followed a similar north-south pattern: lowest in North West (2.9 visits on average), 
  highest in South West (10.9 visits).
- Maternal autonomy also followed this pattern: lowest in North West (0.16), highest in South South (0.49).

### Regression

**Model A: Does wealth, education, or household size predict food consumption?**

- Wealth was **not** significant at any level. This stood out because wealth 
  was the strongest predictor of dietary diversity in my earlier analysis, here, it did not matter at all.
- Education was significant and only at one level (incomplete primary, p = 0.020).
- Number of living children mattered: each additional child was linked to lower odds of the child 
  eating Vitamin A-rich food (p = 0.031).
- Maternal age: older mothers were more likely to have a child who ate Vitamin A-rich food (p < 0.001).
- Only one zone, North East, was significantly different from the reference zone (p = 0.002).

**Model B - Does ANC contact or autonomy predict supplementation?**

- ANC visits were by far the strongest predictor (p < 0.001). This makes sense since supplementation is 
  usually given during a health facility visit.
- Maternal autonomy also mattered (p = 0.036): predicted supplementation coverage rose from 26.2% 
  at the 25th percentile of autonomy to 31.1% at the 75th percentile. This is notably different 
  from my earlier analysis, where autonomy did not predict anything.
- Three zones were significantly different from the reference zone: North Central (p = 0.027), 
  South East (p < 0.001), and South South (p < 0.001).
- Urban/rural residence was also significant (p = 0.037).

## Conclusions

Wealth, which was the strongest predictor of dietary diversity in my earlier analysis, didn't matter at all here. 
Instead, household size and maternal age were what predicted whether a child ate Vitamin A-rich food. 
This suggests that for this specific food group, a mother's time and caregiving capacity might matter more than 
how much money the household has.

For supplementation, health system contact (Antenatal Care visits) was the biggest factor, 
which makes sense since it is usually delivered at a facility. What is interesting is that 
maternal autonomy mattered here, when it didn't matter anywhere in my earlier analysis. 
One possible reason: getting a supplement just requires showing up when it is offered, a single decision, 
while improving a child's daily diet needs ongoing effort and resources, which general household decision-making 
power might not be enough to change.

The main finding is the double gap: 41.6% of children get neither pathway to Vitamin A, 
and this is worst in the North East and North West. This means that in the hardest-hit zones, 
both routes to Vitamin A are failing at the same time, not just one, so interventions there may 
need to tackle both facility access and household-level dietary behavior together.

### A Note on the Anemia Finding

I initially looked at anemia (HW57) by coverage group too, since Vitamin A plays a role in immune function and blood health. 
Without adjusting for other factors, anemia looked lower among children who were supplemented (around 66%) versus those who were not (around 73%), regardless of their diet. But once I adjusted for the same factors as Models A and B, this difference was no longer significant. Because of this, I left anemia out of the final analysis and focused on the two confirmed findings above.

## Limitations

I want to be upfront about what this analysis can not tell us:

- **Same autonomy limitation as before:** V743E (who decides what food is cooked daily) was not asked in the 2024 NDHS, 
    so the autonomy score shows general household decisions, not food-specific ones.
- **Food consumption is based on a single day's recall**, not what the child usually eats, so it may not show their typical diet.
- **Supplementation is based on caregiver recall over 6 months**, which could be misremembered.
- **This is a cross-sectional study**, so none of these results can tell us what causes what.

## What I Would Do Differently

- Check whether ANC visits explain some of autonomy's effect on supplementation, in other words, whether autonomous mothers 
  just attend more ANC visits, and that is what is really driving the result.
- Try this same double-gap approach on another country's DHS data to see if the same pattern shows up elsewhere.
- Test whether autonomy matters more for mothers with low ANC access, or only for those who already have good access.

## Visualizations

All outputs are in the `/outputs` folder:

1. `gap_group_coverage.png`               - the main chart: percentage of children in each of the four coverage groups
2. `pathways_by_wealth.png`               - food consumption vs. supplementation by wealth quintile
3. `descriptive statistics table by zone` - table1_descriptive.png / table1_descriptive.html

## Repository Structure

```
nigeria-DHS2024-vitaminA-pathways/
├── .gitignore
├── README.md
├── nigeria-dhs-vitaminA-2024.Rproj
├── data/
│   └── README_data.txt
├── scripts/
│   └── vitaminA_analysis.R
└── outputs/
    ├── gap_group_coverage.png
    ├── pathways_by_wealth.png
    ├── table1_descriptive.png
    └── table1_descriptive.html
```

## How to Reproduce

1. Visit <https://dhsprogram.com> and create a free account
2. Request access to the 2024 Nigeria DHS dataset (access is usually granted within 24–48 hours)
3. Download the KR and IR Stata files and place them in the `/data` folder
4. Open `nigeria-dhs-vitaminA-2024.Rproj` in RStudio
5. Install required packages if needed: `install.packages(c("tidyverse", "haven", "janitor", "survey", 
   "ggplot2", "gtsummary", "webshot2"))`
6. Run `scripts/vitaminA_analysis.R` from top to bottom

**Important:** DHS microdata cannot be shared publicly under the DHS data access agreement. 
Raw data files are not included in this repository and must be requested directly from dhsprogram.com.

## Author

**Ideraoluwa J. Fasoranti**
Nutrition and Dietetics Graduate | Independent Researcher

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ideraoluwa-fasoranti-)
