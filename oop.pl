%%%% Marini Filippo 900000
%%%%

:- dynamic class/4.     %%% represents the class object
:- dynamic instance/3.  %%% represent an instance of a class

%%% --------------------------------------------------
%%% exposed class predicates

%%% define a class object with a name, parents and fields/methods
%%% - class name must be unique
%%% - when the type of a field is not specified,
%%%     it is automatically set to 'atom'
%%% - parents are explored by depth, so the order of parents is important
%%% - when fields/methods with same signature/name are defined,
%%%     only the first occurrence will be considered
%%% - when inheriting a field, type must be the same or a subtype
def_class(Cname, Parents, Parts) :-
    atom(Cname),
    \+ class(Cname, _, _, _),
    class_list(Parents),
    parse_class(Parents, Parts, Fields, Methods),
    assertz(class(Cname, Parents, Fields, Methods)).

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


%%% check if <Cname> is a class
is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _, _).


%%% --------------------------------------------------
%%% exposed instance predicates

%%% create an instance of the class <Cname>, allow fields initialization
%%%     and save resulting instance in database as <Iname>
%%%     or binds it to variable <Inst>
%%% - to assert an instance it's name must be unique
%%% - when a field is initialized multiple times
%%%     only the first one will be considerated
make(Iname, Cname, Fields) :-
    atom(Iname),
    !,
    \+ instance(Iname, _, _),
    get_superfields_nc(Cname, ClassFields), 
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    asserta(instance(Iname, Cname, InstFields)).

make(Inst, Cname, Fields) :-
    var(Inst),
    !,
    get_superfields_nc(Cname, ClassFields),
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    Inst = instance(_, Cname, InstFields).

make(Inst, Cname, Fields) :-
    get_superfields_nc(Cname, ClassFields),
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    Inst = instance(_, Cname, InstFields).

make(Iname, Cname) :-
    make(Iname, Cname, []).


%%% verify that <Inst> is a valid instance
is_instance(Inst) :-
    Inst = instance(_, Cname, Fields),
    is_class(Cname),
    get_superfields_nc(Cname, ClassFields),
    check_fields(Fields, ClassFields).

%%% verify that <Inst> is a valid instance
%%% and check that <Super> is a superclass of <Inst>
is_instance(Inst, Super) :-
    is_instance(Inst),
    instance(_, Cname, _) = Inst,
    superclass(Super, Cname).


%%% retrieve instance with name <Iname> from database
inst(Iname, Inst) :-
    atom(Iname),
    var(Inst),
    instance(Iname, Cname, Fields),
    Inst = instance(Iname, Cname, Fields).


%%% retrieve field with name <Fname> from instance <Inst>
field(Inst, Fname, Result) :-
    is_instance(Inst),
    !,
    atom(Fname),
    Inst = instance(_, _, IFields),
    contains(IFields, field(Fname, Result, _)).

%%% retrieve field with name <Fname> from instance named <Iname>
field(Iname, Fname, Result) :-
    atom(Iname),
    inst(Iname, Inst),
    field(Inst, Fname, Result).


%%% retrieve a chain of fields from instance or instance name <Inst>
fieldx(Inst, [Fname | Fnames], Result) :-
    field(Inst, Fname, TmpResult),
    fieldx(TmpResult, Fnames, Result).

fieldx(Result, [], Result).


%%% --------------------------------------------------
%%% internal class helper predicates

%%% parse class fields/methods by dividing them to match 
%%%     the class object layout
%%% - check field types
%%% - create dynamic methods definition (can be invoked with instance name
%%%     or instance object itself) 
parse_class(Parents, [Part | Parts], [Part | Fields], Methods) :- 
    Part = field(Name, Value, Type),
    !,
    atom(Name),
    type(Value, Type),
    check_subtype(Part, Parents),
    parse_class(Parents, Parts, Fields, Methods).

parse_class(Parents, [Part | Parts], Fields, Methods) :-
    Part = field(Name, Value),
    !,
    parse_class(Parents, [field(Name, Value, any) | Parts], Fields, Methods).

parse_class(Parents, [Part | Parts], Fields, [Part | Methods]) :- 
    Part = method(Name, Args, Body),
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
    Part = method(Name, Args, Body),
    atom(Name),
    var_list(Args),
    callable(Body),
    parse_class(Parents, Parts, Fields, Methods).

parse_class(_, [], [], []).


check_subtype(field(Name, _, Type), Parents) :-
    get_superfields_nc_aux(Parents, [], SuperFields),
    contains(SuperFields, field(Name, _, OldType)),
    !,
    subtype(Type, OldType).

check_subtype(_, _).


%%% retrieves all fields of <Cname> (it's own plus
%%%     all inherited ones from superclasses)
get_superfields_nc(Cname, Acc) :-
    get_superfields_nc_aux([Cname], [], Acc).

get_superfields_nc_aux([Class | Parents], Fields, Acc) :-
    class(Class, PParents, PFields, _),
    append(PParents, Parents, NextParents),
    append(Fields, PFields, NextFields),
    get_superfields_nc_aux(NextParents, NextFields, Acc).

get_superfields_nc_aux([], Acc, Acc).


%%% checks if <Super> is a superclass of <Class>
superclass(Super, Class) :-
    class(Class, Parents, _, _),
    superclass_aux(Super, Parents).


superclass_aux(Super, [Super | _]) :- !.

superclass_aux(Super, [Parent | Parents]) :-
    class(Parent, PParents, _, _),
    append(Parents, PParents, NextParents),
    superclass_aux(Super, NextParents).


%%% patch body of a function by swapping atom 'this'
%%%     with variable <This>
%%% - 'this' is only patched when used in a callable predicates
%%%     not in compounds
patch_body(Body, This, PBody) :-
    Body = (Stmt, Stmts),
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
    Term = this,
    !,
    patch_stmt(Terms, This, PList).

patch_stmt([Term | Terms], This, [Term | PList]) :-
    patch_stmt(Terms, This, PList).

patch_stmt([], _, []).


%%% retrieve the body of the method with matching signature
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

%%% convert list of initializers from 'make' to 'field' objects 
ifields_2_fields([IField | IFields], [field(Name, Value, any) | Fields]) :-
    arg(1, IField, Name),
    arg(2, IField, Value),
    ifields_2_fields(IFields, Fields).

ifields_2_fields([], []).


%%% initialize instance fields with values 'make' (converted by 'ifields_2_fields')
init_fields([CField | CFields], Fields, [field(Name, Value, Type) | FieldList]) :-
    field(Name, _, Type) = CField,
    contains(Fields, field(Name, Value, _)),
    !,
    type(Value, Type),
    init_fields(CFields, Fields, FieldList).

init_fields([CField | CFields], Fields, [CField | FieldList]) :-
    init_fields(CFields, Fields, FieldList).

init_fields([], _, []).


%%% check that fields are the same (except for value)
check_fields([field(Name, Value, Type) | Fields], [field(Name, _, Type) | CFields]) :-
    type(Value, Type),
    check_fields(Fields, CFields).

check_fields([], []).


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


type(_, any) :- !.

type(Value, atom) :-
    atom(Value),
    !.

type(Value, number) :-
    number(Value),
    !.

type(Value, integer) :-
    integer(Value),
    !.

type(Value, float) :-
    float(Value),
    !.

type(Value, list) :-
    is_list(Value),
    !.

type(Value, string) :-
    string(Value),
    !.

type(Value, Cname) :-
    is_class(Cname),
    is_instance(Value),
    !.

type(Value, Cname) :-
    is_class(Cname),
    inst(Value, Inst),
    is_instance(Inst).


subtype(_, any) :- !.

subtype(integer, number) :- !.

subtype(float, number) :- !.

subtype(Type, Type).


contains([El | _], El) :- !.

contains([_ | Tail], El) :-
    contains(Tail, El).