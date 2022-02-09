# crcbase-karlbom_sep2020

# TODOS

1. Add comparators in sas program _DONE_
2. Cancer reg: Colorectal cancers before index date (diagdate) Colorectal cancers before index date (diagdate). _DONE_
   - Add to exclusion criteria [C18, c19, c20] _DONE_
3. cannot find a2_blodn, in scrcr
4. add all code that start with J to seperate file `previous_abd_surgeries` _DONE_
5. a2_optyp2 -> surgery_type coding (currently 1-11)
6. relapse_pr have 0 rows. _DONE_
   -add to cencoring factors
7. add birthdate to be able to calculate age at proceduredate(index date) _bd not available_
8. Add cci to ad
9. Add education
10. perop_bleed
11. bmi_cat
12. convert to truethy

# Questions

1. SBO mechanisms:
   Should hernia be assessed in between exposure and outcome (SBO only or surgery also) _asuming same time as SBO_

2. Should time to SBO surgery be assessed from SBO or from exposure (procedure date)?

3. When should stoma closure be assessed?

4. Should abdominal pain be assessed both at baseline and as secondary outcome?

5. aim: surgery -> SBO

   - exposed only, descriptive [incidence and timing] and validation[ppv] of scrcr,
   - relative risk to comparators (patreg data only)

6. Should minimal surgery be the exposure instead of surgery?

7. Secondary outcomes?

   - abpain?
   - stoma closure?

8. There are relapses occurring before index date when using the patient register. How should they be handled?

9. Can `u0_besoksdate` be used as date for multiple events?
   Currently used for:
   - sbo_scrcr_date
   - sbo_surgery
   -

- sbo_surgery_date
  -o

10. Cause specific risks?

# Aim

incidence, timing and risk factors for SBO after colorectal cancer surgery
surgery -> SBO
risk factors (exposure variables?) -> surgery

### 1. Inclusion criteria

_scrcr_ltol_

- diagdate_scrcr 2007:2016
- diagage >= 18
- curative_proc == 1 (a2_kurativ_v_rde, curative procedure)
- stage in 1-3 or cm == 0 (cm == cM stage). Stage derived from cm, ct, cp
- TODO Bowel resection (procedure_type eq 3)

**exclusion**:

- Cancer recurrence (relapse eq 1) (from 6 months of date variables relapse_loc_date or repalse_mets_date)

### 2. Datasets

#### a. created in _uk_20210609.sas_

All datasets contain the population only.

##### crd_clean

for population only

##### surgeries

all IPR rows with op codes specified [alot of codes, J, L, P chapers]
nrow 8000k

Used to identify

- stoma closure IPR ONLY (op=JFG00, JFG10, JFG20, JFG23, JFG29, JFG26,JFG30, JFG33, JFG36)

##### relapse_pr

first occurrence of ("C784" "C785" "C786" "C787") in patreg after diagdate_scrcr

##### ileus

All IPR rows (before and after crc diagnosis) indication either:

- ileus ("K565" "K566" "K567")
- ab_pain (R10.0, R10.3, R10.4)
- ab_hernia (K40.0, K40.3, K41.0, K41.3, K42.0, K43.0, K43.3, K43.6, K44.0, K45.0, K46.0)

**Are the ops required?** array DX $ hdia dia1-dia30; _op_=JFG00, JFG10, JFG20, JFG23, JFG29, JFG26,JFG30, JFG33, JFG36

#### cci

Charlson comorbidity index

#### b. Created in crcbase-karlbom/1_create_data.R\_\_

##### migrations

specified in varaibles. Needed for censoring?.
Contains all migrations (immigrations and emigrations) after diagdate_scrcr

## Variables

### Start of follow up

date of cancer surgery (a2_opdat = proceduredate)

### Time since proceduredate

Three time periods (6-18 months, 18-41 months, 41-66 months)

### Exposure

cancer surgery -> incidence SBO

### Outcomes

1. SBO (small bowel obstruction) after colorectal resection (proceduredate)

- u4_ileus_v_rde=1 (u0_besoksdatum for date sbo)
- dia k56.5-7 (indatum for date sbo)

2. SBO-surgery

- u5_ileus_reop_v_rde eq 1 (u0_besoksdatum for date sbo surgery)
- alt1 k56.5-7 plus op=JAP00, JAP01, JFK00, JFK01, JFK10, JFK20, JFK96, JFK97
- alt2 k56.5-7 plus op= JAP00, JAP01, JFB00, JFB01, JFB10, JFB13, JFB20, JFB21,
  JFB96, JFB97, JFC00, JFC01, JFC10, JFC11, JFC20, JFC21,
  JFF10, JFF11, JFF13, JFK00, JFK01, JFK10, JFK20, JFK96, JFK97

## Results

- SBO, frequency and time to
- SBO-surgery, frequency and time to
- Validation, proportion with SBO and SBO-surgery in three time periods (6-18 months, 18-41 months, 41-66 months) comparing _scrcr_ to _patreg_
- Other SBO mechanism
- risk factors (with comparators)

### Table 1

Tidigare bukoperation = Hur många har en operationskod som börjar på J från IPR at baseline (från 1997)
Tidigare SBO (from 1997)
