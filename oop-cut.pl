%%%% Marini Filippo 900000
%%%%


:- dynamic class/4.     %%% represents the class object
:- dynamic instance/3.  %%% represent the instance object

%%% -----------------------------------------------------------------
%%% exposed class predicates

%%% def_class/3: defines a class named `Cname` with `Parents` as class parents a
def_class(Cname, Parents, Parts) :-
    atom(Cname),
    \+ class(Cname, _, _, _),
    class_list(Parents),
    parse_class(Parents, Parts, Fields, Methods),
    assertz(class(Cname, Parents, Fields, Methods)),
    !.

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


%%% is_class/2: checks if `Cname` is a defined class.
is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _, _).

%%% -----------------------------------------------------------------
%%% exposed instance predicates

%%% make/3: creates an instance of a class `Cname` named as `Iname` and fields i
make(Iname, Cname, Fields) :-
    atom(Iname),
    !,
    \+ instance(Iname, _, _),
    get_superfields_nc(Cname, ClassFields), 
    ifields_2_fields(Fields, ConvFields),
    init_fields(ConvFields, ClassFields, InstFields),
    asserta(instance(Iname, Cname, InstFields)).

%%% make/3: creates an instance of a class `Cname` and fields initialized from `
make(Inst, Cname, Fields) :-
    var(Inst),
    !,
    get_superfields_nc(Cname, ClassFields),
    ifields_2_fields(Fields, ConvFields),
    init_fields(ConvFields, ClassFields, InstFields),
    Inst = instance(_, Cname, InstFields).

make(Inst, Cname, Fields) :-
    get_superfields_nc(Cname, ClassFields),
    ifields_2_fields(Fields, ConvFields),
    init_fields(ConvFields, ClassFields, InstFields),
    Inst = instance(_, Cname, InstFields).


make(Iname, Cname) :-
    make(Iname, Cname, []).


%%% is_instance/1 verifies that `Inst` is a valid instance
is_instance(Inst) :-
    instance(_, Cname, Fields) = Inst,
    get_superfields_nc(Cname, CFields),
    check_fields(Fields, CFields).


%%% is_instance/2: verifies that `Inst` is a valid instance, then verifies that 
is_instance(Inst, Super) :-
    is_instance(Inst),
    instance(_, Cname, _) = Inst,
    is_instance_aux(Super, Cname).


is_instance_aux(Super, Super) :- !.

is_instance_aux(Super, Cname) :-
    superclass(Super, Cname).


%%% inst/2: retrieves the instance named `Name` from the database.
inst(Iname, Inst) :-
    atom(Iname),
    var(Inst),
    instance(Iname, Cname, Fields),
    Inst = instance(Iname, Cname, Fields).


%%% field/3: gets the value of the field named `Fname` from the given instance `
field(Inst, Fname, Result) :-
    is_instance(Inst),
    atom(Fname),
    instance(_, _, IFields) = Inst,
    contains(field(Fname, Result, _), IFields).


%%% fieldx/3: gets the value of the first field specified in `Fnames` from the i
fieldx(Inst, [Fname | Fnames], Result) :-
    field(Inst, Fname, TmpResult),
    fieldx(TmpResult, Fnames, Result).

fieldx(Result, [], Result).


%%% --------------------------------------------------
%%% internal class helper predicates

%%% parse_class/4: splits into fields and methods, handle field types and dynami
parse_class(Parents, [Part | Parts], [Part | Fields], Methods) :- 
    field(Name, Value, Type) = Part,
    !,
    atom(Name),
    check_subtype(Part, Parents),
    is_type(Value, Type),
    parse_class(Parents, Parts, Fields, Methods).

parse_class(Parents, [Part | Parts], Fields, Methods) :-
    field(Name, Value) = Part,
    !,
    parse_class(Parents, [field(Name, Value, any) | Parts], Fields, Methods).

parse_class(Parents, [Part | Parts], Fields, [Part | Methods]) :- 
    method(Name, Args, Body) = Part,
    atom(Name),
    var_list(Args),
    callable(Body),
    append([Name, This], Args, SignList),
    Sign =.. SignList,
    ClauseBody = (get_method(Sign, X), patch_body(X, This, Y), call(Y)),
    Clause = (Sign :- ClauseBody),
    \+ clause(Sign, ClauseBody),
    !,
    assert(Clause),
    parse_class(Parents, Parts, Fields, Methods).

parse_class(Parents, [Part | Parts], Fields, [Part | Methods]) :- 
    method(Name, Args, Body) = Part,
    atom(Name),
    var_list(Args),
    callable(Body),
    parse_class(Parents, Parts, Fields, Methods).

parse_class(_, [], [], []).


%%% check_subtype/2: checks that the field `Field` if inherited is a subtype or 
check_subtype(_, []) :- !.

check_subtype(field(Name, _, Type), Parents) :-
    get_superfields_nc_aux(Parents, [], SuperFields),
    contains(field(Name, _, OldType), SuperFields),
    !,
    subtype(Type, OldType),
    !.

check_subtype(_, _).


%%% get_superfields_nc/2: retrieves the fields (own + inherited) 
%%%     of class <Cname> and binds them to <Acc>
get_superfields_nc(Cname, Acc) :-
    get_superfields_nc_aux([Cname], [], Acc).

get_superfields_nc_aux([Class | Parents], Fields, Acc) :-
    class(Class, PParents, PFields, _),
    append(PParents, Parents, NextParents),
    append(Fields, PFields, NextFields),
    get_superfields_nc_aux(NextParents, NextFields, Acc).

get_superfields_nc_aux([], Acc, Acc).


%%% superclass/2: checks whether the argument `Super` is a superclass of the arg
superclass(Super, Class) :-
    class(Class, Parents, _, _),
    superclass_aux(Super, Parents).


superclass_aux(Super, [Super | _]) :- !.

superclass_aux(Super, [Parent | Parents]) :-
    class(Parent, PParents, _, _),
    append(Parents, PParents, NextParents),
    superclass_aux(Super, NextParents).


%%% patch_body/3: patches the body of a function by replacing occurrences of `th
patch_body(Body, This, PBody) :-
    (Stmt, Stmts) = Body,
    Stmt =.. List,
    patch_stmt(List, This, PList),
    PStmt =.. PList,
    patch_body(Stmts, This, PBodyTail),
    PBody = (PStmt, PBodyTail),
    !.

patch_body(Stmt, This, PStmt) :-
    Stmt =.. List,
    patch_stmt(List, This, PList),
    PStmt =.. PList.


patch_stmt([Term | Terms], This, [This | PList]) :-
    atom(Term),
    this = Term,
    !,
    patch_stmt(Terms, This, PList).

patch_stmt([Term | Terms], This, [Term | PList]) :-
    patch_stmt(Terms, This, PList).

patch_stmt([], _, []).


%%% get_method/2: retrieves the body of the method specified by the signature `S
get_method(Sign, Body) :-
    Sign =.. [_, Iname | _],
    atom(Iname),
    !,
    instance(Iname, Cname, _),
    get_method_aux([Cname], Sign, Body).


get_method(Sign, Body) :-
    Sign =.. [_, Inst | _],
    is_instance(Inst),
    instance(_, Cname, _) = Inst,
    get_method_aux([Cname], Sign, Body).


get_method_aux([Class | _], Sign, Body) :-
    class(Class, _, _, Methods),
    match_msign(Methods, Sign, Body),
    !.

get_method_aux([Class | Parents], Sign, Body) :-
    class(Class, PParents, _, _),
    append(PParents, Parents, NewParents),
    get_method_aux(NewParents, Sign, Body).


match_msign([Method | _], Sign, Body) :-
    method(Name, Args, Body) = Method,
    append([Name, _], Args, FoundSign),
    Sign =.. FoundSign,
    !.

match_msign([_ | Methods], Sign, Body) :-
    match_msign(Methods, Sign, Body).


%%% --------------------------------------------------
%%% internal instance helper predicates

%%% ifields_2_fields/2: converts a list of `initializers` to `fields` then binds
ifields_2_fields([Name = Value | IFields], [field(Name, Value, any) | Fields]) :
    ifields_2_fields(IFields, Fields).

ifields_2_fields([], []).


%%% init_fields/3: creates a list of fields equal to `CFields`, but uses values 
init_fields([field(Name, Value, _) | Fields], CFields, [field(Name, Value, Type)
    contains(field(Name, _, Type), CFields),
    is_type(Value, Type),
    init_fields(Fields, CFields, FieldList).

init_fields([], CFields, CFields).


%%% check_fields/2: checks that instance fields are the same as class fields (ex
check_fields(Ifields, Cfields) :-
    check_cfields(Cfields, Ifields),
    check_ifields(Ifields, Cfields).


check_cfields([field(Name, _, Type) | Cfields], Ifields) :-
    contains(field(Name, Value, Type), Ifields),
    is_type(Value, Type),
    check_cfields(Cfields, Ifields).

check_cfields([], _).


check_ifields([field(Name, _, Type) | Ifields], Cfields) :-
    contains(field(Name, _, Type), Cfields),
    check_ifields(Ifields, Cfields).

check_ifields([], _).


%%% --------------------------------------------------
%%% utility predicates

%%% verifies that a list is only made of atoms
atomic_list([]).

atomic_list([Head | Tail]) :-
    atom(Head),
    atomic_list(Tail).


%%% verifies that a list is only made of valid class names
class_list([]).

class_list([Head | Tail]) :-
    is_class(Head),
    class_list(Tail).


%%% verifies that a list is only made of variables
var_list([]).

var_list([Head | Tail]) :-
    var(Head),
    var_list(Tail).


%%% defines the allowed types
is_type(_, any) :- !.

is_type(Value, atom) :-
    atom(Value),
    !.

is_type(Value, number) :-
    number(Value),
    !.

is_type(Value, float) :-
    float(Value),
    !.

is_type(Value, integer) :-
    integer(Value),
    !.

is_type(Value, list) :-
    is_list(Value),
    !.

is_type(Value, string) :-
    string(Value),
    !.

is_type(Value, Cname) :-
    is_instance(Value),
    instance(_, Cname, _) = Value,
    !.

is_type(Value, Cname) :-
    inst(Value, Inst),
    instance(_, Cname, _) = Inst,
    !.

is_type(Value, Type) :-
    subtype(SubType, Type),
    SubType \= Type,
    is_type(Value, SubType).


%%% used to determines types relations
subtype(SubType, SubType).

subtype(SubType, Type) :-
    type_chain(SubType, Type).

subtype(SubType, Type) :-
    type_chain(X, Type),
    nonvar(X),
    subtype(SubType, X),
    SubType \= X.

subtype(SubType, Type) :-
    is_class(Type),
    superclass(Type, SubType).


%%% defines the subtype relations (one-on-one) 
type_chain(integer, float).

type_chain(float, number).

type_chain(_, any).


contains(El, [El | _]) :- !.

contains(El, [_ | Tail]) :-
    contains(El, Tail).
