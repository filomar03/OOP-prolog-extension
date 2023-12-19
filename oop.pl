/*
* TODO: 
*   - convert class representation in binary predicates? pros and cons?  
*   - check 'form' (method body)
*   - avoid classes with same name?
*   - Si noti che le regole di unificazione Prolog si applicano a <value> ed al corpo del metodo (capire che vuol dire)
*/

def_class(Class, Parents) :-
    atom(Class),
    atm_list(Parents),
    asserta(class(Class, Parents)).

def_class(Class, Parents, Parts) :-
    atom(Class),
    atm_list(Parents),
    cls_parts(Parts),
    asserta(class(Class, Parents, Parts)).


atm_list([]).

atm_list([H | T]) :-
    atom(H),
    atm_list(T).


cls_parts([]).

cls_parts([Field | Parts]) :-
    functor(Field, field, 2),
    arg(1, Field, Fname),
    atom(Fname),
    cls_parts(Parts).

cls_parts([Field | Parts]) :- 
    functor(Field, field, 3),
    arg(1, Field, Fname),
    atom(Fname),
    cls_parts(Parts).

cls_parts([Method | Parts]) :- 
    functor(Method, method, 3),
    arg(1, Method, Mname),
    atom(Mname),
    arg(2, Method, Args),
    var_list(Args),
    cls_parts(Parts).


var_list([]).

var_list([H | T]) :-
    var(H),
    var_list(T).


make(Iname, Cname).