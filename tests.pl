:- consult('oop.pl').

class_creation(setup(abolish(class/4))) :-
    def_class(entity, [], [field(id, 1, integer)]),
    def_class(person, [entity], [field(name, billy), field(age, 18, integer)]),
    def_class(student, [person], [field(gpa, 4, integer)]),
    \+ def_class(employee, [adult], []).
