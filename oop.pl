/*
* TODO: 
*   - implement 'fieldx'
*   - check fields in 'is_isntance'
*   - methods implementation
*   - patch 'this' in methods body
*   - refactor names
*   - verify correctnes with tests
*   - implement 3rd 'make' case
*/

%%% --------------------------------------------------
%%% Class predicates

:- dynamic class/4.     %%% represents the class object
:- dynamic icache/2.    %%% represents fields that every isntance should have

def_class(Cname, Parents, Parts) :-
    atom(Cname),
    \+ class(Cname, _, _, _),
    class_list(Parents),
    parse_class(Parts, Fields, Methods),
    get_superfields(Parents, [], SuperFields),  %%% remove to disable instance fields caching
    append(Fields, SuperFields, InstFields),    %%% remove to disable instance fields caching
    list_to_set(InstFields, InstFieldsSet),     %%% remove to disable instance fields caching
    assertz(icache(Cname, InstFieldsSet)),      %%% remove to disable instance fields caching
    assertz(class(Cname, Parents, Fields, Methods)).

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _, _).


%%% --------------------------------------------------
%%% Class helper predicates

parse_class([], [], []).

parse_class([Part | Parts], [Part | Fields], Methods) :- 
    Part = field(Fname, Value, Type),
    !,
    atom(Fname),
    call(Type, Value),
    parse_class(Parts, Fields, Methods).

parse_class([Part | Parts], Fields, Methods) :-
    Part = field(Fname, Value),
    parse_class([field(Fname, Value, atom) | Parts], Fields, Methods).

parse_class([Part | Parts], Fields, [Part | Methods]) :- 
    Part = method(Mname, Args, Body),
    atom(Mname),
    var_list(Args),
    callable(Body),
    %%% patch 'this'
    parse_class(Parts, Fields, Methods).


%%% currently using this predicate to retrieve superfields
%%% because it's faster since it caches the result
get_superfields([Parent | Parents], StackFields, FieldsAcc) :-
    icache(Parent, ParentFields),
    append(StackFields, ParentFields, NewStackFields),
    get_superfields(Parents, NewStackFields, FieldsAcc).

get_superfields([], FieldsAcc, FieldsAcc).


get_superfields_nc([Parent | Parents], StackFields, FieldsAcc) :-
    class(Parent, PParents, Fields, _),
    append(Parents, PParents, NewStackParents),
    append(StackFields, Fields, NewStackFields),
    get_superfields_nc(NewStackParents, NewStackFields, FieldsAcc).

get_superfields_nc([], Acc, Acc).


/*
full_parents(Class, ParentsAccSet) :-
    full_parents_aux([Class], [], ParentsAcc),
    list_to_set(ParentsAcc, ParentsAccSet).    


full_parents_aux([Parent | Parents], StackParentsAcc, ParentsAcc) :-
    class(Parent, PParents, _, _),
    append(Parents, PParents, NextStackParents),
    append(StackParentsAcc, PParents, NextStackParentsAcc),
    full_parents_aux(NextStackParents, NextStackParentsAcc, ParentsAcc).

full_parents_aux([], StackParentsAcc, StackParentsAcc). 
*/

superclass(Super, Class) :-
    class(Class, Parents, _, _),
    member(Super, Parents).

superclass([], _).


%%% --------------------------------------------------
%%% Instance predicates

:- dynamic instance/3.  %%% represent an instance of a class

make(Iname, Cname, Fields) :-
    atom(Iname),
    !,
    \+ instance(Iname, _, _),
    icache(Cname, ClassFields),     %%% swap with 'get_superfields_nc/3',
                                    %%% then add current class fields and transform to set
                                    %%% when instance fields caching is disabled
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    asserta(instance(Iname, Cname, InstFields)).

make(Inst, Cname, Fields) :-
    var(Inst),
    !,
    icache(Cname, ClassFields),
    ifields_2_fields(Fields, ConvFields),
    init_fields(ClassFields, ConvFields, InstFields),
    Inst = instance(_, Cname, InstFields).

make(_, _, _) :-
    %%% implement logic
    true().

make(Iname, Cname) :-
    make(Iname, Cname, []).


is_instance(Inst, Parent) :-
    Inst = instance(_, Cname, _),
    is_class(Cname),
    %%% check fields ???
    superclass(Parent, Cname).

is_instance(Inst) :-
    is_instance(Inst, []).


inst(Iname, Inst) :-
    atom(Iname),
    var(Inst),
    instance(Iname, Cname, Fields),
    Inst = instance(Iname, Cname, Fields).


field(Inst, Fname, Result) :-
    is_instance(Inst),
    atom(Fname),
    Inst = instance(_, Cname, Fields),
    member(field(Fname, Result, _), Fields).


%%% --------------------------------------------------
%%% instance helper predicates

ifields_2_fields([InstField | InstFields], [field(FName, FValue, any) | Fields]) :-
    arg(1, InstField, FName),
    arg(2, InstField, FValue),
    ifields_2_fields(InstFields, Fields).

ifields_2_fields([], []).


init_fields([ClassField | ClassFields], Fields, [field(Fname, Fvalue, Ftype) | FieldList]) :-
    field(Fname, _, Ftype) = ClassField,
    member(field(Fname, Fvalue, _), Fields),
    !,
    call(Ftype, Fvalue),
    init_fields(ClassFields, Fields, FieldList).

init_fields([ClassField | ClassFields], Fields, [ClassField | FieldList]) :-
    init_fields(ClassFields, Fields, FieldList).

init_fields([], _, []).


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


%%% Tests

:- def_class(entity, [], [field(id, 0, integer)]).
:- def_class(person, [entity], [field(name, "Mario", string)]).
:- def_class(robot, [entity], [field(manufacturer, "Xiaomi", string), field(version, "0.0.1", string)]).
:- def_class(cyborg, [person, robot], [field(tflops, 12, integer)]).

:- make(iborg, cyborg, [id = 999, manufacturer = "Apple", tflops = 42]).