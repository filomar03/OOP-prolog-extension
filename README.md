# Basic Object-Oriented Programming (OOP) Extension for Prolog

This Prolog extension introduces basic object-oriented programming concepts, allowing users to define classes, create instances, and work with fields and methods. Below are the main predicates exposed by this extension:

**Class-related Predicates:**

- `def_class/3`:
  - Parameters: `Cname` (class name), `Parents` (list of parent classes), `Parts` (list of class parts - fields/methods).
  - Usage: Defines a class with a unique name (`Cname`) having specified parent classes (`Parents`) and class parts (`Parts`), then asserts the class information into the database.
  - Note: 
    - The class name `Cname` must be unique.
    - Fields with unspecified types are set to `atom`.
    - Inheritance system traverse parents tree by depth.
    - When fields/methods with same name/signature are defined multiple times in the same class, only the first occurrence will be considered.
    - When inheriting a field, type must be the same or a subtype

- `def_class/2`:
  - Parameters: `Class` (class name), `Parents` (list of parent classes).
  - Usage: A shorthand for defining a class without specifying any fields or methods.

- `is_class/1`:
  - Parameters: `Cname` (class name).
  - Usage: Checks if the given argument is a defined class.

**Instance-related Predicates:**

- `make/3`:
  - Parameters: `Iname` (instance name), `Cname` (class name), `Fields` (list of initial field values).
  - Usage: Creates an instance of a class (`Cname`) with name (`Iname`), specified field values (`Fields`) and asserts the instance information into the database.
  - Note: 
    - The instance name `Iname` must be unique.
    - When the same field is initialized multiple times only the first one will be considerated.

- `make/3`:
  - Parameters: `Inst` (variable), `Cname` (class name), `Fields` (list of initial field values).
  - Usage: Creates an instance of a class (`Cname`) with specified field values (`Fields`) and binds it to the variable (`Inst`).

- `make/3`:
  - Parameters: `Inst` (instance), `Cname` (class name), `Fields` (list of initial field values).
  - Usage: Creates an instance of a class (`Cname`) with specified field values (`Fields`) and checks if it the same as (`Inst`).

- `make/2`:
  - Parameters: `Iname` (instance name / variable / instance ), `Cname` (class name).
  - Usage: A shorthand for calling `make/3` without specifying any initial fields.

- `is_instance/1`:
  - Parameters: `Inst` (instance).
  - Usage: Verifies that the given argument is a valid instance.

- `is_instance/2`:
  - Parameters: `Inst` (instance), `Super` (class name).
  - Usage: Verifies that the instance is a valid instance and a subclass of `Super`. 

- `inst/2`:
  - Parameters: `Iname` (instance name), `Inst` (instance).
  - Usage: Retrieves an instance with the given name from the database.

- `field/3`:
  - Parameters: `Inst` (instance), `Fname` (field name), `Result` (variable).
  - Usage: Gets the value of the specified field from the given instance and unifies it with `Result`.

- `field/3`:
  - Parameters: `Iname` (instance name), `Fname` (field name), `Result` (variable).
  - Usage: Gets the value of the specified field from the instance with the given name and unifies it with `Result`.

- `fieldx/3`:
  - Parameters: `Inst` (instance), `Fnames` (list of field names), `Result` (resulting value).
  - Usage: Gets a chain of fields from the given instance or instance name, unifying to `Result`.

**The following predicates are Not Meant for End-User**

**Internal Class Helper Predicates:**

- `parse_class/3`:
  - Parameters: `Parts` (list of class parts), `Fields` (resulting variable), `Methods` (resulting variable).
  - Usage: Parses the class parts into fields and methods, handling field types and dynamic method definitions.

- `check_subtype/2`:
  - Parameters: `Field` (field), `Parents` (list of class names).
  - Usage: checks that `Field` if inherited is a subtype of the inherited one.

- `get_superfields_nc/2`:
  - Parameters: `Cname` (class name), `Acc` (variable).
  - Usage: Retrieves all fields of a class (including inherited fields) and accumulates them.

- `superclass/2`:
  - Parameters: `Super` (class name), `Class` (class name).
  - Usage: Checks if `Super` is a superclass of `Class`.

- `patch_body/3`:
  - Parameters: `Body` (original body), `This` (variable), `PBody` (patched body).
  - Usage: Patches the body of a function by replacing occurrences of 'this' with a variable (`This`).
  - Note: `This` must be unified before going out of scope, for this function to be effective

**Internal Instance Helper Predicates:**

- `ifields_2_fields/2`:
  - Parameters: `IFields` (list of initializers), `Fields` (variable).
  - Usage: Converts a list of initializers from 'make' to 'field' objects.

- `init_fields/3`:
  - Parameters: `CFields` (list of fields), `Fields` (list of fields), `FieldList` (variable).
  - Usage: Creates a list of class fields equal to `CFields`, but uses values provided by `Fields`.

- `check_fields/2`:
  - Parameters: `Fields` (list of fields), `CFields` (list of class fields).
  - Usage: Checks that the 2 lists of fields (`Fields` and `CFields`) have the same fields (except from value).
  
- `type/2`:
  - Parameters: `Value` (value), `Type` (type).
  - Usage: check that `Value` is the same type as `Type`, if `Type` is allowed.

- `subtype/2`:
  - Parameters: `Subtype` (type), `Type` (type).
  - Usage: check if `Subtype` is a subtype of `Type`.