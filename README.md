Marini Filippo 900000
Zheng Lei Maurizio 866251
Moretti Simone 894672

# Basic Object-Oriented Programming (OOP) Extension for Prolog

This Prolog extension introduces basic object-oriented programming concepts, allowing users to define classes, create instances, and work with fields and methods

Supported types for class fields are
  - `any` (no type restriction),
  - `atom`,
  - `number`,
  - `float` (subtype of number),
  - `integer` (subtype of float),
  - `list`,
  - `string`,
  - `classes` (with 'polymorphism').

### Below are the main predicates exposed by this extension:

**Class-related Predicates:**

- `def_class/3`:
  - Parameters: 
    - `Cname` (atom).
    - `Parents` (list of atoms).
    - `Parts` (list of fields or methods): 
      > field format: "field(`Fname` (*atom*), `Fvalue` (*any*), `Ftype` (*atom*))".
      > method format: "method(`Mname` (*atom*), `Margs` (*list of variables*), `Mbody` (*callable*))".
  - Usage: Defines a class named `Cname` with `Parents` as class parents and methods/fields from `Parts`, then asserts the class information into the database.
  - Note: 
    - The class name `Cname` must be unique.
    - Fields with unspecified types are set to `any` type.
    - Inheritance system traverse parents tree by depth.
    - When fields/methods with same name/signature are defined multiple times in the same class, only the first occurrence will be accessible.
    - When inheriting a field, type must be the same or a subtype.

- `def_class/2`:
  - Parameters: 
    - `Class` (atom). 
    - `Parents` (list of atoms).
  - Usage: A shorthand for defining a class without specifying any fields or methods.

- `is_class/1`:
  - Parameters: 
    - `Cname` (atom).
  - Usage: Checks if `Cname` is a defined class.

**Instance-related Predicates:**

- `make/3`:
  - Parameters: 
    - `Iname` (atom).
    - `Cname` (atom).
    - `Fields` (list of initializers):
      > initializer format: "`Fname` (*atom*) = `Fvalue` (*atom*)"
  - Usage: Creates an instance of a class `Cname` named as `Iname` and fields initialized from `Fields` then asserts the instance information into the database.
  - Note: 
    - The instance name `Iname` must be unique.
    - When the same field is initialized multiple times only the first one will be considerated.

- `make/3`:
  - Parameters: 
    - `Inst` (variable).
    - `Cname` (atom).
    - `Fields` (list of initializers):  
  - Usage: Creates an instance of a class `Cname` and fields initialized from `Fields` then binds it to `Inst`.

- `make/2`:
  - Parameters: 
    - `Iname` (atom or variable).
    - `Cname` (atom).
  - Usage: A shorthand for creating instances without specifying initializers.

- `is_instance/1`:
  - Parameters:
    - `Inst` (instance or atom).
  - Usage: Verifies that `Inst` is a valid instance.

- `is_instance/2`:
  - Parameters: 
    - `Inst` (instance or atom).
    - `Super` (name).
  - Usage: Verifies that `Inst` is a valid instance, then verifies that class named `Super` is a super-class (every class is a superclass of itself as specified [here](https://elearning.unimib.it/mod/forum/discuss.php?d=253566)) of `Inst` class. 

- `inst/2`:
  - Parameters: 
    - `Iname` (atom).
    - `Inst` (instance).
  - Usage: Retrieves the instance named `Name` from the database.

- `field/3`:
  - Parameters: 
    - `Inst` (instance or atom).
    - `Fname` (atom).
    - `Result` (variable).
  - Usage: Gets the value of the field named `Fname` from the given instance `Inst` and unifies it with `Result`.

- `fieldx/3`:
  - Parameters: 
    - `Inst` (instance or atom).
    - `Fnames` (list atoms).
    - `Result` (variable).
  - Usage: Gets the value of the first field specified in `Fnames` from the instance `Inst` and recursively uses it to extract the next field until the last one, which is then unified with `Result`.

---

### ❗The following predicates are Not Meant for End-User ❗

**Internal Class Helper Predicates:**

- `parse_class/4`:
  - Parameters: 
    - `Parents` (list of atoms).
    - `Parts` (list of atoms).
    - `Fields` (variable).
    - `Methods` (variable).
  - Usage: Splits into fields and methods, handle field types and dynamic methods creation

- `check_subtype/2`:
  - Parameters: 
    - `Field` (field).
    - `Parents` (list of atoms).
  - Usage: Checks that the field `Field` if inherited is a subtype or the same type as the inherited one.

- `get_superfields_nc/2`:
  - Parameters: 
    - `Cname` (atom).
    - `Acc` (variable).
  - Usage: Retrieves the fields (own + inherited) of class `Cname` and binds them to `Acc`

- `superclass/2`:
  - Parameters: 
    - `Super` (atom), 
    - `Class` (atom).
  - Usage: Checks whether the argument `Super` is a superclass of the argument `Class`.
  - Notes:
    - In this predicate a class is not considered a superclass of itself

- `patch_body/3`:
  - Parameters: -
    - `Body` (callable), `This` (variable), `PBody` (variable).
  - Usage: Patches the body of a function by replacing occurrences of `this` (atom) with the variable `This`.
  - Note: `This` must be unified before going out of scope, for this function to be effective, basically this method doesn't allow to statically patch a method, instead it must be done at runtime. I implemented it this way because i thought it was cleaner since, in Prolog we don't really care about performance 

- `get_method/2`:
  - Parameters: 
    - `Sign` (compound), 
    - `Body` (variable).
  - Usage: Retrieves the body of the method specified by the signature `Sign` and then binds it to `Body`.
  - Notes:
    - This predicate is meant to be called only by dynamic methods definitions, since `Sign` must contain a reference to the caller instance (an instance or instance name).

**Internal Instance Helper Predicates:**

- `ifields_2_fields/2`:
  - Parameters: 
    -`IFields` (list of initializers).
    -`Fields` (variable).
  - Usage: Converts a list of `initializers` to `fields` then binds them to `Field`.

- `init_fields/3`:
  - Parameters: 
    - `CFields` (list of fields).
    - `Fields` (list of fields).
    - `FieldList` (variable).
  - Usage: Creates a list of fields equal to `CFields`, but uses values provided by `Fields` then binds them to `FieldList`.
  
- `check_fields/2`:
  - Parameters: 
    - `IFields` (list of fields).
    - `CFields` (list of fields).
  - Usage: Checks that `IFields` contains all the fields from `CFields` and nothing more

**If some predicates haven't been mentioned, it's because they are only needed to support those mentioned and are not intended to be used on their own, or they are utility which are not strictly related to this project**
