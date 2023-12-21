/*
* TODO: 
*   - disallow multiple fields or methods with same name
*   - optimize with cuts
*   - figure out third 'make' case (https://elearning.unimib.it/mod/forum/discuss.php?d=252585)
*   - figure out which types are valid and how to handle their initialization
*   - 
*/

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


%%% Class helpers

atomic_list([]).

atomic_list([Head | Tail]) :-
    atom(Head),
    atomic_list(Tail).


class_list([]).

class_list([Head | Tail]) :-
    is_class(Head),
    class_list(Tail).


%%% disallow multiple fields or methods with same name
parse_class([], [], []).

parse_class([Part | Parts], [Part | Fields], Methods) :-
    functor(Part, field, 2),
    !,
    arg(1, Part, Fname),
    atom(Fname),
    %%% add field type
    parse_class(Parts, Fields, Methods).

parse_class([Part | Parts], [Part | Fields], Methods) :- 
    functor(Part, field, 3),
    !,
    arg(1, Part, Fname),
    atom(Fname),
    %%% parse field type
    parse_class(Parts, Fields, Methods).

parse_class([Part | Parts], Fields, [Part | Methods]) :- 
    functor(Part, method, 3),
    arg(1, Part, Mname),
    atom(Mname),
    arg(2, Part, Args),
    var_list(Args),
    arg(3, Part, Body),
    callable(Body),
    %%% patch 'this'
    parse_class(Parts, Fields, Methods).


var_list([]).

var_list([Head | Tail]) :-
    var(Head),
    var_list(Tail).


%%% 'superclass([], _)' was created to allow 'is_instance(Inst)'
superclass([], _).

superclass(Super, Class) :-
    is_class(Super),
    class(Class, Parents, _, _),
    member(Super, Parents).


%%% Instance predicates

:- dynamic instance/3.

make(Iname, Cname, Fields) :-
    atom(Iname),
    !,
    \+ instance(Iname, _, _),
    is_class(Cname),
    %%%% initialize fields
    asserta(instance(Iname, Cname, Fields)).

make(Inst, Cname, Fields) :-
    var(Iname),
    !,
    is_class(Cname),
    %%%% initialize fields
    Inst = instance(_, Cname, Fields).

%%% same as 2nd case ???
make(Inst, Cname, Fields) :-
    is_class(Cname),
    %%%% initialize fields
    Inst = instance(_, Cname, Fields).

make(Iname, Cname) :-
    make(Iname, Cname, []).


is_instance(Inst, Parent) :-
    functor(Inst, instance, 3),
    arg(2, Inst, Cname),
    is_class(Cname),
    %%% check fields ???
    superclass(Parent, Cname).


is_instance(Inst) :-
    is_instance(Inst, []).


inst(Iname, Inst) :-
    atom(Iname),
    var(Inst),
    instance(Iname, Cname, Fields),
    %%% try to see what happens when not unifying 'Cname' and 'Fields'
    Inst = instance(Iname, Cname, Fields).


field(Iname, Fname, Result) :-
    inst(Iname, Inst),
    arg(2, Inst, Cname),
    class(Cname, Parents, Fields, []),
    member(field())


%%% Instance helpers

unifica(X, X).