rep(A, F, T, R) :- atomic_list_concat(P, F, A), atomic_list_concat(P, T, R).

esc(In, Out) :-
    atom_string(In, S), atom_string(A, S),
    rep(A, '&', '&amp;', A1),
    rep(A1, '<', '&lt;', A2),
    rep(A2, '>', '&gt;', Out).

%  HTML rows for the rule-to-source annex table.
genhtml :-
    forall(kb:rule(Id, L, C, Ps),
      ( engine:describe(C, CT0), esc(CT0, CT),
        findall(PT, (member(P, Ps), engine:describe(P, PT0), esc(PT0, PT)), PTs),
        atomic_list_concat(PTs, '<br><span class="op">AND</span> ', Body),
        ( kb:source(Id, D, Loc0) -> esc(Loc0, Loc) ; D = '?', Loc = '?' ),
        format('<tr><td class="rid">~w</td><td class="lyr">~w</td><td class="rbody"><span class="op">IF</span> ~w<br><span class="op">THEN</span> <b>~w</b></td><td class="src"><span class="tag">~w</span> ~w</td></tr>~n',
               [Id, L, Body, CT, D, Loc])
      )).

%  HTML rows for the compact Annex A table: Rule | IF | THEN | Source.
%  The source column keeps the section and page and drops the quotation;
%  the full quotation stays in kb.pl, which Annex B reproduces.
ref_number('WHO2009', 3).

%  Plain-English forms of the negated premises, for display only. The
%  rules in kb.pl still use absent/1, shown verbatim in Annex B.
neg_text(warning_sign_present,  'no warning sign').
neg_text(severe_dengue,         'NOT severe dengue').
neg_text(dengue_case,           'the dengue case definition is NOT met').
neg_text(coexisting_risk,       'no co-existing condition').
neg_text(social_risk,           'no adverse social circumstance').
neg_text(tolerates_oral_fluids, 'the patient CANNOT tolerate adequate oral fluids').
neg_text(passes_urine_6h,       'the patient does NOT pass urine at least once every six hours').

premise_text(absent(X), T) :- neg_text(X, T), !.
premise_text(absent(X), T) :- !,
    engine:describe(X, T0), format(atom(T), 'NOT ~w', [T0]).
premise_text(P, T) :- engine:describe(P, T).

short_locator(Loc, Short) :-
    (   sub_atom(Loc, B, _, _, ' -- ') -> sub_atom(Loc, 0, B, _, Short)
    ;   Short = Loc
    ).

genannex :-
    forall(kb:rule(Id, _L, C, Ps),
      ( upcase_atom(Id, UId),
        findall(PT, ( member(P, Ps), premise_text(P, PT0), esc(PT0, PT1),
                      rep(PT1, ' -- ', ' &ndash; ', PT) ), PTs),
        atomic_list_concat(PTs, ' <b>AND</b> ', IfPart),
        engine:describe(C, CT0), rep(CT0, ' -- ', ' &ndash; ', CT1), esc_keep(CT1, CT),
        kb:source(Id, Doc, Loc), ref_number(Doc, N),
        short_locator(Loc, Short0), esc(Short0, Short),
        format('<tr><td class="c">~w</td><td>~w</td><td>~w</td><td>[~w] ~w</td></tr>~n',
               [UId, IfPart, CT, N, Short])
      )).

%  Escape < and > but leave an entity already inserted intact.
esc_keep(In, Out) :-
    rep(In, '<', '&lt;', A1),
    rep(A1, '>', '&gt;', Out).

%  HTML rows for the askable-facts annex table.
genaskhtml :-
    kb:group_order(Gs),
    forall(member(G, Gs),
      ( kb:question_group(G, T0), esc(T0, T),
        format('<tr class="grp"><td colspan="2">~w</td></tr>~n', [T]),
        forall(kb:askable(F, Q0, G),
               ( esc(Q0, Q),
                 format('<tr><td class="rid">~w</td><td>~w</td></tr>~n', [F, Q]) ))
      )).

%  HTML rows for the static-facts annex table.
genfactshtml :-
    forall(member(Cls, [dengue_criterion, warning_sign, coexisting_condition,
                        social_circumstance, severe_organ_sign]),
      ( ( kb:label(class(Cls), CN0) -> true ; CN0 = Cls ), esc(CN0, CN),
        findall(FT, (G =.. [Cls, X], call(kb:G), esc(X, FT)), Fs),
        atomic_list_concat(Fs, ', ', Joined),
        format('<tr><td class="rid">~w</td><td>~w</td></tr>~n', [CN, Joined])
      )).
