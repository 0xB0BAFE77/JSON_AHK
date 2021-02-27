#SingleInstance Force
#Warn
#NoEnv
#MaxMem 1024
#KeyHistory 0
SetBatchLines, -1
ListLines, Off

test()

ExitApp

Esc::ExitApp

test() {
    ; to_ahk() time
    ; json_test_file_multi
    ; iterations = 10
    ; 
    ; Base: 		2.978 sec
    ; 
    ; 
    ; to_json: Using obj/arr parse funcs vs one func with an extra object/array check
    ; Obj/Arr funcs.		file 25MB		i=5		time=10.1 sec
    ; One func ex check		file 25MB		i=5		time=6.7 sec
    ;
    ; to_json: Increase of adding in escape converter
    ; Base:			 		file 25MB		i=5		time=6.72 sec
    ; With conversion:		file 25MB		i=5		time=7.6 sec
    ;
    ; to_json: Checking if \ is in string before running strreplace
    ; Before:		 		file 25MB		i=5		time=7.6 sec
    ; After:				file 25MB		i=5		time=6.5 sec
    ;
    ; to_json: Testing if doing the instr check outside the function call is faster
    ; Inside func:	 		file 25MB		i=5		time=6.5 sec
    ; Outside func:			file 25MB		i=5		time=6.39
    ;
    ; to_ahk: 
    ; Base:	 				file 25MB		i=5		time=2.9 sec
    ; Outside func:			file 25MB		i=5		time=6.39
    ;
    ; 
    
    obj  := {}
    jtxt := json_ahk.import()
    i    := 1
    
    obj := json_ahk.to_ahk(jtxt)
    txt := json_ahk.to_json(obj)
    Clipboard := txt
    MsgBox, % "On clipboard!`n`n" txt
    ExitApp
    
    qpx(1)
    Loop, % i
        obj := json_ahk.to_ahk(jtxt) ;json_ahk.json_table(jtxt)
    t1 := qpx(0)
    
    qpx(1)
    Loop, % i
        json := json_ahk.to_json(obj) ;json_ahk.json_table(jtxt)
    t2 := qpx(0)
    
    Clipboard := json
    MsgBox, % "[qpx]to_ahk convert time: " t1/i " sec"
            . "`n[qpx]to_json convert time: " t2/i " sec"
    
    Return
}

QPX(N=0) { ; Wrapper for QueryPerformanceCounter()by SKAN | CD: 06/Dec/2009
    Local
    SetBatchLines, -1
    Static	F:="", A:="", Q:="", P:="", X:="" ; www.autohotkey.com/forum/viewtopic.php?t=52083 | LM: 10/Dec/2009
    If	( N && !P )
        Return	DllCall("QueryPerformanceFrequency",Int64P,F) + (X:=A:=0) + DllCall("QueryPerformanceCounter",Int64P,P)
    DllCall("QueryPerformanceCounter",Int64P,Q), A:=A+Q-P, P:=Q, X:=X+1
    Return	( N && X=N ) ? (X:=X-1)<<64 : ( N=0 && (R:=A/X/F) ) ? ( R + (A:=P:=X:=0) ) : 1
}


Class JSON_AHK
{
    ; Things to add/change:
    ; Option to preview the current export settings
    ;   Something like json_ahk.preview()
    ;   Add the JSON test file to the script to use as the preview model
    ; Option to put all array values on one line
    ; 
    
    ;=========================================================================================================
    ; Title:		JSON_AHK
    ; Desc:			Library that converts JSON to AHK objects and AHK to JSON
    ; Author:		0xB0BAFE77
    ; Created:		20200301
    ; Methods:
    ;	.to_JSON(ahk_object)	; Converts an AHK object and returns JSON text
    ;	.to_AHK(json_txt)		; Converts JSON text and returns an AHK object
    ;	.stringify(json_txt)	; Organizes code into one single line
    ;	.validate(json_txt)		; Validates a json file and retruns true or false
    ;	.import()				; Returns JSON text from a file
    ;   .preview()              ; [NOT IMPLEMENTED YET] Preview the current JSON export settings
    ;
    ; Properties:
    ;	.indent_unit			; Set to the desired indent character(s). Default=1 tab
    ;   .array_one_line         ; [NOT IMPLEMENTED YET] Puts all array values on one line
    ;	.no_brace_ws			; Remove whitespace from empty braces. Default = True
    ;	.no_brace_ws_all		; Remove whitespace from objects containing empty objects. Default = False
    ;	.no_indent				; Enable indenting of exported JSON files. Default=False
    ;	.no_braces				; Messes up your teeth. Kidding. It removes all braces. Default=False
    ;	.ob_new_line			; Open brace is put on a new line.
    ;							; True:		"key":
    ;							; 			[
    ;							; 				"value",
    ;							; False:	"key": [
    ;							; [Def]			"value",
    ;							;
    ;	.ob_val_inline			; Open brace indented to match value indent.
    ;							; This setting is ignored when ob_new_line is set to false.
    ;							; True:		"key":
    ;							; 				[
    ;							; 				"value",
    ;							; False:	"key":
    ;							; 			[
    ;							; 				"value",
    ;							;
    ;	.brace_val_same			; Brace and first value share same line.
    ;							; True:		["value1",
    ;							; 			"value2",
    ;							; False:	[
    ;							; 			"value1",
    ;							; 			"value2",
    ;							;
    ;	.cb_new_line			; ; Close brace is put on a new line. Default=
    ;							; True:		"value1",
    ;							; 			"value2"
    ;							; 			}
    ;							; False:	"value1",
    ;							; 			"value2"}
    ;							;
    ;	.cb_val_inline			; ; Close brace indented to match value indent. Default=
    ;							; True:			"value1",
    ;							; 				"value2"
    ;							; 				}
    ;							; False:		"value1",
    ;							; 				"value2"
    ;							; 			}
    ;=========================================================================================================
    ; some of these are not implemented yet
    ; JSON export settings              ;Default|
    Static indent_unit      := "`t"     ; `t    | Set to desired indent (EX: "  " for 2 spaces)
    Static esc_slash        := False    ; False | Escapes forward slashes when exporting JSON
    Static ob_new_line      := True     ; True  | Open brace is put on a new line
    Static ob_val_inline    := False    ; False | Open braces on a new line are indented to match value
    Static arr_val_same     := False    ; False | First value of an array appears on the same line as the brace
    Static obj_val_same     := False    ; False | First value of an object appears on the same line as the brace
    Static cb_new_line      := True     ; True  | Close brace is put on a new line
    Static cb_val_inline    := False    ; False | Open braces on a new line are indented to match value
    Static no_brace_ws      := True     ; True  | Remove whitespace from empty braces
    Static add_quotes       := False    ; False | Adds quotation marks to all strings if they lack one
    Static no_braces        := False    ; False | Messes up your teeth. JK. It removes all braces
    ;                                           | This invalidates the JSON and is only meant for human readability
    ; User settings for converting JSON
    Static strip_quotes     := False    ; False | Removes surrounding quotation marks from
    
    ;=========================================================================================================
    
    Static 	rgx        := {}
            ,rgx.e_arr := "^\s*\[[ \t\r\n]+\]\s*$"
            ,rgx.e_obj := "^\s*\{[ \t\r\n]+\}\s*$"
    
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
        Return IsObject(obj)
            ? LTrim(this.to_json_extract(obj, this.is_array(obj)), "`n")
        : this.basic_error("You did not supply a valid object or array")
    }
    
    ; Recursively extracts values from an object
    ; type = Incoming object type: 0 for object, 1 for array
    ; Indent is set by the json_ahk.indent_unit property
    ; It should be left blank as recursion sets indent depth
    to_json_extract(obj, type, ind:="") {
        Local
        ind_big := ind . this.indent_unit                                   ; Set big indent
        ,str    := (this.ob_new_line                                        ; Build beginning of arr/obj
                    ? "`n" (this.ob_val_inline
                        ? ind_big
                        : ind)
                    : "")                                                   ; Create brace prefix
                . (this.no_braces ? "" : type ? "[" : "{")                  ; Add brace
        
        For key, value in obj
            str .= (this.is_array(value)                                    ; Check if value is array
                    ? (type ? ""                                            ; If this obj is array, do nothing
                        : "`n" ind_big key ": ")                            ; Else, construct value prefix
                        . this.to_json_extract(value, 1, ind_big)           ; And get value
                : IsObject(value)                                           ; If value not array, check if object
                    ? (type ? "" : key ": ")                                ; Construct prefix
                        . this.to_json_extract(value, 0, ind_big)           ; And get value
                : "`n" ind_big (type ? "" : key ": ")                       ; If not array or object, is value
                    . (InStr(value, """")                                   ; Check if string
                        ? ("""" StrReplace(StrReplace(StrReplace(""         ; If in string, escape: backslashes, tabs,
                        . StrReplace(StrReplace(StrReplace(StrReplace(""    ; backspaces, formfeeds, linefeeds
                        . StrReplace(SubStr(value, 2, -1),"\","\\")         ; carriage returns, and double quotes
                        ,"`b","\b"),"`f","\f"),"`n","\n"),"`r","\r")        ; \\u is also fixed
                        ,"`t","\t"),"""","\"""),"\\u","\u") """")			; Yes, it's ugly af but it's also faster
                        : value ) )                                         ; If not a string, add value
                    . ","                                                   ; Always end with a comma
        
        str := RTrim(str, ",")                          ; Strip off last extra comma
            . (this.cb_new_line
                ? "`n" (this.cb_val_inline              ; Check user settings
                    ? ind_big
                    : ind)
                : "")                                   ; Create closing prefix
            . (this.no_braces ? "" : type ? "]" : "}")  ; Select brace
        
        ; Empty object formatter
        , (this.no_brace_ws                              ; Check user setting
            && str ~= this.rgx[(type?"e_arr":"e_obj")])  ; RegEx for empty object/array
            ? str := (this.ob_new_line ? "`n" ind : "")  ; If true, create prefix
                ;; In AHK v1, there's no way to distinguish between an empty array and empty object
                ;; When constructing JSON output, empty arrays will always show as empty objects
                . (this.no_braces ? "" : "{}" )          ; Add empty brace.
            : ""
        
        Return str
    }
    
    ; Converts a json text file into a single string
    stringify(json) {
        Local
        
        ; Convert text
        str			:= ""
        ,in_string	:= True
        ,i			:= 0
        ,m_			:= ""
        ,max		:= StrLen(json)
        ,dq			:= Chr(34)
        ,VarSetCapacity(str, 100000000)
        
        ;~ While (i < max)
            ;~ (in_string := !in_string)
                ;~ ? RegExMatch(json, "P)((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*"")))", m_, i)
                    ;~ ? (str .= SubStr(json, i, m_Lenstr)
                    ;~ , i += m_Lenstr)
                ;~ : this.basic_error("Stringify Error: A complete string was expected.`nFound: " SubStr(json, i, 25))
            ;~ : RegExMatch(json, "P).*?""", m_, i)
                ;~ ? (str .= StrReplace(StrReplace(StrReplace(StrReplace(""
                    ;~ . SubStr(json, i, m_Lenstr)," "),"`n"),"`t")"`r")
                ;~ , i += m_Lenstr)
            ;~ : (str .= SubStr(json, i, max-i)
                ;~ , i := max)
        
        MsgBox, % "str: " str
        
        Return RTrim(str, """")
    }
    
    ; Convert json text to an ahk object
    to_ahk(json){
        Local
        
        obj		:= {}			; Main object to build and return
        ;,obj.SetCapacity(1024)	; Does setting a large object size speed up performance?
        ,path	:= []			; Path value should be stored in the object
        ,path_t	:= []			; Tracks if current path is an array (true) or object (false)
        ,i		:= 0			; Tracks current position in the json string
        ,char	:= ""			; Current character
        ,next	:= "s"			; Next expected action: (s)tart, (n)ext, (k)ey, (v)alue
        ,max 	:= StrLen(json)	; Total number of characters in JSON
        ,m_		:= ""			; Stores regex matches
        ,m_str	:= ""			; Stores substring and regex matches
        ,rgx_key:= ""			; Tracks what regex pattern to use
        ; RegEx bank
        ;; should patterns include \s* at the end to capture white space?
        ;; Would that be faster than letting the while loop continue?
        ,rgx	:=	{"k"	: "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*:)"
                    ,"n"	: "((?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?)))"
                    ,"s"	: "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*"")))"
                    ,"b"	: "((?P<str>true|false|null))"	}
        ; Whitespace checker
        ,is_ws	:=	{" "	:True		; Space
                    ,"`t"	:True		; Tab
                    ,"`n"	:True		; New Line
                    ,"`r"	:True	}	; Carriage Return
        ; Object/array enders
        ,is_end	:=	{"]"	:True
                    ,"}"	:True	}
        ; Object/array openers
        ,is_new := {"{"	:"k"
                    ,"["	:"v"	}
        ; Error messages and expectations
        ,err	:=	{snb	:{msg	: "Invalid string|number|true|false|null.`nNeed to write a function that auto-detects this for me."
                            ,exp	: "string number true false null"}
                    ,cls	:{msg	: "Invalid closing brace.`nObjects must end with a } and arrays must end with a ]."
                            ,exp	: "} ]"}
                    ,arr	:{msg	: "The first item in an array must be a value or a closing square bracket."
                            ,exp	: "] - 0 1 2 3 4 5 6 7 8 9 "" t f n"}
                    ,val	:{msg	: "Invalid value.`nNeed to write a function that auto-detects this for me."
                            ,exp	: "string number true false null object array"}
                    ,nxt	:{msg	: "Commas are required between values."
                            ,exp	: ","}
                    ,key	:{msg	: "An object must start with a key or closing curly brace."
                            ,exp	: "Keys must follow string rules."}
                    ,jsn	:{msg	: "Invalid JSON file.`nJSON data starts with a brace."
                            ,exp	: "[ {"}	}
        ; Value validator and regex key assigner
        ,is_val :=	{"0"	:"n"	,"5":"n"	,0	:"n"	,5	:"n"	,"-" :"n"
                    ,"1"	:"n"	,"6":"n"	,1	:"n"	,6	:"n"	,"t" :"b"
                    ,"2"	:"n"	,"7":"n"	,2	:"n"	,7	:"n"	,"f" :"b"
                    ,"3"	:"n"	,"8":"n"	,3	:"n"	,8	:"n"	,"n" :"b"
                    ,"4"	:"n"	,"9":"n"	,4	:"n"	,9	:"n"	,"""":"s"	}
        
        ;~ ,json:= StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(json
                ;~ ,"\b"	,"`b")	; Backspace
                ;~ ,"\f"	,"`f")  ; Formfeed
                ;~ ,"\n"	,"`n")  ; Linefeed
                ;~ ,"\r"	,"`r")  ; Carriage Return
                ;~ ,"\t"	,"`t")  ; Tab
                ;~ ,"\/"	,"/")   ; Slash / Solidus
        
        ; For tracking object path, would using a string with substring be faster than array and push/pop?
        ; Can bit shifting be used as a replacement for path_t (tracks if current path is an array or object so a bunch of true/false)?
        
        While (i < max) {
            If is_ws[(char := SubStr(json, ++i, 1))]						; Get first char
                Continue													; Skip if whitespace
            
            ;this.msg("char: " char "`ni: " i "`nnext: " next "`nIn arr: " path_t[path_t.MaxIndex()] "`npath: " this.view_obj(path))
            
            If (next == "v")												; Get value
                (rgx_key := is_val[char])									; Check if first char is a valid non-object value start
                    ? (RegExMatch(json, rgx[rgx_key], m_, i))				; Get and validate the value type using the right regex
                        ? (obj[path*] := (rgx_key=="s" && InStr(m_str,"\")	; Add value to object
                            ? """" StrReplace(StrReplace(StrReplace(""
                            . StrReplace(StrReplace(StrReplace(""
                            . StrReplace(StrReplace(SubStr(m_str, 2, -1)	; Substring removes the initila quotes
                                ,"\b" ,"`b") ,"\f" ,"`f") ,"\n" ,"`n")		; Backspace, formfeed, linefeed
                                ,"\r" ,"`r") ,"\t" ,"`t") ,"\/" ,"/")		; Carriage return, tab, slash
                                ,"\""","""") ,"\\","\")  """"	; Double quote, backslash, fix unicode
                            : m_str )										; If
                            , i += StrLen(m_str) - 1							; Increment index and check for value ender
                            , next := "e"	)								; Next find ender
                    : this.error(json, i, err.snb.msg, err.snb.exp, m_)		; Otherwise, throw error for invalid number/string/bool/null
                : (char == "{")												; If new object
                    ? (obj[path*] := {}
                        , next := "k" )
                : (char == "[")												; If new array
                    ? (obj[path*] := []
                        , path.Push(1), path_t.Push(True)
                        , next := "a")
                : this.error(json, i, err.val.msg, err.val.exp, char)		; Otherwise, error b/c not a valid value
            Else If (next == "e")											; Check for a value ending (comma or closing brace)
                (char == ",")												; If comma, another value is expected
                    ? (path_t[path_t.MaxIndex()])							; If current path is an array
                        ? (path[path.MaxIndex()]++							; Increment index and get another value
                            , next := "v")
                        : (path.Pop() , path_t.Pop()						; If current path is an object
                            , next := "k")									; Remove key and get a new one
                : ((char == "}") && !(path_t[path_t.MaxIndex()])
                || (char == "]") && path_t[path_t.MaxIndex()])
                    ? (path.Pop()
                        , path_t.Pop()
                        , next := "e" )
                : this.error(json, i, err.end.msg
                    , (char == "}" ? "]" : "}")
                    , char)
            Else If (next == "a")
                (char == "]")
                    ? (path.Pop() ,path_t.Pop(), next := "e")
                : (rgx_key := is_val[char])
                    ? (RegExMatch(json, rgx[rgx_key], m_, i))				; Get and validate the value type using the right regex
                        ? (obj[path*] := (rgx_key=="s" && InStr(m_str,"\")	; Add value to object
                            ? """" StrReplace(StrReplace(StrReplace(""
                            . StrReplace(StrReplace(StrReplace(""
                            . StrReplace(StrReplace(SubStr(m_str, 2, -1)	; Substring removes the initila quotes
                                ,"\b" ,"`b") ,"\f" ,"`f") ,"\n" ,"`n")		; Backspace, formfeed, linefeed
                                ,"\r" ,"`r") ,"\t" ,"`t") ,"\/" ,"/")		; Carriage return, tab, slash
                                ,"\""","""") ,"\\","\")  """"	; Double quote, backslash, fix unicode
                            : m_str )										; If
                            , i += StrLen(m_str) - 1							; Increment index and check for value ender
                            , next := "e"	)								; Next find ender
                    : this.error(json, i, err.snb.msg, err.snb.exp, m_)		; Otherwise, throw error for invalid number/string/bool/null
                : (char == "{")												; If new object
                    ? next := "k"
                : (char == "[")												; If new array
                    ? (obj[path*] := []
                        , path.Push(1)
                        , path_t.Push(True)
                        , next := "a" )
                : this.error(json, i, err.val.msg, err.val.exp, char)		; Otherwise, error b/c not a valid value
            Else If (next == "k")											; Get an object key
                (char == "}")
                    ? next := "e"
                : RegExMatch(json, rgx.k, m_, i)								; Get and validate a key
                    ? (path.Push(m_str)
                        , path_t.Push(False)
                        ;, this.msg("key:" m_str)
                        , i += StrLen(m_) - 1
                        , next := "v"	)
                : this.error(json, i, err.key.msg, err.key.exp, char)		; Throw error for invalid key
            Else If (next == "s")											; Start checks for initial object or array
                (char == "{")
                    ? (obj := {}
                        , next := "k")
                : (char == "[")
                    ? (obj := []
                        , path.Push(1)
                        , path_t.Push(True)
                        , next := "a")
                : this.error(json, i, err.jsn.msg, err.jsn.exp, char)		; Throw error for invalid start of JSON file
            Else this.error(json, i											; Throw error for invalid next [Troubleshooter]
                , "YA MESSED UP!!!`nInvalid next variable."
                , "`n`tb - Beginning" . "`n`te - Ending" . "`n`tk - Key" . "`n`tv - Value"
                , next)
        }
        Return obj
    }
    to_json_err(code) {
        /*
        ; Error messages and expectations
        err	:=	{snb	:{msg	: "Invalid string|number|true|false|null.`nNeed to write a function that auto-detects this for me."
                        ,exp	: "string number true false null"}
                ,cls	:{msg	: "Invalid closing brace.`nObjects must end with a } and arrays must end with a ]."
                        ,exp	: "} ]"}
                ,arr	:{msg	: "The first item in an array must be a value or a closing square bracket."
                        ,exp	: "] - 0 1 2 3 4 5 6 7 8 9 "" t f n"}
                ,val	:{msg	: "Invalid value.`nNeed to write a function that auto-detects this for me."
                        ,exp	: "string number true false null object array"}
                ,nxt	:{msg	: "Commas are required between values."
                        ,exp	: ","}
                ,key	:{msg	: "An object must start with a key or closing curly brace."
                        ,exp	: "Keys must follow string rules."}
                ,jsn	:{msg	: "Invalid JSON file.`nJSON data starts with a brace."
                        ,exp	: "[ {"}	}
        */
        
        Return
    }
    
    string_decode(txt){
        Local
        
        ;str		:= char := code := ""
        ;,txt	:= StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(txt
        ;			,"\b"	,"`b")	; Backspace
        ;			,"\f"	,"`f")	; Formfeed
        ;			,"\n"	,"`n")	; Linefeed
        ;			,"\r"	,"`r")	; Carriage Return
        ;			,"\t"	,"`t")	; Tab
        ;			,"\/"	,"/")	; Slash / Solidus
        ;			,"\"""	,"""")	; Double Quotes
        ;			,"\\"	,"\")	; Last, set \* as placeholder for \
        
        ;~ Loop, Parse, % txt, % "\"
            ;~ str .= (A_Index == 1)									; Always add first line
                ;~ ? A_LoopField
            ;~ : ((char := SubStr(A_LoopField,1,1)) == "*")			; Replace * place holder with \
                ;~ ? "\" . SubStr(A_LoopField,2)
            ;~ : (char == "u")											; Replace unicode
                ;~ ? ((code := "0x" SubStr(A_LoopField,2,4)) >= 0x0000	; Validate hex range
                    ;~ && code <= 0xFFFF)
                    ;~ ? Chr(code) . SubStr(A_LoopField,6)				; Add to str
                ;~ : this.error(txt, A_Index
                    ;~ , "Unicode hex is invalid."
                    ;~ , "#### 4 hex numbers. 0-9, A-F, a-f"
                        ;~ . "`n 0x0000 <= #### >= 0xFFFF"
                    ;~ , code, "", "\")
            ;~ : this.error(txt, A_Index
                ;~ , "Invalid escape character."
                ;~ , "\b \r \n \t \f \\ \/ \"" \u####"
                ;~ , char, "", "\")
        
        ;Return str
        
        Return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(txt
                    ,"\b"	,"`b")	; Backspace
                    ,"\f"	,"`f")	; Formfeed
                    ,"\n"	,"`n")	; Linefeed
                    ,"\r"	,"`r")	; Carriage Return
                    ,"\t"	,"`t")	; Tab
                    ,"\/"	,"/")	; Slash / Solidus
                    ,"\"""	,"""")	; Double Quotes
                    ,"\\"	,"\")	; Last, set \* as placeholder for \
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
    
    ;=============================\
    ;           Hannah.           |
    ;         You still a         |
    ;         bee~itch! ;)        |
    ;=============================/
    
    ; Check if object is an array
    is_array(obj) {
        If !IsObject(obj)
            Return False
        For k, v in obj
            If (k != A_Index)
                Return False
        Return True
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
        
        ; Highlighted problem
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
    view_obj(obj, i:=0) {
        str := indent := ""
        i_unit := "`t"
        
        Loop, % i
            indent .= i_unit
        
        For key, value in obj
            str .= IsObject(value)
                ? indent key ": " this.view_obj(value, i+1) ",`n"
                : indent key ": " value ",`n"
        
        str := RTrim(str, ",`n")
        
        If (i==0)
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

}
