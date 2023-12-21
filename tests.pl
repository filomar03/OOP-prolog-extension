:- consult('oop.pl').

class_creation(setup(abolish(class/4))) :-
    \+ def_class(X, [], []),
    def_class(person, [], []),
    \+ def_class(person, [], []),
    def_class(student, [person], []),
