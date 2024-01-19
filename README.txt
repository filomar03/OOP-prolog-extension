Marini Filippo 900000
Zheng Lei Maurizio 866251
Moretti Simone 894672

Basic Object-Oriented Programming (OOP) Extension for Prolog

This Prolog extension enables basic object-oriented programming, allowing users
to define classes, create instances, and work with fields and methods.

Supported types for class fields are:
- any (no type restriction)
- atom
- number
- float (subtype of number)
- integer (subtype of float)
- list
- string
- classes (with 'polymorphism')

Main Predicates:

- def_class/3:
  - Parameters: Cname (atom), Parents (list of atoms), Parts (list of fields
    or methods)
  - Usage: Defines a class with parents and methods/fields.

- def_class/2:
  - Parameters: Class (atom), Parents (list of atoms)
  - Usage: A shorthand for defining a class without specifying fields or
    methods.

- is_class/1:
  - Parameters: Cname (atom)
  - Usage: Checks if Cname is a defined class.

Instance-related Predicates:

- make/3:
  - Parameters: Iname (atom), Cname (atom), Fields (list of initializers)
  - Usage: Creates an instance of a class with initialized fields.

- make/3:
  - Parameters: Inst (variable), Cname (atom), Fields (list of initializers)
  - Usage: Creates an instance of a class and binds it to Inst.

- make/2:
  - Parameters: Iname (atom or variable), Cname (atom)
  - Usage: A shorthand for creating instances without specifying initializers.

- is_instance/1:
  - Parameters: Inst (instance or atom)
  - Usage: Verifies that Inst is a valid instance.

- is_instance/2:
  - Parameters: Inst (instance or atom), Super (name)
  - Usage: Verifies that Inst is a valid instance and Super is a super-class.

- inst/2:
  - Parameters: Iname (atom), Inst (instance)
  - Usage: Retrieves the instance from the database.

- field/3:
  - Parameters: Inst (instance or atom), Fname (atom), Result (variable)
  - Usage: Gets the value of the field from the instance and unifies it with
    Result.

- fieldx/3:
  - Parameters: Inst (instance or atom), Fnames (list atoms), Result
    (variable)
  - Usage: Gets the value of the first field specified in Fnames from the
    instance and recursively uses it to extract the next field until the last
    one.

Internal Class Helper Predicates:

- parse_class/4:
  - Parameters: Parents (list of atoms), Parts (list of atoms), Fields
    (variable), Methods (variable)
  - Usage: Splits into fields and methods, handles field types, and dynamic
    methods creation.

- check_subtype/2:
  - Parameters: Field (field), Parents (list of atoms)
  - Usage: Checks that the field, if inherited, is a subtype or the same type
    as the inherited one.

- get_superfields_nc/2:
  - Parameters: Cname (atom), Acc (variable)
  - Usage: Retrieves the fields (own + inherited) of class Cname and binds them
    to Acc.

- superclass/2:
  - Parameters: Super (atom), Class (atom)
  - Usage: Checks whether Super is a superclass of Class.

- patch_body/3:
  - Parameters: Body (callable), This (variable), PBody (variable)
  - Usage: Patches the body of a function by replacing occurrences of 'this'
    with the variable This.

- get_method/2:
  - Parameters: Sign (compound), Body (variable)
  - Usage: Retrieves the body of the method specified by the signature Sign and
    binds it to Body.

Internal Instance Helper Predicates:

- ifields_2_fields/2:
  - Parameters: IFields (list of initializers), Fields (variable)
  - Usage: Converts a list of initializers to fields and binds them to Fields.

- init_fields/3:
  - Parameters: CFields (list of fields), Fields (list of fields),
    FieldList (variable)
  - Usage: Creates a list of fields equal to CFields but uses values provided
    by Fields and binds them to FieldList.

- check_fields/2:
  - Parameters: IFields (list of fields), CFields (list of fields)
  - Usage: Checks that IFields contains all the fields from CFields and nothing
    more.
