# JSON_AHK

(Almost done! This will (should) be release by the end of this month!)

#Table of Contents

   1. [What is JSON_AHK?](#1-what-is-json_ahk)
   2. [Methods](#2-methods)
   3. [Properties](#3-properties)
   4. [Known Limitations](#4-known-limitations)*
   5. [Using the reviver](#5-using-the-reviver)
   6. [Examples](#6-examples)
      - [Reviver Examples](#reviver-examples)
   7. [History and Creation](#7-history-and-creation)

\*IMPORTANT NOTE: A lot of these limitations are removed in AHK v2.  
And to answer the question that just popped into your head: YES!  
I will be porting this to v2 as soon as I fully finish v1.

## 1) What is JSON_AHK?

This is an AutoHotkey library that gives AHK v1 JSON support.  
This allows for conversion of JSON text to AHK object, from object to text, and has quite a few other perks that come with it. 

## 2) Methods
```
   ____________  
  / .Methods() \               _______________  _____________
 / ____________ \_____________/ Return Value  \/ Description \_________________________________________________________
|_/            \_____________/________________/_______________\_______________________________________________________ |
|  import()                 ;  True : Str    | GUI JSON file selection. Reads file into memory. Returns text.         ||
|                           ;  False: 0      |                                                                        ||
|  to_obj(json_txt, [rev])  ;  True : Obj    | Converts JSON text string to an AHK object. rev is optional for using  ||
|                           ;  False: 0      | a reviver function to modify or remove data during object creation.    ||
|  to_json(ahk_obj, opt)    ;  True : Str    | Converts an AHK object to JSON text. Opt dictates output format.       ||
|                           ;  False: 0      | Opt: 1 | "string" = stringified, 0 | "pretty" | blank = Readable       ||
|  validate(json_txt)       ;  True : 1      | Validates the JSON text passed in.                                     ||
|                           ;  False: 0      |                                                                        ||
|  pretty(json)             ;  True : Str    | Converts an AHK object or JSON text into human readable JSON text.     ||
|                           ;  False: 0      | Pretty has formatting and indentation.                                 ||
|  stringify(json)          ;  True : Str    | Converts an AHK object or JSON text into portable JSON text.           ||
|                           ;  False: 0      | Stringify = no formatting, most compact, quickest to import.           ||
|___________________________;________________|________________________________________________________________________|/
```

## 3) Properties
```
   ________________  
  /  .Properties   \          _________  _____________
 / ________________ \________/ Default \/ Information \_______________________________________________ 
|_/ Import Options \________/__________/_______________\_____________________________________________ |
|  error_offset             ;  40      | Number of chars to show left and right of error display     ||
|  dupe_key_check           ;  True    | True  = Check for duplicate keys (due to case difference)   ||
|                           ;          | False = Ignore duplicate key checking                       ||
|  import_strip_quotes      ;  True    | True  = Remove string quotes when importing JSON text       ||
|                           ;          | False = Keep string quotes when importing JSON text         ||
|  convert_unicode          ;  False   | True  = Convert unicode escapes to their char               ||
|                           ;          | False = Unicode remains in \uHHHH                           ||
|  convert_tfn              ;  True    | True  = On import set true > 1, false > 0, null > Chr(0)    ||
|                           ;          | False = On import keep true, false, and null as strings     ||
|  save_large_nums          ;  True    | True  = If value is out of range, number is saved as string ||
|                           ;          | False = Values too large for AHK are saved as blank strings ||
|    __________________          _________  _____________                                            ||
|   / ________________ \________/ Default \/ Information \___________________________________________||__
|  |_/ Export Options \________/__________/_______________\_____________________________________________ |
|  |  indent                   ;  0       | Set indent spacing. 0 = Tab, 1+ = Number of spaces to use.  ||
|__|  empty_obj_type           ;  True    | True  = Empty objects and arrays export as {}               ||
   |                           ;          | False = Empty objects and arrays export as []               ||
   |  escape_slashes           ;  True    | True  = Forward slashes will be escaped: \/                 ||
   |                           ;          | False = Forward slashes will not be escaped: /              ||
   |  key_value_inline         ;  True    | True  = Object values and keys appear on same line          ||
   |                           ;          | False = Object values appear indented below key name        ||
   |  key_bracket_inline       ;  False   | True  = Brackets are on same line as key                    ||
   |                           ;          | False = Brackets are put on line after key                  ||
   |  export_add_quotes        ;  True    | True  = Add quotes to strings when exporting                ||
   |                           ;          | False = Assume all strings have quotes when exporting       ||
   |  arr_values_inline        ;  False   | True  = All array values appear on the same line            ||
   |                           ;          | False = Array values each appear on their own new line      ||
   |___________________________;__________|_____________________________________________________________|/
```

## 4) Known Limitations

- **AutoHotkey is not case-sensitive!**
  - That means AHK objects cannot have keys that only differ by case.
  - There is a duplicate key checker that notifies when duplicate keys.
    - You'll have the choice to rename the key, overwrite the original key, or cancel.

- **AutoHotkey does not have an array data type**
  - In AutoHotkey, arrays are numerically indexed objects.
  - This library "assumes" an object is array type if:
    - All keys are numeric
    - The first key is 1
    - Each subsequent key is 1 greater than previous

- **Because arrays are objects, there is no way to differentiate between empty arrays and empty objects**
  - This library forces all empty arrays and objects to export as one type, set by the empty_obj_type property.
    Meaning if a JSON file imports with both empty arrays and objects, at export they will ALL be empty object or empty array.
  - The empty_obj_type property lets you choose if you want empty items to export as ojects {} or arrays [].

- **Real tabs, line feeds, and carriage returns inside strings are discard and never reported as errors (This is not a limitation but more of a disclosure)**
  - Due to how I format the data prior to parse, all line feeds, carriage returns, and tabs inside the JSON file are discarded.
  - The reason for this is actual line feeds, carriage returns, and tabs are endcoded as \n \r and \t respectively inside of strings.  
    The test
    - Because of that, line feeds, carriage returns, and tabs inside of strings never throw an error and never show up. As far as the parser is concerne, they never existed because they shouldn't have been in there in the first place.

## 5) Using the reviver

Template:
```
reviver_func(key, val, type, rem) {
    ; Run whatever code here
    MsgBox, % "P1 - key: " key
        . "`nP2 - val: " val
        . "`nP3 - type: " type 
    Return value ; Then always return a value
    ;Return rem ; Return the 4th param to drop the item from the object
}
```

A reviver lets the user interact with/"tap into" the parser during run time.  
Using a reviver function, you're given the ability to see every key:value pair as well as the value's type (string/number/true/false/null).  
The reviver allows you to make alter or omit the data from the object being built.  
It's designed to work similarly to JavaScript's `parse(json, reviver)`.

To use a reviver, make a function and give it 4 parameters to receive from the parser.  
`reviver_func(p1_key, p2_value, p3_value_type, p4_remove)`

The key name can be used to find specific data.  
Value is the raw text from the JSON file. No conversion is done. This is always string coming in. Which brings us to...  
Value type! This is how you know what data type the value is. It'll always be one of the following
   - s   = String
   - n   = Number
   - tfn = true/false/null

And Remove is used to omit the current value from the object.  
So `Return p4_remove` would prevent the current key:value pair from ever being added.

## 6) Examples

### Reviver Examples:

Let's say your boss wants everyone's first and last name to ALWAYS be capitalized. In every document. On every form.  
You know that the JSON being imported always has 2 keys for the person's name. `first_name` and `last_name`  
Instead of making sure that every single piece of code you're every going to run checks those names, you can build a reviver.  
Do it once at import and then never worry about it again.

This reviver's purpose is to look for keys called `first_name` and `last_name` and capitalize the first letter.
```
    name_fixer(key, val, type, rem)
    {
        If (key = "first_name")              ; If first name is found
            return Format("{:T}", val)       ; Format with Titlecase
        Else If (key = "last_name")          ; Else if last name is found
            return Format("{:T}", val)       ; Format with Titlecase
        Return val                           ; Else return value
    }
```

Another scenario. You're importing a bunch of domestic phone numbers.  
Question: How many different ways can you write a number?  
Answer: A LOT! You could write it almost any you want.
Here are bunch of common ways:
  * 777-555-1234
  * +1-777-555-7890
  * 1 (777) 555-7890
  * 001-777-555-7890
  * 555-7890
  * 17775554321
  * 1 777 555 4567
  * 001 777 555 4567

I could make a hundred variations, but you get the idea.
They all share something in common. There's always a 4 digit extension number and 3 digit exchange number.  
We can use  to capture those numbers, organize them into an array, and return it in place of the original phone number value.

It would look like this:  
Make a reviver to search for keys matching "phone".  
Run a [`RegExMatch`](https://autohotkey.com/docs/commands/RegExMatch.htm) on the value to capture the groups of numbers.
Return the array instead of the original number's value. 

```
parse_phone_nums(key, value, type, rem)
{
    Static rgx := "(?P<area>\d{3})\D*?(?P<exch>\d{3})\D*?(?P<ext>\d{4})\D*$"    ; RegEx match for a phone number
         , domestic := "777"                                                    ; Default area code if not provided
    If (key == "phone")                                                         ; Check if key is phone
    {
        num_ := ""
        If RegExMatch(value, rgx, num_)                                         ; Try to match a phone number
           value := {}                                                          ; If match, turn value into an array
           ,value.area := (num_area = "" ? domestic : num_area)                 ; Add the area code. Default if none.
           ,value.exchange := num_exch                                          ; Add the exchange
           ,value.extension := num_ext                                          ; Add the extension
        Return value                                                            ; Return value (still has original value if regexmatch failed)
    }
    Return value                                                                ; If key isn't phone, return original value
}
```

## 7) History and Creation

Why create a JSON library if one already exists?

When I needed an AHK JSON parser and Googled for one, Coco's library is what came up.
But when I tested it, I grew concerned. It worked...mostly. But certain valid numbers wouldn't validate correctly. They had to do with exponents.

Those number errors didn't really affect me, but it *bothered* me.  
"Why would a library created to work with JSON text **not** validate a valid number?"
This bugged me more than it should have.  
I started wondering if I could make a parser. Not only that, but make one from the ground up. From scratch.
Was I capable of doing so? And if so, could I make a faster? More robust?

I started consuming everything JSON related.
From the [Mozilla JSON docs](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON) to the [flowcharts on JSON.org](https://www.json.org/json-en.html) to the [EMCA-404](https://www.ecma-international.org/publications-and-standards/standards/ecma-404/).  
This became my project for like months when I wasn't doing my other little stuff.

I tried all kinds of different things. I think I built something like 6 completely different FSMs from the ground up.  
From making a parser using matrix validation (holy shit, table-lookups in AHK are slow!), to making a regex based parser (shockingly fast considering it used RegEx), to substringing through the file, to parse-looping through the file char by char, to the current version I have now.  
And optimizing? Oh...my...god. So many optimizations. I have an ENTIRE FILE dedicated to optimizing AHK commands.  
Example: Which process faster? `x := y+1`, `x++ := y`, or `x := ++y`  
Constantly checking for the next way to shave time off.

It just spiraled out of control from there. But it was FUN! I learned sooooooooo much. 
I write almost exclusively in ternary now because of this and another project (spoiler alert: It may or may not have to do with AHK getting an updated and faster GDIPlus library).

The final version I decided on now parses roughly 75% faster than Coco's and that's WITH the options I've added.  
My no means am I badmouthing Coco. That dude is awesome and provided JSON support for the AHK community long before I even considered using JSON with AHK...let alone write a parser for it.  
For that, I'd like to close out the first section by saying this:  
***Thanks for making your JSON AHK library, Coco. Anyone who contributes to the community is a great person and is A-OK with me! :)***
