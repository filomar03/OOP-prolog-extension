# Basic Object-Oriented Programming (OOP) Extension for Prolog

This Prolog extension introduces basic object-oriented programming concepts, all

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
> method format: "method(`Mname` (*atom*), `Margs` (*list of variables*), `Mbody
- Usage: Defines a class named `Cname` with `Parents` as class parents and metho
- Note: 
- The class name `Cname` must be unique.
- Fields with unspecified types are set to `any` type.
- Inheritance system traverse parents tree by depth.
- When fields/methods with same name/signature are defined multiple times in the
- When inheriting a field, type must be the same or a subtype.

- `def_class/2`:
- Parameters: 
- `Class` (atom). 
- `Parents` (list of atoms).
- Usage: A shorthand for defining a class without specifying any fields or metho

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
- Usage: Creates an instance of a class `Cname` named as `Iname` and fields init
- Note: 
- The instance name `Iname` must be unique.
- When the same field is initialized multiple times only the first one will be c

- `make/3`:
- Parameters: 
- `Inst` (variable).
- `Cname` (atom).
- `Fields` (list of initializers):  
- Usage: Creates an instance of a class `Cname` and fields initialized from `Fie

- `make/2`:
- Parameters: 
- `Iname` (atom or variable).
- `Cname` (atom).
- Usage: A shorthand for creating instances without specifying initializers.

- `is_instance/1`:
- Parameters:
- `Inst` (instance or atom).
- Usage: Verifies that `Inst` is a valid instance or a name for a valid instance
- Notes:
- This predicate also accepts the name of an instance instead of only instance o

- `is_instance/2`:
- Parameters: 
- `Inst` (instance or atom).
- `Super` (name).
- Usage: Verifies that `Inst` is a valid instance or a name for a valid instance

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
- Usage: Gets the value of the field named `Fname` from the given instance/insta

- `fieldx/3`:
- Parameters: 
- `Inst` (instance or atom).
- `Fnames` (list atoms).
- `Result` (variable).
- Usage: Gets the value of the first field specified in `Fnames` from the instan

---

### ❗The following predicates are Not Meant for End-User ❗

**Internal Class Helper Predicates:**

- `parse_class/4`:
- Parameters: 
- `Parents` (list of atoms).
- `Parts` (list of atoms).
- `Fields` (variable).
- `Methods` (variable).
- Usage: Splits into fields and methods, handle field types and dynamic methods 

- `check_subtype/2`:
- Parameters: 
- `Field` (field).
- `Parents` (list of atoms).
- Usage: Checks that the field `Field` if inherited is a subtype or the same typ

- `get_superfields_nc/2`:
- Parameters: 
- `Cname` (atom).
- `Acc` (variable).
- Usage: Retrieves the fields (own + inherited) of class `Cname` and binds them 

- `superclass/2`:
- Parameters: 
- `Super` (atom), 
- `Class` (atom).
- Usage: Checks whether the argument `Super` is a superclass of the argument `Cl
- Notes:
- In this predicate a class is not considered a superclass of itself

- `patch_body/3`:
- Parameters: -
- `Body` (callable), `This` (variable), `PBody` (variable).
- Usage: Patches the body of a function by replacing occurrences of `this` (atom
- Note: `This` must be unified before going out of scope, for this function to b

- `get_method/2`:
- Parameters: 
- `Sign` (compound), 
- `Body` (variable).
- Usage: Retrieves the body of the method specified by the signature `Sign` and 
- Notes:
- This predicate is meant to be called only by dynamic methods definitions, sinc

**Internal Instance Helper Predicates:**

- `ifields_2_fields/2`:
- Parameters: 
-`IFields` (list of initializers).
-`Fields` (variable).
- Usage: Converts a list of `initializers` to `fields` then binds them to `Field

- `init_fields/3`:
- Parameters: 
- `CFields` (list of fields).
- `Fields` (list of fields).
- `FieldList` (variable).
- Usage: Creates a list of fields equal to `CFields`, but uses values provided b

- `check_fields/2`:
- Parameters: 
- `IFields` (list of fields).
- `CFields` (list of fields).
- Usage: Checks that the 2 lists of fields are identical.
- Notes: The order of the fields inside the list must also be the same, otherwis

**If some predicates haven't been mentioned, it's because they are only needed t
