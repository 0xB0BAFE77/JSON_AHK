#SingleInstance Force
#Warn
#NoEnv
#MaxMem 1024
#KeyHistory 0
SetBatchLines, -1
;ListLines, Off

;json_ahk.on_load()
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
    ;   - Write ._default() - Method to reset the JSON export display settings
    ;   - Speaking of export, should I write an export() function that works like import() but saves?
    ;   - .strip_quotes has not be implemented yet
    ;     This strips off string quotation marks when creating the AHK object
    ;   - Add error detection for duplicate keys (this includes keys that differe only in case)
    ;   - Add last_error property that can store a string saying what the last error was.
    ;   - Verify all return values
    ;   - Implementeing on_load() and on_exit() for loading/saving settings and preferences
    ;   - Implemented stripping of string quotation marks on conversion to object
    
    ; Creating a change log as of 20210307 to track changes
    ; - Fixed issues with .to_ahk() and .to_json()
    ;   Library works on a basic level now and can be used. :)
    ; - Added: .preview() method
    ; - Worked on comment info
    ; - Added: esc_slash property
    ; - Fixed: Empty brace checking
    ; - Massive update to README file
    ; - Rewrite of stringify()
    ; - Reduced conversion time by doing a mass tab/linefeed/carriage return trimming prior to parsing
    
    
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
    ; .no_brace_ws              | True: [DEF]   "key":{},                                                                                         |
    ;                           | False:        "key":{        },                                                                                 |
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
    
    ; RegEx Bank (Kudos to mateon1 at regex101.com for creating most of these regex patterns)
    Static rgx	    :=  {"k"    : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ ]*:"
                        ,"s"    : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))"
                        ,"n"    : "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))"
                        ,"b"    : "(?P<str>true|false|null)"
                        ,"e"    : "^[ |\t|\n|\r]*(\{[ |\t|\n|\r]*\}|\[[ |\t|\n|\r]*\])[ |\t|\n|\r]*$"}
    
    ; Used to assess values (string, number, true, false, null)
    Static  is_val :=   {"0":"n" ,"5":"n" ,0:"n" ,5:"n" ,"-" :"n"
                        ,"1":"n" ,"6":"n" ,1:"n" ,6:"n" ,"t" :"b"
                        ,"2":"n" ,"7":"n" ,2:"n" ,7:"n" ,"f" :"b"
                        ,"3":"n" ,"8":"n" ,3:"n" ,8:"n" ,"n" :"b"
                        ,"4":"n" ,"9":"n" ,4:"n" ,9:"n" ,"""":"s" }
    
    test() {
        ; IfElse vs ternary,    25 MB file,         5 iterations
        ; IfElse                to_ahk:             to_json: 
        ; Ternary               to_ahk: 3.65 sec    to_json: 16.8 sec
        
        obj     := {}
        jtxt    := json_ahk.test_file
        ;jtxt    := json_ahk.import()
        i       := 1
        
        ;this.array_one_line := True
        
        this.qpx(1)
        Loop, % i
            obj := json_ahk.to_ahk(jtxt)
        t1 := this.qpx(0)
        MsgBox, % "to_ahk done. Time: " t1/i " sec"
        
        this.qpx(1)
        Loop, % i
            json := json_ahk.to_json(obj)
        t2 := this.qpx(0)
        MsgBox, % (Clipboard := json)
        MsgBox, % "to_json done. Time: " t2/i " sec"
        
        Clipboard := json
        MsgBox, % "[qpx]to_ahk convert time: " t1/i " sec"
                . "`n[qpx]to_json convert time: " t2/i " sec"
        
        Return
    }
    
    on_load() {

        Return
    }
    
    on_exit() {
        ; Save settings
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
        ; Settings for forward slash escaping
        this.esc_slash_search := (this.esc_slash ? "/" : "")
        this.esc_slash_replace := (this.esc_slash ? "\/" : "")
        
        Return IsObject(obj)
            ? Trim(this.to_json_extract(obj, this.is_array(obj)), "`n")
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
        
        ;MsgBox, % "Starting Extract:`n`ntype: " type "`nind: >->" ind "<-<`n`n" this.view_obj(obj)
        
        ind_big := ind . this.indent_unit                                   		; Set big indent
        
        ,str    := (this.ob_new_line
                        ? "`n" (this.ob_val_inline ? ind_big : ind)                 ; Build beginning of arr/obj
                    : "")                                                   		; Create brace prefix
                . (this.no_braces ? "" : type ? "[" : "{")                  		; Add correct brace
        
        ;~ For key, value in obj
            ;~ str .= (this.is_array(value)                                    		; Check if value is array
                    ;~ ? (type ? ""                                            		; If current obj is array, do nothing
                        ;~ : "`n" ind_big key ": ")                            		; Else, construct obj prefix
                    ;~ . this.to_json_extract(value, 1, ind_big)           		    ; Then get extracted values
                ;~ : IsObject(value)                                           		; If value not array, check if object
                    ;~ ? (type ? "" : key ": ")                                		; Construct obj prefix
                        ;~ . this.to_json_extract(value, 0, ind_big)           		; Extract values
                ;~ : (type && this.array_one_line ? "" : "`n" ind_big)					; Should array elements be on 1 line
                    ;~ . (type ? "" : key ": ")                       					; If object, add key
                    ;~ . (InStr(value, """")                                   		; If string, encode: backslashes, backspaces
                        ;~ ? ("""" StrReplace(StrReplace(StrReplace(StrReplace(""		; formfeeds, linefeeds, carriage returns,
                        ;~ . StrReplace(StrReplace(StrReplace(StrReplace(StrReplace("" ; horizontal tabs, and fix \\u
                        ;~ . SubStr(value, 2, -1),"\","\\"),"`b","\b"),"`f","\f")		; Yes, this is ugly af 
                        ;~ ,"`n","\n"),"`r","\r"),"`t","\t"),"""","\"""),"\\u","\u")	; It's also faster thi
                        ;~ ,this.esc_slash_search, this.esc_slash_replace) """")					; Also, optionally escapes slashes
                        ;~ : value ) )                                         		; If not string, bypass decode and add value
                    ;~ . ","                                                   		; Always end with a comma
        
        ;;;;;;;;;;;;;;;;;;;; LEFT OFF HERE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        For key, value in obj
            ;this.msg("SubStr(value, 1, 1): " SubStr(value, 1, 1) "`n" str)
            str .= (type)
                ? (IsObject(value)
                    ? this.to_json_extract(value, this.is_array(value), ind_big)
                : RegExMatch(value, this.rgx[this.is_val[SubStr(value, 1, 1)]])
                    ? ("`n"
                        . ind_big
                        . value)
                : this.to_obj_error(value))
                . ","
            ; If object, add key and colon
            : "`n" ind_big . key ": "
                ? (IsObject(value)
                    ? this.to_json_extract(value, this.is_array(value), ind_big)
                : RegExMatch(value, this.rgx[this.is_val[SubStr(value, 1, 1)]])
                    ? value
                : this.to_obj_error(value))
                . ","
        
        ;MsgBox, % "type: " type "`nkey: " key "`nvalue: " value "`nstr: " str
        
        ;~ For key, value in obj
            ;~ str .= (this.is_array(value)
                    ;~ ? (type ? ""
                        ;~ : "`n" ind_big key ": ")
                    ;~ . this.to_json_extract(value, 1, ind_big)
                ;~ : IsObject(value)
                    ;~ ? (type ? "" : key ": ")
                        ;~ . this.to_json_extract(value, 0, ind_big)
                ;~ : (type && this.array_one_line ? "" : "`n" ind_big)
                    ;~ . (type ? "" : key ": ")
                    ;~ . (InStr(value, """")
                        ;~ ? ("""" StrReplace(StrReplace(StrReplace(StrReplace(""
                        ;~ . StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(""
                        ;~ . SubStr(value, 2, -1),"\","\\"),"`b","\b"),"`f","\f")
                        ;~ ,"`n","\n"),"`r","\r"),"`t","\t"),"""","\"""),"\\u","\u")
                        ;~ ,this.esc_slash_search, this.esc_slash_replace) """")
                        ;~ : value ) )
                    ;~ . ","
        
        str := RTrim(str, ",")   							; Strip off last comma
        If (type && this.array_one_line)						; Array elements on 1 line check
            str .= "]"									; If yes, cap off with bracket
        Else {
            str .= (this.cb_new_line							; Otherwise check if closing brace is on new line
                ? "`n" (this.cb_val_inline ? ind_big : ind)		; Check if brace should be indented to value
                : "" )											; Otherwise do nothing
            . (this.no_braces ? "" : type ? "]" : "}")		; Add appropriate closing brace
        }
        
        ; Empty object checker
        ;; In AHK v1, all arrays are objects so there is no way to distinguish between an empty array and empty object
        ;; When constructing JSON output, empty arrays will always show as empty objects
        ;; Can I just used array.Length()?
        If (this.no_empty_brace_ws && RegExMatch(str, this.rgx.e))
            str := this.no_braces
                ? ""
                : (this.ob_new_line ? "`n" ind : "") . "{}"
        
        Return str
    }
    
    to_obj_error(msg) {
        MsgBox, % "to_json() error.`n`n" msg
        Return
    }
    
    ; Converts a json text file into a single string
    stringify(json) {
        Local
        
        str := IsObject(json)
            ? this.stringify_obj(json, this.is_arr(json))
            : this.stringify_txt(json)
        
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

/*
[     "JSON Test Pattern pass8",
	{
		"object with 1 member":
		[
			"array with 1 element"
		]
	},
	{},
	[],
	{
		"test":"one",
		"test2":"two"
	},
	-42,
	true,
	false,
*/

    stringify_txt(txt){
        ; Remove all non-space whitespace
        ; Tabs/linefeeds/carriage returns are escaped in strings
        ; In a json file, these 3 forms of whitespace are only there for formatting
        txt := StrReplace(StrReplace(StrReplace(txt,"`t"),"`n"),"`r")
        str := ""
        i   := n := j := 1
        max := StrLen(txt)
        in_str := False
        
        While (i < max)
        {
            n := InStr(txt, """",, i)
            If in_str
            {
                str .= SubStr(txt, i, n-i+1)
                ,j := 1
                While (SubStr(txt, n-j, 1) == "\")
                    j++
                in_str := Mod(j,2) ? False : True
            }
            Else
                str .= StrReplace(SubStr(txt, i, n-i+1), " ")
                ,in_str := True
            i := ++n
        }
        Return (str . StrReplace(SubStr(txt, i, max)," "))
    }

    ; Convert json text to an ahk object
    to_ahk(json){
        Local
        ; Remove all non-string whitepsace as this speeds up the process immensely
        json    := StrReplace(json, "`n")
        ,json   := StrReplace(json, "`r")
        ,json   := StrReplace(json, "`t")
        
        obj     := {}                       ; Main object to build and return
        ,obj.SetCapacity(1024)              ; Does setting a large object size speed up performance?
        ,path   := []                       ; Path value should be stored in the object
        ,type   := []                       ; Tracks if current path is an array (true) or object (false)
        ,p_i    := 0                        ; Tracks path arrays and path type
        ,this.i := 0                        ; Tracks current position in the json string. Class var for error checking.
        ,char   := ""                       ; Current character
        ,next   := "s"                      ; Next expected action: (s)tart, (k)ey, (v)alue, (a)rray
        ,m_     := ""                       ; Stores regex matches
        ,m_str  := ""                       ; Stores regex match subpattern
        ,max    := StrLen(json)             ; Track total characters in json
        ,strip_q:= (this.strip_quotes       ; Set whether quotes should be stripped
            ? "" : """")
        
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
        
        ;~ While (this.i < max)
            ;~ (char := SubStr(json,++this.i,1)) = " "                                 ; Check if non-string whitespace
                ;~ ? ""                                                                ; If whitespace, do nothing
            ;~ : next == "v"                                                           ; If value is expected
                ;~ ? is_val[char]                                                      ; Check if valid start to string/num/null/bool
                    ;~ ? RegExMatch(json, rgx[is_val[char]], m_, this.i)               ; Validate through regex
                        ;~ ? (obj[path*] := (is_val[char]=="s"                         ; If string and a backslash is present, decode
                            ;~ ? (InStr(m_str, "\")                                    ; Check for escape characters
                                ;~ ? (this.strip_quotes ? "" : """")                   ; Optional quotes
                                    ;~ . this.string_decode(SubStr(m_str,2,-1))        ; If escape chars present, decode string
                                    ;~ . (this.strip_quotes ? "" : """")               ; Optional quotes
                                ;~ : this.strip_quotes                                 ; If strip quotes is true
                                    ;~ ? SubStr(m_str,2,-1)                            ; Strip quotes
                                    ;~ : m_str )                                       ; Else send with quotes
                            ;~ : m_str )                                               ; If not a string, use captured value
                            ;~ ,this.i += StrLen(m_str)-1, next := "e" )               ; Update index and next
                    ;~ : this.to_json_err("value", is_val[char])                       ; Invalid string/num/bool/null
                ;~ : InStr("{[", char)                                                 ; If not a value, check if new object or array
                    ;~ ? (obj[path*] := {}, next := (char == "{" ? "k" : "a") )        ; Add new object and get key/value
                ;~ : this.to_json_err("value")                                         ; Invalid value/object/array
            ;~ : next == "e"                                                           ; If an ender is expected
                ;~ ? char == ","                                                       ; If another value is expected
                    ;~ ? type[p_i] ? (path[p_i]++, next := "v" )                       ; If array, increment index
                    ;~ : (path.Pop(), type.Pop(), --p_i, next := "k" )                 ; Else object so pop key and get a new one
                ;~ : ((char == "}" && !type[p_i]) || (char == "]" && type[p_i]))       ; If valid end of object/array
                    ;~ ? (path.Pop(), type.Pop(), --p_i, next := "e")                  ; Remove last key and type
                ;~ : this.to_json_err("end", type[p_i])                                ; If invalid ender, error
            ;~ : next == "k"                                                           ; If object key expected
                ;~ ? RegExMatch(json, rgx.k, m_, this.i)                               ; If valid key and colon are present
                    ;~ ? (path[++p_i] := m_str, type[p_i] := 0                         ; Add key and update type
                    ;~ , this.i += StrLen(m_)-1, next := "v" )                         ; Get next value
                ;~ : char == "}" ? next := "e"                                         ; Else check if end of object
                ;~ : this.to_json_err("key")                                           ; If invalid key, error
            ;~ : next == "a"                                                           ; If new array
                ;~ ? char == "]" ? next := "e"                                         ; Check if end of array
                ;~ : (path[++p_i] := 1, type[p_i] := 1, --this.i, next := "v")         ; Else increment index, update type, decrement char index
            ;~ : next == "s"                                                           ; If start of JSON
                ;~ ? char == "{" ? (next := "k")                                       ; If valid JSON object, get a key
                ;~ : char == "[" ? (next := "a")                                       ; If valid array, get value
                ;~ : this.to_json_err("start")                                         ; If invalid start, error
            ;~ : ""
            ;~ ;,this.tt("index: " this.i "`nmax: " max "`np_i: " p_i "`nnext: " next "`nA_Index: " A_Index)
        
        ;~ While (this.i < max)
        ;~ {
;~ ;            MsgBox, % "this.i: " this.i "`nmax: " max
            ;~ (char := SubStr(json,++this.i,1))
            
            ;~ ;Tooltip, % "this.i: " this.i "`nmax: " max "`nchar: " char "`nAsc(char): " Asc(char) "`nnext: " next "`np_i: " p_i "`npath:`n" this.view_obj(path) "`n`nobj:`n" this.view_obj(obj)
            
            ;~ If (char == " ") ;is_ws[char]
                ;~ Continue
            ;~ Else If (next == "v")
            ;~ {
                ;~ If is_val[char]
                ;~ {
                    ;~ If RegExMatch(json, rgx[is_val[char]], m_, this.i)
                    ;~ {
                        ;~ obj[path*] := (is_val[char]=="s") 
                            ;~ ? InStr(m_str, "\")
                                ;~ ? (this.strip_quotes ? "" : """")
                                    ;~ . this.string_decode(SubStr(m_str,2,-1))
                                    ;~ . (this.strip_quotes ? "" : """")
                                ;~ : this.strip_quotes     
                                    ;~ ? SubStr(m_str,2,-1)
                                    ;~ : m_str
                            ;~ : m_str
                        ;~ ,this.i += StrLen(m_str)-1
                        ;~ ,next := "e"
                        ;~ ;MsgBox, % "VALUE`n`nchar: " char "`nnext: " next "`nthis.i: " this.i "`nis_val[char]: " is_val[char] "`nm_: " m_ "`nm_str: " m_str "`nobj[path*]: " obj[path*]
                    ;~ }
                    ;~ Else this.to_json_err("value", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
                ;~ }
                ;~ Else If (char == "{")
                ;~ {
                    ;~ obj[path*] := {}
                    ;~ ,next := "k"
                ;~ }
                ;~ Else If (char == "[")
                ;~ {
                    ;~ obj[path*] := {}
                    ;~ ,next := "a"
                ;~ }
                ;~ Else 
                    ;~ this.to_json_err("value", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
                ;~ ;MsgBox, % "VALUE`n`nchar: " char "`nis_val[char]: " is_val[char] "`nthis.view_obj(obj): " this.view_obj(obj) "`nthis.view_obj(path): " this.view_obj(path)
            ;~ }
            ;~ Else If (next == "e")
            ;~ {
                ;~ If (char == ",")
                ;~ {
                    ;~ If type[p_i]
                    ;~ {
                        ;~ path[p_i]++
                        ;~ ,next := "v"
                    ;~ }
                    ;~ Else
                    ;~ {
                        ;~ path.Pop()
                        ;~ ,type.Pop()
                        ;~ ,--p_i
                        ;~ ,next := "k"
                    ;~ }
                ;~ }
                ;~ Else If ((char == "}" && !type[p_i]) || (char == "]" && type[p_i]))
                ;~ {
                    ;~ path.Pop()
                    ;~ ,type.Pop()
                    ;~ ,--p_i
                ;~ }
                ;~ Else this.to_json_err("end")
            ;~ }
            ;~ Else If (next == "k")
            ;~ {
                ;~ If (char == "}")
                    ;~ next := "e"
                ;~ Else If RegExMatch(json, rgx.k, m_, this.i)
                ;~ {
                    ;~ path[++p_i] := m_str
                    ;~ ,type[p_i] := 0
                    ;~ ,this.i += StrLen(m_) - 1
                    ;~ ,next := "v"
                ;~ }
                ;~ Else
                    ;~ this.to_json_err("key", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
            ;~ }
            ;~ Else If (next == "a")
            ;~ {
                ;~ If (char == "]")
                    ;~ next := "e"
                ;~ Else
                ;~ {
                    ;~ path[++p_i] := 1
                    ;~ ,type[p_i] := 1
                    ;~ ,next := "v"
                    ;~ ,--this.i
                ;~ }
            ;~ }
            ;~ Else If (next == "s")
            ;~ {
                ;~ If (char == "{")
                    ;~ next := "k"
                ;~ Else If (char == "[")
                    ;~ next := "a"
                ;~ Else
                    ;~ this.to_json_err("start", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
            ;~ }
            ;~ Else MsgBox, "Next Var Error. A valid next was not set."
            ;~ ;ToolTip, % "this.i: " this.i "`nmax: " max "`nchar: " char "`nnext: " next "`nA_Index: " A_Index
        ;~ }
        
        While (this.i < max)
            ((char := SubStr(json,++this.i,1)) == " ")
                ? ""
            : (next == "v")
                ? is_val[char]
                    ? RegExMatch(json, this.rgx[is_val[char]], m_, this.i)
                        ? ( obj[path*] := (is_val[char]=="s") 
                            ? InStr(m_str, "\")
                                ? strip_q . this.string_decode(SubStr(m_str,2,-1)) . strip_q
                                : this.strip_quotes     
                                    ? SubStr(m_str,2,-1)
                                    : m_str
                            : m_str
                        ,this.i += StrLen(m_str)-1
                        ,next := "e" )
                    : this.to_json_err("value", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
                : (char == "{")
                    ? (obj[path*] := {}, next := "k")
                : (char == "[")
                    ? (obj[path*] := {}, next := "a")
                : this.to_json_err("value", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
            : (next == "e")
                ? (char == ",")
                    ? type[p_i]
                        ? (path[p_i]++, next := "v")
                    : (path.Pop(), type.Pop(), --p_i, next := "k")
                : ((char == "}" && !type[p_i]) 
                || (char == "]" && type[p_i]))
                    ? (path.Pop(), type.Pop(), --p_i)
                : this.to_json_err("end")
            : (next == "k")
                ? (char == "}")
                    ? next := "e"
                : RegExMatch(json, this.rgx.k, m_, this.i)
                    ? (path[++p_i] := m_str, type[p_i] := 0
                        ,this.i += StrLen(m_) - 1, next := "v" )
                ; Why does this not work?!
                ; There is something off with the key regex match
                ; May rewrite this. Remove the key regex completely,
                ; use the string check from next=value, implement a
                ; way to track if assigning a string or an object key,
                ; and include a colon check.
                ;~ ? RegExMatch(json, this.rgx.k, m_, this.i)
                    ;~ ? (path[++p_i] := m_str, type[p_i] := 0
                        ;~ ,this.i += StrLen(m_) - 1, next := "v" )
                ;~ : (char == "}")
                    ;~ ? next := "e"
                : this.to_json_err("key", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
            : (next == "a")
                ? (char == "]")
                    ? next := "e"
                : (path[++p_i] := 1, type[p_i] := 1 ,next := "v", --this.i)
            : (next == "s")
                ? (char == "{")
                    ? next := "k"
                : (char == "[")
                    ? next := "a"
                : this.to_json_err("start", "this.view_obj(obj): " this.view_obj(obj) "`np_i: " p_i)
            : ""
        
        this.json := ""             ; Post conversion clean up
        
        (p_i != 0)                  ; Verify there are no open objects or arrays
            ? this.msg("Error! path index p_i is not 0!") ;this.to_json_err("")  ; Error if p_i isn't 0
            : ""
        
        Return obj
    }
    
    to_json_err(next, extra:="") {
        char := SubStr(this.json, this.i, 1)
        offset := 20
        max := StrLen(this.json)
        d_min := (this.i-offset < 1 ? 1 : this.i-offset)
        d_max := (this.i+offset > max ? max  : this.i+offset)
        ;display := SubStr(this.json, d_min, d_max)
        display := SubStr(this.json, d_min, this.i-d_min)
                . ">-->" SubStr(this.json, this.i, 1) "<--<"
                . SubStr(this.json, this.i+1, d_max-this.i)
        MsgBox, % "BIG ERROR!`nnext: " next "`nextra: " extra "`nchar: " char "`nascii: " Asc(char) "`nthis.i: " this.i "`nmax: " strlen(this.json) "`n" display
        
        Exit
    }
    
    error_display(offset:=20) {
        max := StrLen(this.json)
        min := (this.i-offset < 0   ? 0     : this.i-offset )
        max := (this.i+offset > max ? max   : this.i+max )
        Return SubStr(this.json, min, this.i-min-1)
                    . ">-->" SubStr(this.json, this.i, 1) "<--<"
                    . SubStr(this.json, this.i+1, max)
    }
    
    string_decode(txt) {
        txt := StrReplace(txt,  "\b", "`b")     ; Backspace
        ,txt:= StrReplace(txt, "\f", "`f")      ; Formfeed
        ,txt:= StrReplace(txt, "\n", "`n")      ; Linefeed
        ,txt:= StrReplace(txt, "\r", "`r")      ; Carriage Return
        ,txt:= StrReplace(txt, "\t", "`t")      ; Tab
        ,txt:= StrReplace(txt, "\/", "/")       ; Slash / Solidus
        ,txt:= StrReplace(txt, "\""", """")     ; Double Quotes
        Return StrReplace(txt, "\\", "\")       ; Reverse Slash / Solidus
    }
    
    ; Encodes specific chars to escaped chars
    string_encode(txt) {
        Local
        txt := StrReplace(SubStr(txt, 2, -1) ,"\" ,"\\" )
        ,txt := StrReplace(txt ,"`b" ,"\b" )
        ,txt := StrReplace(txt ,"`f" ,"\f" )
        ,txt := StrReplace(txt ,"`n" ,"\n" )
        ,txt := StrReplace(txt ,"`r" ,"\r" )
        ,txt := StrReplace(txt ,"`t" ,"\t" )
        ,txt := StrReplace(txt ,"""" ,"\""")
        Return """" StrReplace(txt ,"\\u" ,"\u") """"
    }
    
    ; Default settings for json_ahk
    _default() {
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
            Return 0
        For k, v in obj
            If (k != A_Index)
                Return 0
        Return 1
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
