# crcbase-karlbom_sep2020

## Included sas programs

### 1. Inclusion criteria
__scrcr_ltol_
- 2007:2016
- diagage o18
- curative_proc eq 1 (a2_kurativ_v_rde, curative procedure)
- stage 1-3 or cm eq 0 (cm eq cM stage). stage from cm, ct, cp
- TODO Bowel resection (procedure_type eq 3)

__exclusion__:

- Cancer recurrence (relapse eq 1) (from 6 months of date variables relapse_loc_date or repalse_mets_date)

### 2. Datasets

#### crd_clean 
for population only

#### surgeries 
all IPR rows with op codes specified [alot of codes, J, L, P chapers]
nrow 8000k

Used to identify: 
- stoma closure IPR ONLY (op=JFG00, JFG10, JFG20, JFG23, JFG29, JFG26,JFG30, JFG33, JFG36) 


#### relapse_pr 
first occurrence of ("C784" "C785" "C786" "C787") in patreg after diagdate_scrcr

#### ileus
All IPR rows (before and after crc diagnosis) indication either: 

 - ileus ("K565" "K566" "K567") 
 - ab_pain (R10.0, R10.3, R10.4)
 - ab_hernia (K40.0, K40.3, K41.0, K41.3, K42.0, K43.0, K43.3, K43.6, K44.0, K45.0, K46.0)

__Are the ops required?__ array DX $ hdia dia1-dia30; _op_=JFG00, JFG10, JFG20, JFG23, JFG29, JFG26,JFG30, JFG33, JFG36
 

#### cci
Charlson comorbidity index

__Created in crcbase-karlbom/1_create_data.R__

- migrations (specified in varaibles. Needed for censoring?). Contains all migrations after diagdate_scrcr

## Variables
### Exposure 

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

### Results
- SBO, frequency and time to 
- SBO-surgery, frequency and time to
- Validation, proportion with SBO and SBO-surgery in three time periods (6-18 months, 18-41 months, 41-66 months)
- Other SBO mechanism

