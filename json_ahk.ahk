#SingleInstance Force
#Warn
#NoEnv
#MaxMem 1024
#KeyHistory 0
SetBatchLines, -1
ListLines, Off



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
    
	; Creating a change log as of 20210307 to track changes
	; - Fixed issues with .to_ahk() and .to_json()
	;   Library works on a basic level now and can be used. :)
	; - Added: .preview() method
	; - Updated general comment info
	; - Added: esc_slash property
	; - Fixed: Empty brace checking
	
	
    ;==================================================================================================================
    ; Title:        JSON_AHK
    ; Desc:         Library that converts JSON to AHK objects and AHK to JSON
    ; Author:       0xB0BAFE77
    ; Created:      20200301
    ; Last Update:  20210307
    ; Methods:
    ;   .to_JSON(ahk_object)    ; Converts an AHK object and returns JSON text
    ;   .to_AHK(json_txt)       ; Converts JSON text and returns an AHK object
    ;   .stringify(json_txt)    ; Organizes code into one single line
    ;   .validate(json_txt)     ; Validates a json file and retruns true or false
    ;   .import()               ; Returns JSON text from a file
    ;   .preview()              ; Preview the current JSON export settings
    ;
    ; Properties:
    ;   .indent_unit            ; Set to the desired indent character(s). Default=1 tab
    ;   .array_one_line         ; [NOT IMPLEMENTED YET] Puts all array values on one line
    ;   .no_brace_ws            ; Remove whitespace from empty braces. Default = True
    ;   .no_brace_ws_all        ; Remove whitespace from objects containing empty objects. Default = False
    ;   .no_indent              ; Enable indenting of exported JSON files. Default=False
    ;   .no_braces              ; Messes up your teeth. Kidding. It removes all braces. Default=False
    ;                           ; This setting is strictly for human consumption and removes all JSON formatting
    ;===========================;======================================================================================
    ;   .ob_new_line            ; Open brace is put on a new line.
    ;                           ; True:     "key":
    ;                           ; [DEF]     [
    ;                           ;               "value",
    ;                           ; False:    "key": [
    ;                           ;               "value",
    ;===========================;======================================================================================
    ;    .ob_val_inline         ; Open brace indented to match value indent.
    ;                           ; This setting is ignored when ob_new_line is set to false.
    ;                           ; True:     "key":
    ;                           ;               [
    ;                           ;               "value1",
    ;                           ; False:    "key":
    ;                           ; [DEF]     [
    ;                           ;               "value1",
    ;===========================;======================================================================================
    ;    .ob_brace_val          ; Brace and first value share same line and usually used with .ob_val_inline
    ;                           ; True:     "key":
    ;                           ;               ["value1",
    ;                           ;               "value2",
    ;                           ; False:    "key":
    ;                           ; [DEF]         [
    ;                           ;               "value1",
    ;                           ;               "value2",
    ;===========================;======================================================================================
    ;    .cb_new_line           ; Close brace is put on a new line.
    ;                           ; True:         "value2",
    ;                           ; [DEF]         "value3"
    ;                           ;           }
    ;                           ; False:        "value2",
    ;                           ;               "value3"}
    ;===========================;======================================================================================
    ;    .cb_val_inline         ; Close brace indented to match value indent.
    ;                           ; True:         "value2",
    ;                           ;               "value3"
    ;                           ;               }
    ;                           ; False:        "value2",
    ;                           ; [DEF]         "value3"
    ;                           ;           }
    ;===========================;======================================================================================
    ;    .array_one_line        ; Array values are put on one line.
    ;                           ; True:     "key": ["value1", "value2"]
    ;                           ; False     "key":
    ;                           ; [DEF]     [
    ;                           ;               "value1",
    ;                           ;
    ;==================================================================================================================
    ; JSON export settings              ;Default|
    Static indent_unit      := "`t"     ; `t    | Set to desired indent (EX: "  " for 2 spaces)
    Static esc_slash        := False    ; False | Optionally escape forward slashes when exporting JSON
    Static ob_new_line      := True     ; True  | Open brace is put on a new line
    Static ob_val_inline    := False    ; False | Open braces on a new line are indented to match value
    Static cb_new_line      := True     ; True  | Close brace is put on a new line
    Static cb_val_inline    := False    ; False | Open braces on a new line are indented to match value
	
    Static arr_val_same     := False    ; False | First value of an array appears on the same line as the brace
    Static obj_val_same     := False    ; False | First value of an object appears on the same line as the brace
	
    Static no_empty_brace_ws:= True     ; True  | Remove whitespace from empty braces
    Static array_one_line	:= False	; False | List array elements on one line instead of multiple
	Static add_quotes       := False    ; False | Adds quotation marks to all strings if they lack one
    Static no_braces        := False    ; False | Removes object and array braces. This invalidates its JSON
    ;                                   ;       | format and should only be used for human consumption/readability
    ; User settings for converting JSON
    Static strip_quotes     := False    ; False | Removes surrounding quotation marks from
    
    ;==================================================================================================================
    
    ; Test file (very thorough)
    Static test_file := "[`n`t""JSON Test Pattern pass1"",`n`t{""object with 1 members"":[""array with 1 element""]},`n`t{},`n`t[],`n`t-42,`n`ttrue,`n`tfalse,`n`tnull,`n`t{`n`t`t""integer"": 1234567890,`n`t`t""real"": -9876.543210,`n`t`t""e"": 0.123456789e-12,`n`t`t""E"": 1.234567890E+34,`n`t`t"""":  23456789012E66,`n`t`t""zero"": 0,`n`t`t""one"": 1,`n`t`t""space"": "" "",`n`t`t""quote"": ""\"""",`n`t`t""backslash"": ""\\"",`n`t`t""controls"": ""\b\f\n\r\t"",`n`t`t""slash"": ""/ & \/"",`n`t`t""alpha"": ""abcdefghijklmnopqrstuvwyz"",`n`t`t""ALPHA"": ""ABCDEFGHIJKLMNOPQRSTUVWYZ"",`n`t`t""digit"": ""0123456789"",`n`t`t""0123456789"": ""digit"",`n`t`t""special"": ""````1~!@#$``%^&*()_+-={':[,]}|;.</>?"",`n`t`t""hex"": ""\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"",`n`t`t""true"": true,`n`t`t""false"": false,`n`t`t""null"": null,`n`t`t""array"":[  ],`n`t`t""object"":{  },`n`t`t""address"": ""50 St. James Street"",`n`t`t""url"": ""http://www.JSON.org/"",`n`t`t""comment"": ""// /* <!-- --"",`n`t`t""# -- --> */"": "" "",`n`t`t"" s p a c e d "" :[1,2 , 3`n`n,`n`n4 , 5`t`t,`t`t  6`t`t   ,7`t`t],""compact"":[1,2,3,4,5,6,7],`n`t`t""jsontext"": ""{\""object with 1 member\"":[\""array with 1 element\""]}"",`n`t`t""quotes"": ""&#34; \u0022 ``%22 0x22 034 &#x22;"",`n`t`t""\/\\\""\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t``1~!@#$``%^&*()_+-=[]{}|;:',./<>?""`n: ""A key can be any string""`n`t},`n`t0.5 ,98.6`n,`n99.44`n,`n`n1066,`n1e1,`n0.1e1,`n1e-1,`n1e00,2e+00,2e-00`n,""rosebud""]"
    
    ; Import JSON file
    import() {
        Local
        path := json := ""
        VarSetCapacity(json, 1024)
        
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
    
	preview() {
		MsgBox, % (Clipboard := this.to_json(this.to_ahk(this.test_file)))
		Return
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
		
		qpx(1)
		str := ""
		For k, v in this.to_ahk(json)
			str .= v
		t1 := qpx(0)
		
		MsgBox, % "time to stringify: " t1 " sec"
		ExitApp
		
        Return str
    }
    
    ; Convert json text to an ahk object
    to_ahk(json){
        Local
        
        obj      := {}              ; Main object to build and return
        ;,obj.SetCapacity(1024)     ; Does setting a large object size speed up performance?
        ,path    := []              ; Path value should be stored in the object
        ,type    := []              ; Tracks if current path is an array (true) or object (false)
        ,p_i     := 0               ; [NEW] tracks current index for the path arrays (replaces the need to call .MaxIndex() over and over)
        ,this.i  := 0               ; Tracks current position in the json string
        ,char    := ""              ; Current character
        ,next    := "s"             ; Next expected action: (s)tart, (n)ext, (k)ey, (v)alue
        ,max     := StrLen(json)    ; Total number of characters in JSON
        ,m_      := ""              ; Stores regex matches
        ,m_str   := ""              ; Stores regex match subpattern
        ,rgx_key := ""              ; Tracks what regex pattern to use for validation
        ; RegEx bank
        ;; should patterns include \s* at the end to capture white space?
        ;; Would that be faster than letting the while loop continue?
        ,rgx	:=  {"k"    : "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*:)"
                    ,"n"    : "((?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?)))"
                    ,"s"    : "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*"")))"
                    ,"b"    : "((?P<str>true|false|null))"    }
        
        ; Whitespace checker
        ,is_ws  :=  {" " :True      ; Space
                    ,"`t":True      ; Tab
                    ,"`n":True      ; New Line
                    ,"`r":True }    ; Carriage Return
        
        ; Error messages and expectations
        ,err    :=  {snb    :{msg   : "Invalid string|number|true|false|null.`nNeed to write a function that auto-detects this for me."
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
			;MsgBox, % "this.i: " this.i "`nnext: " next "`nmax: " max "`nchar: " char "`nthis.view_obj(obj): " this.view_obj(obj)
			is_ws[(char := SubStr(json,++this.i,1))]
				? ""
			: next == "v"
				? is_val[char]
					? RegExMatch(json,rgx[is_val[char]],m_,this.i)
						? (obj[path*] := (is_val[char]=="s" && InStr(m_str,"\")
							? """" this.string_decode(SubStr(m_str,2,-1)) """" : m_str )
							,this.i += StrLen(m_str)-1 , next := "e" )
					: this.to_json_err(is_val[char])
				: InStr("{[", char) ? (obj[path*] := {}, next := (char == "{" ? "k" : "a") )
				: this.to_json_err("value")
			: next == "e"
				? char == ","
					? type[p_i] ? (path[p_i]++, next := "v")
						: (path.Pop(), type.Pop(), --p_i, next := "k")
				: ((char == "}" && !type[p_i]) || (char == "]" && type[p_i]))
					? (path.Pop(), type.Pop(), --p_i, next := "e")
				: this.to_json_err("end")
			: next == "a"
				? char == "]" ? next := "e"
				: (path[++p_i] := 1, type[p_i] := 1, --this.i, next := "v")
			: next == "k"
				? char == "}" ? next := "e"
				: RegExMatch(json,rgx.k,m_,this.i)
					? (path[++p_i] := m_str, type[p_i] := 0, this.i += StrLen(m_)-1, next := "v" )
				: this.to_json_err("key")
			: next == "s"
				? char == "{" ? (next := "k")
				: char == "[" ? (next := "a")
				: this.to_json_err("start")
			: ""
        
        this.json := ""     ; Post conversion clean up
        
        Return obj
    }
    
    to_json_err(index, state) {
        ; error states:
        ; s - string
        ; n - number
        ; b - true/false/null
        ; e
        
        ; err states
        ; s - start
        ; a - array
        ; 
        state := (state == "s" ? True : False)
        validate := this.make_valid_table()
        Return
    }
    
    string_decode(txt){
        Return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(txt
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
        
        txt	:= """" StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(""
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
        ,start		:= ((index - offset) < 0)
                        ? 0
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
}
