/*
* TODO: 
*   - disallow multiple fields or methods with same name
*   - optimize with cuts
*   - figure out third 'make' case (https://elearning.unimib.it/mod/forum/discuss.php?d=252585)
*   - figure out which types are valid and how to handle their initialization
*   - 
*/

%%% --------------------------------------------------
%%% Class predicates

:- dynamic class/4.

def_class(Cname, Parents, Parts) :-
    atom(Cname),
    \+ class(Cname, _, _, _),
    class_list(Parents),
    parse_class(Parts, Fields, Methods),
    assertz(class(Cname, Parents, Fields, Methods)).

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _, _).


%%% --------------------------------------------------
%%% Class helper predicates

%%% disallow multiple fields or methods with same name
parse_class([], [], []).

parse_class([Part | Parts], [Part | Fields], Methods) :- 
    Part = field(Fname, _, Type),
    !,
    atom(Fname),
    atom(Type),
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


parents(Class, Parents) :-
    is_class(Class),
    class(Class, Parents, _, _).


full_parents(Class, ParentsAcc) :-
    is_class(Class),
    full_parents_aux([Class], [], ParentsAcc).


full_parents_aux([], StackParentsAcc, StackParentsAcc).

full_parents_aux([Parent | Parents], StackParentsAcc, ParentsAcc) :-
    class(Parent, PParents, _, _),
    append(Parents, PParents, NextStackParents),
    append(StackParentsAcc, PParents, NextStackParentsAcc),
    full_parents_aux(NextStackParents, NextStackParentsAcc, ParentsAcc).
    

fields(Class, Fields) :-
    is_class(Class),
    class(Class, _, Fields, _).


methods(Class, Methods) :-
    is_class(Class),
    class(Class, _, _, Methods).


superclass(Super, Class) :-
    parents(Class, Parents),
    member(Super, Parents).

%%% 'superclass([], _)' was created to allow 'is_instance(Inst)'
superclass([], _).


%%% --------------------------------------------------
%%% Instance predicates

:- dynamic instance/3.

make(Iname, Cname, _) :-
    atom(Iname),
    !,
    \+ instance(Iname, _, _),
    is_class(Cname),
    %%% initialize fields
    asserta(instance(Iname, Cname, _)).

make(Inst, Cname, _) :-
    var(Inst),
    !,
    is_class(Cname),
    %%% initialize fields
    Inst = instance(_, Cname, _).

%%% same as 2nd case ???
make(Inst, Cname, Fields) :-
    is_class(Cname),
    %%% initialize fields
    Inst = instance(_, Cname, Fields).

make(Iname, Cname) :-
    make(Iname, Cname, []).


is_instance(Inst, Parent) :-
    Inst = instance(_, Cname, Fields),
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


%%% --------------------------------------------------
%%% instance helper predicates

gen_fields([], []).

gen_fields([Cname | Cnames], [Fields | FieldsAcc]) :-
    class(Cname, Parents, Fields, _),
    append(Cnames, Parents, ParentsAcc),
    gen_fields(ParentsAcc, FieldsAcc).


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