%  =====================================================================
%  engine.pl  --  INFERENCE ENGINE
%  Dengue Triage Expert System (DengueTriage-ES)
%
%  Contains three components that are kept strictly separate from the
%  knowledge base in kb.pl:
%
%    1. Working memory          wm/2, denied/1
%    2. Forward chaining        data driven, stratified saturation
%    3. Backward chaining       goal driven, asks only what it needs
%    4. Explanation facility    HOW (proof trees) and WHY (goal stack)
%  =====================================================================

:- module(engine,
          [ reset_session/0,
            observe/1, deny/1, observed/1,
            known/1, justification/2,
            forward_chain/0, forward_chain/1,
            prove/2, prove_and_record/2,
            trace_entries/1, print_trace/0,
            explain/1, print_proof/1,
            conclusions/1, describe/2,
            set_auto_answers/1, clear_auto_answers/0 ]).

:- use_module(library(readutil)).
:- use_module(kb).

%  ---------------------------------------------------------------------
%  1. WORKING MEMORY
%  ---------------------------------------------------------------------
%  wm(Fact, Justification)
%      Justification = observed
%                    | fired(RuleId, PremiseFactsUsed)
%  denied(Fact)      the user explicitly answered "no"
%  fired_seq(Seq, RuleId, Conclusion, PremisesUsed)   firing trace
%  auto(Fact, YesNo) scripted answers, used by the test harness

:- dynamic wm/2.
:- dynamic denied/1.
:- dynamic fired_seq/4.
:- dynamic seq_counter/1.
:- dynamic auto/2.
:- dynamic auto_mode/0.
:- dynamic goal_stack/1.

reset_session :-
    retractall(wm(_,_)),
    retractall(denied(_)),
    retractall(fired_seq(_,_,_,_)),
    retractall(seq_counter(_)),
    retractall(goal_stack(_)),
    assertz(seq_counter(0)),
    assertz(goal_stack([])).

observe(Fact) :-
    (   wm(Fact, _) -> true
    ;   assertz(wm(Fact, observed)),
        retractall(denied(Fact))
    ).

deny(Fact) :-
    (   denied(Fact) -> true ; assertz(denied(Fact)) ).

observed(Fact) :- wm(Fact, observed).

known(Fact) :- wm(Fact, _).

justification(Fact, J) :- wm(Fact, J).

next_seq(N) :-
    retract(seq_counter(N0)),
    N is N0 + 1,
    assertz(seq_counter(N)).

%  ---------------------------------------------------------------------
%  2. FORWARD CHAINING  (data driven)
%
%  The knowledge base is stratified: rule/4 carries the layer a rule
%  belongs to, and every negated premise absent(X) refers only to a
%  strictly lower layer. The engine therefore saturates layer 1
%  completely, then layer 2, and so on. This guarantees that when a
%  negation is evaluated, everything it could depend on has already
%  been derived, so the fixpoint is unique and does not depend on the
%  order in which rules happen to be written.
%  ---------------------------------------------------------------------

forward_chain :- forward_chain(silent).

forward_chain(Mode) :-
    kb:max_layer(Max),
    forall(between(1, Max, Layer), saturate_layer(Layer, Mode)).

saturate_layer(Layer, Mode) :-
    (   fire_one(Layer, Mode)
    ->  saturate_layer(Layer, Mode)
    ;   true
    ).

fire_one(Layer, Mode) :-
    kb:rule(Id, Layer, Conclusion, Premises),
    \+ wm(Conclusion, _),
    premises_hold(Premises, Used),
    !,
    next_seq(N),
    assertz(wm(Conclusion, fired(Id, Used))),
    assertz(fired_seq(N, Id, Conclusion, Used)),
    (   Mode == verbose -> announce_firing(N, Id, Conclusion, Used) ; true ).

announce_firing(N, Id, Conclusion, Used) :-
    describe(Conclusion, CT),
    format('  [~w] ~w fires~n', [N, Id]),
    format('      premises : ~w~n', [Used]),
    format('      concludes: ~w~n', [CT]).

%  --- premise evaluation ----------------------------------------------
%  premises_hold(+PremiseList, -FactsActuallyUsed)

premises_hold([], []).
premises_hold([P|Ps], Used) :-
    premise_holds(P, U1),
    premises_hold(Ps, U2),
    append(U1, U2, Used).

%  A satisfied negative premise is recorded as part of the
%  justification, so the trace can show that a rule fired partly
%  because something was NOT established.
premise_holds(absent(X), [absent(X)]) :- !,
    \+ wm(X, _).
premise_holds(any_of(List), [F]) :- !,
    member(F, List),
    wm(F, _),
    !.
premise_holds(atleast(N, Class), Found) :- !,
    findall(F, (class_member(Class, F), wm(F, _)), Found),
    length(Found, K),
    K >= N.
premise_holds(Fact, [Fact]) :-
    wm(Fact, _).

class_member(Class, F) :-
    Goal =.. [Class, F],
    call(kb:Goal).

%  ---------------------------------------------------------------------
%  3. BACKWARD CHAINING  (goal driven)
%
%  prove(+Goal, -Proof) tries to establish Goal. Where a goal is a
%  primitive observation the engine asks the user for it, and only
%  then, which is the behaviour that distinguishes backward from
%  forward chaining. Proof is a tree the explanation facility prints.
%  ---------------------------------------------------------------------

prove(Goal, Proof) :-
    push_goal(Goal),
    catch(prove_(Goal, Proof), E, (pop_goal, throw(E))),
    pop_goal.

prove_(absent(G), node(absent(G), negation, [])) :- !,
    \+ prove_quiet(G).
prove_(any_of(List), node(any_of(List), disjunction, [Sub])) :- !,
    member(G, List),
    prove(G, Sub),
    !.
%  Counting stops as soon as N members are established, so a goal
%  driven session never asks for the sixth criterion once the second
%  has already been confirmed.
prove_(atleast(N, Class), node(atleast(N, Class), counting, Subs)) :- !,
    findall(F, class_member(Class, F), Fs),
    collect_atleast(Fs, N, [], Subs).
prove_(Goal, node(Goal, observed, [])) :-
    wm(Goal, observed), !.
prove_(Goal, node(Goal, fired(Id), [])) :-
    wm(Goal, fired(Id, _)), !.
prove_(Goal, node(Goal, asked, [])) :-
    kb:askable(Goal, _, _), !,
    ask_user(Goal),
    wm(Goal, _).
prove_(Goal, node(Goal, rule(Id), Subs)) :-
    kb:rule(Id, _Layer, Goal, Premises),
    prove_list(Premises, Subs),
    record_derived(Goal, Id, Premises).

prove_list([], []).
prove_list([P|Ps], [S|Ss]) :-
    prove(P, S),
    prove_list(Ps, Ss).

collect_atleast(_, 0, Acc, Subs) :- !, reverse(Acc, Subs).
collect_atleast([], N, _, _) :- N > 0, !, fail.
collect_atleast([F|Fs], N, Acc, Subs) :-
    (   prove(F, S)
    ->  N1 is N - 1, collect_atleast(Fs, N1, [S|Acc], Subs)
    ;   collect_atleast(Fs, N, Acc, Subs)
    ).

prove_quiet(G) :- prove(G, _).

record_derived(Goal, Id, Premises) :-
    (   wm(Goal, _)
    ->  true
    ;   next_seq(N),
        assertz(wm(Goal, fired(Id, Premises))),
        assertz(fired_seq(N, Id, Goal, Premises))
    ).

prove_and_record(Goal, Proof) :- prove(Goal, Proof).

%  --- asking the user -------------------------------------------------

ask_user(Fact) :-
    wm(Fact, _), !.
ask_user(Fact) :-
    denied(Fact), !, fail.
ask_user(Fact) :-
    auto_mode, !,
    (   auto(Fact, yes) -> observe(Fact) ; deny(Fact), fail ).
ask_user(Fact) :-
    kb:askable(Fact, Question, _),
    repeat,
    format('~n  ? ~w~n', [Question]),
    format('    [y = yes, n = no, w = why am I being asked this]~n    > '),
    read_line_to_string(user_input, Raw),
    normalise(Raw, Ans),
    (   Ans == "y"  -> observe(Fact), !
    ;   Ans == "n"  -> deny(Fact), !, fail
    ;   Ans == "w"  -> explain_why, fail
    ;   format('    Please answer y, n or w.~n'), fail
    ).

normalise(Raw, Ans) :-
    (   Raw == end_of_file -> Ans = "n"
    ;   string_lower(Raw, L), normalize_space(string(Ans), L)
    ).

%  --- WHY: show the goal the engine is currently pursuing -------------

push_goal(G) :-
    retract(goal_stack(S)),
    assertz(goal_stack([G|S])).

pop_goal :-
    retract(goal_stack(S)),
    (   S = [_|R] -> assertz(goal_stack(R)) ; assertz(goal_stack([])) ).

explain_why :-
    goal_stack(Stack),
    format('~n    WHY: I am working backwards through these goals.~n'),
    reverse(Stack, Chain),
    why_chain(Chain, 0),
    format('~n').

why_chain([], _).
why_chain([G|Gs], D) :-
    tab(4), tab(D),
    describe(G, T),
    (   D =:= 0
    ->  format('Top goal: ~w~n', [T])
    ;   format('needed for the above: ~w~n', [T])
    ),
    D1 is D + 2,
    why_chain(Gs, D1).

%  ---------------------------------------------------------------------
%  4. EXPLANATION FACILITY
%  ---------------------------------------------------------------------

%  --- the numbered firing trace ---------------------------------------

trace_entries(Es) :-
    findall(e(N, Id, C, P), fired_seq(N, Id, C, P), Es0),
    sort(1, @=<, Es0, Es).

print_trace :-
    trace_entries(Es),
    (   Es == []
    ->  format('  (no rule fired)~n')
    ;   forall(member(e(N, Id, C, Used), Es), print_trace_entry(N, Id, C, Used))
    ).

print_trace_entry(N, Id, C, Used) :-
    describe(C, CT),
    format('~n  Step ~w   rule ~w~n', [N, Id]),
    format('    IF    '),
    print_premises(Used),
    format('    THEN  ~w~n', [CT]),
    (   kb:source(Id, Doc, Locator)
    ->  format('    src   [~w] ~w~n', [Doc, Locator])
    ;   true
    ).

print_premises([]) :- format('(no premises)~n').
print_premises([P]) :- !, describe(P, T), format('~w~n', [T]).
print_premises([P|Ps]) :-
    describe(P, T), format('~w~n', [T]),
    forall(member(Q, Ps), (describe(Q, QT), format('          AND ~w~n', [QT]))).

%  --- HOW: a proof tree rebuilt from working memory -------------------

explain(Fact) :-
    (   wm(Fact, _)
    ->  build_tree(Fact, Tree), print_proof(Tree)
    ;   describe(Fact, T),
        format('  ~w was not established in this session.~n', [T])
    ).

build_tree(Fact, node(Fact, observed, [])) :-
    wm(Fact, observed), !.
build_tree(Fact, node(Fact, rule(Id), Subs)) :-
    wm(Fact, fired(Id, Used)), !,
    findall(S, (member(U, Used), build_subtree(U, S)), Subs).
build_tree(Fact, node(Fact, unknown, [])).

build_subtree(absent(X), node(absent(X), negation, [])) :- !.
build_subtree(U, S) :- build_tree(U, S).

print_proof(Tree) :- print_node(Tree, 2).

print_node(node(Goal, Why, Subs), Indent) :-
    tab(Indent),
    describe(Goal, T),
    (   Why = rule(Id)
    ->  format('~w   <- rule ~w~n', [T, Id]),
        (   kb:source(Id, Doc, Loc)
        ->  I2 is Indent + 4, tab(I2), format('[~w] ~w~n', [Doc, Loc])
        ;   true )
    ;   Why == observed
    ->  format('~w   (observed)~n', [T])
    ;   Why == negation
    ->  format('~w   (could not be established, so taken as false)~n', [T])
    ;   Why == asked
    ->  format('~w   (answered by the user)~n', [T])
    ;   Why == disjunction
    ->  format('~w   (one alternative sufficed)~n', [T])
    ;   Why == counting
    ->  format('~w   (counted)~n', [T])
    ;   format('~w~n', [T])
    ),
    I is Indent + 4,
    forall(member(S, Subs), print_node(S, I)).

%  --- the conclusions the session reached -----------------------------

conclusions(Cs) :-
    findall(C,
            ( member(C, [classification(_), management_group(_),
                         critical_phase_onset, discharge_ready,
                         avoid_nsaids, daily_review]),
              wm(C, _) ),
            Cs).

%  --- turning an internal term into readable English ------------------

describe(absent(X), T) :- !,
    describe(X, T0),
    format(atom(T), 'NOT established: ~w', [T0]).
describe(any_of(L), T) :- !,
    findall(D, (member(X, L), describe(X, D)), Ds),
    atomic_list_concat(Ds, ', or ', Joined),
    format(atom(T), 'any one of: ~w', [Joined]).
describe(atleast(N, C), T) :- !,
    ( kb:label(class(C), CT) -> true ; CT = C ),
    format(atom(T), 'at least ~w of the ~w', [N, CT]).
describe(X, T) :- kb:label(X, T), !.
describe(X, T) :- kb:askable(X, Q, _), !, T = Q.
describe(X, T) :- term_to_atom(X, T).

%  ---------------------------------------------------------------------
%  5. SCRIPTED ANSWERS (used by tests.pl)
%  ---------------------------------------------------------------------

set_auto_answers(Yeses) :-
    retractall(auto(_,_)),
    forall(member(F, Yeses), assertz(auto(F, yes))),
    (   auto_mode -> true ; assertz(auto_mode) ).

clear_auto_answers :-
    retractall(auto(_,_)),
    retractall(auto_mode).
