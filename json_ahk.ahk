/*

  _________________
 / Class: json_ahk \__________________________________________________________________________________________________
/__________________/_________________________________________________________________________________________________/|
|_Methods:________________|_Description and return values____________________________________________________________||
|  import(convert:=1)     | GUI prompt to select file. Fail returns 0.                                               ||
|                         | Convert true returns JSON text converted to object.                                      ||
|                         | Convert false returns the JSON text from chosen file.                                    ||
|  to_obj(json_text)      | Converts JSON text to AHK object. Fail returns 0.                                        ||
|  to_json(obj, opt:="")  | Convert an AHK object to JSON text. Fail returns 0.                                      ||
|                         | opt = 0 or "pretty" returns text formatted for human readability                         ||
|                         | opt = 1 or "stringify" returns text with no formatting for portability                   ||
|  validate(json_text)    | Validates JSON text -> returns 1 for valid or 0 for failure                              ||
|  stringify(json)        | Returns json_text without any formatting                                                 ||
|                         | Both objects and json text can be passed in                                              ||
|___NOT_YET_IMPLEMENTED___|__________________________________________________________________________________________||
|   preview()             | Show preview of current export settings using the built in test file                     ||
|   editor()              | Launch the JSON editor used for troubleshooting                                          ||
|____________________________________________________________________________________________________________________||
|====================================================================================================================||
|_Properties:__________|_Default_|_Description_______________________________________________________________________||
|  error_last          |         | Stores information about last error                                               ||
|  error_log           |         | Store list of all errors this session                                             ||
|  indent_unit         |  "  "   | Chars used for each level of indentation e.g. "`t" for tab                        ||
|  dupe_key_check      |  True   | True -> check for duplicate keys, false -> ignore the check                       ||
|  error_offset        |  30     | Number of characters left and right of caught errors                              ||
|  empty_obj_type      |  True   | True  -> {}          Empty objects/arrays export as {}                            ||
|                      |         | False -> []          Empty objects and arrays export as []                        ||
|  escape_slashes      |  True   | True  -> \/          Forward slashes will be escaped: \/                          ||
|                      |         | False -> /           Forward slashes will not be escaped: /                       ||
|  key_value_inline    |  True   | True  -> key:value   Object values and keys appear on same line                   ||
|                      |         | False -> key:        Object values appear indented below key name                 ||
|                      |         |            value                                                                  ||
|  key_bracket_inline  |  False  | True  -> key: {      Brackets are on same line as key                             ||
|                      |         | False -> key:        Brackets are put on line after key                           ||
|                      |         |          {                                                                        ||
|  import_keep_quotes  |  True   | True  -> Keep string quotes when importing JSON text.                             ||
|                      |         | False -> Remove string quotes when importing JSON text.                           ||
|  export_add_quotes   |  True   | True  -> Add quotes to strings when exporting JSON text.                          ||
|                      |         | False -> Assume all strings are quoted when exporting JSON text.                  ||
|______________________|_________|___________________________________________________________________________________|/
*/

Class JSON_AHK
{
    ;===========================================================================.
    ; Title:        JSON_AHK                                                    |
    ; Desc:         Library that converts JSON to AHK objects and AHK to JSON   |
    ; Author:       0xB0BAFE77                                                  |
    ; Created:      20200301                                                    |
    ; Last Update:  20220209                                                    |
    ;==========================================================================='
    
    ; AHK limitations disclaimer
    ;   - AHK is not a case-sensitive language. Object keys that only differ by case are considered the same key to AHK.
    ;     There is a built-in duplicate key checker that should catch this.
    ;   - Arrays are objects in AHK and not their own defined type.
    ;     This library "assumes" an array by checking 2 things:
    ;	    If the first key is a 1 or 0
    ;       Every subsequent key is 1 greater than the last
    ;     Because arrays are objects, there's no way to tell an empty array from an empty object
    ;     The property called empty_obj_type that allows you to choose if empty objects export as [] or {}
    
    ; Currently working on/to-do:
    ;   - Need to build a custom error display GUI and implement full error checking.
    ;     - This should be able to pinpoint the exact spot where the error occurred and why
    ;     - Edit box will allow for quick manual corrections and resubmissiom for processing
    ;     - Would like to try and make a smart-fixer for troubleshooting common problems automatically.
    ;   - Verify all return values
    ;   - Need to implement preview(). This will use the same custom edit box the error detector will use.
    
    ;==================================================================================================================
    ; AHK to JSON settings  | Setting  | Default | Information
    ;----------------------------------;---------+------------------------------------------------------------------
    Static indent_unit        := "  "  ; "  "    | Chars used for each level of indentation e.g. "`t" for tab
    Static dupe_key_check     := True  ; True    | True = Check for duplicate keys such as keys that only differ by case
    ;                                  ;         | False = Ignore key checking
    Static empty_obj_type     := True  ; True    | True = Empty objects and arrays export as {}
    ;                                  ;         | False = Empty objects and arrays export as []
    Static escape_slashes     := True  ; True    | True = Forward slashes will be escaped: \/
    ;                                  ;         | False = Forward slashes will not be escaped: /
    Static key_value_inline   := True  ; True    | True = Object values and keys appear on same line
    ;                                  ;         | False = Object values appear indented below key name
    Static key_bracket_inline := False ; False   | True = Brackets are on same line as key
    ;                                  ;         | False = Brackets are put on line after key
    Static import_keep_quotes := True  ; True    | True = When importing JSON text, store string quotes
    ;                                  ;         | False = When importing JSON text, remove string quotes
    Static export_add_quotes  := True  ; True    | True = When exporting JSON text, add quotes to strings
    ;                                  ;         | False = When exporting JSON text, assume all strings are quoted
    Static error_offset       := 30    ; 30      | Number of characters left and right of caught errors
    ;--------------------------------------------+------------------------------------------------------------------
    
    ; RegEx Bank (Kudos to mateon1 at regex101.com for creating the core of some of these.)
    Static rgx	    :=  {"k" : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ ]*:[ ]*" ; key
                        ,"s" : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ ]*"      ; string
                        ,"n" : "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))[ ]*"                  ; number
                        ,"b" : "(?P<str>true|false|null)[ ]*"                                                           ; bool
                        ,"b2": "^(?P<str>true|false|null)$"                                                             ; bool|null strict
                        ,"s2": "^(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))$"        ; string strict
                        ,"n2": "^(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))$"}                   ; number strict
    
    ; Used to sort through values when parsing
    Static is_val   :=  {"0":"n" ,"5":"n" ,0:"n" ,5:"n" , "-":"n"       ; s = string
                        ,"1":"n" ,"6":"n" ,1:"n" ,6:"n" , "t":"b"       ; n = number
                        ,"2":"n" ,"7":"n" ,2:"n" ,7:"n" , "f":"b"       ; b = bool = true/false
                        ,"3":"n" ,"8":"n" ,3:"n" ,8:"n" , "n":"b"       ; b = null is not bool but included
                        ,"4":"n" ,"9":"n" ,4:"n" ,9:"n" ,"""":"s"}
    
    ; Prompt user to select file then convert to an object
    ; Validation is handled during conversion
    import(convert:=1)
    {
        Local
        FileSelectFile, path, 3,, Select a JSON file, JSON (*.json; *.js; *.txt)
        If (ErrorLevel = 1)
        {
            this.error(A_ThisFunc "`nFile select canceled.")
            Return 0
        }
        FileRead, json_txt, % path
        
        Return convert ? this.to_object(json_txt) : json_txt
    }
    
    ; Error logging that can be found be checking json_ahk.error_log
    ; this.error(A_ThisFunc "`nat index " index ".")   ; 
    error(txt, report:=0)
    {
        (report = 0)
            ? (this.error_last := A_Now "`n" txt, this.error_log  .= this.error_last "`n`n")
        Return (report = 1) ? error_last
            :  (report = 2) ? 
            
    }
    
    ; Validates JSON text
    validate(json)
    {
        Return this.to_obj(json, 1)
    }
    
    ; Convert JSON text to an AHK object
    ; Returns 0 if fail
    ; Returns 1 if validating (valid set to true)
    ; Otherwise, returns JSON object
    to_obj(json, valid:=0)
    {
        Local
         json       := this.strip_ws(json)          ; Strip whitespace to speed up validation
        ,path       := []                           ; Stores the current object path
        ,is_arr     := []                           ; Track if path is in an array (1) or an object (0)
        ,p_index    := 0                            ; Tracks path index
        ,char       := ""                           ; Current character of json text
        ,next       := "s"                          ; Next expected action: (s)tart, (k)ey, (v)alue, (a)rray, (e)nder
        ,m_         := ""                           ; Stores regex matches
        ,m_str      := ""                           ; Stores regex match subpattern
        ,max        := StrLen(json)                 ; Track total characters in json
        ,err        := 0                            ; Track if an error occurs
        ,this.index := 0                            ; Tracks position in JSON string
        ,obj        := {}                           ; Object to build and return
        ,this.jbak  := json
        
        ; FSM for validating JSON text and building an obj
        While (this.index < max) && (err < 1)                                                       ; Start parsing JSON file
        {
            ((char := SubStr(json, ++this.index, 1)) = " ") ? ""                                    ; Increment index, get next char, and skip if char is space
            : next == "v"                                                                           ; If next expected is a value...
                ? this.is_val[char]                                                                     ; Check if char is valid start to a value
                    ? RegExMatch(json, this.rgx[this.is_val[char]], m_, this.index)                     ; Validate value
                        ? (this.index += StrLen(m_)-1, next := "e"                                      ; If a value, update index and next and continue
                            , (this.dupe_key_check && obj.HasKey(path*)                                 ; Duplicate key checker
                                ? err := this.to_obj_err(1, path)                                       ; Error out if duplicate found
                                : valid ? ""                                                            ; Do nothing else if only validating
                                : obj[path*] := (char == """" ? this.json_decode(m_str) : m_str)))      ; Else add the value, encoding it if it's a string
                        : err := this.to_obj_err(2, path)                                               ; If not valid, error out
                : char == "{" ? next := "k"                                                             ; Else if char is open curly brace, create new object and set next to key
                : char == "[" ? next := "a"                                                             ; Else if char is open square brace, create new array and set next to array
                : err := this.to_obj_err(3, path)                                                       ; If no char match, error out
            : next == "e"                                                                           ; If next expected is ender (end of a piece of data)...
                ? char == ","                                                                           ; If char is comma, another value is expected
                    ? is_arr[p_index] ? (path[p_index]++, next := "v")                                  ; If current path is array, expect a value
                    : (path.Pop(), --p_index, next := "k")                                              ; Else if current path is object, expect a key
                : (char == "]" && is_arr[p_index])                                                      ; If char is close square bracket and path is array
                || (char == "}" && !is_arr[p_index])                                                    ; OR if char is close curly brace and path is object
                    ? (path.Pop(), --p_index)                                                           ; Update path, is_arr, and path index
                : err := this.to_obj_err(4, path)                                                       ; Otherwise, error out
            : next == "k"                                                                           ; If next expected is start of object (key)
                ? char == "}" ? (next := "e")                                                           ; If char is closing curly brace, add empty object and expect ender
                : RegExMatch(json, this.rgx.k, m_, this.index)                                          ; Else check if valid key
                    ? (++p_index, path[p_index] := m_str, is_arr[p_index] := 0                          ; If valid, increment path index, update path is_arr to object, add key to path...
                        ,this.index += StrLen(m_) - 1, next := "v" )                                    ; ...update index, and a value should be expected next
                    : err := this.to_obj_err(5, path)                                                   ; Otherwise, error out
            : next == "a"                                                                           ; If next expected is start of an array
                ? char == "]" ? (next := "e")                                                           ; If closing square bracket, add empty array and expect ender
                : (path[p_index] := is_arr[++p_index] := 1, next := "v", --this.index)                  ; Otherwise, path, is_arr, expect a value, and decrment index b/c we're currently on the first char of the value
            : next == "s"                                                                           ; If next expected is start of JSON
                ? char == "{" ? next := "k"                                                             ; If open curly brace, expect a key (start of object)
                : char == "[" ? next := "a"                                                             ; If open square braace, expect start of an array
                : err := this.to_obj_err(6, path)                                                       ; Otherwise, error out
            : err := this.to_obj_err(7, path)                                                       ; Final catch error. This should never be seen. 
        }
        
        (p_index != 0) ? err := this.to_obj_err(8, path) : ""                                       ; p_index being 0 means all paths were successfully closed
        
        Return (err > 0) ? 0
            : (valid) ? 1
            : obj
    }
    
    to_obj_err(index, path, msg_num)
    {
        msg_list := {1: {msg    : "Duplicate key was found."
                        ,expct  : "Due to AHK not being case sensitive, this can happen "
                                . "if a JSON file has 2 keys that only differ in case."}
                    ,2: {msg    : "Error finding valid value."
                        ,expct  : "string number true false null"}
                    ,3: {msg    : "Invalid JSON value."
                        ,expct  : "string number object array true false null"}
                    ,4: {msg    : "Invalid ending character."
                        ,expct  : ", ] }"}
                    ,5: {msg    : "Invalid character after start of object."
                        ,expct  : "string }"}
                    ,6: {msg    : "A JSON file must start with a square bracket or a curly brace."
                        ,expct  : "{ ["}
                    ,7: {msg    : "Invalid next variable during parse value."
                        ,expct  : "The end user should never see this message."}
                    ,8: {msg    : "Open array(s) or object(s)."
                        ,expct  : "All open brackets/braces must have an accompanying closing bracket/brace"} }
        
        path_full := ""
        , max     := StrLen(this.jbak)
        , offset  := this.error_offset
        
        For k, v in path
            path_full .= (A_Index > 1 ? "." : "") v
        
        MsgBox, % "Error at index: " index
            . "`nCharacter: " SubStr(this.jbak, index, 1)
            . "`nPath: " path_full
            . "`nError Message: " msg
            . "`nExpected: " expected
            . "`n`n" SubStr(this.jbak
                , (index - offset < 1 ? 1 : index - offset)
                , (index - offset < 1 ? index-1 : offset))
            . " >>>" SubStr(this.jbak, index, 1) "<<< "
            . SubStr(this.jbak, index+1, (index + offset > max ? "" : offset))
        Return 1
    }
    
    strip_ws(txt)
    {
         txt := StrReplace(txt, "`t")
        ,txt := StrReplace(txt, "`n")
        ,txt := StrReplace(txt, "`r")
        Return Trim(txt, " ")
    }
    
    ; Convert AHK object to JSON string
    ; Options:
    ;   0 | "pretty"    > Exports text formatted for human readability
    ;   1 | "stringify" > Exports text with no formatting for portability
    to_json(obj, opt:="")
    {
        str := Isobject(obj)
            ? this.to_json_extract(obj)
            : ({"":1, 0:1, "pretty":1}[opt]
                ? "[`n" this.indent_unit obj "`n]"
                : "[" obj "]")
        Return str
    }
    
    ; "New line on need"
    to_json_extract(obj, ind:="")
    {
        If this.is_empty_object(obj)                                            ; Check if object is empty
            Return "`n" ind (this.empty_obj_type ? "{}" : "[]")                 ; Return empty obj/arr based on user preference
        
        ind2    := ind . this.indent_unit                                       ; Step up indent
        , str   := (is_arr := this.is_array(obj)) ? "[" : "{"                   ; If array add bracet else add brace
        
        For k, v in obj                                                         ; Loop through object
            str .= (A_Index = 1 ? "" : ",")                                     ; Multiple item comma check
                . (is_arr ? "" : "`n" ind2 this.json_encode(k) ": ")
                . (IsObject(v)                                                  ; If value is object
                    ? ((is_arr || !this.key_bracket_inline ? "`n" ind2 : "")
                        . this.to_json_extract(v, ind2))                        ; Recursively extract object
                    : (is_arr ? ""
                        : this.key_value_inline ? "" 
                        : "`n" ind2 this.indent_unit)
                    . ((this.is_num(v) || this.is_tfn(v)) ? v                   ; If number|true|false|null use value
                        : this.json_encode(v)))                                 ; Else value is string so encode
        
        Return RTrim(str, ",")                                                  ; Strip extra comma off end
            . "`n" ind
            .  (is_arr ? "]" : "}")                                             ; End with correct bracket
    }
    
    stringify(json)
    {
        Return IsObject(json)
            ? this.stringify_object(json)
            : this.stringify_text(json)
    }
    
    stringify_text(txt)
    {
        index := 1
        , txt := this.strip_ws(txt)
        , str := ""
        
        While (start := RegExMatch(txt, this.rgx.s2, match, index))
            str .= StrReplace(SubStr(txt, index, start-index), " ") match
            , index := start + StrLen(match)
        
        Return str StrReplace(SubStr(txt, index), " ")
    }
    
    stringify_object(obj)
    {
        str  := ((is_arr := this.is_array(obj)) ? "[" : "{")                    ; Check if obj is array and add bracket
        For k, v in obj                                                         ; Loop through object
            str .= (A_Index = 1 ? "" : ",")                                     ; Add a comma items after first
                . (is_arr ? "" : """" k """:")                                  ; Add key if object
                . (IsObject(v)                                                  ; If value is object
                    ? this.stringify_object(v)                                  ; Recursively extract object
                    : (this.is_num(v) || this.is_tfn(v))                        ; Else if num, true, false, or null
                        ? v                                                     ; Include value
                        : this.json_encode(v))                                  ; Else if string, encode
        Return str (is_arr ? "]" : "}")                                         ; End with correct bracket and return
    }
    
    pretty(json)
    {
        Return IsObject(json)
            ? this.to_json(json)
            : this.to_json(this.to_obj(json))
    }
    
    pretty_text(txt)
    {
        index := 1
        , txt := this.strip_ws(txt)
        , str := ""
        
        While (start := RegExMatch(txt, this.rgx.s2, match, index))
            str .= StrReplace(SubStr(txt, index, start-index), " ") match
            , index := start + StrLen(match)
        
        Return str StrReplace(SubStr(txt, index), " ")
    }
    
    ; Converts escaped characters to their actual values
    json_decode(txt)
    {
        Local
        If InStr(txt, "\")
             txt := StrReplace(txt, "\\" , "\" )                                ; Reverse Slash / Solidus
            ,txt := StrReplace(txt, "\b" , "`b")                                ; Backspace
            ,txt := StrReplace(txt, "\f" , "`f")                                ; Formfeed
            ,txt := StrReplace(txt, "\n" , "`n")                                ; Linefeed
            ,txt := StrReplace(txt, "\r" , "`r")                                ; Carriage Return
            ,txt := StrReplace(txt, "\t" , "`t")                                ; Tab
            ,txt := StrReplace(txt, "\/" , "/" )                                ; Slash / Solidus
            ,txt := StrReplace(txt, "\""", """")                                ; Double Quotes
        
        Return (this.import_keep_quotes ? txt : SubStr(txt, 2, -1))
    }
    
    ; Converts required characters to their escaped versions
    json_encode(txt)
    {
        Local
        
        If InStr(txt, "\`b`f`n`r`t""")                                          ; Check if anything needs replaced
             txt := StrReplace(txt, "\"  , "\\" )                               ; Backslash must be replaced first
            ,txt := StrReplace(txt, "\\u", "\u" )                               ; Fix unicode \\ problem caused by last step
            ,txt := StrReplace(txt, "`b" , "\b" )                               ; Encode Backspace
            ,txt := StrReplace(txt, "`f" , "\f" )                               ; Encode Formfeed
            ,txt := StrReplace(txt, "`n" , "\n" )                               ; Encode Linefeed
            ,txt := StrReplace(txt, "`r" , "\r" )                               ; Encode Carriage Return
            ,txt := StrReplace(txt, "`t" , "\t" )                               ; Encode Tab (Horizontal)
            ,txt := StrReplace(txt, """" , "\""")                               ; Encode Quotation Marks
            ,this.escape_slashes ? txt := StrReplace(txt, "/"  , "\/" ) : ""    ; Escape forward slashes based on user preference
        
        Return (this.export_add_quotes ? """" txt """" : txt)
    }
    
    ; Check if object is an array
    ; Arrays must start at 0 or 1 and have all numerical, sequential indexes
    is_array(obj)
    {
        If obj.HasKey(0)
            For key, value in obj
                If (key = A_Index-1)
                    Continue
                Else Return 0
        Else If obj.HasKey(1)
            For key, value in obj
                If (key = A_Index)
                    Continue
                Else Return 0
        Else Return 0
        Return 1
    }
    
    ; Check if empty object
    is_empty_object(obj)
    {
        For key, value in obj
            Return 0
        Return IsObject(obj) ? 1 : 0
    }
    
    ; Check if true, false, or null
    is_tfn(data)
    {
        Return RegExMatch(data, this.rgx.b2)
    }
    
    ; Check if valid JSON number
    is_num(data)
    {
        Return RegExMatch(data, this.rgx.n2)
    }
    
    ; === Testing tools ===
    ; Test files
    Static test_file_a := "[`n`t""JSON Test Pattern pass1"",`n`t{""object with 1 members"":[""array with 1 element""]},`n`t{},`n`t[],`n`t-42,`n`ttrue,`n`tfalse,`n`tnull,`n`t{`n`t`t""integer"": 1234567890,`n`t`t""real"": -9876.543210,`n`t`t""e"": 0.123456789e-12,`n`t`t""E"": 1.234567890E+34,`n`t`t"""":  23456789012E66,`n`t`t""zero"": 0,`n`t`t""one"": 1,`n`t`t""space"": "" "",`n`t`t""quote"": ""\"""",`n`t`t""backslash"": ""\\"",`n`t`t""controls"": ""\b\f\n\r\t"",`n`t`t""slash"": ""/ & \/"",`n`t`t""alpha"": ""abcdefghijklmnopqrstuvwyz"",`n`t`t""ALPHA"": ""ABCDEFGHIJKLMNOPQRSTUVWYZ"",`n`t`t""digit"": ""0123456789"",`n`t`t""0123456789"": ""digit"",`n`t`t""special"": ""````1~!@#$``%^&*()_+-={':[,]}|;.</>?"",`n`t`t""hex"": ""\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"",`n`t`t""true"": true,`n`t`t""false"": false,`n`t`t""null"": null,`n`t`t""array"":[  ],`n`t`t""object"":{  },`n`t`t""address"": ""50 St. James Street"",`n`t`t""url"": ""http://www.JSON.org/"",`n`t`t""comment"": ""// /* <!-- --"",`n`t`t""# -- --> */"": "" "",`n`t`t"" s p a c e d "" :[1,2 , 3`n`n,`n`n4 , 5`t`t,`t`t  6`t`t   ,7`t`t],""compact"":[1,2,3,4,5,6,7],`n`t`t""jsontext"": ""{\""object with 1 member\"":[\""array with 1 element\""]}"",`n`t`t""quotes"": ""&#34; \u0022 ``%22 0x22 034 &#x22;"",`n`t`t""\/\\\""\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t``1~!@#$``%^&*()_+-=[]{}|;:',./<>?""`n: ""A key can be any string""`n`t},`n`t0.5 ,98.6`n,`n99.44`n,`n`n1066,`n1e1,`n0.1e1,`n1e-1,`n1e00,2e+00,2e-00`n,""rosebud""]"
    Static test_file_o := "{`n`t""key_01_str"": ""String"",`n`t""key_02_num"": -1.05e+100,`n`t""key_03_true_false_null"":`n`t{`n`t`t""true"": true,`n`t`t""false"": false,`n`t`t""null"": null`n`t},`n`t""key_04_obj_num"":`n`t{`n`t`t""Integer"": 1234567890,`n`t`t""Integer negative"": -420,`n`t`t""Fraction/decimal"": 0.987654321,`n`t`t""Exponent"": 99e2,`n`t`t""Exponent negative"": -1e-999,`n`t`t""Exponent positive"": 11e+111,`n`t`t""Mix of all"": -3.14159e+100`n`t},`n`t""key_05_arr"":`n`t[`n`t`t""Value1"",`n`t`t""Value2"",`n`t`t""Value3""`n`t],`n`t""key_06_nested_obj_arr"":`n`t{`n`t`t""matrix"":`n`t`t[`n`t    `t[`n`t    `t`t0,`n`t    `t`t1,`n`t    `t`t2`n`t    `t],`n`t    `t[`n`t    `t`t0,`n`t    `t`t1,`n`t    `t`t2`n`t    `t],`n`t    `t[`n`t    `t`t0,`n`t    `t`t1,`n`t    `t`t2`n`t    `t]`n`t`t],`n`t`t""person object example"":`n`t`t{`n`t    `t""name"": ""0xB0BAFE77"",`n`t    `t""job"": ""Professional Geek"",`n`t    `t""faves"":`n`t    `t{`n`t    `t`t""color"":`n`t    `t`t[`n`t    `t    `t""Black"",`n`t    `t    `t""White""`n`t    `t`t],`n`t    `t`t""food"":`n`t    `t`t[`n`t    `t    `t""Pizza"",`n`t    `t    `t""Cheeseburger"",`n`t    `t    `t""Steak""`n`t    `t`t],`n`t    `t`t""vehicle"":`n`t    `t`t{`n`t    `t    `t""make"": ""Subaru"",`n`t    `t    `t""model"": ""WRX STI"",`n`t    `t    `t""year"": 2018,`n`t    `t    `t""color"":`n`t    `t    `t{`n`t    `t`t    `t""Primary"": ""Black"",`n`t    `t`t    `t""Secondary"": ""Red""`n`t    `t    `t},`n`t    `t    `t""transmission"": ""M"",`n`t    `t    `t""msrp"": 26995.00`n`t    `t`t}`n`t    `t}`n`t`t}`n`t},`n`t""key_07_string_stuff"":`n`t{`n`t`t""ALPHA UPPER"": ""ABCDEFGHIJKLMNOPQRSTUVWXYZ"",`n`t`t""alpha lower"": ""abcdefghijklmnopqrstuvwxyz"",`n`t`t""Specials"": ""!@#$%^&*()_+-=[]{}<>,./?;':"",`n`t`t""Digits"": ""0123456789"",`n`t`t""0123456789"": ""Digits"",`n`t`t""key_case_check"": ""key_case_check lower"",`n`t`t""KEY_CASE_CHECK"": ""KEY_CASE_CHECK UPPER"",`n`t`t""Escape Characters"":`n`t`t{`n`t    `t""ESC_01 Quotation Mark"": ""\"""",`n`t    `t""ESC_02 Backslash/Reverse Solidus"": ""\\"",`n`t    `t""ESC_03 Slash/Solidus (Not a mandatory escape)"": ""\/ and / work"",`n`t    `t""ESC_04 Backspace"": ""\b"",`n`t    `t""ESC_05 Formfeed"": ""\f"",`n`t    `t""ESC_06 Linefeed"": ""\n"",`n`t    `t""ESC_07 Carriage Return"": ""\r"",`n`t    `t""ESC_08 Horizontal Tab"": ""\t"",`n`t    `t""ESC_09 Unicode"": ""\u00AF\\_(\u30C4)_\/\u00AF"",`n`t    `t""ESC_10 All"": ""\\\/\""\b\f\n\r\t\u0033"",`n`t    `t""ESC_11 \/\t\u0033\t\/"": ""Key with Encodes""`n`t`t}`n`t},`n`t""key_08_text_of_json_text"": ""{\""object with 1 member\"": [\""array with 1 element\""]}"",`n`t""key_09_quotes"": ""&#34; \u0022 `%22 0x22 034 &#x22;"",`n`t""key_10_empty"":`n`t{`n`t`t""Empty Value"": """",`n`t`t"""": ""Empty Key"",`n`t`t""Empty Array"": [],`n`t`t""Empty Object"": {}`n`t},`n`t""key_11_spacing"":`n`t{`n`t`t""compact"":[1,2,3,4,""a"",""b"",""c"",""d""],`n`t`t""expanded"":`n`t`t[`n`t    `t""This "",                      ""is""  `t    `t          ,""considered""`n`t    `t`t    `t,""valid "",`t    `t`t    ""spacing.\n"",`n`t    `t""JSON "",`n`t    `t`t""only "",`n`t    `t    `t""cares "",`n`t    `t`t    `t""about "",`n`t    `t`t    `t`t""whitespace "",`n`t    `t`t    `t    `t""inside "",`n`t    `t`t    `t`t    `t""of"",`n`t    `t`t    `t`t    `t`t""strings.""`n`t    `t`t    `t`t    `t    `t],`n`t`t""valid JSON whitespace"":`n`t    `t    `t[""Space"",`n`t    `t`t""Linefeed"",`n`t    `t""Carriage Return"",`n`t`t""Horizontal Tab""]`n`t},`n`t""key_12_code_comments"": [""C"", ""REM"", ""::"", ""NB."", ""#"", ""%"", ""//"", ""'"", ""!"", "";"", ""--"", ""*"", ""||"", ""*>""]`n}"
    
    
    msg(msg)
    {
        MsgBox, % msg
    }
    
    quick_view(data)
    {
        Return Trim(this.quick_extract(data), "`n")
    }
    
    quick_extract(obj, ind:="")
    {
        str := ""
        If IsObject(obj)
        {
            For k, v in obj
                str .= "`n" ind k ": " (IsObject(v) ? this.quick_extract(v, ind "`t") : v)
            return str
        }
        Else return obj
    }
}
