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
    ;     This will be a toggleable property option. something like .key_check
    ;   - Arrays are objects in AHK and not their own defined type.
    ;     This library "assumes" an array by checking 2 things:
    ;	    If the first key in the object is a 1
    ;       If each following key is 1 greater than the last
    ;     Because there are no keys to check in an empty array []
    ;     it will always be detected as an empty object {}
    
    ; Currently working on/to-do:
    ;   - Stringfy doesn't work. Rewrite needed.
    ;   - Error checking still needs to be implemented
    ;     This should be able to the user EXACTLY where the error is and why it's an error.
    ;   - Add option to put array elements on one line when exporting JSON text
    ;   - Write .validate() (use to_obj as a template w/o actually writing to the object)
    ;   - Write ._default() - Method to reset the JSON export display settings
    ;   - Speaking of export, should I write an export() function that works like import() but saves?
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
    ; Update for 20210405
    ; - Rewrote to_json() and fixed most of the properties issues
    ; - Currently, a 10MB file on a crappy thin client machine will convert in ~13 seconds (either way)
    ; - Doing more optimizing
    ; - Still building the error detector
    ; - 2 Built-in testfiles. One object, one array.
    ; - 
    
    
    ;===========================================================================.
    ; Title:        JSON_AHK                                                    |
    ; Desc:         Library that converts JSON to AHK objects and AHK to JSON   |
    ; Author:       0xB0BAFE77                                                  |
    ; Created:      20200301                                                    |
    ; Last Update:  20210405                                                    |
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
    ; ._default()       |
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
    ; AHK to JSON (Export) settings         ;Default|
    Static indent_unit          := "`t"     ; `t    | Set to desired indent (EX: "  " for 2 spaces)
    
    Static ob_new_line          := True     ; True  | Open brace is put on a new line
    Static ob_val_inline        := False    ; False | Open braces on a new line are indented to match value
    Static cb_new_line          := True     ; True  | Close brace is put on a new line
    Static cb_val_inline        := False    ; False | Close brace on a new line are indented to match value
    
    Static arr_val_same_line  := False    ; False | First value of an array appears on the same line as the brace
    Static obj_val_same_line  := False    ; False | First value of an object appears on the same line as the brace
    
    Static no_brace_ws          := True     ; True  | Remove whitespace from empty braces
    Static esc_slash            := False    ; False | Add the optional escape to forward slashes/solidus
    Static array_one_line       := False    ; False | List array elements on one line instead of multiple
    Static empty_arr_same_line  := True     ; True  | Overrides ob_new_line and keeps empty arrays on same line as key
    Static add_quotes           := False    ; False | Adds quotation marks to all strings if they lack one
    Static no_braces            := False    ; False | Removes object and array braces. This invalidates its JSON
                                            ;       | format and should only be used for human consumption/readability
    
    ; JSON to AHK (import) settings
    Static strip_quotes         := False    ; False | Removes quotation marks from strings on export
    Static dupe_key_check       := True     ; True  | Notifies users of dupliciate keys.
    ;==================================================================================================================
    
    ; Test files that check almost everything
    ; _a starts as an array and _o starts as an object
    Static test_file_a := "[`n`t""JSON Test Pattern pass1"",`n`t{""object with 1 members"":[""array with 1 element""]},`n`t{},`n`t[],`n`t-42,`n`ttrue,`n`tfalse,`n`tnull,`n`t{`n`t`t""integer"": 1234567890,`n`t`t""real"": -9876.543210,`n`t`t""e"": 0.123456789e-12,`n`t`t""E"": 1.234567890E+34,`n`t`t"""":  23456789012E66,`n`t`t""zero"": 0,`n`t`t""one"": 1,`n`t`t""space"": "" "",`n`t`t""quote"": ""\"""",`n`t`t""backslash"": ""\\"",`n`t`t""controls"": ""\b\f\n\r\t"",`n`t`t""slash"": ""/ & \/"",`n`t`t""alpha"": ""abcdefghijklmnopqrstuvwyz"",`n`t`t""ALPHA"": ""ABCDEFGHIJKLMNOPQRSTUVWYZ"",`n`t`t""digit"": ""0123456789"",`n`t`t""0123456789"": ""digit"",`n`t`t""special"": ""````1~!@#$``%^&*()_+-={':[,]}|;.</>?"",`n`t`t""hex"": ""\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"",`n`t`t""true"": true,`n`t`t""false"": false,`n`t`t""null"": null,`n`t`t""array"":[  ],`n`t`t""object"":{  },`n`t`t""address"": ""50 St. James Street"",`n`t`t""url"": ""http://www.JSON.org/"",`n`t`t""comment"": ""// /* <!-- --"",`n`t`t""# -- --> */"": "" "",`n`t`t"" s p a c e d "" :[1,2 , 3`n`n,`n`n4 , 5`t`t,`t`t  6`t`t   ,7`t`t],""compact"":[1,2,3,4,5,6,7],`n`t`t""jsontext"": ""{\""object with 1 member\"":[\""array with 1 element\""]}"",`n`t`t""quotes"": ""&#34; \u0022 ``%22 0x22 034 &#x22;"",`n`t`t""\/\\\""\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t``1~!@#$``%^&*()_+-=[]{}|;:',./<>?""`n: ""A key can be any string""`n`t},`n`t0.5 ,98.6`n,`n99.44`n,`n`n1066,`n1e1,`n0.1e1,`n1e-1,`n1e00,2e+00,2e-00`n,""rosebud""]"
    Static test_file_o := "{`n`t""key_01_str"": ""String"",`n`t""key_02_num"": -1.05e+100,`n`t""key_03_true_false_null"":`n`t{`n`t`t""true"": true,`n`t`t""false"": false,`n`t`t""null"": null`n`t},`n`t""key_04_obj_num"":`n`t{`n`t`t""Integer"": 1234567890,`n`t`t""Integer negative"": -420,`n`t`t""Fraction/decimal"": 0.987654321,`n`t`t""Exponent"": 99e2,`n`t`t""Exponent negative"": -1e-999,`n`t`t""Exponent positive"": 11e+111,`n`t`t""Mix of all"": -3.14159e+100`n`t},`n`t""key_05_arr"":`n`t[`n`t`t""Value1"",`n`t`t""Value2"",`n`t`t""Value3""`n`t],`n`t""key_06_nested_obj_arr"":`n`t{`n`t`t""matrix"":`n`t`t[`n`t    `t[`n`t    `t`t0,`n`t    `t`t1,`n`t    `t`t2`n`t    `t],`n`t    `t[`n`t    `t`t0,`n`t    `t`t1,`n`t    `t`t2`n`t    `t],`n`t    `t[`n`t    `t`t0,`n`t    `t`t1,`n`t    `t`t2`n`t    `t]`n`t`t],`n`t`t""person object example"":`n`t`t{`n`t    `t""name"": ""0xB0BAFE77"",`n`t    `t""job"": ""Professional Geek"",`n`t    `t""faves"":`n`t    `t{`n`t    `t`t""color"":`n`t    `t`t[`n`t    `t    `t""Black"",`n`t    `t    `t""White""`n`t    `t`t],`n`t    `t`t""food"":`n`t    `t`t[`n`t    `t    `t""Pizza"",`n`t    `t    `t""Cheeseburger"",`n`t    `t    `t""Steak""`n`t    `t`t],`n`t    `t`t""vehicle"":`n`t    `t`t{`n`t    `t    `t""make"": ""Subaru"",`n`t    `t    `t""model"": ""WRX STI"",`n`t    `t    `t""year"": 2018,`n`t    `t    `t""color"":`n`t    `t    `t{`n`t    `t`t    `t""Primary"": ""Black"",`n`t    `t`t    `t""Secondary"": ""Red""`n`t    `t    `t},`n`t    `t    `t""transmission"": ""M"",`n`t    `t    `t""msrp"": 26995.00`n`t    `t`t}`n`t    `t}`n`t`t}`n`t},`n`t""key_07_string_stuff"":`n`t{`n`t`t""ALPHA UPPER"": ""ABCDEFGHIJKLMNOPQRSTUVWXYZ"",`n`t`t""alpha lower"": ""abcdefghijklmnopqrstuvwxyz"",`n`t`t""Specials"": ""!@#$%^&*()_+-=[]{}<>,./?;':"",`n`t`t""Digits"": ""0123456789"",`n`t`t""0123456789"": ""Digits"",`n`t`t""key_case_check"": ""key_case_check lower"",`n`t`t""KEY_CASE_CHECK"": ""KEY_CASE_CHECK UPPER"",`n`t`t""Escape Characters"":`n`t`t{`n`t    `t""ESC_01 Quotation Mark"": ""\"""",`n`t    `t""ESC_02 Backslash/Reverse Solidus"": ""\\"",`n`t    `t""ESC_03 Slash/Solidus (Not a mandatory escape)"": ""\/ and / work"",`n`t    `t""ESC_04 Backspace"": ""\b"",`n`t    `t""ESC_05 Formfeed"": ""\f"",`n`t    `t""ESC_06 Linefeed"": ""\n"",`n`t    `t""ESC_07 Carriage Return"": ""\r"",`n`t    `t""ESC_08 Horizontal Tab"": ""\t"",`n`t    `t""ESC_09 Unicode"": ""\u00AF\\_(\u30C4)_\/\u00AF"",`n`t    `t""ESC_10 All"": ""\\\/\""\b\f\n\r\t\u0033"",`n`t    `t""ESC_11 \/\t\u0033\t\/"": ""Key with Encodes""`n`t`t}`n`t},`n`t""key_08_text_of_json_text"": ""{\""object with 1 member\"": [\""array with 1 element\""]}"",`n`t""key_09_quotes"": ""&#34; \u0022 `%22 0x22 034 &#x22;"",`n`t""key_10_empty"":`n`t{`n`t`t""Empty Value"": """",`n`t`t"""": ""Empty Key"",`n`t`t""Empty Array"": [],`n`t`t""Empty Object"": {}`n`t},`n`t""key_11_spacing"":`n`t{`n`t`t""compact"":[1,2,3,4,""a"",""b"",""c"",""d""],`n`t`t""expanded"":`n`t`t[`n`t    `t""This "",                      ""is""  `t    `t          ,""considered""`n`t    `t`t    `t,""valid "",`t    `t`t    ""spacing.\n"",`n`t    `t""JSON "",`n`t    `t`t""only "",`n`t    `t    `t""cares "",`n`t    `t`t    `t""about "",`n`t    `t`t    `t`t""whitespace "",`n`t    `t`t    `t    `t""inside "",`n`t    `t`t    `t`t    `t""of"",`n`t    `t`t    `t`t    `t`t""strings.""`n`t    `t`t    `t`t    `t    `t],`n`t`t""valid JSON whitespace"":`n`t    `t    `t[""Space"",`n`t    `t`t""Linefeed"",`n`t    `t""Carriage Return"",`n`t`t""Horizontal Tab""]`n`t},`n`t""key_12_code_comments"": [""C"", ""REM"", ""::"", ""NB."", ""#"", ""%"", ""//"", ""'"", ""!"", "";"", ""--"", ""*"", ""||"", ""*>""]`n}"
    
    ; RegEx Bank (I'd like to give Kudos to mateon1 at regex101.com for creating most of these. His are superior to the ones I made.)
    Static rgx	    :=  {"k"    : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ ]*:"
                        ,"s"    : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))"
                        ,"n"    : "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))"
                        ,"b"    : "(?P<str>true|false|null)"
                        ,"e"    : ":?[ |\t|\n|\r]*[\{|\[][ |\t|\n|\r]*$"}
    
    ; Used to assess values (string, number, true, false, null)
    Static is_val   :=  {"0":"n" ,"5":"n" ,0:"n" ,5:"n" ,"-" :"n"
                        ,"1":"n" ,"6":"n" ,1:"n" ,6:"n" ,"t" :"b"
                        ,"2":"n" ,"7":"n" ,2:"n" ,7:"n" ,"f" :"b"
                        ,"3":"n" ,"8":"n" ,3:"n" ,8:"n" ,"n" :"b"
                        ,"4":"n" ,"9":"n" ,4:"n" ,9:"n" ,"""":"s" }
    
    Static is_ws    :=  {" "    :True
                        ,"`t"   :True
                        ,"`r"   :True
                        ,"`n"   :True }
    
    test_settings() {
        ; JSON settings
        this.indent_unit        := "`t"
        this.ob_new_line        := False
        this.ob_val_inline      := False
        this.cb_new_line        := False
        this.cb_val_inline      := False
        
        this.arr_val_same_line  := False
        this.obj_val_same_line  := False
        
        this.no_brace_ws        := True
        this.array_one_line     := False
        this.add_quotes         := False
        this.no_braces          := False
        
        ; Obj settings
        this.strip_quotes       := False
        this.dupe_key_check     := True
        
        Return
    }
    
    test() {
        ; Doing mass strreplace for tab/LF/CR prior to parsing
        ; 10 MB x3 Before:      to_ahk:       sec   to_json:       sec
        ; 10 MB x3 After:       to_ahk:       sec   to_json:       sec
        ; 25 MB x2 Before:      to_ahk:       sec   to_json:       sec
        ; 25 MB x2 After:       to_ahk:       sec   to_json:       sec
        
        ; Doing mass strreplace for tab/LF/CR prior to parsing
        ; 10 MB x3 Before:      to_ahk: 15.01 sec   to_json: 12.44 sec
        ; 10 MB x3 After:       to_ahk: 13.13 sec   to_json: 13.02 sec
        ; 25 MB x2 Before:      to_ahk: 20.27 sec   to_json: 70.20 sec
        ; 25 MB x2 After:       to_ahk: 19.47 sec   to_json: 77.10 sec
        
        ; Setting str size prior to creating json. 10MB file.
        ; 10 MB x5 Before:      to_ahk: 13.06 sec   to_json: 13.89 sec
        ; 10 MB x5 After:       to_ahk: 13.14 sec   to_json: 13.66 sec
        ; 25 MB x2 Before:      to_ahk: 19.53 sec   to_json: 77.43 sec
        ; 25 MB x2 After:       to_ahk: 19.36 sec   to_json: 77.03 sec
        
        tests := {"Good"            :"""ABC\n\t123\n\t\t\u0033"""
                 ,"Bad escape"      :"""ABC\q\t123\n\t\t\u0033"""
                 ,"Invalid Hex 1"   :"""ABC\n\t123\n\t\t\uz033"""
                 ,"Invalid Hex 2"   :"""ABC\n\t123\n\t\t\u0z33"""
                 ,"Invalid Hex 3"   :"""ABC\n\t123\n\t\t\u00z3"""
                 ,"Invalid Hex 4"   :"""ABC\n\t123\n\t\t\u003z"""
                 ,"No end quote"    :"""ABC\n\t123\n\t\t\u0033"   
                 ,"No start quote"  :  "ABC\n\t123\n\t\t\u0033""" }
        
        For k, v in tests
        {
            MsgBox, Testing for %k%.
            this.validate_string(v)
        }
        
        ExitApp
        Return
        
        obj     := {}
        jtxt    := json_ahk.test_file_a
        jtxt    := json_ahk.import()
        i       := 2
        
        this.test_settings()
        this.qpx(1)
        txt := this.stringify_txt(jtxt)
        t1 := this.qpx(0)
        MsgBox, % "Time to stringify: " t1 " sec"
        
        ;this.array_one_line := True
        
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
                . "`nJSON on clipboard."
                . "`n`n" json
        
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
    
    validate(json) {
        
        Return
    }
    
    preview(save:=0) {
        txt := this.to_json(this.to_ahk(this.test_file_a))
        save ? Clipboard := txt : ""
        ; This msgbox needs to be replaced by a custom made edit box
        ; that displays the text in monospaced font and is in a scrollable,
        ; ediablte field.
        ; MsgBox makes JSON files look hideous. No customization, either.
        MsgBox, % txt
        Return txt
    }
    
    ; Convert AHK object to JSON string
    to_json(obj, ind:="") {
        ; User settings for forward slash escaping
        this.esc_slash_search := (this.esc_slash ? "/" : "")
        this.esc_slash_replace := (this.esc_slash ? "\/" : "")
        
        IsObject(obj)
            ? str := this.to_json_extract(obj, this.is_array(obj))
            : this.basic_error("You did not supply a valid object or array")
        
        ; Clean up outside of JSON
        str := Trim(str, "`n`t`r ")
        
        ; Fix last brace if cb_val_inline is used
        (this.cb_new_line && this.cb_val_inline)
            ? str := RegExReplace(str, "^(.*?)[ |\t]*(\}|\])$", "$1$2")
            : ""
        
        Return str
    }
    
    ; Recursively extracts values from an object
    ; type tracks if obj is an array. 1 if array else 0 if object
    ; ind is the indentation before the value and set using .indent_unit class property
    ; ind is incremented each time recursion happens
    ; o_key is the key of the current object being extracted and includes the colon
    ; o_key is always blank for arrays
    to_json_extract(obj, type, ind:="", o_key:="") {
        Local
        
        str := ind
            . (o_key = ""
                ? (this.ob_val_inline
                    ? this.indent_unit
                    : "")
                : o_key
                . (this.ob_new_line
                    ? "`n" ind
                    . (this.ob_val_inline
                        ? this.indent_unit
                        : "")
                    : ""))
            . (type ? "[" : "{")
            . (type && this.arr_val_same_line
                ? ""
                : !type && this.obj_val_same_line
                ? ""
                : "`n")
        
        For key, value in obj
            str .= IsObject(value)
                ? this.to_json_extract(value
                    ,this.is_array(value)
                    ,ind . this.indent_unit
                    ,(type ? "" : this.string_encode(key) ": "))
                    . ",`n"
                : ind . this.indent_unit
                    . (type ? "" : this.string_encode(key) ": ")
                    . ((v := this.is_val[SubStr(value, 1, 1)])
                        ? v == "s"
                            ? this.string_encode(value)
                            : value
                        : this.basic_error("to_json() error."
                            . "`nThis is not a valid value: " value))
                    . ","
                    . "`n"
        
        Return (this.no_brace_ws && RegExMatch(str, this.rgx.e))    ; Check user settings for empty array
            ? ind o_key "{}"                                        ; Return compressed empty array
            : RTrim(str, ",`n")                                     ; Otherwise, strip ending
                . (this.cb_new_line
                    ? "`n" ind (this.cb_val_inline
                        ? this.indent_unit
                        : "")
                    : "")
                . (this.no_braces ? ""
                    : type ? "]"
                    : "}")
        
        ;; Note about arrays and objects in AHK
        ;; In AHK v1, all arrays are objects so there is no way to distinguish between an empty array and empty object
        ;; When constructing JSON output, empty arrays will always show as empty objects
    }
    
    to_json_validate() {
        
        Return
    }
    
    to_json_error(msg) {
        MsgBox, % "to_json_error() error message.`n`nMessage:`n" msg
        Return
    }
    
    ; Converts a json text file into a single string
    stringify(json) {
        Local
        
        str := IsObject(json)
            ? this.stringify_obj(json, this.is_array(json))
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
    
    stringify_txt(txt){
        ; Reduce parse time by bulk removing all non-space whitespace
        txt     := StrReplace(txt,"`t")
        ,txt    := StrReplace(txt,"`n")
        ,txt    := StrReplace(txt,"`r")
        ,str    := ""
        ,i      := 1
        ,max    := StrLen(txt)
        
        While (i < max)
            (start   := RegExMatch(txt, "P)(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*"")", len, i))
                ? (str .= StrReplace(SubStr(txt, i, start-i), " ")
                    . SubStr(txt, start, len)
                    ,i := start+len)
                : (str .= StrReplace(SubStr(txt, i), " ")
                    ,i := max)
        
        Return str
    }
    
    ; Convert json text to an ahk object
    to_ahk(json){
        Local
        ; Remove all non-string whitepsace as this speeds up the process immensely
        json    := StrReplace(json, "`n")
        ,json   := StrReplace(json, "`r")
        ,json   := StrReplace(json, "`t")
        
        obj     := {}                       ; Main object to build and return
        ,path   := []                       ; Path value should be stored in the object
        ,type   := []                       ; Tracks if current path is an array (true) or object (false)
        ,p_i    := 0                        ; Tracks path arrays and path type
        ,this.i := 0                        ; Tracks current position in the json string. Class var for error checking.
        ,char   := ""                       ; Current character
        ,next   := "s"                      ; Next expected action: (s)tart, (k)ey, (v)alue, (a)rray, (e)nder
        ,m_     := ""                       ; Stores regex matches
        ,m_str  := ""                       ; Stores regex match subpattern
        ,max    := StrLen(json)             ; Track total characters in json
        ,strip_q:= (this.strip_quotes       ; Set whether quotes should be stripped
            ? ""
            : """")
        ,this.json := json                  ; Store JSON in class for error detection
        
        While (this.i < max)
            (char := SubStr(json,++this.i,1)) = " "
                ? ""
                : next == "v"
                    ? this.is_val[char]
                        ? RegExMatch(json, this.rgx[this.is_val[char]], m_, this.i)
                            ? (obj[path*] := (this.is_val[char] == "s")
                                ? InStr(m_str, "\")
                                    ? strip_q
                                    . this.string_decode(SubStr(m_str,2,-1))
                                    . strip_q
                                    : this.strip_quotes
                                        ? SubStr(m_str,2,-1)
                                        : m_str
                                : m_str
                            ,this.i += StrLen(m_str)-1
                            ,next := "e" )
                        : this.to_json_err("value", this.is_val[char])
                    : char == "{"
                        ? (obj[path*] := {}, next := "k")
                    : char == "["
                        ? (obj[path*] := {}, next := "a")
                    : this.to_json_err("value")
                : next == "e"
                    ? char == ","
                        ? type[p_i]
                            ? (path[p_i]++, next := "v")
                        : (path.Pop(), type.Pop(), --p_i, next := "k")
                    : (char == "}" && !type[p_i])
                    || (char == "]" && type[p_i])
                        ? (path.Pop(), type.Pop(), --p_i)
                    : this.to_json_err("end", type[p_i])
                : next == "k"
                    ? char == "}"
                        ? next := "e"
                    : RegExMatch(json, this.rgx.k, m_, this.i)
                        ? (path[++p_i] := m_str, type[p_i] := 0
                            ,this.i += StrLen(m_) - 1, next := "v" )
                    : this.to_json_err("key")
                : next == "a"
                    ? char == "]"
                        ? next := "e"
                        : (path[++p_i] := 1, type[p_i] := 1, next := "v", --this.i)
                : next == "s"
                    ? char == "{" ? next := "k"
                    : char == "[" ? next := "a"
                    : this.to_json_err("start")
                : this.basic_error("Invalid next variable during parse value."
                    . "`nThe end user should never see this message.")
        
        this.json := ""                         ; Post parse clean-up
        
        (p_i != 0)                              ; p_i being 0 means all paths were successfully closed
            ? this.to_json_err("Too many/few braces.", p_i)
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
    
    error_display(txt, i, offset:=20) {
        max := StrLen(this.json)
        min := (this.i-offset < 1   ? 1     : this.i-offset )
        max := (this.i+offset > max ? max   : this.i+max )
        Return SubStr(this.json, min, this.i-min-1)
                    . ">-->" SubStr(this.json, this.i, 1) "<--<"
                    . SubStr(this.json, this.i+1, max)
    }
    
    ; Converts escaped characters to their actual values
    string_decode(txt) {
        Local
        If !InStr(txt, "\")
            Return txt
        
        txt	 := StrReplace(txt, "\\", "\")      ; Reverse Slash / Solidus
        ,txt := StrReplace(txt, "\b", "`b")     ; Backspace
        ,txt := StrReplace(txt, "\f", "`f")     ; Formfeed
        ,txt := StrReplace(txt, "\n", "`n")     ; Linefeed
        ,txt := StrReplace(txt, "\r", "`r")     ; Carriage Return
        ,txt := StrReplace(txt, "\t", "`t")     ; Tab
        ,txt := StrReplace(txt, "\/", "/")      ; Slash / Solidus
        ,txt := StrReplace(txt, "\""", """")	; Double Quotes	
        Return txt
    }
    
    ; Converts necessary characters to their escaped version
    string_encode(txt) {
        Local
        
        If (txt == "")
            Return txt
        
        txt  := StrReplace(SubStr(txt, 2, -1)   ; Quotes are stripped off
                ,"\"  ,"\\" )                   ; Replace Backslashes
        ,txt := StrReplace(txt ,"`b" ,"\b" )    ; Replace Backspace
        ,txt := StrReplace(txt ,"`f" ,"\f" )    ; Replace Formfeed
        ,txt := StrReplace(txt ,"`n" ,"\n" )    ; Replace Linefeed
        ,txt := StrReplace(txt ,"`r" ,"\r" )    ; Replace Carriage Return
        ,txt := StrReplace(txt ,"`t" ,"\t" )    ; Replace Tab (Horizontal)
        ,txt := StrReplace(txt ,"""" ,"\""")    ; Replace Quotation Marks
        ,txt := StrReplace(txt ,"\\u" ,"\u")    ; Fix Unicode Escapes
        Return """"                             ; Optional Slash / Solidus encoding
            . StrReplace(txt                    ; Add stripped quotes are replaced
                , this.esc_slash_search
                , this.esc_slash_replace)
            . """"
    }
    
    ; Default settings for json_ahk
    _default() {
        this.indent_unit        := "`t"
        this.esc_slash          := False
        this.ob_new_line        := True
        this.ob_val_inline      := False
        this.arr_val_same_line  := False
        this.obj_val_same_line  := False
        this.cb_new_line        := True
        this.cb_val_inline      := False
        this.no_brace_ws        := True
        this.add_quotes         := False
        this.no_braces          := False
        this.strip_quotes       := False
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
    
    validate_string(txt){
        index	:= 0
        state   := "BG"
        ps      := ""
        error   := false
        
        ; Create table
        table    := {}
        ; Add forbidden characters (first 32 chars of ASCII table)
        For key, value in table
            Loop, 128
                table[key][(A_Index-1)] := 0
        ; Create string map
        ; Each key is an ascii char code
        ; Each associated values maps to the next allowed "next state"
        ; 0 is a failure
        ; Characters not found return an empty string
        ;            "        \        /        0        1        2        3        4        5        6        7        8        9        A        B        C        D        E        F        a        b        c        d         e         f         n         r         t         u       ;
        table.BG := {34:"ST", 92:0   , 47:0   , 48:0   , 49:0   , 50:0   , 51:0   , 52:0   , 53:0   , 54:0   , 55:0   , 56:0   , 57:0   , 65:0   , 66:0   , 67:0   , 68:0   , 69:0   , 70:0   , 97:0   , 98:0   , 99:0   , 100:0   , 101:0   , 102:0   , 110:0   , 114:0   , 116:0   , 117:0   }
        table.ST := {34:1   , 92:"ES", 47:"ST", 48:"ST", 49:"ST", 50:"ST", 51:"ST", 52:"ST", 53:"ST", 54:"ST", 55:"ST", 56:"ST", 57:"ST", 65:"ST", 66:"ST", 67:"ST", 68:"ST", 69:"ST", 70:"ST", 97:"ST", 98:"ST", 99:"ST", 100:"ST", 101:"ST", 102:"ST", 110:"ST", 114:"ST", 116:"ST", 117:"ST"}
        table.ES := {34:"ST", 92:"ST", 47:"ST", 48:0   , 49:0   , 50:0   , 51:0   , 52:0   , 53:0   , 54:0   , 55:0   , 56:0   , 57:0   , 65:0   , 66:0   , 67:0   , 68:0   , 69:0   , 70:0   , 97:0   , 98:"ST", 99:0   , 100:0   , 101:0   , 102:"ST", 110:"ST", 114:"ST", 116:"ST", 117:"U1"}
        table.U1 := {34:0   , 92:0   , 47:0   , 48:"U2", 49:"U2", 50:"U2", 51:"U2", 52:"U2", 53:"U2", 54:"U2", 55:"U2", 56:"U2", 57:"U2", 65:"U2", 66:"U2", 67:"U2", 68:"U2", 69:"U2", 70:"U2", 97:"U2", 98:"U2", 99:"U2", 100:"U2", 101:"U2", 102:"U2", 110:0   , 114:0   , 116:0   , 117:0   }
        table.U2 := {34:0   , 92:0   , 47:0   , 48:"U3", 49:"U3", 50:"U3", 51:"U3", 52:"U3", 53:"U3", 54:"U3", 55:"U3", 56:"U3", 57:"U3", 65:"U3", 66:"U3", 67:"U3", 68:"U3", 69:"U3", 70:"U3", 97:"U3", 98:"U3", 99:"U3", 100:"U3", 101:"U3", 102:"U3", 110:0   , 114:0   , 116:0   , 117:0   }
        table.U3 := {34:0   , 92:0   , 47:0   , 48:"U4", 49:"U4", 50:"U4", 51:"U4", 52:"U4", 53:"U4", 54:"U4", 55:"U4", 56:"U4", 57:"U4", 65:"U4", 66:"U4", 67:"U4", 68:"U4", 69:"U4", 70:"U4", 97:"U4", 98:"U4", 99:"U4", 100:"U4", 101:"U4", 102:"U4", 110:0   , 114:0   , 116:0   , 117:0   }
        table.U4 := {34:0   , 92:0   , 47:0   , 48:"ST", 49:"ST", 50:"ST", 51:"ST", 52:"ST", 53:"ST", 54:"ST", 55:"ST", 56:"ST", 57:"ST", 65:"ST", 66:"ST", 67:"ST", 68:"ST", 69:"ST", 70:"ST", 97:"ST", 98:"ST", 99:"ST", 100:"ST", 101:"ST", 102:"ST", 110:0   , 114:0   , 116:0   , 117:0   }
        
        ; Parse through provided text
        Loop, Parse, % txt
        {
            state := table[(ps := state)][Asc(A_LoopField)]     ; Save previous state and use table to update current state
            ,(state = 0) ? (error := true, index := A_Index)    ; If 0 (forbidden char), error and record index
            : (state = "")                                      ; If no match was found
                ? (ps == "ST") ? state := "ST"                  ; If previously ST, set back to ST
                : (error := true, index := A_Index)             ; Otherwise, invalid char so error out
        } Until (error) || (state = 1)                          ; End loop if error or if string success
        
        ; Define errors
        If (state != 1)
            If (ps == "BG")
                this.err_msg    := "String Error. Strings must start with a quotation mark."
                ,this.err_fnd   := SubStr(txt, index, 1)
                ,this.err_exp   := """"
            Else If (ps == "ST")
                this.err_msg    := "String Error. The first 32 ASCII characters are forbidden in strings and must be escaped"
                ,this.err_fnd   := "Char code: " Asc(SubStr(txt, index, 1))
                ,this.err_exp   := "Characters above the first 32."
            Else If (ps == "ES")
                this.err_msg    := "String Error. An invalid escape character was found."
                ,this.err_fnd   := "\" SubStr(txt, index, 1)
                ,this.err_exp   := "\b \f \n \r \t \"" \\ \/ \u"
            Else If InStr(ps, "U")
                this.err_msg    := "String Error. Invalid hex character in unicode."
                ,this.err_fnd   := SubStr(txt, index, 1)
                ,this.err_exp   := "0 1 2 3 4 5 6 7 8 9 A B C D E F a b c d e f"
        Else
            MsgBox, % "String passes."
            ;MsgBox, % "All checked.`nstate: " state "`nps: " ps "`nerror: " error "`nindex: " index "`ncount: " count "`ntext len: " StrLen(txt)
        
        Return
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
        table.T1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T2",""  ,""  ,""  ,""  ,"" ] ; true > r
        table.T2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"T3",""  ,"" ] ; true > u
        table.T3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; true > e
        table.F1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F2",""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > a
        table.F2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F3",""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > l
        table.F3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"F4",""  ,""  ,""  ,"" ] ; false > s
        table.F4 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; false > e
        table.N1 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N2",""  ,"" ] ; null > u
        table.N2 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,"N3",""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; null > l
        table.N3 := [""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,""  ,-6  ,""  ,""  ,""  ,""  ,""  ,""  ,"" ] ; null > l
        
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
