%  =====================================================================
%  tests.pl  --  AUTOMATED TEST SUITE
%  Dengue Triage Expert System (DengueTriage-ES)
%
%  run_all/0   runs every scenario through the forward chainer, then
%              repeats a subset through the backward chainer, and
%              finally checks that the explanation facility produces
%              a proof for each conclusion it claims.
%  =====================================================================

:- module(tests, [ run_all/0, run_forward_tests/0, run_backward_tests/0,
                   run_explanation_tests/0 ]).

:- use_module(kb).
:- use_module(engine).
:- use_module(scenarios).

line   :- format('~`-t~72|~n').
dline  :- format('~`=t~72|~n').

run_all :-
    nl, dline,
    format('  AUTOMATED TEST SUITE~n'),
    dline,
    run_forward_tests,
    run_backward_tests,
    run_explanation_tests,
    nl.

%  ---------------------------------------------------------------------
%  A. FORWARD CHAINING TESTS
%  ---------------------------------------------------------------------

run_forward_tests :-
    nl, format('  A. FORWARD CHAINING -- classification and management group~n'),
    line,
    findall(Id, scenarios:scenario(Id, _, _, _), Ids),
    foldl(run_forward_test, Ids, 0-0, Pass-Fail),
    line,
    format('  forward chaining: ~w passed, ~w failed~n', [Pass, Fail]).

run_forward_test(Id, P0-F0, P-F) :-
    scenarios:scenario(Id, Title, Facts, Expected),
    engine:reset_session,
    engine:clear_auto_answers,
    forall(member(X, Facts), engine:observe(X)),
    engine:forward_chain(silent),
    findall(E, (member(E, Expected), \+ engine:known(E)), Missing),
    derived_facts(Derived),
    actual_conclusions(Reported),
    fired_rule_ids(Rules),
    (   Missing == []
    ->  P is P0 + 1, F = F0, Verdict = 'PASS'
    ;   P = P0, F is F0 + 1, Verdict = 'FAIL'
    ),
    nl,
    format('  ~w  ~w~n', [Id, Title]),
    format('      expected : ~w~n', [Expected]),
    format('      derived  : ~w~n', [Derived]),
    format('      reported : ~w~n', [Reported]),
    format('      rules    : ~w~n', [Rules]),
    (   Missing \== []
    ->  format('      MISSING  : ~w~n', [Missing])
    ;   true
    ),
    format('      result   : ~w~n', [Verdict]).

actual_conclusions(Cs) :- engine:conclusions(Cs).

%  Every fact the engine inferred, as opposed to the facts it was told.
derived_facts(Fs) :-
    engine:trace_entries(Es),
    findall(C, member(e(_, _, C, _), Es), Fs).

fired_rule_ids(Ids) :-
    engine:trace_entries(Es),
    findall(Id, member(e(_, Id, _, _), Es), Ids).

%  ---------------------------------------------------------------------
%  B. BACKWARD CHAINING TESTS
%
%  The same scenarios are replayed, but the engine is now given a goal
%  and must ask for what it needs. set_auto_answers/1 supplies the
%  answers, so a scenario's fact list becomes its answer script.
%  A backward test states both goals that must be proved and goals
%  that must NOT be provable.
%  ---------------------------------------------------------------------

bc_test(b01, t04, severe_dengue,                              proved).
bc_test(b02, t01, severe_dengue,                              not_proved).
bc_test(b03, t02, classification(dengue_with_warning_signs),  proved).
bc_test(b04, t01, management_group(a),                        proved).
bc_test(b05, t03, management_group(a),                        not_proved).
bc_test(b06, t03, management_group(b),                        proved).
bc_test(b07, t10, discharge_ready,                            proved).
bc_test(b08, t07, dengue_case,                                not_proved).

run_backward_tests :-
    nl, format('  B. BACKWARD CHAINING -- goal driven proof~n'),
    line,
    findall(Id, bc_test(Id, _, _, _), Ids),
    foldl(run_backward_test, Ids, 0-0, Pass-Fail),
    line,
    format('  backward chaining: ~w passed, ~w failed~n', [Pass, Fail]).

run_backward_test(Id, P0-F0, P-F) :-
    bc_test(Id, ScenarioId, Goal, Want),
    scenarios:scenario(ScenarioId, _, Facts, _),
    engine:reset_session,
    engine:set_auto_answers(Facts),
    (   engine:prove(Goal, _) ->  Got = proved ; Got = not_proved ),
    engine:clear_auto_answers,
    (   Got == Want
    ->  P is P0 + 1, F = F0, Verdict = 'PASS'
    ;   P = P0, F is F0 + 1, Verdict = 'FAIL'
    ),
    format('  ~w  goal ~w on scenario ~w~n', [Id, Goal, ScenarioId]),
    format('      expected ~w, got ~w  ->  ~w~n', [Want, Got, Verdict]).

%  ---------------------------------------------------------------------
%  C. EXPLANATION TESTS
%
%  For every scenario, every conclusion the system reports must have a
%  justification in working memory, and every rule in the firing trace
%  must carry a source citation. A conclusion the system cannot
%  explain, or a rule with no cited source, is a defect.
%  ---------------------------------------------------------------------

run_explanation_tests :-
    nl, format('  C. EXPLANATION -- every conclusion is justified and cited~n'),
    line,
    findall(Id, scenarios:scenario(Id, _, _, _), Ids),
    foldl(run_explanation_test, Ids, 0-0, Pass-Fail),
    check_all_rules_cited(CiteVerdict),
    line,
    format('  explanation: ~w passed, ~w failed~n', [Pass, Fail]),
    format('  every rule in the knowledge base carries a source: ~w~n', [CiteVerdict]).

run_explanation_test(Id, P0-F0, P-F) :-
    scenarios:scenario(Id, _, Facts, _),
    engine:reset_session,
    engine:clear_auto_answers,
    forall(member(X, Facts), engine:observe(X)),
    engine:forward_chain(silent),
    engine:conclusions(Cs),
    findall(C, (member(C, Cs), \+ engine:justification(C, _)), Unjustified),
    engine:trace_entries(Es),
    findall(RId, (member(e(_, RId, _, _), Es), \+ kb:source(RId, _, _)), Uncited),
    (   Unjustified == [], Uncited == []
    ->  P is P0 + 1, F = F0, Verdict = 'PASS'
    ;   P = P0, F is F0 + 1, Verdict = 'FAIL'
    ),
    format('  ~w  ~w conclusions, ~w unjustified, ~w uncited rules  ->  ~w~n',
           [Id, Cs, Unjustified, Uncited, Verdict]).

check_all_rules_cited(Verdict) :-
    findall(Id, (kb:rule(Id, _, _, _), \+ kb:source(Id, _, _)), Missing),
    (   Missing == [] -> Verdict = 'YES' ; Verdict = Missing ).
