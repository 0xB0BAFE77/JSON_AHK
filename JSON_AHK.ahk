#SingleInstance Force
#Warn
#NoEnv
#KeyHistory 0
SetBatchLines, -1
ListLines, Off

test()

ExitApp

Esc::ExitApp

test() {
	jtxt := ""
	;jtxt := "!B\/\\\\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t"
	;FileRead, jtxt, D:\Scripts\JSON_Test_File.json
	;FileRead, jtxt, C:\Users\TESTCENTER\Desktop\TCM\Tools\AHK\Scripts\JSON_Test_File.json
	if (jtxt = "")
		jtxt := json_ahk.import()
	
	time	:= 0 - A_TickCount
	obj		:= json_ahk.to_ahk(jtxt)
	MsgBox, % "Time to convert to object: " time+A_TickCount " ms"
	MsgBox, % json_ahk.view_obj(obj)

	i		:= 1
	total	:= 0 - A_TickCount
	Loop, % i
		str := JSON_AHK.to_json(obj)
	total += A_TickCount
	
	MsgBox, % "Time to convert to JSON: " total/i " ms"
	Clipboard := str
	MsgBox, % str
	Return
}

Class JSON_AHK
{
	;=========================================================================================================
	; Title:		JSON_AHK
	; Desc:			Library that converts JSON to AHK objects and AHK to JSON
	; Author:		0xB0BAFE77
	; Created:		20200301
	; Methods:
	;	.to_JSON(ahk_object)	; Converts an AHK object and returns JSON text
	;	.to_AHK(json_txt)		; Converts JSON text and returns an AHK object
	;	.stringify(json_txt)	; Organizes code into one single line
	;	.readable(json_txt)		; Organizes code into indented, readable lines
	;	.validate(json_txt)		; Validates a json file and retruns true or false
	;	.import()				; Returns JSON text from a file
	;
	; Properties:
	;	.indent_unit			; Set to the desired indent character(s). Default=1 tab
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
	;							; 			}	;							;
	;	.comma_first_line		; ; Close brace indented to match value indent. Default=
	;							; True:			"value1",
	;							; 				"value2"
	;							; False:		"value1"
	;							; 				,"value2"
	;=========================================================================================================
	
	; User Settings							;Default|
	Static	indent_unit			:= "`t"		; `t	| Set to the desired indent character(s)
			,comma_first_line	:= True		; True	| Put comma on same line as value
			,ob_new_line		:= True		; True	| Open brace is put on a new line
			,ob_val_inline		:= False	; False	| Open brace indented to match value indent
			,brace_val_same		:= False	; False	| Brace and first value share same line
			,cb_new_line		:= False	; True	| Close brace is put on a new line
			,cb_val_inline		:= False	; False	| Close brace indented to match value indent
			,no_brace_ws		:= True		; True	| Remove whitespace from empty braces
			,no_braces			:= False	; False	| Messes up your teeth. JK. It removes all braces
			,remove_quotes		:= False	; False	| Removes surrounding quotation marks from strings
	;Static no_brace_ws_all	:= True		; Remove whitespace from objects containing empty objects. Default = False
	
	;=========================================================================================================
	
	; JSON values
	Static 	dq		:= Chr(0x22)
			,is_ws	:= 	{" "	:True		; Space
						,"`t"	:True		; Tab
						,"`n"	:True		; Linefeed
						,"`r"	:True	}	; Carriage Return
			,is_esc	:= 	{""""	:""""		; Double Quote
						,"\"	:"\"		; Backslash / Reverse Solidus
						,"/"	:"/"		; Slash / Solidus
						,"b"	:"`b"		; Backspace
						,"f"	:"`f"		; Formfeed
						,"n"	:"`n"		; Linefeed
						,"r"	:"`r"		; Carriage Return
						,"t"	:"`t"	}	; Tab
	
	; Import JSON file
	import() {
		Local
		FileSelectFile, path, 3,, Select a JSON file, JSON (*.json)
		If (ErrorLevel = 1) {
			this.basic_error("No file was selected.")
			Return False
		}
		FileRead, json, % path
		If (ErrorLevel = 1) {
			this.basic_error("An error occurred when loading the file."
				. "`n" A_LastError)
			Return False
		}
		Return json
	}
	
	; Convert AHK object to JSON string
	to_json(obj) {
		Return this.is_array(obj)
			? Trim(this.extract_arr(obj), "`n,")
		: IsObject(obj)
			? Trim(this.extract_obj(obj), "`n,")
		: this.basic_error("You did not supply a valid object or array")
	}
	extract_obj(obj, indent:="") {
		Local
		str	:= (this.ob_new_line
				? "`n" (this.ob_val_inline
					? indent . this.indent_unit
					: indent)
				: "")
			. "{"
		
		For key, value in obj
			str .= "`n"
				. indent
				. this.indent_unit
				. key ": " 
				. (this.is_array(value)
					? this.extract_arr(value
						, indent . this.indent_unit)
				: IsObject(value)
					? this.extract_obj(value
						, indent . this.indent_unit)
				: (SubStr(value, 1, 1) == this.dq
					? this.esc_char_encode(value)
					: value	))
				. ","
		
		str := RTrim(str, ",")  						; Trim off last comma
			. "`n"
			. indent
			. "}"
		,(this.no_brace_ws								; Remove whitespace from empty object
			&& str ~= "^\s*\{[ |\t|\n|\r]*\},?\s*$")
			? str	:= "`n"
					. indent
					. "{}"
			: ""
		
		Return str
	}
	extract_arr(arr, indent:="") {
		Local
		str	:= (this.ob_new_line
				? "`n" (this.ob_val_inline
					? indent . this.indent_unit
					: indent)
				: "")
			. "["
		
		For index, value in arr
			str .= "`n"
				. indent
				. this.indent_unit
				. (this.is_array(value)
					? this.extract_arr(value
						, indent . this.indent_unit)
				: IsObject(value)
					? this.extract_obj(value
						, indent . this.indent_unit)
				: (SubStr(value, 1, 1) == this.dq
					? this.esc_char_encode(value)
					: value	))
				. ","
		
		str := RTrim(str, ",")  						; Trim off last comma
				. "`n"
				. indent
				. "]"
		
		, this.no_brace_ws								; Remove whitespace from empty array
			&& (str ~= "^\s*\[[ |\t|\n|\r]*\],?\s*$")
			? str	:= "`n"
					. indent
					. "[]"
			: ""
		
		Return str
	}
	
	collapse_multiple_objects(txt) {
		Local
		orig	:= txt
		,open_c	:= open_s := 0
		,valid	:= True
		,breaker:= False
		
		Loop, Parse, % " ,`t`n`r"
			txt := StrReplace(txt, A_LoopField, "")
		
		;; did i include commas between multiple objects?
		While (!breaker)
			char := SubStr(txt, A_Index, 1)
			, InStr("{}", char)
				? (char = "{")
					? open_c++
					: open_c--
			: InStr("[]", char)
				? (char = "[")
					? open_s++
					: open_s--
			: (breaker := True
				, valid := False)
			,(open_c < 0 || open_s < 0)
				? valid := False
				: (open_c = 0 && open_s = 0)
					? breaker := True
					: ""
		
		Return (valid ? txt : orig)
	}
	
	; Converts a json file into a single string
	stringify(json) {
		Local
		/* Account for objects or text
		If IsObj(json)
			; Convert obj
		Else
			; Convert txt
		*/
		
		; Convert text
		str			:= ""
		,VarSetCapacity(str, 10000)
		,char		:= ""
		,last		:= ""
		,max_chars	:= StrLen(json)
		,in_string	:= False
		,index		:= 0
		,start		:= 0
		,is_ws		:= {" ":True,"`t":True,"`n":True,"`r":True}
		
		Loop, % max_chars {
			char := SubStr(json, A_Index, 1)
			, (start > 0)
				? (!in_string && is_ws[char])
					? (str .= SubStr(json, start, A_Index-start)
						, start := 0)
					: ""
				: (!in_string && is_ws[char])
					? ""
					: start := A_Index
			, (char == """" && last != "\")
				? in_string := !in_string
				: ""
			, last := (char = "\" && last = "\")
				? ""
				: char
		}
		If (start)
			str .= SubStr(json, start, max_chars-start)
		
		Return str
	}
	
	; Makes JSON text readable for humans
	readable(json_txt) {
		
		Return
	}
	
	; Convert json text to an ahk object
	to_ahk(json){
		Local
		
		obj		:= {}			; Main object to build and return
		;,obj.SetCapacity(10000)	; Does setting a large object size speed up performance?
		,path	:= []			; Path value should be stored in the object
		,path_a	:= []			; Tracks if current path is an array (true) or object (false)
		,i		:= 0			; Tracks current position in the json string
		,char	:= ""			; Current character
		,next	:= "s"			; Next expected action: (s)tart, (n)ext, (k)ey, (v)alue
		,max 	:= StrLen(json)	; Total number of characters in JSON
		,m_		:= ""			; Stores regex matches
		,m_str	:= ""			; Stores substring and regex matches
		,rgx_key:= ""			; Tracks what regex pattern to use
		; RegEx bank
		;; should patterns include whitespace at the end?
		;; Would that be faster than letting the while loop continue?
		,rgx	:=	{"k"	: "([ |\t|\n|\r]*?(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*?:[ |\t|\n|\r]*)"
					,"n"	: "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))"
					,"s"	: "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*)"
					,"b"	: "((?P<str>true|false|null)[ |\t|\n|\r]*)"
					,"cc"	: "[ |\t|\n|\r]*?\}]"
					,"cs"	: "[ |\t|\n|\r]*?\]]"	}
		; Whitespace checker
		,is_ws	:=	{" "	:True		; Space
					,"`t"	:True		; Tab
					,"`n"	:True		; New Line
					,"`r"	:True	}	; Carriage Return
		; Object/array openers
		,is_new :=	{"{"	:"o"
					,"["	:"a"	}
		; Object/array enders
		,is_end	:=	{"]"	:True
					,"}"	:True	}
		; Error messages and expectations
		,err	:=	{snb	:{msg	: "Invalid string|number|true|false|null.`nNeed to write a function that auto-detects this for me."
							,exp	: "string number true false null"}
					,cls	:{msg	: "Invalid closing brace.`nObjects must end with a } and arrays must end with a ]."
							,exp	: "} ]"}
					,key	:{msg	: "Invalid object key name. Key's must adhere to JSON string rules."
							,exp	: """"}
					,val	:{msg	: "Invalid value.`nNeed to write a function that auto-detects this for me."
							,exp	: "string number true false null object array"}
					,cma	:{msg	: "Values must be followed by a comma or an appropriate closing brace."
							,exp	: ",]}"}
					,obj	:{msg	: "Invalid key or closing to object."
							,exp	: "See JSON.org for rules on object keys [strings]."}
					,dbg	:{msg	: "Invalid next var."
							,exp	: "You messed up. Fix it."}
					,cla	:{msg	: "Arrays must have either a comma or a closing square brace after a value."
							,exp	: ", ]"}
					,clo	:{msg	: "Objects must have either a comma or a closing square brace after a value."
							,exp	: ", ]"}
					,jsn	:{msg	: "A JSON payload should be an object or array, not a string."
							,exp	: "[ {"}	}
		; Value validator and regex key assigner
		,is_val :=	{"0"	:"n"	,"5":"n"	,0	:"n"	,5	:"n"	,"-" :"n"
					,"1"	:"n"	,"6":"n"	,1	:"n"	,6	:"n"	,"t" :"b"
					,"2"	:"n"	,"7":"n"	,2	:"n"	,7	:"n"	,"f" :"b"
					,"3"	:"n"	,"8":"n"	,3	:"n"	,8	:"n"	,"n" :"b"
					,"4"	:"n"	,"9":"n"	,4	:"n"	,9	:"n"	,"""":"s"	}
		
		While ( (char := SubStr(json, ++i, 1)) != "") {
			
			If is_ws[char]
				Continue
			MsgBox, % "char: " char "`ni: " i "`nnext: " next 
			
			(next == "v")
				? is_val[char]
					? RegExMatch(json, rgx[is_val[char]], m_, i)
						? (obj[path*] := m_str, i+=StrLen(m_)-1, next:="c") ; decode here
					: this.error(json, i, err.snb.msg, err.snb.exp, SubStr(json, i-10, 21))
				? (next := is_new[char])
					? obj[path*] := {}
				: this.error(json, i, err.val.msg, err.val.exp, char)
			: (next == "k")
				: RegExMatch(json, rgx.k, m_, i)
					? (path.Push(m_str), path_a.Push(False), i+=StrLen(m_)-1, next:="v")
				: this.error(json, i, err.key.msg, err.key.exp, SubStr(json, i-10, 21))
			: (next == "o")
				? (char == "}")
					? (next := "c")
				: RegExMatch(json, rgx.k, m_, i)
					? (path.Push(m_str), path_a.Push(False), i+=StrLen(m_)-1, next:="v")
				: this.error(json, i, err.obj.msg, err.obj.exp, SubStr(json, i-10, 21))
			: (next == "a")
				? (char == "]")
					? (next := "c")
				: (path.Push(1), path_a.Push(True), i--, next := "v")
			: (next == "c")
				? path_a[path_a.MaxIndex()]
					? (char == ",")
						? (path[path.MaxIndex()]++, next := "v")
					: char == "]"
						? (path.Pop(), path_a.Pop())
					: this.error(json, i, err.cla.msg, err.cla.exp, char)
				: (char == ",")
						? (path.Pop(), path_a.Pop(), next := "k")
				: (char == "}")
					? (path.Pop(), path_a.Pop())
				: this.error(json, i, err.clo.msg, err.clo.exp, char)
			: (next == "s")
				? (is_new[char])
					? (obj[path*] := {}, next := is_new[char])
				: this.error(json, i, err.jsn.msg, err.jsn.exp, char)
			: this.error(json, i, err.dbg.msg, err.dbg.exp, next)
		}
		
		MsgBox on clipboard
		
		MsgBox, % this.view_obj(obj)
		Return obj
	}
	
	string_decode(txt){
		Local
		
		str		:= char := code := ""
		,txt	:= StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(txt
					,"\b"	,"`b")	; Backspace
					,"\f"	,"`f")	; Formfeed
					,"\n"	,"`n")	; Linefeed
					,"\r"	,"`r")	; Carriage Return
					,"\t"	,"`t")	; Tab
					,"\/"	,"/")	; Slash / Solidus
					,"\"""	,"""")	; Double Quotes
					,"\\"	,"\*")	; Last, set \* as placeholder for \
		
		Loop, Parse, % txt, % "\"
			str .= (A_Index == 1)									; Always add first line
				? A_LoopField
			: ((char := SubStr(A_LoopField,1,1)) == "*")			; Replace * place holder with \
				? "\" . SubStr(A_LoopField,2)
			: (char == "u")											; Replace unicode
				? ((code := "0x" SubStr(A_LoopField,2,4)) >= 0x0000	; Validate hex range
					&& code <= 0xFFFF)
					? Chr(code) . SubStr(A_LoopField,6)				; Add to str
				: this.error(txt, A_Index
					, "Unicode hex is invalid."
					, "#### 4 hex numbers. 0-9, A-F, a-f"
						. "`n 0x0000 <= #### >= 0xFFFF"
					, code, "", "\")
			: this.error(txt, A_Index
				, "Invalid escape character."
				, "\b \r \n \t \f \\ \/ \"" \u####"
				, char, "", "\")
		
		Return str
	}
	
	; Encodes specific chars to escaped chars
	string_encode(txt) {
		Local
		
		txt	:= SubStr(txt, 2, -1)
		,txt:= StrReplace(txt, "\", "\\")	; Backslash / Reverse Solidus
		,txt:= StrReplace(txt, "/",	 "\/")	; Slash / Solidus
		,txt:= StrReplace(txt, """", "\""")	; Double Quote
		,txt:= StrReplace(txt, "`t", "\t")	; Tab
		,txt:= StrReplace(txt, "`r", "\r")	; Carriage Return
		,txt:= StrReplace(txt, "`n", "\n")	; Linefeed
		,txt:= StrReplace(txt, "`f", "\f")	; Formfeed
		,txt:= StrReplace(txt, "`b", "\b")	; Backspace
		
		Return (this.dq . txt . this.dq)
	}
	
	;==============================\
	;          Hannah...           |
	;          You still           |
	;         a bee~itch!          |
	;==============================/
	
	; Check if object is an array
	is_array(obj) {
		status := 1
		For i, v in obj
			(i == A_Index)
				? ""
				: status := 0
		Until (status == 0)
		Return status
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
			. "`nExtra: " extra
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
				? "`n" indent key ":`n" this.view_obj(value, i+1)
				: indent key ": " value "`n"
		
		str := RTrim(str, "`n")
		str := StrReplace(str, "`n`n", "`n")
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

