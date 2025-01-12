# 04 fam tree /mother-offspring analysis
library(tidyverse)

# Variables for network/family tree analysis

# 1: cpshbvprox, cpshbvprox_rev--------------
# moved to end of 01_datacleaning.R

# 2: anotherpos-------------
# lives in hh with another pos moved to 01_datacleaning.R

# 3: hbvposdiroff, hasdiroff----------

# households with direct offspring
hhwdirect <- diroff %>% group_by(hrhhid,h10_hbv_rdt) %>% count()
# exposed vs unexp
table(hhwdirect$h10_hbv_rdt)

# HOW TO EVALUATE cpshbvprox ALL=2 VS NOT 
diroff2 <- diroff %>% group_by(hrhhid) %>% 
  mutate(probvacc = case_when(
    cpshbvprox==2 ~ 0, # here 0 is yes so that we can sum within households in next step and create indicator based on sum=0
    TRUE ~ 1 # at least one child prob/possibly not vacc
  ) %>% as.numeric(),
      defnotvacc = case_when(
        cpshbvprox==0 ~ 1, # here 1 is yes so we can sum across hh members and use >=1 vs 0 to make indicator 
        TRUE ~ 0 # at least one child prob/possibly IS vacc
   ) %>% as.numeric(),
  )

table(diroff2$probvacc)
table(diroff2$defnotvacc)


# diroff2 <- diroff2 %>% group_by(hrhhid) %>% summarise(allkidsvacc = sum(probvacc))
#allkidsvacc----------
diroff3 <- diroff2 %>% group_by(hrhhid) %>% summarise(allkidsvacc = ifelse(sum(probvacc)==0,1,0)) #if all kids probably vaccinated, sum will be 0 at hh level - allkidsvacc=1, else hh gets value 0
#oldestdefnotvacc-----
diroff3_pt2 <- diroff2 %>% group_by(hrhhid) %>% summarise(oldestnotvacc = ifelse(sum(defnotvacc)>0,1,0)) # sum in hh - if at least one, make indicator

table(diroff3$allkidsvacc)
table(diroff3_pt2$oldestnotvacc)


# join these indicators back on to ind and hh datasets  
inddata1 <- left_join(inddata1, diroff3[, c("hrhhid","allkidsvacc")],  by = "hrhhid")
hhdata1 <- left_join(hhdata1, diroff3[, c("hrhhid","allkidsvacc")],  by = "hrhhid")

inddata1 <- left_join(inddata1, diroff3_pt2[, c("hrhhid","oldestnotvacc")],  by = "hrhhid")
hhdata1 <- left_join(hhdata1, diroff3_pt2[, c("hrhhid","oldestnotvacc")],  by = "hrhhid")
# drop
# inddata1 <- inddata1 %>% select(-c(allkidsvacc, oldestnotvacc))
# hhdata1 <- hhdata1 %>% select(-c(allkidsvacc, oldestnotvacc))


# eval pos offspring by vacc status
diroff4 <- left_join(diroff2, diroff3[, c("hrhhid","allkidsvacc")],  by = "hrhhid")

diroffhh <- left_join(diroffhh, diroff3, by = "hrhhid")

diroff4 <- left_join(diroff4, diroffhh[, c("hrhhid","hbvposdiroff")],  by = "hrhhid")
agebypos <- diroff4 %>% group_by(h10_hbv_rdt) %>% filter(hbvposdiroff >0) %>%  summarise(hrhhid, hbvposdiroff,age_combined)


# use for direct offspring analysis

directoff <- left_join(diroff4[, c("pid","probvacc","defnotvacc")], inddata1, by = "pid")
mismatch <- directoff %>% filter(!(pid %in% diroff$pid))
directoff$cpshbvprox_rev <- 2 - directoff$cpshbvprox 

# to avoid rerunning all of the above:
directoff <- inddata1 %>% filter(hr3_relationship == 3)

# Summary of new variables:------
# cpshbvprox: 3 categories for likely vacc, poss vacc, prob vacc
# hbvposdiroff: count of HBV+ direct offspring. NAs are either no diroff (n=23) or not tested (n=3)
# hasdiroff: yes/no 1/0 does hh have direct offspring enrolled
### not added onto inddata1 in redownload March 2023
# allkidsvacc: hh level indicator for if all dir off in hh likely vacc vs no (incl poss/prob)
# oldestdefnotvacc: indicator for if hh has at least one direct offspring born before CPS had HBV vacc
addmargins(table(inddata1$allkidsvacc, inddata1$hbvposdiroff, useNA = "always"))


addmargins(table(inddata1$allkidsvacc, inddata1$h10_hbv_rdt_f, useNA = "always"))
addmargins(table(hhdata1$allkidsvacc, hhdata1$h10_hbv_rdt_f, useNA = "always"))
addmargins(table(hhdata1$oldestnotvacc, hhdata1$h10_hbv_rdt_f, useNA = "always"))
addmargins(table(hhdata1$oldestnotvacc, hhdata1$allkidsvacc, hhdata1$h10_hbv_rdt_f, useNA = "always"))

hhdata1 %>% filter(h10_hbv_rdt==1 & oldestnotvacc==1) %>% summarise(hrhhid)

# select the households that: have a pos mother, have a kid that might not have received CPS
exphh_kidnotvacc_hh <- hhdata1 %>% filter(allkidsvacc==0 & h10_hbv_rdt==1)

# households selected in fogarty: fogarty_2 per vhs.R
# remove those not in fogarty to see who has exposed but possibly not vacc kids and won't be evaled in fogarty
exphh_kidnotvacc_hh$hrhhid
exphh_kidnotvacc_hh_nofog <- exphh_kidnotvacc_hh %>% filter(!(hrhhid %in% fogarty_2$hrhhid))

exphh_kidnotvacc_hh_infog <- exphh_kidnotvacc_hh %>% filter((hrhhid %in% fogarty_2$hrhhid)) %>%  select("hrhhid")

exphh_kidnotvacc <- inddata1 %>% filter((hrhhid %in% exphh_kidnotvacc_hh_nofog$hrhhid)) %>% select("hrhhid","participant_code","hdov","h10_hbv_rdt","n","hr3_relationship_f","age_combined", "hr4_sex_f", "i27a_rdt_result_f","cpshbvprox")

table(exphh_kidnotvacc$cpshbvprox, exphh_kidnotvacc$h10_hbv_rdt)
nrow(exphh_kidnotvacc$hrhhid)

# Nov 1 calcs
addmargins(table(inddata1$cpshbvprox, inddata1$hhmemcat_f, inddata1$h10_hbv_rdt))
addmargins(table(inddata1$h10_hbv_rdt, inddata1$hhmemcat_f))
addmargins(table(inddata1$h10_hbv_rdt, inddata1$hhmemcat_f, inddata1$i27a_rdt_result_f))

addmargins(table(directoff$hr4_sex_f, directoff$h10_hbv_rdt))

addmargins(table(directoff$totalpositive, directoff$h10_hbv_rdt))

counts <- inddata1 %>% group_by(h10_hbv_rdt, hr3_relationship_f,i27a_rdt_result_f ) %>% count(directoff)

positives <- inddata1 %>% filter(i27a_rdt_result==1)
length(unique(positives$hrhhid))

table(positives$hhmemcat_f)

diroffhh <- left_join(diroffhh, hhdata1[, c("hrhhid","h10_hbv_rdt_f")],  by = "hrhhid")
addmargins(table(diroffhh$h10_hbv_rdt_f, diroffhh$allkidsvacc))

hhid_exp_kidnotvac <- diroffhh %>% filter(h10_hbv_rdt_f=="HBV+" & allkidsvacc==0)

ind_hhid_exp_kidnotvac <- inddata1 %>% filter((hrhhid %in% hhid_exp_kidnotvac$hrhhid))
table(ind_hhid_exp_kidnotvac$hhmemcat_f)
addmargins(table(ind_hhid_exp_kidnotvac$i27a_rdt_result_f,ind_hhid_exp_kidnotvac$hr3_relationship_f ))

ind_hhid_exp_kidnotvac %>% filter(hr3_relationship==3 &i27a_rdt_result==1) %>% count(hrhhid)

table(ind_hhid_exp_kidnotvac$totalpositive)#, ind_hhid_exp_kidnotvac$hrhhid)

## Nov 3 handwritten fam trees--------------
# 16 hh with another member pos (27 total)
# 10 hh with a dir off pos (8 are exposed, 2 unexposed but mother tested pos)
# 6 hh with another hh member pos (3 exposed, 3 unexposed). in these 3 exposed, one had children born before vacc, other two liekly vacc

# that covers 8+3=11 households with an infected mother. what about the other 89?
# ___ have direct off, ___ do not.
# using hhmempos created in 01_datacleaning.R
table(inddata1$hhmempos)
# give hh value if there is a hh member positive
hhtest <- inddata1 %>% group_by(hrhhid) %>% mutate(hh_hasposmemb = max(hhmempos)) %>% filter(hh_hasposmemb==1)
# select only those hh w a positive member
hhwposmembers <- hhdata1 %>% filter((hrhhid %in% hhtest$hrhhid))
# select only those hh WITHOUT a positive member
hhnoposothermembers <- hhdata1 %>% filter(!(hrhhid %in% hhtest$hrhhid))

table(hhnoposothermembers$h10_hbv_rdt)
#restrict to those exposed (index mom pos) so that we can better understand these hh
exphh_89_noinf <- hhnoposothermembers %>% filter(h10_hbv_rdt==1)
# how many have direct offspring, and within this, how many have all children born since HBV was fully rolled out (roughly 11/12 years)
addmargins(table(exphh_89_noinf$hasdiroff, exphh_89_noinf$allkidsvacc, useNA = "always"))

ind_89_expnoinf <- diroff %>% filter((hrhhid %in% exphh_89_noinf$hrhhid))

table(ind_89_expnoinf$cpshbvprox)
#given hh a value--this doesn't seem to have worked
ind_89_expnoinf <- ind_89_expnoinf %>% group_by(hrhhid) %>% mutate(cpshbvprox_hh = max(cpshbvprox))

expnotvacc <- exphh_89_noinf %>% filter(allkidsvacc==0)

expnotvacc_ind <- diroff %>% filter((hrhhid %in% expnotvacc$hrhhid))
expnotvacc_ind %>% group_by(hrhhid) %>% summarise(min(cpshbvprox))

expnotvacc_ind <- expnotvacc_ind %>% group_by(hrhhid) %>%  mutate(somenotvacc = min(cpshbvprox))
table(expnotvacc_ind$somenotvacc, useNA = "always")
expnotvacc_ind %>% group_by(somenotvacc) %>% count()
# get 9 exposed households with no one else pos, with dir off not vacc
expnotvacc_ind_0 <- expnotvacc_ind %>% filter(somenotvacc==0)

expnotvacc_hh <- exphh_89_noinf %>% filter((hrhhid %in% expnotvacc_ind_0$hrhhid)) 
# get 9 exposed hh with no one else pos, with dir off possibly not vacc
expnotvacc_ind_1 <- expnotvacc_ind %>% filter(somenotvacc==1)
expnotvacc_hh_1 <- exphh_89_noinf %>% filter((hrhhid %in% expnotvacc_ind_1$hrhhid)) 



# select the 9 households with a child unvaccinated but exposed--actually 10 including the huosehold with husband infected (1011)
expnotvacc_ind %>% group_by(hrhhid) %>% filter(min(cpshbvprox)==0) %>% summarise(hrhhid)

# Nov 10 for hover table 1--------------
addmargins(table(hhdata1$allkidsvacc, hhdata1$h10_hbv_rdt_f, useNA = "always"))


#expunvacc <- 
hhdata1 %>% filter(allkidsvacc==0 & h10_hbv_rdt==1) %>% summarise(hrhhid)
addmargins(table(hhdata1$oldestnotvacc, hhdata1$allkidsvacc))
addmargins(table(hhdata1$oldestnotvacc, hhdata1$allkidsvacc,hhdata1$h10_hbv_rdt_f ))

# households with husbands
maris <- inddata1 %>% filter(hr3_relationship == 2) %>% select("hrhhid", "pid","hdov","h10_hbv_rdt","hr3_relationship_f", "i3_hiv_pos_test_f","acq_ind","avert_indic","astmh_indic","i27a_rdt_result","i27a_rdt_result_f", 
                                                               "age_combined","cpshbvprox","serostatchange","serochangedir","i23_sex_hx_part_past3mo","i23a_sex_hx_past3mo_num","i24_sex_hx_part_past1yr","i24a_sex_hx_past1yr_num")

inddata1$i24_sex_hx_part_past1yr
  
table(maris$i3_hiv_pos_test_f)
table(maris$avert_indic,maris$h10_hbv_rdt, useNA = "always")
table(maris$serochangedir, maris$i27a_rdt_result_f)
table(maris$i3_hiv_pos_test_f,maris$i27a_rdt_result_f )
table(maris$i23_sex_hx_part_past3mo)

# verify only one in each hh
maris %>% group_by(hrhhid) %>% count() %>% print(n=Inf)


#Post-CROI--------------
# post-discussion with Marcel Tues Feb 21 - what is main story
addmargins(table(directoff$cpshbvprox)) # 0 = no vacc, 1=poss, 2=prob
addmargins(table(directoff$h10_hbv_rdt_f, directoff$cpshbvprox)) # 0 = no vacc, 1=poss, 2=prob
addmargins(table(directoff$h10_hbv_rdt_f, directoff$paststudymutexcl)) # 0 = no vacc, 1=poss, 2=prob

addmargins(table(hhdata1$h10_hbv_rdt, hhdata1$paststudymutexcl)) # 0 = no vacc, 1=poss, 2=prob

# create indicator for whether direct offspring was the pregnancy of a previous study
directoff %>% filter(paststudymutexcl == "newscreening" & age_combined <1) %>% summarise(age_combined, hdov, hrhhid)

table(inddata1$age_combined)

test <- directoff %>% 
  mutate(pregpaststudy = case_when(
    age_combined < 7 & paststudymutexcl == "acq" ~ 1, # check with marcel on these ages
    age_combined >1.5 & age_combined <5 & paststudymutexcl == "astmh only" ~ 1, #check with peyton on these numbers
    age_combined >1.5 & age_combined <5 & paststudymutexcl == "avert/astmh" ~ 1, #check with peyton on these numbers
    age_combined < 1 & paststudymutexcl == "newscreening" ~ 1, # check with patrick on these dates and ages, only 2 
    TRUE ~ 0)
    %>% as.numeric())

table(test$pregpaststudy, useNA = "always")

test$cpshbvprox
test$hbvpmtct <- NA_character_
test <- test %>% 
  mutate(hbvpmtct = case_when(
    cpshbvprox == 0 ~ "No HBV intervention",
    pregpaststudy == 1 & paststudymutexcl == "acq" ~ "TDF+penta",
    pregpaststudy == 0 & paststudymutexcl == "acq" ~ "Penta & possibly TDF", #pregnancies prior to ACQ
   
    pregpaststudy == 1 & paststudymutexcl == "astmh only" & h10_hbv_rdt==0 & hrhhid=="HRB-1029" ~ "BD+penta", # HRB-1029 was group C in Astmh (BD arm)
    pregpaststudy == 1 & paststudymutexcl == "astmh only" & h10_hbv_rdt==0 & hrhhid !="HRB-1029" ~ "Penta or BD+penta", # need to connect ACQ IDs to HOVER IDs to determine randomization group...
    # need to confirm HRB-1042 group (another kid turned pos)
    pregpaststudy == 0 & paststudymutexcl == "astmh only" & h10_hbv_rdt==0 ~ "Penta only",
    pregpaststudy == 1 & paststudymutexcl == "astmh only" & h10_hbv_rdt==1 ~ "BD+penta",
    pregpaststudy == 0 & paststudymutexcl == "astmh only" & h10_hbv_rdt==1 ~ "Penta only",
    
    pregpaststudy == 1 & paststudymutexcl == "avert/astmh"  ~ "BD+penta",
    pregpaststudy == 0 & paststudymutexcl == "avert/astmh"  ~ "Penta only",
    
    pregpaststudy == 1 & paststudymutexcl == "newscreening"  ~ "BD+penta",
    pregpaststudy == 0 & paststudymutexcl == "newscreening"  ~ "Penta only",
    
    TRUE ~ NA_character_)
  %>% as.character()
  )
addmargins(table(test$hbvpmtct, test$i27a_rdt_result_f, test$h10_hbv_rdt_f))

test %>% filter(h10_hbv_rdt==0 &i27a_rdt_result_f=="HBsAg+") %>% summarise(hrhhid,hbvpmtct )

library(tidyverse)
olderinhover <- inddata1 %>% filter(age_combined > 45)
addmargins(table(olderinhover$hr4_sex_f))

# Jim Moody talk - network analysis--------------------------------------------------------