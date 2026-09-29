%  =====================================================================
%  kb.pl  --  KNOWLEDGE BASE
%  Dengue Triage Expert System (DengueTriage-ES)
%
%  All clinical knowledge in this file is transcribed from published
%  clinical guidelines. No rule was invented by the developers.
%  Every rule carries a source/3 fact naming the document and page.
%  See docs/SOURCES.md and Annex A of the report for full citations.
%  =====================================================================

:- module(kb, [ askable/3, question_group/2, group_order/1,
                dengue_criterion/1, warning_sign/1,
                coexisting_condition/1, social_circumstance/1,
                severe_organ_sign/1,
                rule/4, source/3, doc/2, label/2, advice/2, max_layer/1 ]).

%  Each rule is written immediately above the source/3 fact that cites
%  the guideline it came from, so the two predicates interleave on
%  purpose. This keeps a rule and its provenance impossible to separate.
:- discontiguous rule/4.
:- discontiguous source/3.

%  ---------------------------------------------------------------------
%  SECTION 1 -- SOURCE REGISTRY
%  ---------------------------------------------------------------------

doc('WHO2009',   'WHO (2009) Dengue: Guidelines for Diagnosis, Treatment, Prevention and Control, New Edition. WHO/HTM/NTD/DEN/2009.1').
doc('SLMoH2012', 'Ministry of Health Sri Lanka with the Ceylon College of Physicians (Nov 2012) National Guidelines on Management of Dengue Fever and Dengue Haemorrhagic Fever in Adults, revised and expanded edition').
doc('CDC2024',   'US Centers for Disease Control and Prevention, Clinical Features of Dengue and Guidelines for Classifying Dengue').

%  ---------------------------------------------------------------------
%  SECTION 2 -- STATIC FACTS (the vocabulary of the domain)
%  ---------------------------------------------------------------------

%  F01-F06 : the six probable-dengue criteria   [WHO2009 Fig 1.4, p.11]
dengue_criterion(nausea_vomiting).
dengue_criterion(rash).
dengue_criterion(aches_pains).
dengue_criterion(tourniquet_positive).
dengue_criterion(leukopenia).
dengue_criterion(warning_sign_present).

%  F07-F13 : the seven WHO warning signs        [WHO2009 Fig 1.4, p.11]
warning_sign(abdominal_pain).
warning_sign(persistent_vomiting).
warning_sign(fluid_accumulation).
warning_sign(mucosal_bleeding).
warning_sign(lethargy_restlessness).
warning_sign(liver_enlargement).
warning_sign(lab_warning).

%  F14-F20 : co-existing conditions needing in-hospital care
%                                               [WHO2009 s.2.3.2.2, p.34]
coexisting_condition(pregnancy).
coexisting_condition(infancy).
coexisting_condition(old_age).
coexisting_condition(obesity).
coexisting_condition(diabetes_mellitus).
coexisting_condition(renal_failure).
coexisting_condition(chronic_haemolytic_disease).

%  F21-F22 : social circumstances needing in-hospital care
%                                               [WHO2009 s.2.3.2.2, p.34]
social_circumstance(lives_alone).
social_circumstance(lives_far_from_facility).

%  F23-F25 : severe organ involvement           [WHO2009 Fig 1.4, p.11]
severe_organ_sign(ast_alt_ge_1000).
severe_organ_sign(impaired_consciousness).
severe_organ_sign(heart_impairment).

%  ---------------------------------------------------------------------
%  SECTION 3 -- ASKABLE FACTS (primitive observations)
%      askable(Fact, QuestionText, Group)
%  ---------------------------------------------------------------------

group_order([exposure, criteria, warning, severe, host, intake, phase, discharge]).

question_group(exposure,  'A. Exposure and fever').
question_group(criteria,  'B. Probable-dengue criteria').
question_group(warning,   'C. Warning signs').
question_group(severe,    'D. Signs of severe dengue').
question_group(host,      'E. Co-existing conditions and social circumstances').
question_group(intake,    'F. Oral intake, urine output, haematocrit').
question_group(phase,     'G. Phase of illness').
question_group(discharge, 'H. Discharge assessment').

askable(endemic_exposure, 'Does the patient live in, or has travelled in the last 14 days to, a dengue-endemic area?', exposure).
askable(fever,            'Does the patient have fever, or a history of fever in this illness?', exposure).
askable(lab_confirmed,    'Is there a positive laboratory test for dengue (NS1 antigen, IgM or RT-PCR)?', exposure).

askable(nausea_vomiting,     'Nausea or vomiting?', criteria).
askable(rash,                'Rash?', criteria).
askable(aches_pains,         'Aches and pains (headache, retro-orbital pain, myalgia, arthralgia)?', criteria).
askable(tourniquet_positive, 'Is the tourniquet test positive?', criteria).
askable(leukopenia,          'Leukopenia (low total white cell count)?', criteria).

askable(abdominal_pain,        'Abdominal pain or tenderness?', warning).
askable(persistent_vomiting,   'Persistent vomiting?', warning).
askable(fluid_accumulation,    'Clinical fluid accumulation (pleural effusion or ascites)?', warning).
askable(mucosal_bleeding,      'Mucosal bleeding (gums, nose, vaginal or gastrointestinal)?', warning).
askable(lethargy_restlessness, 'Lethargy or restlessness?', warning).
askable(liver_enlargement,     'Liver enlargement greater than 2 cm?', warning).
askable(hct_rising,            'Is the haematocrit rising?', warning).
askable(platelet_dropping,     'Is the platelet count falling rapidly?', warning).

askable(narrow_pulse_pressure,        'Is the pulse pressure 20 mmHg or less?', severe).
askable(poor_perfusion,               'Signs of poor capillary perfusion (cold extremities, delayed capillary refill or rapid pulse)?', severe).
askable(hypotension,                  'Is the patient hypotensive (systolic blood pressure has fallen)?', severe).
askable(respiratory_distress,         'Respiratory distress?', severe).
askable(overt_bleeding_unstable,      'Persistent or severe overt bleeding with unstable haemodynamic status?', severe).
askable(hct_drop_after_resuscitation, 'Has the haematocrit fallen after fluid resuscitation while the patient remains haemodynamically unstable?', severe).
askable(ast_alt_ge_1000,              'Is AST or ALT 1000 IU/L or above?', severe).
askable(impaired_consciousness,       'Impaired consciousness?', severe).
askable(heart_impairment,             'Impairment of the heart or other organs?', severe).

askable(pregnancy,                  'Is the patient pregnant?', host).
askable(infancy,                    'Is the patient an infant?', host).
askable(old_age,                    'Is the patient elderly?', host).
askable(obesity,                    'Is the patient obese?', host).
askable(diabetes_mellitus,          'Diabetes mellitus?', host).
askable(renal_failure,              'Renal failure?', host).
askable(chronic_haemolytic_disease, 'Chronic haemolytic disease (for example thalassaemia)?', host).
askable(lives_alone,                'Does the patient live alone?', host).
askable(lives_far_from_facility,    'Does the patient live far from a health facility without reliable transport?', host).

askable(tolerates_oral_fluids, 'Can the patient tolerate adequate volumes of oral fluids?', intake).
askable(passes_urine_6h,       'Does the patient pass urine at least once every six hours?', intake).
askable(stable_haematocrit,    'Is the haematocrit stable?', intake).

askable(defervescence,      'Has the temperature dropped to 37.5 C or below and stayed there (defervescence)?', phase).
askable(day_of_illness_3_7, 'Is this day 3 to 7 of the illness?', phase).

askable(afebrile_48h,         'Has the patient been free of fever for 48 hours?', discharge).
askable(clinical_improvement, 'Is there improvement in well-being, appetite, haemodynamic status and urine output, with no respiratory distress?', discharge).
askable(platelet_rising,      'Is the platelet count showing an increasing trend?', discharge).

%  ---------------------------------------------------------------------
%  SECTION 4 -- PRODUCTION RULES
%
%      rule(RuleId, Layer, Conclusion, PremiseList)
%
%  Layer is the stratum of the rule. The forward chainer saturates
%  layer N completely before it starts layer N+1. Because every
%  negated premise absent(X) refers only to a strictly lower layer,
%  the knowledge base is a stratified logic program and the fixpoint
%  it reaches is unique and independent of rule ordering.
%
%  Premise forms understood by the engine (see engine.pl):
%      Atom            -- the fact must be established
%      absent(Atom)    -- the fact must NOT be established
%      any_of(List)    -- at least one member established
%      atleast(N,Cls)  -- at least N members of class Cls established
%  ---------------------------------------------------------------------

max_layer(6).

%  --- Layer 1 : composite observations -------------------------------

%  R01  Laboratory warning sign: rising HCT with falling platelets.
rule(r01, 1, lab_warning,
     [ hct_rising, platelet_dropping ]).
source(r01, 'WHO2009', 'Figure 1.4, p.11 -- warning signs: "Laboratory: increase in HCT concurrent with rapid decrease in platelet count"').

%  R02  Any of the seven warning signs is present.
rule(r02, 1, warning_sign_present,
     [ any_of([abdominal_pain, persistent_vomiting, fluid_accumulation,
               mucosal_bleeding, lethargy_restlessness, liver_enlargement,
               lab_warning]) ]).
source(r02, 'WHO2009', 'Figure 1.4, p.11 -- the seven warning signs').

%  R03  Shock recognised by a narrow pulse pressure.
rule(r03, 1, shock,
     [ narrow_pulse_pressure ]).
source(r03, 'WHO2009', 's.2.1.4, p.28 -- "The patient is considered to have shock if the pulse pressure ... is <= 20 mm Hg"').

%  R04  Shock recognised by poor capillary perfusion.
rule(r04, 1, shock,
     [ poor_perfusion ]).
source(r04, 'WHO2009', 's.2.1.4, p.28 -- "or he/she has signs of poor capillary perfusion (cold extremities, delayed capillary refill, or rapid pulse rate)"').

%  R05  Presence of at least one co-existing risk condition.
rule(r05, 1, coexisting_risk,
     [ any_of([pregnancy, infancy, old_age, obesity, diabetes_mellitus,
               renal_failure, chronic_haemolytic_disease]) ]).
source(r05, 'WHO2009', 's.2.3.2.2, p.34 -- "co-existing conditions that may make dengue or its management more complicated (such as pregnancy, infancy, old age, obesity, diabetes mellitus, renal failure, chronic haemolytic diseases)"').

%  R06  Presence of a social circumstance that prevents safe home care.
rule(r06, 1, social_risk,
     [ any_of([lives_alone, lives_far_from_facility]) ]).
source(r06, 'WHO2009', 's.2.3.2.2, p.34 -- "certain social circumstances (such as living alone, or living far from a health facility without reliable means of transport)"').

%  R07  Laboratory confirmation of dengue.
rule(r07, 1, confirmed_dengue,
     [ lab_confirmed ]).
source(r07, 'WHO2009', 'Figure 1.4, p.11 -- "Laboratory-confirmed dengue"').

%  --- Layer 2 : case definition and severe criteria ------------------

%  R08  Probable dengue.
rule(r08, 2, probable_dengue,
     [ endemic_exposure, fever, atleast(2, dengue_criterion) ]).
source(r08, 'WHO2009', 'Figure 1.4, p.11 -- "Probable dengue: live in / travel to dengue endemic area. Fever and 2 of the following criteria: Nausea, vomiting; Rash; Aches and pains; Tourniquet test positive; Leukopenia; Any warning sign"').

%  R09  Severe plasma leakage leading to shock.
rule(r09, 2, severe_plasma_leakage,
     [ shock ]).
source(r09, 'WHO2009', 'Figure 1.4, p.11 -- "Severe plasma leakage leading to: Shock (DSS)"').

%  R10  Severe plasma leakage: fluid accumulation with respiratory distress.
rule(r10, 2, severe_plasma_leakage,
     [ fluid_accumulation, respiratory_distress ]).
source(r10, 'WHO2009', 'Figure 1.4, p.11 -- "Fluid accumulation with respiratory distress"').

%  R11  Severe bleeding: overt bleeding with unstable haemodynamics.
rule(r11, 2, severe_bleeding,
     [ overt_bleeding_unstable ]).
source(r11, 'WHO2009', 's.2.3.3, p.41 -- "persistent and/or severe overt bleeding in the presence of unstable haemodynamic status, regardless of the haematocrit level"').

%  R12  Severe bleeding: HCT falls after resuscitation, patient unstable.
rule(r12, 2, severe_bleeding,
     [ hct_drop_after_resuscitation ]).
source(r12, 'WHO2009', 's.2.3.3, p.41 -- "a decrease in haematocrit after fluid resuscitation together with unstable haemodynamic status"').

%  R13  Severe organ impairment: liver.
rule(r13, 2, severe_organ_impairment,
     [ ast_alt_ge_1000 ]).
source(r13, 'WHO2009', 'Figure 1.4, p.11 -- "Severe organ involvement: Liver: AST or ALT >= 1000"').

%  R14  Severe organ impairment: central nervous system.
rule(r14, 2, severe_organ_impairment,
     [ impaired_consciousness ]).
source(r14, 'WHO2009', 'Figure 1.4, p.11 -- "CNS: Impaired consciousness"').

%  R15  Severe organ impairment: heart and other organs.
rule(r15, 2, severe_organ_impairment,
     [ heart_impairment ]).
source(r15, 'WHO2009', 'Figure 1.4, p.11 -- "Heart and other organs"').

%  R16  Onset of the critical phase.
rule(r16, 2, critical_phase_onset,
     [ defervescence, day_of_illness_3_7, hct_rising ]).
source(r16, 'WHO2009', 's.2.1.2, p.26 -- "Around the time of defervescence ... usually on days 3-7 of illness, an increase in capillary permeability in parallel with increasing haematocrit levels may occur. This marks the beginning of the critical phase"').

%  --- Layer 3 : the dengue case ---------------------------------------

%  R17  A probable case is a dengue case.
rule(r17, 3, dengue_case,
     [ probable_dengue ]).
source(r17, 'WHO2009', 'Figure 1.4, p.11 -- probable dengue enters the case classification').

%  R18  A laboratory-confirmed case is a dengue case.
rule(r18, 3, dengue_case,
     [ confirmed_dengue ]).
source(r18, 'WHO2009', 'Figure 1.4, p.11 -- "Laboratory-confirmed dengue (important when no sign of plasma leakage)"').

%  --- Layer 4 : severity ----------------------------------------------

%  R19  Severe dengue by severe plasma leakage.
rule(r19, 4, severe_dengue,
     [ dengue_case, severe_plasma_leakage ]).
source(r19, 'WHO2009', 's.2.1.4, p.27 -- "Severe dengue is defined by one or more of the following: (i) plasma leakage that may lead to shock (dengue shock) and/or fluid accumulation, with or without respiratory distress"').

%  R20  Severe dengue by severe bleeding.
rule(r20, 4, severe_dengue,
     [ dengue_case, severe_bleeding ]).
source(r20, 'WHO2009', 's.2.1.4, p.27 -- "and/or (ii) severe bleeding"').

%  R21  Severe dengue by severe organ impairment.
rule(r21, 4, severe_dengue,
     [ dengue_case, severe_organ_impairment ]).
source(r21, 'WHO2009', 's.2.1.4, p.27 -- "and/or (iii) severe organ impairment"').

%  --- Layer 5 : case classification -----------------------------------

%  R22  Classification: severe dengue.
rule(r22, 5, classification(severe_dengue),
     [ severe_dengue ]).
source(r22, 'WHO2009', 'Figure 1.4, p.11 -- third classification band "SEVERE DENGUE"').

%  R23  Classification: dengue with warning signs.
rule(r23, 5, classification(dengue_with_warning_signs),
     [ dengue_case, warning_sign_present, absent(severe_dengue) ]).
source(r23, 'WHO2009', 'Figure 1.4, p.11 -- "DENGUE with warning signs"').

%  R24  Classification: dengue without warning signs.
rule(r24, 5, classification(dengue_without_warning_signs),
     [ dengue_case, absent(warning_sign_present), absent(severe_dengue) ]).
source(r24, 'WHO2009', 'Figure 1.4, p.11 -- "DENGUE without warning signs"').

%  R25  Not classifiable as dengue on the information supplied.
rule(r25, 5, classification(dengue_not_established),
     [ absent(dengue_case) ]).
source(r25, 'WHO2009', 'Figure 1.4, p.11 -- the case definition is not met, so no dengue classification can be assigned').

%  --- Layer 6 : management group and advice ---------------------------

%  R26  Group C -- emergency treatment and urgent referral.
rule(r26, 6, management_group(c),
     [ severe_dengue ]).
source(r26, 'WHO2009', 's.2.3.2.3, p.35 -- "Group C - patients who require emergency treatment and urgent referral when they have severe dengue"').

%  R27  Group B -- warning signs present.
rule(r27, 6, management_group(b),
     [ classification(dengue_with_warning_signs) ]).
source(r27, 'WHO2009', 's.2.3.2.2, p.34 -- "These include patients with warning signs"').

%  R28  Group B -- co-existing condition.
rule(r28, 6, management_group(b),
     [ dengue_case, coexisting_risk, absent(severe_dengue) ]).
source(r28, 'WHO2009', 's.2.3.2.2, p.34 -- "those with co-existing conditions that may make dengue or its management more complicated"').

%  R29  Group B -- social circumstances.
rule(r29, 6, management_group(b),
     [ dengue_case, social_risk, absent(severe_dengue) ]).
source(r29, 'WHO2009', 's.2.3.2.2, p.34 -- "and those with certain social circumstances"').

%  R30  Group B -- cannot tolerate oral fluids.
rule(r30, 6, management_group(b),
     [ dengue_case, absent(tolerates_oral_fluids), absent(severe_dengue) ]).
source(r30, 'WHO2009', 's.2.3.2.1, p.33 -- Group A is restricted to "patients who are able to tolerate adequate volumes of oral fluids", so a patient who cannot must be managed in hospital').

%  R31  Group B -- inadequate urine output.
rule(r31, 6, management_group(b),
     [ dengue_case, absent(passes_urine_6h), absent(severe_dengue) ]).
source(r31, 'WHO2009', 's.2.3.2.1, p.33 -- Group A is restricted to patients who "pass urine at least once every six hours"').

%  R32  Group A -- may be managed at home.
rule(r32, 6, management_group(a),
     [ classification(dengue_without_warning_signs),
       tolerates_oral_fluids, passes_urine_6h, stable_haematocrit,
       absent(coexisting_risk), absent(social_risk) ]).
source(r32, 'WHO2009', 's.2.3.2.1, p.33 -- "These are patients who are able to tolerate adequate volumes of oral fluids and pass urine at least once every six hours, and do not have any of the warning signs ... Those with stable haematocrit can be sent home"').

%  R33  Fit for discharge.
rule(r33, 6, discharge_ready,
     [ afebrile_48h, clinical_improvement, platelet_rising, stable_haematocrit ]).
source(r33, 'WHO2009', 'Textbox F, p.48 -- "Discharge criteria (all of the following conditions must be present): No fever for 48 hours. Improvement in clinical status ... Increasing trend of platelet count. Stable haematocrit without intravenous fluids"').

%  R34  Avoid NSAIDs in any dengue case.
rule(r34, 6, avoid_nsaids,
     [ dengue_case ]).
source(r34, 'WHO2009', 's.2.3.2.1, p.34 -- "Do not give acetylsalicylic acid (aspirin), ibuprofen or other non-steroidal anti-inflammatory agents (NSAIDs) as these drugs may aggravate gastritis or bleeding"').

%  R35  Daily review while ambulatory.
rule(r35, 6, daily_review,
     [ management_group(a) ]).
source(r35, 'WHO2009', 's.2.3.2.1, p.34 -- "Ambulatory patients should be reviewed daily for disease progression ... until they are out of the critical period"').

%  ---------------------------------------------------------------------
%  SECTION 5 -- ADVICE ATTACHED TO CONCLUSIONS
%  ---------------------------------------------------------------------

advice(management_group(a),
       [ 'Manage at home. Issue the WHO home care card.',
         'Encourage oral rehydration solution, fruit juice and other fluids with electrolytes and sugar.',
         'Paracetamol for high fever, at intervals of not less than six hours; tepid sponging.',
         'Return to hospital immediately if there is no clinical improvement, deterioration around defervescence, severe abdominal pain, persistent vomiting, cold clammy extremities, lethargy or restlessness, bleeding, or no urine for 4 to 6 hours.' ]).

advice(management_group(b),
       [ 'Refer for in-hospital management and close observation through the critical phase.',
         'If warning signs are present: obtain a reference haematocrit, then give isotonic fluid (0.9% saline, Ringer lactate or Hartmann solution) at 5 to 7 ml/kg/hour for 1 to 2 hours, reduce to 3 to 5 ml/kg/hour for 2 to 4 hours, then 2 to 3 ml/kg/hour or less by clinical response.',
         'Monitor vital signs and peripheral perfusion 1 to 4 hourly, urine output 4 to 6 hourly, and haematocrit before and after fluid replacement then 6 to 12 hourly.' ]).

advice(management_group(c),
       [ 'EMERGENCY. Admit to a hospital with intensive care and blood transfusion facilities, and refer urgently.',
         'Begin judicious intravenous resuscitation with isotonic crystalloid; use colloid in hypotensive shock.',
         'Obtain haematocrit before and after fluid resuscitation where possible.',
         'Transfuse as soon as severe bleeding is suspected; do not wait for the haematocrit to fall.' ]).

advice(discharge_ready,
       [ 'All four discharge criteria are met; the patient may be discharged.' ]).

advice(avoid_nsaids,
       [ 'Do not give aspirin, mefenamic acid, ibuprofen, other NSAIDs or steroids. Antibiotics are not indicated.' ]).

advice(daily_review,
       [ 'Review daily for white cell count, defervescence and warning signs until out of the critical period.' ]).

advice(critical_phase_onset,
       [ 'The critical phase has begun. Significant plasma leakage usually lasts 24 to 48 hours; monitor intensively throughout.' ]).

%  ---------------------------------------------------------------------
%  SECTION 6 -- HUMAN-READABLE LABELS
%  ---------------------------------------------------------------------

label(classification(severe_dengue),                  'SEVERE DENGUE').
label(classification(dengue_with_warning_signs),      'DENGUE WITH WARNING SIGNS').
label(classification(dengue_without_warning_signs),   'DENGUE WITHOUT WARNING SIGNS').
label(classification(dengue_not_established),         'DENGUE CASE DEFINITION NOT MET').
label(management_group(a), 'GROUP A -- may be managed at home').
label(management_group(b), 'GROUP B -- refer for in-hospital management').
label(management_group(c), 'GROUP C -- requires emergency treatment and urgent referral').
label(dengue_case,             'the dengue case definition is met').
label(probable_dengue,         'probable dengue').
label(confirmed_dengue,        'laboratory-confirmed dengue').
label(warning_sign_present,    'at least one warning sign is present').
label(lab_warning,             'rising haematocrit with falling platelet count').
label(shock,                   'shock').
label(severe_plasma_leakage,   'severe plasma leakage').
label(severe_bleeding,         'severe bleeding').
label(severe_organ_impairment, 'severe organ impairment').
label(severe_dengue,           'severe dengue').
label(coexisting_risk,         'a co-existing condition is present').
label(social_risk,             'social circumstances prevent safe home care').
label(critical_phase_onset,    'the critical phase has begun').
label(discharge_ready,         'the patient meets the discharge criteria').
label(avoid_nsaids,            'NSAIDs and aspirin must be avoided').
label(daily_review,            'daily ambulatory review is required').

%  Names of the fact classes, used when a rule counts members of one.
label(class(dengue_criterion),      'probable-dengue criteria').
label(class(warning_sign),          'WHO warning signs').
label(class(coexisting_condition),  'co-existing conditions').
label(class(social_circumstance),   'social circumstances').
label(class(severe_organ_sign),     'signs of severe organ involvement').

%  Declarative forms of the askable facts. The askable/3 text is a
%  question and is used when the engine interrogates the user; these
%  labels are the same facts stated as assertions, which is what a
%  rule trace and a proof tree need.
label(endemic_exposure,             'lives in or has travelled to a dengue-endemic area').
label(fever,                        'fever').
label(lab_confirmed,                'a positive dengue laboratory test').
label(nausea_vomiting,              'nausea or vomiting').
label(rash,                         'rash').
label(aches_pains,                  'aches and pains').
label(tourniquet_positive,          'a positive tourniquet test').
label(leukopenia,                   'leukopenia').
label(abdominal_pain,               'abdominal pain or tenderness').
label(persistent_vomiting,          'persistent vomiting').
label(fluid_accumulation,           'clinical fluid accumulation').
label(mucosal_bleeding,             'mucosal bleeding').
label(lethargy_restlessness,        'lethargy or restlessness').
label(liver_enlargement,            'liver enlargement greater than 2 cm').
label(hct_rising,                   'a rising haematocrit').
label(platelet_dropping,            'a rapidly falling platelet count').
label(narrow_pulse_pressure,        'a pulse pressure of 20 mmHg or less').
label(poor_perfusion,               'signs of poor capillary perfusion').
label(hypotension,                  'hypotension').
label(respiratory_distress,         'respiratory distress').
label(overt_bleeding_unstable,      'severe overt bleeding with unstable haemodynamic status').
label(hct_drop_after_resuscitation, 'a falling haematocrit after fluid resuscitation with continuing instability').
label(ast_alt_ge_1000,              'AST or ALT of 1000 IU/L or above').
label(impaired_consciousness,       'impaired consciousness').
label(heart_impairment,             'impairment of the heart or other organs').
label(pregnancy,                    'pregnancy').
label(infancy,                      'infancy').
label(old_age,                      'old age').
label(obesity,                      'obesity').
label(diabetes_mellitus,            'diabetes mellitus').
label(renal_failure,                'renal failure').
label(chronic_haemolytic_disease,   'chronic haemolytic disease').
label(lives_alone,                  'the patient lives alone').
label(lives_far_from_facility,      'the patient lives far from a health facility without reliable transport').
label(tolerates_oral_fluids,        'the patient tolerates adequate volumes of oral fluids').
label(passes_urine_6h,              'the patient passes urine at least once every six hours').
label(stable_haematocrit,           'a stable haematocrit').
label(defervescence,                'defervescence').
label(day_of_illness_3_7,           'day 3 to 7 of the illness').
label(afebrile_48h,                 'no fever for 48 hours').
label(clinical_improvement,         'improvement in clinical status').
label(platelet_rising,              'an increasing trend of platelet count').
