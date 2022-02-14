# JSON_AHK

Update: 08Feb2022
It's been a while but I've finally resumed work on JSON_AHK.  
It's in a mostly working state.
I'm in the process of creating a battery of error testing scenarios.  
This ReadMe is under active development, too.

#Table of Contents

   1. Description and Information
   2. Known Limitations
   3. Methods and Properties

## 1) Description and Information

This is an AHK library I designed from th ground up to give AutoHotkey the ability to work with JSON files.  
This library allows for conversion of JSON text to AHK object, from object to JSON text, and has quite a few other bells and whistles (covered below).  
It has basic object and json conversions as well as many preferences (covered below).

Why create it if a JSON library already exists?
I created this library after realizing there is not a JSON lib for AHK that works correctly.
Initially, I tried Coco's library. And it does work...mostly.  
I grew concerned when it failed to validate multiple numbers in a JSON test file.
After realizing that, I decided to write my own validator. Not only to ensure ALL data validates correctly, but also to see if I could increase the performance speed and efficiency of the process as much as possible while keeping it all native to AHK.  
This new library runs x2 faster than Coco's, appears to validate all data types correctly (still running tests), and has a bunch of configuration and customization features added to it, handled all through changing properties.

## 2) Known Limitations

- **AutoHotkey is not case-sensitive!**
  - That means AHK objects cannot have keys that only differ by case.
  - There is a duplicate key checker that notifies you of a duplicate key.

- **AutoHotkey does not have an array data type**
  - In AutoHotkey, arrays are just numerically indexed objects.
  - This library "assumes" that an object is of array type if:
    - All keys are numeric
    - The first key is a 1
    - Each subsequent key is 1 greater than the last

- **Because arrays are objects, there is no way to differentiate between empty arrays and empty objects**
  - This library forces all empty arrays and objects to export as one type, set by the empty_obj_type property.
  - The empty_obj_type property lets you choose if you want all empty items to export as ojects {} or arrays []

## 3) Methods and Properties

```
  _________________
 / Class: json_ahk \__________________________________________________________________________________________________
/__________________/_________________________________________________________________________________________________/|
|_Methods:________________|_Description and return values____________________________________________________________||
|  import()               | GUI prompt to select file. Return JSON text or 0 on fail.                                ||
|  import_to_obj()        | GUI prompt to select file. Return converted object or 0 on fail.                         ||
|  to_obj(json_text)      | Convert JSON text to an AHK object. Return object or 0 on fail.                          ||
|  to_json(obj, opt:="")  | Convert AHK object to JSON text. Fail returns 0.                                         ||
|                         | opt = 0 OR "pretty" -> Text is formatted for human readability.                          ||
|                         | opt = 1 OR "stringify" -> No formatting or padding. Output is on 1 line for portability. ||
|  validate(json_text)    | Validate JSON text -> Return 1 for valid or 0 on fail.                                   ||
|  pretty(json_in)        | Returns formatted (readable) JSON text or 0 on fail.                                     ||
|                         | json_in can be JSON text or an AHK object.                                               ||
|  stringify(json_in)     | Returns JSON text on 1 line with no formatting or 0 on fail.                             ||
|                         | json_in can be JSON text or an AHK object.                                               ||
|___NOT_YET_IMPLEMENTED___|__________________________________________________________________________________________||
|   preview()             | Show preview of current export settings using built-in test file.                        ||
|   editor()              | Launch JSON editor designed for troubleshooting.                                         ||
|____________________________________________________________________________________________________________________||
|====================================================================================================================||
|_Properties:__________|_Default_|_Description_______________________________________________________________________||
|  error_last          |         | Store information about last error                                                ||
|  error_log           |         | Store all errors this session                                                     ||
|  indent_unit         |  "  "   | Chars used for each level of indentation e.g. "`t" =tab, "  " = 2 spaces, etc.    ||
|  dupe_key_check      |  True   | True -> checks for duplicate keys, false -> ignore checking                       ||
|  error_offset        |  30     | Number of characters left and right of caught errors                              ||
|  import_keep_quotes  |  True   | True  -> Keep string quotes when importing JSON text.                             ||
|                      |         | False -> Remove string quotes when importing JSON text.                           ||
|  export_add_quotes   |  True   | True  -> Add quotes to strings when exporting JSON text.                          ||
|                      |         | False -> Assume all strings are quoted when exporting JSON text.                  ||
|  empty_obj_type      |  True   | True  -> {}          Empty objects/arrays export as {}                            ||
|                      |         | False -> []          Empty objects and arrays export as []                        ||
|  escape_slashes      |  True   | True  -> \/          Forward slashes will be escaped: \/                          ||
|                      |         | False -> /           Forward slashes will not be escaped: /                       ||
|  key_bracket_inline  |  False  | True  -> key: {      Brackets are on same line as key                             ||
|                      |         | False -> key:        Brackets are put on line after key                           ||
|                      |         |          {                                                                        ||
|  key_value_inline    |  True   | True  -> key: value  Object values and keys appear on same line                   ||
|                      |         | False -> key:        Object values appear indented below key name                 ||
|                      |         |            value                                                                  ||
|______________________|_________|___________________________________________________________________________________|/
```
