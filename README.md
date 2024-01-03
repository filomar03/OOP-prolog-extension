# Basic Object-Oriented Programming (OOP) Extension for Prolog

This Prolog extension introduces basic object-oriented programming concepts, allowing users to define classes, create instances, and work with fields and methods. Below are the main predicates exposed by this extension:

**Class-related Predicates:**

- `def_class/3`:
  - Parameters: `Cname` (class name), `Parents` (list of parent classes), `Parts` (list of class parts - fields/methods).
  - Usage: Defines a class with a unique name (`Cname`) having specified parent classes (`Parents`) and class parts (`Parts`), then asserts the class information into the database.
  - Note: The class name `Cname` must be unique

- `def_class/2`:
  - Parameters: `Class` (class name), `Parents` (list of parent classes).
  - Usage: A shorthand for defining a class without specifying any fields or methods initially.

- `is_class/1`:
  - Parameters: `Cname` (class name).
  - Usage: Checks if the given argument is a defined class.

**Instance-related Predicates:**

- `make/3`:
  - Parameters: `Iname` (instance name), `Cname` (class name), `Fields` (list of initial field values).
  - Usage: Creates an instance of a class (`Cname`) with name (`Iname`), specified field values (`Fields`) and asserts the instance information into the database.
  - Note: The instance name `Iname` must be unique

- `make/3`:
  - Parameters: `Inst` (resulting variable), `Cname` (class name), `Fields` (list of initial field values).
  - Usage: Creates an instance of a class (`Cname`) with specified field values (`Fields`) and binds it to the variable (`Inst`).

- `make/2`:
  - Parameters: `Iname` (instance name), `Cname` (class name).
  - Usage: A shorthand for creating an instance without specifying any initial fields.

- `is_instance/1`:
  - Parameters: `Inst` (instance).
  - Usage: Verifies that the given argument is a valid instance.

- `is_instance/2`:
  - Parameters: `Inst` (instance), `Parent` (parent class).
  - Usage: Verifies that the instance is a valid instance of the specified parent class.

- `inst/2`:
  - Parameters: `Iname` (instance name), `Inst` (instance).
  - Usage: Retrieves an instance with the given name from the database.

- `field/3`:
  - Parameters: `Inst` (instance), `Fname` (field name), `Result` (resulting value).
  - Usage: Gets the value of the specified field from the given instance.

- `field/3`:
  - Parameters: `Iname` (instance name), `Fname` (field name), `Result` (resulting value).
  - Usage: Gets the value of the specified field from the instance with the given name.

- `fieldx/3`:
  - Parameters: `Inst` (instance), `Fnames` (list of field names), `Result` (resulting value).
  - Usage: Gets a chain of fields from the given instance or instance name.

**The following predicates are Not Meant for End-User**

**Internal Class Helper Predicates:**

- `parse_class/3`:
  - Parameters: `Parts` (list of class parts), `Fields` (resulting variable), `Methods` (resulting variable).
  - Usage: Parses the class parts into fields and methods, handling field types and creating dynamic method definitions.

- `get_superfields_nc/2`:
  - Parameters: `Cname` (class name), `Acc` (resulting variable).
  - Usage: Retrieves all fields of a class (including inherited fields) and accumulates them.

- `superclass/2`:
  - Parameters: `Super` (superclass name), `Class` (class name).
  - Usage: Checks if `Super` is a superclass of `Class`.

- `patch_body/3`:
  - Parameters: `Body` (original body), `This` (variable), `PBody` (patched body).
  - Usage: Patches the body of a function by replacing occurrences of 'this' with a variable (`This`).
  - Note: `This` must be unified before going out of scope, for this function to be effective

**Internal Instance Helper Predicates:**

- `ifields_2_fields/2`:
  - Parameters: `IFields` (list of initializers), `Fields` (resulting variable).
  - Usage: Converts a list of initializers from 'make' to 'field' objects.

- `init_fields/3`:
  - Parameters: `CFields` (list of class fields), `Fields` (list of initialized fields), `FieldList` (resulting variable).
  - Usage: Creates a list of class fields (`CFields`), but uses values provided by initialized fields (`Fields`) .

- `check_fields/2`:
  - Parameters: `Fields` (list of fields), `CFields` (list of class fields).
  - Usage: Checks that fields are the same (except for values) based on their types.
  