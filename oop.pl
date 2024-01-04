%%%% Marini Filippo 900000
%%%%

:- dynamic class/4.     %%% represents the class object
:- dynamic instance/3.  %%% represent an instance of a class

%%% --------------------------------------------------
%%% exposed class predicates

%%% defines a class object with a name, parents and fields/methods
%%% - class name must be unique
%%% - when the type of a field is not specified,
%%%     it is automatically set to 'atom'
%%% - the order in which the parents are specified is important,
%%%     because when non unique fields/methods are inherited
%%%     only the first occurrence can actually be accessed 
def_class(Cname, Parents, Parts) :-
    atom(Cname),
    \+ class(Cname, _, _, _),
    class_list(Parents),
    parse_class(Parts, Fields, Methods),
    assertz(class(Cname, Parents, Fields, Methods)).

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


%%% check if <Cname> is a class
is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _, _).


%%% --------------------------------------------------
%%% exposed instance predicates

%%% creates an instance of <Cname>, allows fields initialization 
%%%     and saves resulting instance in database as <Iname>
%%%     or binds it to variable <Inst>
%%% - to assert an instance it's name must be unique
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


%%% verifies that <Inst> is a valid instance
%%% - can check that <Parent> is a superclass of <Inst>
is_instance(Inst) :-
    Inst = instance(_, Cname, Fields),
    is_class(Cname),
    get_superfields_nc(Cname, ClassFields),
    check_fields(Fields, ClassFields).

is_instance(Inst, Parent) :-
    is_instance(Inst),
    instance(_, Cname, _) = Inst,
    superclass(Parent, Cname).


%%% retrieves instance with name <Iname> from database
inst(Iname, Inst) :-
    atom(Iname),
    var(Inst),
    instance(Iname, Cname, Fields),
    Inst = instance(Iname, Cname, Fields).


%%% get field with name <Fname> from <Inst> (instance)
field(Inst, Fname, Result) :-
    is_instance(Inst),
    atom(Fname),
    Inst = instance(_, _, IFields),
    member(field(Fname, Result, _), IFields).

%%% get field with name <Fname> from <Iname> (instance name)
field(Iname, Fname, Result) :-
    atom(Iname),
    !,
    inst(Iname, Inst),
    field(Inst, Fname, Result).


%%% get a chain of fields from <Inst> (instance or instance name)
fieldx(Inst, [Fname | Fnames], Result) :-
    field(Inst, Fname, TmpResult),
    fieldx(TmpResult, Fnames, Result).

fieldx(Result, [], Result).


%%% --------------------------------------------------
%%% internal class helper predicates

%%% parse class fields/methods by dividing them to match 
%%%     the class object layout
%%% - checks field types
%%% - creates dynamic methods definition (can be invoked with instance name
%%%     or instance object itself) 
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
    Rule = (Sign :- get_method(Sign, X), patch_body(X, This, Y), call(Y)), 
    assert(Rule),
    parse_class(Parts, Fields, Methods).

parse_class([], [], []).


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


superclass_aux(Super, [Super | _]).

superclass_aux(Super, [Parent | Parents]) :-
    class(Parent, PParents, _, _),
    append(Parents, PParents, NextParents),
    superclass_aux(Super, NextParents).


%%% patches body of a function by swapping 'this' atom
%%%     with variable <This>
%%% - 'this' is only patched when used in a callable predicate
%%%     example: 
%%%      field(this, name, X)   valid!
%%%      writeln(student(this), name, X)   NOT valid!
patch_body(Body, This, PBody) :-
    Body =.. BodyList,
    patch_body_aux(BodyList, This, PBody).


%%% differentiates when function body is only one statement or more
patch_body_aux([Stmt | Stmts], This, PBody) :-
    nonvar(Stmt),
    Stmt = ',',
    patch_multiple(Stmts, This, PBodyList),
    PBody =.. [',' | PBodyList].

patch_body_aux(StmtList, This, PStmt) :-
    patch_single(StmtList, This, PStmtList),
    PStmt =.. PStmtList.


%%% recursively patches multiple statements
patch_multiple([Stmt | Stmts], This, [PStmt | PBody]) :-
    Stmt =.. StmtList,
    patch_single(StmtList, This, PStmtList),
    PStmt =.. PStmtList,
    patch_multiple(Stmts, This, PBody).

patch_multiple([], _, []).


%%% patch a single statement
patch_single([Term | Terms], This, [This | PStmtList]) :-
    atom(Term),
    Term = this,
    patch_single(Terms, This, PStmtList).

patch_single([Term | Terms], This, [Term | PStmtList]) :-
    patch_single(Terms, This, PStmtList).

patch_single([], _, []).


%%% retrieves the body of the method with matching signature
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
    member(field(Name, Value, _), Fields),
    !,
    call(Type, Value),
    init_fields(CFields, Fields, FieldList).

init_fields([CField | CFields], Fields, [CField | FieldList]) :-
    init_fields(CFields, Fields, FieldList).

init_fields([], _, []).


%%% check that fields are the same (except for value)
check_fields([field(Name, Value, Type) | Fields], [field(Name, _, Type) | CFields]) :-
    call(Type, Value),
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