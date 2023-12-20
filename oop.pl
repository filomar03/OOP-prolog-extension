/*
* TODO: 
*   - check 'form' (method body)
*   - Si noti che le regole di unificazione Prolog si applicano a <value> ed al corpo del metodo (capire che vuol dire)
*   - Il comportamento di make cambia a seconda di che cosa `e il primo argomento <instance-name> (capire che vuol dire)
*   - convert class representation in binary predicates? pros and cons?  
*   - 
*/

:- dynamic class/3.


def_class(Class, Parents, Parts) :-
    \+ is_class(Class),
    atomic_list(Parents),
    valid_parts(Parts),
    assertz(class(Class, Parents, Parts)).

def_class(Class, Parents) :-
    def_class(Class, Parents, Parts).


atomic_list([]).

atomic_list([Head | Tail]) :-
    atom(Head),
    atomic_list(Tail).


valid_parts([]).

valid_parts([Field | Parts]) :-
    functor(Field, field, 2),
    arg(1, Field, Fname),
    atom(Fname),
    valid_parts(Parts).

valid_parts([Field | Parts]) :- 
    functor(Field, field, 3),
    arg(1, Field, Fname),
    atom(Fname),
    valid_parts(Parts).

valid_parts([Method | Parts]) :- 
    functor(Method, method, 3),
    arg(1, Method, Mname),
    atom(Mname),
    arg(2, Method, Args),
    var_list(Args),
    valid_parts(Parts).


var_list([]).

var_list([Head | Tail]) :-
    var(Head),
    var_list(Tail).


is_class(Cname) :-
    atom(Cname),
    class(Cname, _, _).


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
    

is_contained(X, [X | _]).
is_contained(X, [_ | Ys]) :-
    is_contained(X, Ys).