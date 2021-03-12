#SingleInstance Force
#Warn
#NoEnv
#MaxMem 1024
#KeyHistory 0
SetBatchLines, -1
ListLines, Off

json_ahk.test()

Return

Esc::ExitApp

Class JSON_AHK
{
    ; AHK limitations disclaimer
    ;   - AHK is not a case-sensitive language. Object keys that only differ by case are considered the same key to AHK.
    ;     I'm adding in a check to see if the key exists first. If so, it will warn the user before overwriting.
    ;     This will be a toggleable property option. something like json_ahk.dupe_key_check
    ;   - Arrays are actually objects in AHK and not their own defined type.
    ;     This library "assumes" arrays by their indexes.
    ;	  If the first index is 1 and all subsequent indexes are 1 higher than the previous, it's considered an array
    ;     Because of this, blank arrays [] will always export as blank objects {}.
    
    ; Currently working on:
    ;   - Stringfy doesn't work. Rewrite needed.
    ;   - Error checking still needs to be implemented
    ;     This should be able to the user EXACTLY where the error is and why it's an error.
    ;   - Add option to put array elements on one line when exporting JSON text
    ;   - Write .validate() (use to_obj as a template w/o actually writing to the object)
    ;   - Write .to_json_default() - Method to reset the JSON export display settings
    ;   - Speaking of export, should I write an export() function that works like import() but saves?
    ;   - .strip_quotes has not be implemented yet
    ;     This strips off string quotation marks when creating the AHK object
    ;   - Add error detection for duplicate keys (this includes keys that differe only in case)
    ;   - Add last_error property that can store a string saying what the last error was.
    ;   - Verify all return values
    
    ; Creating a change log as of 20210307 to track changes
    ; - Fixed issues with .to_ahk() and .to_json()
    ;   Library works on a basic level now and can be used. :)
    ; - Added: .preview() method
    ; - Worked on comment info
    ; - Added: esc_slash property
    ; - Fixed: Empty brace checking
    ; - Massive update to README file
    
    
    ;===========================================================================.
    ; Title:        JSON_AHK                                                    |
    ; Desc:         Library that converts JSON to AHK objects and AHK to JSON   |
    ; Author:       0xB0BAFE77                                                  |
    ; Created:      20200301                                                    |
    ; Last Update:  20210307                                                    |
    ;==========================================================================='
    
    ;=============================================================================================================================================.
    ; Methods           | Return Value                 | Function                                                                                 |
    ;-------------------|------------------------------|------------------------------------------------------------------------------------------|
    ; .to_json(object)  | JSON string or 0 if failed.  | Convert an AHK object to JSON text.                                                      |
    ; .to_ahk(json)     | AHK object or 0 if failed.   | Convert JSON text to an AHK object.                                                      |
    ; .stringify(json)  | JSON string or 0 if failed.  | Removes all non-string whitespace.                                                       |
    ; .validate(json)   | true if valid else false.    | Checks if object or text is valid JSON. Offers basic error correction.                   |
    ; .import()         | JSON string or 0 if failed.  | Opens a window to select a JSON file.                                                    |
    ; .preview(p1)      | Always returns blank.        | Preview current JSON export settings. Passing true to p1 will save preview to clipboard. |
    ;============================================================================================================================================='
    
    ;=============================================================================================================================================.
    ; Properties:               | Default | Function                                                                                              |
    ;---------------------------+---------+-------------------------------------------------------------------------------------------------------|
    ; .indent_unit              | `t      | Assign indentation. Can be any amount of spaces, tabs, linefeeds or carriage returns.                 |
    ; .esc_slash                | false   | Adds the optional escape to forward slashes on JSON export.                                           |
    ; .no_brace_ws              | true    | Removes whitespace from empty objects.                                                                |
    ; .no_braces                | true    | Removes all braces and brackets from the JSON text export.                                            |
    ; .ob_new_line              | true    | Put opening braces/brackets on a new line.                                                            |
    ; .ob_val_inline            | false   | Indent opening brace to be inline with the values. This setting is ignored when .ob_new_line is true. |
    ; .ob_brace_val             | false   | First element is put on the same line as the opening brace. Usually used with .ob_val_inline          |
    ; .cb_new_line              | true    | Put closing braces/brackets on a new line.                                                            |
    ; .cb_val_inline            | false   | Indent closing brace to be inline with the values. This setting is ignored when .ob_new_line is true. |
    ; .array_one_line           | true    | Put all array elements on same line.                                                                  |
    ;---------------------------+---------'-------------------------------------------------------------------------------------------------------'
    ; Examples:                 |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------.
    ; .no_brace_ws              | True: [DEF]   {},                                                                                               |
    ;                           | False:        {        },                                                                                       |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------|
    ; .ob_new_line              | True: [DEF]   "key":                                                                                            |
    ;                           |               [                                                                                                 |
    ;                           |                   "value",                                                                                      |
    ;                           | False:        "key": [                                                                                          |
    ;                           |                   "value",                                                                                      |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------|
    ; .ob_val_inline            | True:         "key":                                                                                            |
    ;                           |                   [                                                                                             |
    ;                           |                   "value1",                                                                                     |
    ;                           | False: [DEF]  "key":                                                                                            |
    ;                           |               [                                                                                                 |
    ;                           |                   "value1",                                                                                     |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------|
    ; .ob_brace_val             | True:         "key":                                                                                            |
    ;                           |                   ["value1",                                                                                    |
    ;                           |                   "value2",                                                                                     |
    ;                           | False: [DEF]  "key":                                                                                            |
    ;                           |                   [                                                                                             |
    ;                           |                   "value1",                                                                                     |
    ;                           |                   "value2",                                                                                     |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------|
    ; .cb_new_line              | True: [DEF]       "value2",                                                                                     |
    ;                           |                   "value3"                                                                                      |
    ;                           |               }                                                                                                 |
    ;                           | False:            "value2",                                                                                     |
    ;                           |                   "value3"}                                                                                     |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------|
    ; .cb_val_inline            | True:             "value2",                                                                                     |
    ;                           |                   "value3"                                                                                      |
    ;                           |                   }                                                                                             |
    ;                           | False: [DEF]      "value2",                                                                                     |
    ;                           |                   "value3"                                                                                      |
    ;                           |               }                                                                                                 |
    ;---------------------------+-----------------------------------------------------------------------------------------------------------------|
    ;.array_one_line            | True:         "key": ["value1", "value2"]                                                                       |
    ;                           | False: [DEF]  "key": [                                                                                          |
    ;                           |                   "value1",                                                                                     |
    ;                           |                   "value2"                                                                                      |
    ;___________________________|_________________________________________________________________________________________________________________|
    
    ;==================================================================================================================
    ; JSON export settings              ;Default|
    Static indent_unit       := "`t"     ; `t    | Set to desired indent (EX: "  " for 2 spaces)
    Static esc_slash         := False    ; False | Optionally escape forward slashes when exporting JSON
    Static ob_new_line       := True     ; True  | Open brace is put on a new line
    Static ob_val_inline     := False    ; False | Open braces on a new line are indented to match value
    Static cb_new_line       := True     ; True  | Close brace is put on a new line
    Static cb_val_inline     := False    ; False | Open braces on a new line are indented to match value
    
    Static arr_val_same      := False    ; False | First value of an array appears on the same line as the brace
    Static obj_val_same      := False    ; False | First value of an object appears on the same line as the brace
    
    Static no_empty_brace_ws := True     ; True  | Remove whitespace from empty braces
    Static array_one_line	 := False	 ; False | List array elements on one line instead of multiple
    Static add_quotes        := False    ; False | Adds quotation marks to all strings if they lack one
    Static no_braces         := False    ; False | Removes object and array braces. This invalidates its JSON
    ;                                    ;       | format and should only be used for human consumption/readability
    ; User settings for converting JSON
    Static strip_quotes      := False    ; False | Removes surrounding quotation marks from
    ;==================================================================================================================
    
    ; Test file (very thorough)
    Static test_file := "[`n`t""JSON Test Pattern pass1"",`n`t{""object with 1 members"":[""array with 1 element""]},`n`t{},`n`t[],`n`t-42,`n`ttrue,`n`tfalse,`n`tnull,`n`t{`n`t`t""integer"": 1234567890,`n`t`t""real"": -9876.543210,`n`t`t""e"": 0.123456789e-12,`n`t`t""E"": 1.234567890E+34,`n`t`t"""":  23456789012E66,`n`t`t""zero"": 0,`n`t`t""one"": 1,`n`t`t""space"": "" "",`n`t`t""quote"": ""\"""",`n`t`t""backslash"": ""\\"",`n`t`t""controls"": ""\b\f\n\r\t"",`n`t`t""slash"": ""/ & \/"",`n`t`t""alpha"": ""abcdefghijklmnopqrstuvwyz"",`n`t`t""ALPHA"": ""ABCDEFGHIJKLMNOPQRSTUVWYZ"",`n`t`t""digit"": ""0123456789"",`n`t`t""0123456789"": ""digit"",`n`t`t""special"": ""````1~!@#$``%^&*()_+-={':[,]}|;.</>?"",`n`t`t""hex"": ""\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"",`n`t`t""true"": true,`n`t`t""false"": false,`n`t`t""null"": null,`n`t`t""array"":[  ],`n`t`t""object"":{  },`n`t`t""address"": ""50 St. James Street"",`n`t`t""url"": ""http://www.JSON.org/"",`n`t`t""comment"": ""// /* <!-- --"",`n`t`t""# -- --> */"": "" "",`n`t`t"" s p a c e d "" :[1,2 , 3`n`n,`n`n4 , 5`t`t,`t`t  6`t`t   ,7`t`t],""compact"":[1,2,3,4,5,6,7],`n`t`t""jsontext"": ""{\""object with 1 member\"":[\""array with 1 element\""]}"",`n`t`t""quotes"": ""&#34; \u0022 ``%22 0x22 034 &#x22;"",`n`t`t""\/\\\""\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t``1~!@#$``%^&*()_+-=[]{}|;:',./<>?""`n: ""A key can be any string""`n`t},`n`t0.5 ,98.6`n,`n99.44`n,`n`n1066,`n1e1,`n0.1e1,`n1e-1,`n1e00,2e+00,2e-00`n,""rosebud""]"
    
    test() {
        ; Current speeds for 25 mb file average of 1,000,000 iterations
        ;
        
        
        obj     := {}
        jtxt    := json_ahk.import()
        ;jtxt    := json_ahk.test_file
        i       := 1
        this.stringify(jtxt)
        ExitApp
        
        this.qpx(1)
        Loop, % i
            obj := json_ahk.to_ahk(jtxt)
        t1 := this.qpx(0)
        
        this.qpx(1)
        Loop, % i
            json := json_ahk.to_json(obj)
        t2 := this.qpx(0)
        
        Clipboard := json
        MsgBox, % "[qpx]to_ahk convert time: " t1/i " sec"
                . "`n[qpx]to_json convert time: " t2/i " sec"
        
        Return
    }
    
    ; Import JSON file
    import() {
        Local
        path := json := ""
        
        FileSelectFile, path, 3,, Select a JSON file, JSON (*.json)
        If (ErrorLevel = 1)
            Return False
        
        FileRead, json, % path
        If (ErrorLevel = 1) {
            this.basic_error("An error occurred when loading the file."
                . "`nError:" A_LastError)
            Return False
        }
        
        Return json
    }
    
    ; Pretty much a clone of to_ahk() except no writing/object building
    ; I would just adapt to_ahk() but the extra if checks are going to slow things down
    validate(json) {
        
        Return
    }
    
    ; Convert AHK object to JSON string
    to_json(obj, ind:="") {
        
        this.esc_slash_s := (this.esc_slash ? "/" : "")
        this.esc_slash_r := (this.esc_slash ? "\/" : "")
        
        Return IsObject(obj)
            ? LTrim(this.to_json_extract(obj, this.is_array(obj)), "`n")
        : this.basic_error("You did not supply a valid object or array")
    }
    
    preview(save:=0) {
        txt := this.to_json(this.to_ahk(this.test_file))
        save ? Clipboard := txt : ""
        MsgBox, % txt
        Return ""
    }
    
    ; Recursively extracts values from an object
    ; type = Incoming object type: 0 for object, 1 for array
    ; Indent is set by the json_ahk.indent_unit property
    ; It should be left blank as recursion sets indent depth
    to_json_extract(obj, type, ind:="") {
        Local
        
        ind_big := ind . this.indent_unit                                   		; Set big indent
        ,str    := (this.ob_new_line                                        		; Build beginning of arr/obj
                    ? "`n" (this.ob_val_inline ? ind_big : ind)
                    : "")                                                   		; Create brace prefix
                . (this.no_braces ? "" : type ? "[" : "{")                  		; Add correct brace
        
        For key, value in obj
            str .= (this.is_array(value)                                    		; Check if value is array
                    ? (type ? ""                                            		; If current obj is array, do nothing
                        : "`n" ind_big key ": ")                            		; Else, construct obj prefix
                        . this.to_json_extract(value, 1, ind_big)           		; Then get extracted values
                : IsObject(value)                                           		; If value not array, check if object
                    ? (type ? "" : key ": ")                                		; Construct obj prefix
                        . this.to_json_extract(value, 0, ind_big)           		; Extract values
                : (type && this.array_one_line ? "" : "`n" ind_big)					; Should array elements be on 1 line
                    . (type ? "" : key ": ")                       					; If object, add key
                    . (InStr(value, """")                                   		; If string, encode: backslashes, backspaces
                        ? ("""" StrReplace(StrReplace(StrReplace(StrReplace(""		; formfeeds, linefeeds, carriage returns,
                        . StrReplace(StrReplace(StrReplace(StrReplace(StrReplace("" ; horizontal tabs, and fix \\u
                        . SubStr(value, 2, -1),"\","\\"),"`b","\b"),"`f","\f")		; Yes, this is ugly af 
                        ,"`n","\n"),"`r","\r"),"`t","\t"),"""","\"""),"\\u","\u")	; It's also faster thi
                        ,this.esc_slash_s, this.esc_slash_r) """")					; Also, optionally escapes slashes
                        : value ) )                                         		; If not string, bypass decode and add value
                    . ","                                                   		; Always end with a comma
        
        str := RTrim(str, ",")   							; Strip off last comma
        (type && this.array_one_line)						; Array elements on 1 line check
            ? str .= "]"									; If yes, cap off with bracket
        : str .= (this.cb_new_line							; Otherwise check if closing brace is on new line
            ? "`n" (this.cb_val_inline ? ind_big : ind)		; Check if brace should be indented to value
            : "" )											; Otherwise do nothing
            . (this.no_braces ? "" : type ? "]" : "}")		; Add appropriate closing brace
        
        ; Empty object checker
        ;; In AHK v1, all arrays are objects so there is no way to distinguish between an empty array and empty object
        ;; When constructing JSON output, empty arrays will always show as empty objects
        If this.no_empty_brace_ws
            If RegExMatch(str, "^[ |\t|\n|\r]*(\{[ |\t|\n|\r]*\}|\[[ |\t|\n|\r]*\])[ |\t|\n|\r]*$")
                str := (this.ob_new_line ? "`n" ind : "") 				; If true, create prefix
                    . (this.no_braces ? "" : "{}" )   					; Add empty brace.
        
        Return str
    }
    
    ; Converts a json text file into a single string
    stringify(json) {
        Local
        
        this.qpx(1)
        str := IsObject(json)
            ? this.stringify_obj(json, this.is_arr(json))
            : this.stringify_txt(json)
        t1 := this.qpx(0)
        Clipboard := str
        
        MsgBox, % "time to stringify: " t1 " sec"
            . "`nresult:`n`n" str
        ExitApp
        
        Return str
    }
    
    stringify_obj(obj, type) {
        str := (type ? "[" : "{")
        For key, value in obj
            str .= (type ? "" : key ":" )
                . (this.is_arr(value)
                    ? this.stringify_obj(value, 1)
                : IsObject(value)
                    ? this.stringify_obj(value, 0)
                : value ) ","
        str := RTrim(str, ",")
        Return str (type ? "]" : "}")
    }
    
    stringify_txt(txt){
        MsgBox starting
        str := ""
        i   := 1
        max := StrLen(txt)
        
        Loop, % max
        {
            RegExMatch(txt, "(?P<nstr>.*)(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))", match, i)
            MsgBox, % "match: " match "`nmatchnstr: " matchnstr "`nmatchstr: " matchstr
        }
        ExitApp
        Loop, % Max
        {
            If RegExMatch(txt, "P)(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))", match, i)
                str .= StrReplace(StrReplace(StrReplace(StrReplace(SubStr(txt, i, matchposstr-i)," "),"`t"),"`n"),"`r")
                    . SubStr(txt, matchposstr, matchlenstr)
            Else Break
            i += matchposstr + matchlenstr - 1
        }
        
        Return str StrReplace(StrReplace(StrReplace(StrReplace(SubStr(txt, i)," "),"`t"),"`n"),"`r")
    }

    ; Convert json text to an ahk object
    to_ahk(json){
        Local
        
        obj      := {}              ; Main object to build and return
        ,obj.SetCapacity(1024)      ; Does setting a large object size speed up performance?
        ,path    := []              ; Path value should be stored in the object
        ,type    := []              ; Tracks if current path is an array (true) or object (false)
        ,p_i     := 0               ; [NEW] tracks current index for the path arrays (replaces the need to call .MaxIndex() over and over)
        ,this.i  := 0               ; Tracks current position in the json string
        ,char    := ""              ; Current character
        ,next    := "s"             ; Next expected action: (s)tart, (n)ext, (k)ey, (v)alue
        ,max     := StrLen(json)    ; Total number of characters in JSON
        ,m_      := ""              ; Stores regex matches
        ,m_str   := ""              ; Stores regex match subpattern
        
        ; RegEx bank
        ; mateon1 at regex101.com created these regex patterns
        ,rgx	:=  {"k"    : "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*:)"
                    ,"n"    : "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))"
                    ,"s"    : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))"
                    ,"b"    : "(?P<str>true|false|null)"    }
        
        ; Define whitespace
        ,is_ws  :=  {" " :True      ; Space
                    ,"`t":True      ; Tab
                    ,"`n":True      ; New Line
                    ,"`r":True }    ; Carriage Return
        
        ; Value validator and regex key assigner
        ,is_val :=  {"0":"n" ,"5":"n" ,0:"n" ,5:"n" ,"-" :"n"
                    ,"1":"n" ,"6":"n" ,1:"n" ,6:"n" ,"t" :"b"
                    ,"2":"n" ,"7":"n" ,2:"n" ,7:"n" ,"f" :"b"
                    ,"3":"n" ,"8":"n" ,3:"n" ,8:"n" ,"n" :"b"
                    ,"4":"n" ,"9":"n" ,4:"n" ,9:"n" ,"""":"s" }
        
        ; Store JSON in class for error detection
        this.json := json
        
        ; For tracking object path, would using a string with substring be faster than array and push/pop?
        ; Can bit shifting be used as a replacement for type (tracks if current path is an array or object so a bunch of true/false)?
        
        While (this.i < max)
            is_ws[(char := SubStr(json,++this.i,1))]                                    ; Get next character and check if whitespace
                ? ""                                                                    ; If whitespace, do nothing
            : next == "v"                                                               ; If value is expected
                ? InStr("{[", char)                                                     ; If new object or array
                    ? (obj[path*] := {}, next := (char == "{" ? "k" : "a") )            ; Add new object and get key/value
                : RegExMatch(json,rgx[is_val[char]],m_,this.i)                          ; If char is valid start of value
                    ? (obj[path*] := (is_val[char]=="s" && InStr(m_str,"\")             ; Add value to object
                        ? """" this.string_decode(SubStr(m_str,2,-1)) """" : m_str )    ; If value is string, decode escapes
                        ,this.i += StrLen(m_str)-1 , next := "e" )
                : this.to_json_err("value", is_val[char])                               ; If invalid value, error
            : next == "e"                                                               ; If an ender is expected
                ? char == ","                                                           ; If another value is expected
                    ? type[p_i] ? (path[p_i]++, next := "v" )                           ; If array, increment index
                        : (path.Pop(), type.Pop(), --p_i, next := "k" )                 ; Else object so pop key and get a new one
                : ((char == "}" && !type[p_i]) || (char == "]" && type[p_i]))           ; If valid end of object/array
                    ? (path.Pop(), type.Pop(), --p_i, next := "e")                      ; Remove last key and type
                : this.to_json_err("end", type[p_i])                                    ; If invalid ender, error
            : next == "a"                                                               ; If new array
                ? char == "]" ? next := "e"                                             ; Check if end of array
                : (path[++p_i] := 1, type[p_i] := 1, --this.i, next := "v")             ; Else increment index, update type, decrement char index
            : next == "k"                                                               ; If object key expected
                ? RegExMatch(json, rgx.k, m_, this.i)                                   ; If valid key and colon are present
                    ? (path[++p_i] := m_str, type[p_i] := 0                             ; Add key and update type
                    , this.i += StrLen(m_)-1, next := "v" )                             ; Get next value
                : char == "}" ? next := "e"                                             ; Else check if end of object
                : this.to_json_err("key")                                               ; If invalid key, error
            : next == "s"                                                               ; If start of JSON
                ? char == "{" ? (next := "k")                                           ; If valid JSON object, get a key
                : char == "[" ? (next := "a")                                           ; If valid array, get value
                : this.to_json_err("start")                                             ; If invalid start, error
            : ""
        
        this.json := ""             ; Post conversion clean up
        
        (p_i != 0)                  ; Verify there are no open objects or arrays
            ? this.to_json_err("")  ; Error if p_i isn't 0
            : ""
        
        Return obj
    }
    
    to_json_err(next, extra:="") {
        valid   := this.make_valid_table()
        val_key := this.make_valid_table_key()
        txt     := ""
        char    := SubStr(this.json, this.i, 1)
        max     := StrLen(this.json)
        
        state := {"start": "BG"
                , "value": "VL"
                , "key"  : "ON"
                , "end"  : "CC"}[next]
        
        ;~ ; error states:
        ;~ ; start
        ;~ ; key
        ;~ ; value
        ;~ ; end
        
        ;~ SubStr(this.json, this.i, 1)
        
        ;~ While (st != "")
        ;~ {
            ;~ state := valid[state][]
        ;~ }
        
        ;~ If (next = "start")
            ;~ msg := "JSON files must start with a brace ({) to indicate an object or a bracket ([) to indicate an array."
                ;~ . "`nAny amount of white space (space, tab, linefeed, carriage return) can come before the opening brace/bracket."
            ;~ ,found := char
            ;~ ,err_disp := this.error_display()
        ;~ Else If (next = "key")
            
        ;~ Else If (next = "value")
            
        ;~ Else If (next = "end")
            
        
        
        ; Error messages and expectations
        err    :=  {snb    :{msg   : "Invalid string|number|true|false|null.`nNeed to write a function that auto-detects this for me."
                            ,exp    : "string number true false null"}
                    ,cls    :{msg   : "Invalid closing brace.`nObjects must end with a } and arrays must end with a ]."
                            ,exp    : "} ]"}
                    ,arr    :{msg   : "The first item in an array must be a value or a closing square bracket."
                            ,exp    : "] - 0 1 2 3 4 5 6 7 8 9 "" t f n"}
                    ,val    :{msg   : "Invalid value.`nNeed to write a function that auto-detects this for me."
                            ,exp    : "string number true false null object array"}
                    ,nxt    :{msg   : "Commas are required between values."
                            ,exp    : ","}
                    ,key    :{msg   : "An object must start with a key or closing curly brace."
                            ,exp    : "Keys must follow string rules."}
                    ,jsn    :{msg   : "Invalid JSON file.`nJSON data starts with a brace."
                            ,exp    : "[ {"}    }
        
        ;~ If (state = "start")
            ;~ msg := "JSON files must start with a brace ({) or a bracket ([)."
                ;~ . "`nAny amount of whitespace (spaces, tabs, linefeeds, carriage returns) "
                ;~ . "can come before the start of the object or array."
            ;~ ,found := char
            ;~ ,expect := "{ or ["
        ;~ Else If (state = "key")
            
        ;~ Else If (state = "")
            
        ;~ Else If (state = "")
            
        ;~ Else If (state = "")
            
        
        state := (state == "s" ? True : False)
        validate := this.make_valid_table()
        Return
    }
    
    error_display(offset:=20) {
        max := StrLen(this.json)
        min := (this.i-offset < 0   ? 0     : this.i-offset )
        max := (this.i+offset > max ? max   : this.i+max )
        Return SubStr(this.json, min, this.i-min-1)
                    . ">-->" SubStr(this.json, this.i, 1) "<--<"
                    . SubStr(this.json, this.i+1, max)
    }
    
    string_decode(txt){
        Return StrReplace(StrReplace(StrReplace(StrReplace(""
            . StrReplace(StrReplace(StrReplace(StrReplace(txt
                    ,"\b"	,"`b")	; Backspace
                    ,"\f"	,"`f")	; Formfeed
                    ,"\n"	,"`n")	; Linefeed
                    ,"\r"	,"`r")	; Carriage Return
                    ,"\t"	,"`t")	; Tab
                    ,"\/"	,"/")	; Slash / Solidus
                    ,"\"""	,"""")	; Double Quotes
                    ,"\\"	,"\")	; Reverse Slash / Solidus
    }
    
    ; Encodes specific chars to escaped chars
    string_encode(txt) {
        Local
        
        MsgBox, % "before:`n`n" txt
        
        txt	:= StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(""
            . StrReplace(StrReplace(StrReplace(StrReplace(SubStr(txt, 2, -1)
                ,"\"	,"\\" )		; Backspace
                ,"`b"	,"\b" )		; Backspace
                ,"`f"	,"\f" )		; Formfeed
                ,"`n"	,"\n" )		; Linefeed
                ,"`r"	,"\r" )		; Carriage Return
                ,"`t"	,"\t" )		; Tab
                ,"/" 	,"\/" )		; Slash / Solidus
                ,""""	,"\""")		; Double Quotes
                ,"\\u"	,"\u") """" ; Fixes unicode
        
        MsgBox, % "after:`n`n" txt
        Return ("""" txt """")
    }
    
    to_json_default() {
        json_ahk.indent_unit      := "`t"
        json_ahk.esc_slash        := False
        json_ahk.ob_new_line      := True
        json_ahk.ob_val_inline    := False
        json_ahk.arr_val_same     := False
        json_ahk.obj_val_same     := False
        json_ahk.cb_new_line      := True
        json_ahk.cb_val_inline    := False
        json_ahk.no_empty_brace_ws:= True
        json_ahk.add_quotes       := False
        json_ahk.no_braces        := False
        json_ahk.strip_quotes     := False
        Return
    }
    
    ; Check if object is an array
    is_array(obj) {
        If !obj.HasKey(1)
            Return False
        For k, v in obj
            If (k != A_Index)
                Return False
        Return True
    }
    
    ; ===== Error checking =====
    make_valid_table() {
        ; Validation table for a JSON file
        ; -1  = New Object/Get Key
        ; -2  = New Array
        ; -3  = String Start
        ; -4  = Empty Object
        ; -5  = Additional Value
        ; -6  = End of Value (Str/Num/TFN)
        ; -7  = Start of Value (Str/Num/TFN)
        ; -8  = End of Object/Array
        ; -9  = End of Value, Over 1 Char
        ; -10 = Valid JSON Start
        
        table    := {}
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.BG := ["BG","BG",-10 ,""  ,-10 ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Beginning
        table.AN := ["AN","AN",-1  ,""  ,-2  ,-8  ,""  ,""  ,-7  ,""  ,""  ,""  ,-7  ,""  ,-7  ,-7  ,""  ,""  ,""  ,""  ,""  ,-7  ,""  ,-7  ,""  ,""  ,-7  ,""  ,""  ,"" ] ; Array New
        table.ON := ["ON","ON",""  ,-4  ,""  ,""  ,""  ,""  ,-3  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Object New
        table.OK := ["OK","OK",""  ,""  ,""  ,""  ,""  ,""  ,-3  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Object Key
        table.OC := ["OC","OC",""  ,""  ,""  ,""  ,""  ,"VL",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Object Colon
        table.VL := ["VL","VL",-1  ,""  ,-2  ,""  ,""  ,""  ,-7  ,""  ,""  ,""  ,-7  ,""  ,-7  ,-7  ,""  ,""  ,""  ,""  ,""  ,-7  ,""  ,-7  ,""  ,""  ,-7  ,""  ,""  ,"" ] ; Value
        table.CC := ["CC","CC",""  ,-8  ,""  ,-8  ,-5  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Comma Close
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.ST := ["ST",""  ,"ST","ST","ST","ST","ST","ST",-6  ,"ES","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","" ] ; String
        table.ES := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST","ST","ST",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST",""  ,""  ,"ST",""  ,"ST","ST",""  ,"ST","U1",""  ,"" ] ; String Escape
        table.U1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U2","U2","U2","U2","U2","U2","U2","U2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 1
        table.U2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U3","U3","U3","U3","U3","U3","U3","U3",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 2
        table.U3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U4","U4","U4","U4","U4","U4","U4","U4",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 3
        table.U4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST","ST","ST","ST","ST","ST","ST","ST",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 4
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.NN := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ND","NI",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Negative
        table.NI := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,"D1","NI","NI",""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Integer
        table.ND := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,"D1",""  ,""  ,""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Decimal
        table.D1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"D2","D2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Decimal 1
        table.D2 := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"D2","D2",""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Decimal 2
        table.NE := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E1","E1",""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Exponent
        table.E1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Exponent 1
        table.E2 := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Exponent 2
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.T1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T2",""  ,""  ,""  ,""  ,"" ] ; true > tR
        table.T2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T3",""  ,"" ] ; true > trU
        table.T3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; true > true
        table.F1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > fa
        table.F2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F3",""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > fal
        table.F3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F4",""  ,""  ,""  ,"" ] ; false > fals
        table.F4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > false
        table.N1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N2",""  ,"" ] ; null > nu
        table.N2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N3",""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; null > nul
        table.N3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; null > null
        
        Return table
    }

    ; ===== Error checking =====
    err_find_table() {
        ; Validation table for a JSON file
        ; -1  = New Object/Get Key
        ; -2  = New Array
        ; -3  = String Start
        ; -4  = Empty Object
        ; -5  = Additional Value
        ; -6  = End of Value (Str/Num/TFN)
        ; -7  = Start of Value (Str/Num/TFN)
        ; -8  = End of Object/Array
        ; -9  = End of Value, Over 1 Char
        ; -10 = Valid JSON Start
        
        table    := {}
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.BG := ["BG","BG",-10 ,""  ,-10 ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Beginning
        table.AN := ["AN","AN",-1  ,""  ,-2  ,-8  ,""  ,""  ,-7  ,""  ,""  ,""  ,-7  ,""  ,-7  ,-7  ,""  ,""  ,""  ,""  ,""  ,-7  ,""  ,-7  ,""  ,""  ,-7  ,""  ,""  ,"" ] ; Array New
        table.ON := ["ON","ON",""  ,-4  ,""  ,""  ,""  ,""  ,-3  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Object New
        table.OK := ["OK","OK",""  ,""  ,""  ,""  ,""  ,""  ,-3  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Object Key
        table.OC := ["OC","OC",""  ,""  ,""  ,""  ,""  ,"VL",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Object Colon
        table.VL := ["VL","VL",-1  ,""  ,-2  ,""  ,""  ,""  ,-7  ,""  ,""  ,""  ,-7  ,""  ,-7  ,-7  ,""  ,""  ,""  ,""  ,""  ,-7  ,""  ,-7  ,""  ,""  ,-7  ,""  ,""  ,"" ] ; Value
        table.CC := ["CC","CC",""  ,-8  ,""  ,-8  ,-5  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Comma Close
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.ST := ["ST",""  ,"ST","ST","ST","ST","ST","ST",-6  ,"ES","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","" ] ; String
        table.ES := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST","ST","ST",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST",""  ,""  ,"ST",""  ,"ST","ST",""  ,"ST","U1",""  ,"" ] ; String Escape
        table.U1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U2","U2","U2","U2","U2","U2","U2","U2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 1
        table.U2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U3","U3","U3","U3","U3","U3","U3","U3",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 2
        table.U3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U4","U4","U4","U4","U4","U4","U4","U4",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 3
        table.U4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST","ST","ST","ST","ST","ST","ST","ST",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Unicode Char 4
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.NN := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ND","NI",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Negative
        table.NI := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,"D1","NI","NI",""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Integer
        table.ND := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,"D1",""  ,""  ,""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Decimal
        table.D1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"D2","D2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Decimal 1
        table.D2 := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"D2","D2",""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Decimal 2
        table.NE := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E1","E1",""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Number > Exponent
        table.E1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Exponent 1
        table.E2 := [-6  ,-6  ,""  ,-9  ,""  ,-9  ,-9  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; Exponent 2
        ;            1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30                      
        ;            spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    1-9 ABCDF a    b    e    E    f    l    n    r    s    t    u    ALL  NA                      
        table.T1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T2",""  ,""  ,""  ,""  ,"" ] ; true > tR
        table.T2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T3",""  ,"" ] ; true > trU
        table.T3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; true > true
        table.F1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > fa
        table.F2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F3",""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > fal
        table.F3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F4",""  ,""  ,""  ,"" ] ; false > fals
        table.F4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > false
        table.N1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N2",""  ,"" ] ; null > nu
        table.N2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N3",""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; null > nul
        table.N3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; null > null
        
        Return table
    }


    ; Uses char codes to assign validation table columns
    ; This bypasses AHK's "case-insensitive object key" issue
    make_valid_table_key() {
        ;             Spc     Tab     LF      CR      {       }       [       ]       ,       :       "       
        table_key := {32:1   ,9:2    ,10:2   ,13:2   ,123:3  ,125:4  ,91:5   ,93:6   ,44:7   ,58:8   ,34:9    
                     ;0       1       2       3       4       A       B       C       D       E        F      
                     ,48:15  ,49:16  ,50:16  ,51:16  ,52:16  ,65:17  ,66:17  ,67:17  ,68:17  ,69:21  ,70:17   
                     ;5       6       7       8       9       a       b       c       e       e       f       
                     ,53:16  ,54:16  ,55:16  ,56:16  ,57:16  ,97:18  ,98:19  ,99:20  ,100:20 ,101:20 ,102:22  
                     ;\       /       +       -       .       l       n       r       s       t       u       
                     ,92:10  ,47:11  ,43:12  ,45:13  ,46:14  ,108:23 ,110:24 ,114:25 ,115:26 ,116:27 ,117:28 }
        
        Loop, 32                              ; The first 32 ASCII control characters are forbidden
            (table_key[A_Index-1] > 0)        ; Tab, Linefeed, Carriage Return are the exceptions
                ? ""
                : table_key[A_Index-1] := 30  ; Index 30 is used to indicate a forbidden character
        
        Return table_key
    }
    
    basic_error(msg) {
        MsgBox, % msg
        Exit
    }
    
    error(txt, index, msg, expected, found, extra:="", delim:="", offset:=90) {
        txt_display	:= ""
        ,error_sec	:= ""
        ,start		:= ((index - offset) < 0) ? 0
                        : (index - offset)
        ,stop		:= index + offset
        
        ; Error display
        Loop, Parse, % txt, % delim
            If (A_Index < start)
                Continue
            Else If (A_Index > stop)
                Break
            Else error_sec .= A_LoopField
        
        ; Highlight problem
        Loop, Parse, % txt
        {
            If (A_Index > stop)
                Break
            Else If (A_Index < start)
                Continue
            Else If (A_Index = index)
                txt_display .= ">> " A_LoopField " <<"
            Else txt_display .= A_LoopField
        }
        
        MsgBox, 0x0, Error, % msg
            . "`nExpected: " expected
            . "`nFound: " found
            . "`nIndex: " index
            . "`nTxt: " error_sec
            . "`nError: " txt_display
            . (extra = "" ? "" : "`n" extra)
        Exit
    }
    
    ; ===== Test Methods =====
    ; View the contents of an object
    view_obj(obj, indent:="") {
        str := ""
        
        For key, value in obj
            str .= IsObject(value)
                ? indent key ": `n" indent A_Tab Trim(this.view_obj(value, indent . A_Tab), ", `r`t`n") ",`n"
                : indent key ": " value ",`n"
        
        str := Trim(Trim(str, "`n"), ",")
        
        If (indent = "")
            Clipboard := str
        Return str
    }

    msg(list*){
        str := ""
        For k, v in list
            str .= A_Index ": " v "`n"
        
        MsgBox, % str
        Return
    }
    
    qpx(N=0) {  ; Wrapper for QueryPerformanceCounter()by SKAN   | CD: 06/Dec/2009
        Local   ; www.autohotkey.com/forum/viewtopic.php?t=52083 | LM: 10/Dec/2009
        Static F:="", A:="", Q:="", P:="", X:=""
        If (N && !P)
            Return DllCall("QueryPerformanceFrequency",Int64P,F) + (X:=A:=0)
                + DllCall("QueryPerformanceCounter",Int64P,P)
        DllCall("QueryPerformanceCounter",Int64P,Q), A:=A+Q-P, P:=Q, X:=X+1
        Return (N && X=N) ? (X:=X-1)<<64 : (N=0 && (R:=A/X/F)) ? (R + (A:=P:=X:=0)) : 1
    }
}




    ; Table method I tried that didn't work as well as hoped
    ;~ json_table(json) {
        ;~ Local
        
        ;~ obj		:= {}            ; Converted object
        ;~ ,json_valid	:= {}        ; JSON Validation Table
        ;~ ,i		:= 0             ; Character index
        ;~ ,start	:= 0             ; Value start
        ;~ ,char	:= ""            ; Current char
        ;~ ,last_s	:= ""
        ;~ ,state	:= "BG"          ; Validation state
        ;~ ,get_key:= False         ; True if capturing string for object key
        ;~ ,max	:= StrLen(json)  ; Total chars in JSON string (Loop sentry)
        ;~ ,path	:= []            ; Tracks value paths
        ;~ ,path_t	:= []            ; Tracks if path is array or object
        
        ;~ ; Character token converter
        ;~ char_con := {" ":" "  ,"`r":"w"  ,"`n":"w"  ,"`t":"w"  ,"""":"q" ; Whitespace and string
                    ;~ ,"0":"z"  ,"1" :"#"  ,"2" :"#"  ,"3" :"#"  ,"4" :"#" ; Number int
                    ;~ ,"5":"#"  ,"6" :"#"  ,"7" :"#"  ,"8" :"#"  ,"9" :"#" ; Number int
                    ;~ ,0  :"z"  ,1   :"#"  ,2   :"#"  ,3   :"#"  ,4   :"#" ; Number int
                    ;~ ,5  :"#"  ,6   :"#"  ,7   :"#"  ,8   :"#"  ,9   :"#" ; Number int
                    ;~ ,"+":"+"  ,"-" :"-"  ,"." :"."  ,"c" :"x"  ,"d" :"x" ; Number symbols and CD hex
                    ;~ ,"[":"["  ,"]" :"]"  ,"{" :"{"  ,"}" :"}"            ; Arrays and objects
                    ;~ ,",":","  ,":" :":"  ,"\" :"\"  ,"/" :"/" }          ; Separators and escape chars
        
        ;~ ; Case sensitive character checker
        ;~ case_check := {"a":True ,"b":True ,"e":True ,"f":True ,"l":True
                      ;~ ,"n":True ,"r":True ,"s":True ,"t":True ,"u":True }
        
        ;~ ; Case sensitive conversion via char code
        ;~ case_con := {65 :"x"   ; A - hex
                    ;~ ,66 :"x"   ; B - hex
                    ;~ ,69 :"^"   ; E - number Exp, hex
                    ;~ ,70 :"x"   ; F - hex
                    ;~ ,76 :"*"   ; L - NA
                    ;~ ,78 :"*"   ; N - NA
                    ;~ ,82 :"*"   ; R - NA
                    ;~ ,83 :"*"   ; S - NA
                    ;~ ,84 :"*"   ; T - NA
                    ;~ ,85 :"*"   ; U - NA
                    ;~ ,97 :"a"   ; a - false, hex
                    ;~ ,98 :"b"   ; b - backspace
                    ;~ ,101:"e"   ; e - number exp, true, false, hex
                    ;~ ,102:"f"   ; f - false, formfeed, hex
                    ;~ ,108:"l"   ; l - false
                    ;~ ,110:"n"   ; n - null, linefeed
                    ;~ ,114:"r"   ; r - true, carriage return
                    ;~ ,115:"s"   ; s - false
                    ;~ ,116:"t"   ; t - true, horizontal tab
                    ;~ ,117:"u" } ; u - true, null, unicode
        
        ;~ ; Sets state when a value is started
        ;~ value_state := {"-" : "NN"    ; Number negative
                       ;~ ,"#" : "NI"    ; Number integer
                       ;~ ,"z" : "ND"    ; Number decimal
                       ;~ ,"q" : "ST"    ; String
                       ;~ ,"t" : "T1"    ; true
                       ;~ ,"f" : "F1"    ; false
                       ;~ ,"n" : "N1" }  ; null
        
        ;~ ; Sets state when a value ends
        ;~ value_end_state := {",":9       ; Get next value
                           ;~ ,"]":6       ; End of array
                           ;~ ,"}":6       ; End of object
                           ;~ ,"q":"CC"    ; Find next step after string
                           ;~ ," ":"CC"    ; Find next step after space
                           ;~ ,"w":"CC" }  ; Find next step after whitespace
        
        ;~ is_num := {"NI" : True
                  ;~ ,"ND" : True
                  ;~ ,"D2" : True
                  ;~ ,"E2" : True}
        
        ;~ ;1 - First Array
        ;~ ;2 - First Object
        ;~ ;3 - New Object
        ;~ ;4 - Empty Object
        ;~ ;5 - New Array
        ;~ ;6 - Array/Object End
        ;~ ;7 - Value End
        ;~ ;8 - Value Start
        ;~ ;9 - Next Value
        
        ;~ ; JSON file validation table
        ;~ ;                 spc       ws       {        }        [        ]        ,        :        "        \        /        +        -        .        z        #        x        a        b        e        ^        f        l        n        s        t        r        u       ALL      
        ;~ json_valid.BG := {" ":"BG","w":"BG","{":"2" ,"" :""  ,"[":"1" ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        
        ;~ json_valid.OB := {" ":"OB","w":"OB","" :""  ,"}":4   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"q":8   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.OC := {" ":"OC","w":"OC","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,":":"VL","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.AR := {" ":"AR","w":"AR","{":3   ,"" :""  ,"[":5   ,"]":6   ,"" :""  ,"" :""  ,"q":8   ,"" :""  ,"" :""  ,"" :""  ,"-":8   ,"" :""  ,"z":8   ,"#":8   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"f":8   ,"" :""  ,"n":8   ,"" :""  ,"t":8   ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.VL := {" ":"VL","w":"VL","{":3   ,"" :""  ,"[":5   ,"" :""  ,"" :""  ,"" :""  ,"q":8   ,"" :""  ,"" :""  ,"" :""  ,"-":8   ,"" :""  ,"z":8   ,"#":8   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"f":8   ,"" :""  ,"n":8   ,"" :""  ,"t":8   ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.CC := {" ":"CC","w":"CC","" :""  ,"}":6   ,"" :""  ,"]":6   ,",":9   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ ;                 spc       ws       {        }        [        ]        ,        :        "        \        /        +        -        .        0        #        x        a        b        e        ^        f        l        n        s        t        r        u       ALL      
        ;~ json_valid.ST := {" ":"ST","" :""  ,"{":"ST","}":"ST","[":"ST","]":"ST",",":"ST",":":"ST","q":7   ,"\":"ES","/":"ST","+":"ST","-":"ST",".":"ST","z":"ST","#":"ST","x":"ST","a":"ST","b":"ST","e":"ST","^":"ST","f":"ST","l":"ST","n":"ST","s":"ST","t":"ST","r":"ST","u":"ST","*":"ST" }
        ;~ json_valid.ES := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"q":"ST","\":"ST","/":"ST","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"b":"ST","" :""  ,"" :""  ,"f":"ST","" :""  ,"n":"ST","" :""  ,"t":"ST","r":"ST","u":"U1","" :""   }
        ;~ json_valid.U1 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"U2","#":"U2","x":"U2","a":"U2","b":"U2","e":"U2","^":"U2","f":"U2","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.U2 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"U3","#":"U3","x":"U3","a":"U3","b":"U3","e":"U3","^":"U3","f":"U3","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.U3 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"U4","#":"U4","x":"U4","a":"U4","b":"U4","e":"U4","^":"U4","f":"U4","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.U4 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"ST","#":"ST","x":"ST","a":"ST","b":"ST","e":"ST","^":"ST","f":"ST","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ ;                 spc       ws       {        }        [        ]        ,        :        "        \        /        +        -        .        0        #        x        a        b        e        ^        f        l        n        s        t        r        u       ALL      
        ;~ ;" " = CC, "w" = CC, ","
        ;~ json_valid.NN := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"ND","#":"NI","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.NI := {" ":7   ,"w":7   ,"" :""  ,"}":7   ,"" :""  ,"]":7   ,",":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,".":"D1","z":"NI","#":"NI","" :""  ,"" :""  ,"" :""  ,"e":"NE","^":"NE","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.ND := {" ":7   ,"w":7   ,"" :""  ,"}":7   ,"" :""  ,"]":7   ,",":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,".":"D1","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"e":"NE","^":"NE","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.D1 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"D2","#":"D2","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.D2 := {" ":7   ,"w":7   ,"" :""  ,"}":7   ,"" :""  ,"]":7   ,",":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"D2","#":"D2","" :""  ,"" :""  ,"" :""  ,"e":"NE","^":"NE","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.NE := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"+":"E1","-":"E1","" :""  ,"z":"E2","#":"E2","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.E1 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"E2","#":"E2","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.E2 := {" ":7   ,"w":7   ,"" :""  ,"}":7   ,"" :""  ,"]":7   ,",":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"z":"E2","#":"E2","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ ;                 spc       ws       {        }        [        ]        ,        :        "        \        /        +        -        .        0        #        x        a        b        e        ^        f        l        n        s        t        r        u       ALL      
        ;~ json_valid.T1 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"r":"T2","" :""  ,"" :""   }
        ;~ json_valid.T2 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"u":"T3","" :""   }
        ;~ json_valid.T3 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"e":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.F1 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"a":"F2","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.F2 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"l":"F3","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.F3 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"s":"F4","" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.F4 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"e":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.N1 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"u":"N2","" :""   }
        ;~ json_valid.N2 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"l":"N3","" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ json_valid.N3 := {"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"l":7   ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""  ,"" :""   }
        ;~ ;                 spc       ws       {        }        [        ]        ,        :        "        \        /        +        -        .        0        #        x        a        b        e        ^        f        l        n        s        t        r        u       ALL      
        
        ;~ While (i < max) {
            ;~ (char_con[(char := SubStr(json, ++i, 1))] == "")  ; Get next char and check if char_con fails
                ;~ ? (case_check[char])                          ; If char is one of the case sensitive letters
                    ;~ ? char := case_con[Asc(char)]             ; Assign char using its key code
                ;~ : char := "*"                                 ; Otherwise, assign char * (any character)
            ;~ : char := char_con[char]                          ; If char_con passed, assign correct symbol
            
            ;~ state := json_valid[(last_s := state)][char]           ; Update state using JSON validation table
            
            ;~ ; 1 - First Array
            ;~ If (state == 1)
                ;~ state		:= "AR"
                ;~ ,obj		:= []
                ;~ ,path.Push(1)
                ;~ ,path_t.Push(True)
            ;~ ; 2 - First Object
            ;~ Else If (state == 2)
                ;~ state		:= "OB"
                ;~ ,obj		:= {}
                ;~ ,get_key	:= True
            ;~ ; 3 - New Object
            ;~ Else If (state == 3)
                ;~ state		:= "OB"
                ;~ ,obj[path*]	:= {}
                ;~ ,get_key	:= True
            ;~ ; 4 - Empty Object
            ;~ Else If (state == 4)
                ;~ state		:= "CC"
                ;~ ,get_key	:= False
            ;~ ; 5 - New Array
            ;~ Else If (state == 5)
                ;~ state		:= "AR"
                ;~ ,obj[path*]	:= []
                ;~ ,path.Push(1)
                ;~ ,path_t.Push(True)
            ;~ ; 6 - Array/Object End
            ;~ Else If (state == 6)
                ;~ state		:= "CC"
                ;~ ,path.Pop()
                ;~ ,path_t.Pop()
            ;~ ; 7 - Non-Number End
            ;~ Else If (state == 7)
                ;~ If (get_key)
                    ;~ state 		:= "OC"
                    ;~ ,get_key	:= False
                    ;~ ;,this.msg("key: >" SubStr(json, start, i-start+1) "<")
                    ;~ ,path.Push(SubStr(json, start, i-start+1))
                    ;~ ,path_t.Push(False)
                ;~ Else If (is_num[last_s])
                    ;~ state := "CC"
                    ;~ ;,this.msg("number: >" SubStr(json, start, i-start) "<")
                    ;~ ,obj[path*]	:= SubStr(json, start, i-start)
                    ;~ ,i--
                ;~ Else
                    ;~ state 		:= "CC"
                    ;~ ;,this.msg("Value: >" SubStr(json, start, i-start+1) "<")
                    ;~ ,obj[path*]	:= SubStr(json, start, i-start+1)
            ;~ ; 8 - Value Start
            ;~ Else If (state == 8)
                ;~ state	:= value_state[char]
                ;~ ,start	:= i
            ;~ ; 9 - Next Value
            ;~ Else If (state == 9)
                ;~ If path_t[path_t.MaxIndex()]
                    ;~ state	:= "VL"
                    ;~ ,path[path.MaxIndex()]++
                ;~ Else
                    ;~ state		:= "OB"
                    ;~ ,get_key	:= True
                    ;~ ,path.Pop()
                    ;~ ,path_t.pop()
            ;~ ; Error - Blank state means an error occurred
            ;~ Else If (state == "")
                ;~ this.json_valid_error(json, i, last_s)
            
        ;~ }
        
        ;~ Return
        
        ; Scrapped number indexed table and converter
        ;~ ; Character token converter
        ;~ char_con := {" ":1   ,"`r":2   ,"`n":2   ,"`t":2   ,"""":9             ; Whitespace and string
                    ;~ ,"{":3   ,"}" :4   ,"[":5    ,"]" :6   ,"," :7   ,":":8    ; Arrays and objects
                    ;~ ,"0":15  ,"1" :16  ,"2" :16  ,"3" :16  ,"4" :16            ; Number int
                    ;~ ,"5":16  ,"6" :16  ,"7" :16  ,"8" :16  ,"9" :16            ; Number int
                    ;~ ,0  :15  ,1   :16  ,2   :16  ,3   :16  ,4   :16            ; Number int
                    ;~ ,5  :16  ,6   :16  ,7   :16  ,8   :16  ,9   :16            ; Number int
                    ;~ ,"c":17  ,"d" :17  ,"C" :17  ,"D" :17                      ; Number hex
                    ;~ ,"+":12  ,"-" :13  ,"." :14  ,"\" :10  ,"/" :11            ; Number symbols and escape chars
                    ;~ ,"t":25  ,"r" :26  ,"u" :27  ,"l" :23  ,"s" :24  ,"n": } ; true false null
        ;~ ; Necessary capital letter check b/c AHK object keys aren't case sensitive
        ;~ char_cap := {65 :17 ,66 :17 ,69 :21 ,70 :17  ; 65  = A, 66  = B, 69  = E, 70  = F
                    ;~ ,97 :18 ,98 :19 ,101:20 ,102:22  ; 97  = a, 98  = b, 101 = e, 102 = f
                    ;~ ,116:25 ,114:26 ,117:27          ; 116 = t, 114 = r, 117 = u
                    ;~ ,108:23 ,115:24 ,110:28 }        ; 108 = l, 115 = s, 110 = n
        
        ;~ ;             spc  ws   {    }    [    ]    ,    :    "    \    /    +    -    .    0    #    x    a    b    e    E    f    l    s    t    r    u    n    ALL
        ;~ ;             1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29
        ;~ json_valid.BG := ["BG","BG","ON",""  ,"PA",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.ON := ["ON","ON",""  ,"OK",""  ,""  ,""  ,""  ,"ST",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.AN := ["AN","AN","ON",""  ,"AN",""  ,""  ,""  ,"ST",""  ,""  ,""  ,"NM",""  ,"NM","NM",""  ,""  ,""  ,""  ,""  ,"F1",""  ,""  ,"T1",""  ,""  ,"N1",""   ]
        ;~ json_valid.VL := ["VL","VL","ON",""  ,"AN",""  ,""  ,""  ,"ST",""  ,""  ,""  ,"NN",""  ,"ND","NI",""  ,""  ,""  ,""  ,""  ,"F1",""  ,""  ,"T1",""  ,""  ,"N1",""   ]
        ;~ json_valid.OK := ["OK","OK",""  ,"OE",""  ,"AE",""  ,""  ,"ST",""  ,""  ,""  ,"NM",""  ,"NM","NM",""  ,""  ,""  ,""  ,""  ,"F1",""  ,""  ,"T1",""  ,""  ,"N1",""   ]
        ;~ json_valid.ST := ["ST",""  ,"ST","ST","ST","ST","ST","ST","OK","SE","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST","ST" ]
        ;~ json_valid.ES := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST","ST","ST",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST",""  ,""  ,"ST",""  ,""  ,"ST","ST","U1","ST",""   ]
        ;~ json_valid.U1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U2","U2","U2","U2","U2","U2","U2","U2",""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.U2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U3","U3","U3","U3","U3","U3","U3","U3",""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.U3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"U4","U4","U4","U4","U4","U4","U4","U4",""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.U4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ST","ST","ST","ST","ST","ST","ST","ST",""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.NN := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"ND","NI",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.NI := ["OK","OK",""  ,"OK",""  ,"OK","OK",""  ,""  ,""  ,""  ,""  ,""  ,"D1","NI","NI",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.ND := ["OK","OK",""  ,"OK",""  ,"OK","OK",""  ,""  ,""  ,""  ,""  ,""  ,"D1",""  ,""  ,""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.D1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"D2","D2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.D2 := ["OK","OK",""  ,"OK",""  ,"OK","OK",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"NE","NE",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.NE := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E1","E1",""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.E1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.E2 := ["OK","OK",""  ,"OK",""  ,"OK","OK",""  ,""  ,""  ,""  ,""  ,""  ,""  ,"E2","E2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.T1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T2",""  ,""  ,""   ]
        ;~ json_valid.T2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T3",""  ,""   ]
        ;~ json_valid.T3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"OK",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.F1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.F2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F3",""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.F3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F4",""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.F4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"OK",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.N1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N2",""  ,""   ]
        ;~ json_valid.N2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N3",""  ,""  ,""  ,""  ,""  ,""   ]
        ;~ json_valid.N3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N4",""  ,""  ,""  ,""  ,""  ,""   ]
    ;~ }
