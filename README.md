This is currently in a beta state.  
The two core methods work [.to_ahk() .to_json()], but there's a lot of stuff I'm still working on [error checking, error correction, etc.].

# JSON_AHK

This is an AHK library that provides JSON support.  
json_ahk is able to convert JSON text into a valid AHK object as well as converting AHK object into JSON text.

This library comes with multiple methods as well as quite a few properties that can be set to customize your JSON text output.  
Some people want all elements of an array on one line, some wan't them on separate lines.  
Some people want the opening brace/bracket on the same line as the key. Some don't.
Some people just want their entire json on one line.  
You can do all of that with this library.  
The properties section below contains a list of all the properties and examples of what each does.

It should be noted that this library does suffer from some limitations imposed by the AHK language.
Known issues:  
    - AHK is a case-insensitive language. If any key-pair values differ only by their letter case, AHK considers them the same key.  
      Example: These keys are identical {"ALPHA":"WORDS", "alpha":"words"}  
      I'm trying to figure a way to overcome this limitation. Until then, I'll add a warning on duplicate keys.  
	- All arrays in AHK are objects. Because they are no differentiated in AHK, this library has to make assumptions based on index.  
	  Because of that, empty JSON arrays `[]` will always export as empty objects `{}`.  
      I have not come up with a way around this as it's core to the langauge.


## Methods  

   | Methods           | Return Value                 | Function                                                                                 |
   |:------------------|:-----------------------------|:-----------------------------------------------------------------------------------------|
   | .to_json(object)  | JSON string or 0 if failed.  | Convert an AHK object to JSON text.                                                      |
   | .to_ahk(json)     | AHK object or 0 if failed.   | Convert JSON text to an AHK object.                                                      |
   | .stringify(json)  | JSON string or 0 if failed.  | Removes all non-string whitespace.                                                       |
   | .validate(json)   | true if valid else false.    | Checks if object or text is valid JSON. Offers basic error correction.                   |
   | .import()         | JSON string or 0 if failed.  | Opens a window to select a JSON file.                                                    |
   | .preview(p1)      | Always returns blank.        | Preview current JSON export settings. Passing true to p1 will save preview to clipboard. |

## Properties

    | Property        | Default | Function                                                                                              |
    |:----------------|:--------|:------------------------------------------------------------------------------------------------------|
    | .indent_unit    | `t      | Assign indentation. Can be any character and any amount. Ex 2 spaces "  " or 2 tabs "`t`t".           |
    | .no_brace_ws    | true    | Removes whitespace from empty objects.                                                                |
    | .no_braces      | true    | Removes all braces and brackets from the JSON text export.                                            |
    | .ob_new_line    | true    | Put opening braces/brackets on a new line.                                                            |
    | .ob_val_inline  | false   | Indent opening brace to be inline with the values. This setting is ignored when .ob_new_line is true. |
    | .ob_brace_val   | false   | First element is put on the same line as the opening brace. Usually used with .ob_val_inline          |
    | .cb_new_line    | true    | Put closing braces/brackets on a new line.                                                            |
    | .cb_val_inline  | false   | Indent closing brace to be inline with the values. This setting is ignored when .ob_new_line is true. |
    | .array_one_line | true    | Put all array elements on same line.                                                                  |

### Property Examples:

```
------------------.---------------------------------------------
 .no_brace_ws     | True: [DEF]   {},
                  | False:        {        },
------------------+---------------------------------------------
 .ob_new_line     | True: [DEF]   "key":
                  |               [
                  |                   "value",
                  | False:        "key": [
                  |                   "value",
------------------+---------------------------------------------
  .ob_val_inline  | True:         "key":
                  |                   [
                  |                   "value1",
                  | False: [DEF]  "key":
                  |               [
                  |                   "value1",
------------------+---------------------------------------------
  .ob_brace_val   | True:         "key":
                  |                   ["value1",
                  |                   "value2",
                  | False: [DEF]  "key":
                  |                   [
                  |                   "value1",
                  |                   "value2",
------------------+---------------------------------------------
  .cb_new_line    | True: [DEF]       "value2",
                  |                   "value3"
                  |               }
                  | False:            "value2",
                  |                   "value3"}
------------------+---------------------------------------------
  .cb_val_inline  | True:             "value2",
                  |                   "value3"
                  |                   }
                  | False: [DEF]      "value2",
                  |                   "value3"
                  |               }
------------------+---------------------------------------------
  .array_one_line | True:         "key": ["value1", "value2"]
                  | False: [DEF]  "key": [
                  |                   "value1",
                  |                   "value2"
__________________|_____________________________________________
```

## Changelog
  - Fixed all issues with .to_ahk() and .to_json()
    Library works on a basic level now and can be used. :)
  - Added: .preview() method
  - Updated comment info
  - Added: esc_slash property
  - Fixed: Empty brace checking
  - Massive update to README file
