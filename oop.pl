%%% --------------------------------------------------
%%% Class predicates

:- dynamic class/4.     %%% represents the class object
:- dynamic icache/2.    %%% represents fields that every isntance should have

def_class(Cname, Parents, Parts) :-
    atom(Cname),
    \+ class(Cname, _, _, _),
    class_list(Parents),
    parse_class(Parts, Fields, Methods),
    % get_superfields(Parents, [], SuperFields),  %%% remove to disable instance fields caching
    % append(Fields, SuperFields, InstFields),    %%% remove to disable instance fields caching
    % list_to_set(InstFields, InstFieldsSet),     %%% remove to disable instance fields caching
    % assertz(icache(Cname, InstFieldsSet)),      %%% remove to disable instance fields caching
    assertz(class(Cname, Parents, Fields, Methods)).

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _, _).


%%% --------------------------------------------------
%%% Class helper predicates

%%% if a field or method is defined multiple time, only the first one will be considered
parse_class([Part | Parts], [Part | Fields], Methods) :- 
    Part = field(Name, Value, Type),
    !,
    atom(Name),
    call(Type, Value),
    parse_class(Parts, Fields, Methods).

parse_class([Part | Parts], Fields, Methods) :-
    Part = field(Name, Value),
    parse_class([field(Name, Value, atom) | Parts], Fields, Methods).

parse_class([Part | Parts], Fields, [Part | Methods]) :- 
    Part = method(Name, Args, Body),
    atom(Name),
    var_list(Args),
    callable(Body),
    append([Name, This], Args, SignList),
    Sign =.. SignList,
    Rule = (Sign :- get_method(Sign, X), Sign =.. [_, This | _], patch_body(X, This, Y), call(Y)),
    assert(Rule),
    parse_class(Parts, Fields, Methods).

parse_class([], [], []).


%%% unused
/* get_superfields([Parent | Parents], CurrentFields, FieldsAcc) :-
    icache(Parent, ParentFields),
    append(CurrentFields, ParentFields, NextFields),
    get_superfields(Parents, NextFields, FieldsAcc).

get_superfields([], FieldsAcc, FieldsAcc). */


get_superfields_nc(Cname, Acc) :-
    get_superfields_nc_aux([Cname], [], Acc).
    % list_to_set(Acc, Fields).

get_superfields_nc_aux([Class | Parents], Fields, Acc) :-
    class(Class, PParents, PFields, _),
    append(Parents, PParents, NextParents),
    append(Fields, PFields, NextFields),
    get_superfields_nc_aux(NextParents, NextFields, Acc).

get_superfields_nc_aux([], Acc, Acc).


superclass(Super, Class) :-
    class(Class, Parents, _, _),
    superclass_aux(Super, Parents).


superclass_aux(Super, [Super | _]).

superclass_aux(Super, [Parent | Parents]) :-
    class(Parent, PParents, _, _),
    append(Parents, PParents, NextParents),
    superclass_aux(Super, NextParents).


patch_body(Body, This, PBody) :-
    Body =.. BodyList,
    patch_body_aux(BodyList, This, PBody).


patch_body_aux([Stmt | Stmts], This, PBody) :-
    nonvar(Stmt),
    Stmt = ',',
    patch_multiple(Stmts, This, PBodyList),
    PBody =.. [',' | PBodyList].

patch_body_aux(StmtList, This, PStmt) :-
    patch_single(StmtList, This, PStmtList),
    PStmt =.. PStmtList.


patch_multiple([Stmt | Stmts], This, [PStmt | PBody]) :-
    Stmt =.. StmtList,
    patch_single(StmtList, This, PStmtList),
    PStmt =.. PStmtList,
    patch_multiple(Stmts, This, PBody).

patch_multiple([], _, []).


patch_single([Term | Terms], This, [This | PStmtList]) :-
    atom(Term),
    Term = this,
    patch_single(Terms, This, PStmtList).

patch_single([Term | Terms], This, [Term | PStmtList]) :-
    patch_single(Terms, This, PStmtList).

patch_single([], _, []).


get_method(Sign, Body) :-
    Sign =.. [_, Iname | _],
    instance(Iname, Cname, _),
    get_method_aux([Cname], Sign, Body).


get_method_aux([Class | _], Sign, Body) :-
    class(Class, _, _, Methods),
    match_msign(Methods, Sign, Body).

get_method_aux([Class | Parents], Sign, Body) :-
    class(Class, PParents, _, _),
    append(Parents, PParents, NewParents),
    get_method_aux(NewParents, Sign, Body).


match_msign([Method | _], Sign, Body) :-
    method(Name, Args, Body) = Method,
    append([Name, _], Args, FoundSign),
    Sign =.. FoundSign.

match_msign([_ | Methods], Sign, Body) :-
    match_msign(Methods, Sign, Body).


%%% --------------------------------------------------
%%% Instance predicates

:- dynamic instance/3.  %%% represent an instance of a class

make(Iname, Cname, Fields) :-
    atom(Iname),
    !,
    \+ instance(Iname, _, _),
    % icache(Cname, ClassFields),             %%% use this when instance fields are cached
    get_superfields_nc(Cname, ClassFields), %%% use this when instance fields are NOT cached
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    asserta(instance(Iname, Cname, InstFields)).

make(Inst, Cname, Fields) :-
    var(Inst),
    !,
    % icache(Cname, ClassFields),             %%% use this when instance fields are cached
    get_superfields_nc(Cname, ClassFields), %%% use this when instance fields are NOT cached
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    Inst = instance(_, Cname, InstFields).

make(_, _, _) :-
    %%% implement logic
    fail().

make(Iname, Cname) :-
    make(Iname, Cname, []).


is_instance(Inst) :-
    Inst = instance(_, Cname, Fields),
    is_class(Cname),
    % icache(Cname, ClassFields),             %%% use this when instance fields are cached
    get_superfields_nc(Cname, ClassFields), %%% use this when instance fields are NOT cached
    check_fields(Fields, ClassFields).

is_instance(Inst, Parent) :-
    is_instance(Inst),
    instance(_, Cname, _) = Inst,
    superclass(Parent, Cname).


inst(Iname, Inst) :-
    atom(Iname),
    var(Inst),
    instance(Iname, Cname, Fields),
    Inst = instance(Iname, Cname, Fields).


field(Iname, Fname, Result) :-
    atom(Iname),
    !,
    inst(Iname, Inst),
    atom(Fname),
    Inst = instance(_, _, IFields),
    member(field(Fname, Result, _), IFields).


field(Inst, Fname, Result) :-
    is_instance(Inst),
    atom(Fname),
    Inst = instance(_, _, IFields),
    member(field(Fname, Result, _), IFields).


fieldx(Inst, [Fname | Fnames], Result) :-
    field(Inst, Fname, TmpResult),
    fieldx(TmpResult, Fnames, Result).

fieldx(Result, [], Result).


%%% --------------------------------------------------
%%% instance helper predicates

ifields_2_fields([IField | IFields], [field(Name, Value, any) | Fields]) :-
    arg(1, IField, Name),
    arg(2, IField, Value),
    ifields_2_fields(IFields, Fields).

ifields_2_fields([], []).


init_fields([CField | CFields], Fields, [field(Name, Value, Type) | FieldList]) :-
    field(Name, _, Type) = CField,
    member(field(Name, Value, _), Fields),
    !,
    call(Type, Value),
    init_fields(CFields, Fields, FieldList).

init_fields([CField | CFields], Fields, [CField | FieldList]) :-
    init_fields(CFields, Fields, FieldList).

init_fields([], _, []).


check_fields([field(Name, Value, Type) | Fields], [field(Name, _, Type) | CFields]) :-
    call(Type, Value),
    check_fields(Fields, CFields).

check_fields([], []).


%%% --------------------------------------------------
%%% utility predicates

atomic_list([]).

atomic_list([Head | Tail]) :-
    atom(Head),
    atomic_list(Tail).


class_list([]).

class_list([Head | Tail]) :-
    is_class(Head),
    class_list(Tail).


var_list([]).

var_list([Head | Tail]) :-
    var(Head),
    var_list(Tail).


list_to_set(List, Set) :-
    list_to_set_aux(List, [], Set).


list_to_set_aux([], Set, Set).

list_to_set_aux([Head | Tail], StackSet, Set) :-
    member(Head, StackSet),
    list_to_set_aux(Tail, StackSet, Set).

list_to_set_aux([Head | Tail], StackSet, Set) :-
    append(StackSet, [Head], NewStackSet),
    list_to_set_aux(Tail, NewStackSet, Set).