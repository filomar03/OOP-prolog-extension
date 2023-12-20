/*
* TODO: 
*   - which types are valid and how to handle their initialization
*   - check 'form' (method body)
*   - Si noti che le regole di unificazione Prolog si applicano a <value> ed al corpo del metodo (capire che vuol dire)
*   - Il comportamento di make cambia a seconda di che cosa `e il primo argomento <instance-name> (capire che vuol dire)
*   - convert class representation in binary predicates? pros and cons?  
*   - 
*/

%%% Class predicates

:- dynamic class/4.

def_class(Cname, Parents, Parts) :-
    \+ is_class(Cname),
    atomic_list(Parents),
    parse_class(Parts, Fields, Methods),
    assertz(class(Cname, Parents, Fields, Methods)).

def_class(Class, Parents) :-
    def_class(Class, Parents, []).


is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _).


%%% Class helpers

atomic_list([]).

atomic_list([Head | Tail]) :-
    atom(Head),
    atomic_list(Tail).


prova(Cls) :-
    parse_class(Cls, X, Y),
    writeln(X),
    writeln(Y).


parse_class([], [], []).

parse_class([Part | Parts], [Part | Fields], Methods) :-
    functor(Part, field, 2),
    arg(1, Part, Fname),
    atom(Fname),
    %%% add field type
    parse_class(Parts, Fields, Methods).

parse_class([Part | Parts], [Part | Fields], Methods) :- 
    functor(Part, field, 3),
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
    %%% check if body is callable
    %%% patch 'this'
    parse_class(Parts, Fields, Methods).


var_list([]).

var_list([Head | Tail]) :-
    var(Head),
    var_list(Tail).


%%% Instance predicates

:- dynamic instance/3.

make(Iname, Cname, Fields) :-
    is_class(Cname),
    asserta(instance(Iname, Cname, Fields)).

make(Iname, Cname) :-
    make(Iname, Cname, []).


is_instance(Iname) :-
    instance(Iname, _).

is_instance(Iname, Parent) :-
    atom(Parent),
    instance(Iname, Cname),
    class(Cname, Parents, _),
    is_contained(Parent, Parents).
    

inst(Iname, Inst) :-
    atom(Iname).


%%% Instance helpers

is_contained(X, [X | _]).
is_contained(X, [_ | Ys]) :-
    is_contained(X, Ys).