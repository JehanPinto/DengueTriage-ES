%  =====================================================================
%  ui.pl  --  USER INTERFACE (command line)
%  Dengue Triage Expert System (DengueTriage-ES)
%  =====================================================================

:- module(ui, [ start/0 ]).

:- use_module(kb).
:- use_module(engine).
:- use_module(scenarios).
:- use_module(tests).

%  ---------------------------------------------------------------------
%  Small printing helpers
%  ---------------------------------------------------------------------

rule_line    :- format('~`-t~72|~n').
double_line  :- format('~`=t~72|~n').

heading(T) :-
    nl, double_line,
    format('  ~w~n', [T]),
    double_line.

read_choice(S) :-
    read_line_to_string(user_input, Raw),
    (   Raw == end_of_file
    ->  S = "0"
    ;   string_lower(Raw, L), normalize_space(string(S), L)
    ).

%  ---------------------------------------------------------------------
%  Entry point
%  ---------------------------------------------------------------------

start :-
    banner,
    main_loop.

banner :-
    nl, double_line,
    format('   DengueTriage-ES~n'),
    format('   An expert system for the clinical triage of suspected dengue~n'),
    rule_line,
    format('   Knowledge base : WHO (2009) Dengue: Guidelines for Diagnosis,~n'),
    format('                    Treatment, Prevention and Control --~n'),
    format('                    Figure 1.4 and Chapter 2~n'),
    format('   Rules          : 35      Facts : 25 static + 42 askable~n'),
    rule_line,
    format('   FOR TEACHING AND ASSESSMENT ONLY. This program is not a~n'),
    format('   medical device and must not be used to treat a real patient.~n'),
    double_line.

main_loop :-
    nl,
    format('  MAIN MENU~n'),
    rule_line,
    format('   1  New consultation  (forward chaining, data driven)~n'),
    format('   2  New consultation  (backward chaining, goal driven)~n'),
    format('   3  Run a built-in scenario~n'),
    format('   4  Show the reasoning trace of the last consultation~n'),
    format('   5  Explain a conclusion  (HOW was it reached?)~n'),
    format('   6  Browse the knowledge base~n'),
    format('   7  Run the automated test suite~n'),
    format('   8  Help~n'),
    format('   0  Quit~n'),
    rule_line,
    format('  > '),
    read_choice(C),
    (   C == "0"
    ->  format('~n  Goodbye.~n~n')
    ;   dispatch(C),
        main_loop
    ).

dispatch("1") :- !, consult_forward.
dispatch("2") :- !, consult_backward.
dispatch("3") :- !, scenario_menu.
dispatch("4") :- !, show_trace.
dispatch("5") :- !, explain_menu.
dispatch("6") :- !, browse_menu.
dispatch("7") :- !, tests:run_all.
dispatch("8") :- !, help.
dispatch(_)   :- format('~n  Not a menu option.~n').

%  ---------------------------------------------------------------------
%  1. FORWARD CHAINING CONSULTATION
%
%  All observations are collected first, then the engine runs to a
%  fixpoint. This is data driven inference: the facts push the
%  reasoning forward and every conclusion the data supports is drawn.
%  ---------------------------------------------------------------------

consult_forward :-
    heading('NEW CONSULTATION -- FORWARD CHAINING'),
    engine:reset_session,
    engine:clear_auto_answers,
    format('  Answer each question with y or n. Press Enter alone for no.~n'),
    format('  Type s to skip the rest of a section (all answers taken as no).~n'),
    kb:group_order(Groups),
    forall(member(G, Groups), ask_group(G)),
    heading('INFERENCE -- rules firing in order'),
    engine:forward_chain(verbose),
    report.

ask_group(Group) :-
    kb:question_group(Group, Title),
    nl, rule_line,
    format('  ~w~n', [Title]),
    rule_line,
    findall(F, kb:askable(F, _, Group), Fs),
    ask_each(Fs).

ask_each([]).
ask_each([F|Fs]) :-
    kb:askable(F, Q, _),
    format('  ~w~n  [y/n/s] > ', [Q]),
    read_choice(A),
    (   A == "y" -> engine:observe(F), ask_each(Fs)
    ;   A == "s" -> forall(member(X, [F|Fs]), engine:deny(X))
    ;   engine:deny(F), ask_each(Fs)
    ).

%  ---------------------------------------------------------------------
%  2. BACKWARD CHAINING CONSULTATION
%
%  The engine starts from a hypothesis and asks only the questions it
%  actually needs in order to prove or refute it. Typing w at any
%  question makes the engine explain why it is asking.
%  ---------------------------------------------------------------------

consult_backward :-
    heading('NEW CONSULTATION -- BACKWARD CHAINING'),
    engine:reset_session,
    engine:clear_auto_answers,
    format('  Choose the hypothesis to test:~n'),
    rule_line,
    format('   1  Does this patient have SEVERE DENGUE?~n'),
    format('   2  Does this patient have DENGUE WITH WARNING SIGNS?~n'),
    format('   3  Can this patient be managed at home (GROUP A)?~n'),
    format('   4  Does this patient need in-hospital care (GROUP B)?~n'),
    format('   5  Does this patient meet the DISCHARGE criteria?~n'),
    rule_line,
    format('  > '),
    read_choice(C),
    ( bc_goal(C, Goal) -> pursue(Goal) ; format('~n  Not a menu option.~n') ).

bc_goal("1", severe_dengue).
bc_goal("2", classification(dengue_with_warning_signs)).
bc_goal("3", management_group(a)).
bc_goal("4", management_group(b)).
bc_goal("5", discharge_ready).

pursue(Goal) :-
    engine:describe(Goal, T),
    nl, format('  Goal: ~w~n', [T]),
    format('  I will ask only the questions I need. Type w for why.~n'),
    (   engine:prove(Goal, Proof)
    ->  heading('RESULT -- THE GOAL IS PROVED'),
        format('  Proved: ~w~n~n', [T]),
        format('  Proof tree:~n~n'),
        engine:print_proof(Proof),
        nl,
        show_advice_for(Goal)
    ;   heading('RESULT -- THE GOAL IS NOT PROVED'),
        format('  On the answers given, ~w could not be established.~n', [T]),
        format('  Note that this is negation as failure: it means the~n'),
        format('  knowledge base contains no rule whose premises are~n'),
        format('  satisfied, not that the condition is medically excluded.~n')
    ).

%  ---------------------------------------------------------------------
%  3. BUILT-IN SCENARIOS
%  ---------------------------------------------------------------------

scenario_menu :-
    heading('BUILT-IN SCENARIOS'),
    findall(Id-T, scenarios:scenario(Id, T, _, _), Ss),
    forall(member(Id-T, Ss), format('   ~w  ~w~n', [Id, T])),
    rule_line,
    format('  Enter a scenario id (for example t04), or b to go back~n  > '),
    read_choice(C),
    (   C == "b"
    ->  true
    ;   atom_string(Id, C),
        (   scenarios:scenario(Id, _, _, _)
        ->  run_scenario(Id)
        ;   format('~n  No such scenario.~n')
        )
    ).

run_scenario(Id) :-
    scenarios:scenario(Id, Title, Facts, _Expected),
    heading('SCENARIO'),
    format('  ~w  ~w~n', [Id, Title]),
    nl, format('  Observations entered into working memory:~n'),
    forall(member(F, Facts),
           ( engine:describe(F, T), format('    - ~w~n', [T]) )),
    engine:reset_session,
    engine:clear_auto_answers,
    forall(member(F, Facts), engine:observe(F)),
    heading('INFERENCE -- rules firing in order'),
    engine:forward_chain(verbose),
    report.

%  ---------------------------------------------------------------------
%  REPORTING THE OUTCOME
%  ---------------------------------------------------------------------

report :-
    heading('CONCLUSION'),
    (   engine:known(classification(C))
    ->  kb:label(classification(C), CL),
        format('  Case classification : ~w~n', [CL])
    ;   format('  Case classification : none could be derived~n')
    ),
    (   engine:known(management_group(G))
    ->  kb:label(management_group(G), GL),
        format('  Management group    : ~w~n', [GL])
    ;   format('  Management group    : none (the case definition is not met)~n')
    ),
    nl,
    engine:conclusions(Cs),
    format('  Everything the system concluded:~n'),
    forall(member(X, Cs),
           ( engine:describe(X, T), format('    - ~w~n', [T]) )),
    nl,
    format('  RECOMMENDED ACTION~n'),
    rule_line,
    forall(member(X, Cs), print_advice(X)),
    nl,
    heading('REASONING -- how this conclusion was reached'),
    engine:print_trace,
    nl,
    format('  Use menu option 5 to see the proof tree for any single~n'),
    format('  conclusion, and option 4 to see this trace again.~n').

print_advice(X) :-
    (   kb:advice(X, As)
    ->  engine:describe(X, T),
        format('~n  Because ~w:~n', [T]),
        forall(member(A, As), format('    * ~w~n', [A]))
    ;   true
    ).

show_advice_for(Goal) :-
    (   kb:advice(Goal, As)
    ->  format('  Recommended action:~n'),
        forall(member(A, As), format('    * ~w~n', [A]))
    ;   true
    ).

%  ---------------------------------------------------------------------
%  4 and 5. TRACE AND EXPLANATION
%  ---------------------------------------------------------------------

show_trace :-
    heading('REASONING TRACE OF THE LAST CONSULTATION'),
    engine:print_trace.

explain_menu :-
    heading('EXPLAIN A CONCLUSION'),
    engine:conclusions(Cs),
    (   Cs == []
    ->  format('  Nothing has been concluded yet. Run a consultation first.~n')
    ;   number_list(Cs, 1, Numbered),
        forall(member(N-X, Numbered),
               ( engine:describe(X, T), format('   ~w  ~w~n', [N, T]) )),
        rule_line,
        format('  Enter a number > '),
        read_choice(S),
        (   number_string(N, S), member(N-Fact, Numbered)
        ->  nl, format('  HOW was this reached?~n~n'),
            engine:explain(Fact)
        ;   format('~n  Not a valid number.~n')
        )
    ).

number_list([], _, []).
number_list([X|Xs], N, [N-X|R]) :-
    N1 is N + 1,
    number_list(Xs, N1, R).

%  ---------------------------------------------------------------------
%  6. BROWSING THE KNOWLEDGE BASE
%  ---------------------------------------------------------------------

browse_menu :-
    heading('BROWSE THE KNOWLEDGE BASE'),
    format('   1  All rules with their sources~n'),
    format('   2  Static facts~n'),
    format('   3  Askable facts (the questions)~n'),
    format('   4  Source documents~n'),
    rule_line,
    format('  > '),
    read_choice(C),
    browse(C).

browse("1") :- !,
    nl,
    forall(kb:rule(Id, L, C, Ps),
           ( engine:describe(C, CT),
             format('~n  ~w   (layer ~w)~n', [Id, L]),
             format('    IF   ~w~n', [Ps]),
             format('    THEN ~w~n', [CT]),
             (  kb:source(Id, D, Loc)
             -> format('    SRC  [~w] ~w~n', [D, Loc]) ; true )
           )).
browse("2") :- !,
    nl,
    show_class('Probable-dengue criteria', dengue_criterion),
    show_class('Warning signs', warning_sign),
    show_class('Co-existing conditions', coexisting_condition),
    show_class('Social circumstances', social_circumstance),
    show_class('Severe organ signs', severe_organ_sign).
browse("3") :- !,
    nl,
    kb:group_order(Gs),
    forall(member(G, Gs),
           ( kb:question_group(G, T),
             format('~n  ~w~n', [T]),
             forall(kb:askable(F, Q, G), format('    ~w~n       ~w~n', [F, Q]))
           )).
browse("4") :- !,
    nl,
    forall(kb:doc(Tag, Full), format('  [~w]~n    ~w~n~n', [Tag, Full])).
browse(_) :- format('~n  Not a menu option.~n').

show_class(Title, Pred) :-
    format('~n  ~w~n', [Title]),
    Goal =.. [Pred, X],
    forall(call(kb:Goal), format('    - ~w~n', [X])).

%  ---------------------------------------------------------------------
%  8. HELP
%  ---------------------------------------------------------------------

help :-
    heading('HELP'),
    format('  WHAT THIS SYSTEM DOES~n'),
    format('    It takes the clinical findings of a patient with suspected~n'),
    format('    dengue and returns three things: the WHO case classification,~n'),
    format('    the WHO management group (A, B or C), and the reasoning that~n'),
    format('    led to them, rule by rule, with the guideline page each rule~n'),
    format('    came from.~n~n'),
    format('  FORWARD versus BACKWARD CHAINING~n'),
    format('    Option 1 collects every observation first and then lets the~n'),
    format('    data drive the rules forward to every conclusion they support.~n'),
    format('    Option 2 starts from a hypothesis and asks only the questions~n'),
    format('    needed to settle it, so you will usually answer far fewer~n'),
    format('    questions. Both use the same rules in kb.pl.~n~n'),
    format('  EXPLANATION~n'),
    format('    WHY  : type w at any question in a backward chaining session~n'),
    format('           to see the chain of goals that made the engine ask it.~n'),
    format('    HOW  : menu option 5 prints the proof tree of a conclusion,~n'),
    format('           with the guideline citation at every step.~n').
