%  =====================================================================
%  scenarios.pl  --  TEST SCENARIOS
%  Dengue Triage Expert System (DengueTriage-ES)
%
%  scenario(Id, Title, ObservedFacts, ExpectedConclusions)
%
%  Every fact not listed is taken to be absent (the user answered no).
%  These scenarios drive both the demonstration mode of the user
%  interface and the automated test suite in tests.pl.
%  =====================================================================

:- module(scenarios, [ scenario/4 ]).

scenario(t01,
  'Classic dengue, no warning signs, fit for home care',
  [ endemic_exposure, fever, nausea_vomiting, rash, aches_pains,
    tolerates_oral_fluids, passes_urine_6h, stable_haematocrit ],
  [ classification(dengue_without_warning_signs), management_group(a) ]).

scenario(t02,
  'Dengue with warning signs: abdominal pain and persistent vomiting',
  [ endemic_exposure, fever, nausea_vomiting, aches_pains,
    abdominal_pain, persistent_vomiting,
    tolerates_oral_fluids, passes_urine_6h ],
  [ classification(dengue_with_warning_signs), management_group(b) ]).

scenario(t03,
  'Dengue without warning signs in a pregnant patient',
  [ endemic_exposure, fever, rash, aches_pains, pregnancy,
    tolerates_oral_fluids, passes_urine_6h, stable_haematocrit ],
  [ classification(dengue_without_warning_signs), management_group(b) ]).

scenario(t04,
  'Dengue shock syndrome: narrow pulse pressure and poor perfusion',
  [ endemic_exposure, fever, nausea_vomiting, aches_pains,
    abdominal_pain, narrow_pulse_pressure, poor_perfusion ],
  [ classification(severe_dengue), management_group(c) ]).

scenario(t05,
  'Severe dengue by severe organ impairment: AST or ALT at or above 1000',
  [ endemic_exposure, fever, aches_pains, nausea_vomiting,
    lethargy_restlessness, ast_alt_ge_1000 ],
  [ classification(severe_dengue), management_group(c) ]).

scenario(t06,
  'Laboratory-confirmed dengue with severe bleeding',
  [ endemic_exposure, fever, lab_confirmed,
    mucosal_bleeding, overt_bleeding_unstable ],
  [ classification(severe_dengue), management_group(c) ]).

scenario(t07,
  'Febrile patient who does not meet the dengue case definition',
  [ endemic_exposure, fever, rash ],
  [ classification(dengue_not_established) ]).

scenario(t08,
  'Laboratory-confirmed dengue in a patient who lives alone',
  [ endemic_exposure, fever, lab_confirmed, lives_alone,
    tolerates_oral_fluids, passes_urine_6h, stable_haematocrit ],
  [ classification(dengue_without_warning_signs), management_group(b) ]).

scenario(t09,
  'Laboratory warning sign: rising haematocrit with falling platelets',
  [ endemic_exposure, fever, aches_pains, leukopenia,
    hct_rising, platelet_dropping,
    tolerates_oral_fluids, passes_urine_6h ],
  [ lab_warning, warning_sign_present,
    classification(dengue_with_warning_signs), management_group(b) ]).

scenario(t10,
  'Recovering inpatient assessed against the discharge criteria',
  [ endemic_exposure, fever, lab_confirmed,
    afebrile_48h, clinical_improvement, platelet_rising,
    stable_haematocrit, tolerates_oral_fluids, passes_urine_6h ],
  [ discharge_ready, classification(dengue_without_warning_signs) ]).

scenario(t11,
  'Dengue without warning signs but unable to tolerate oral fluids',
  [ endemic_exposure, fever, nausea_vomiting, aches_pains,
    passes_urine_6h, stable_haematocrit ],
  [ classification(dengue_without_warning_signs), management_group(b) ]).

scenario(t12,
  'Onset of the critical phase at defervescence',
  [ endemic_exposure, fever, aches_pains, nausea_vomiting,
    defervescence, day_of_illness_3_7, hct_rising, platelet_dropping,
    tolerates_oral_fluids, passes_urine_6h ],
  [ critical_phase_onset, classification(dengue_with_warning_signs),
    management_group(b) ]).
