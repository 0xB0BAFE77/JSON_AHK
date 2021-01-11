#SingleInstance Force
#Warn
#NoEnv
#KeyHistory 0
ListLines, Off
SetBatchLines, -1

test()

ExitApp

Esc::ExitApp

test() {
	;jtxt := "!B\/\\\\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t"
	;FileRead, jtxt, D:\Scripts\JSON_Test_File.json
	;FileRead, jtxt, C:\Users\TESTCENTER\Desktop\TCM\Tools\AHK\Scripts\JSON_Test_File.json
	if (jtxt = "")
		jtxt := json_ahk.import()
	
	start 	:= A_TickCount
	obj		:= json_ahk.to_ahk(jtxt)
	MsgBox, % "Time to convert to object: " A_TickCount-start " ms"
	
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
	
	; User Settings
	Static	indent_unit			:= "`t"		; Default = `t		Set to the desired indent character(s)
			,comma_first_line	:= True		; Default = True	Put comma on same line as value
			,ob_new_line		:= True		; Default = True	Open brace is put on a new line
			,ob_val_inline		:= False	; Default = False	Open brace indented to match value indent
			,brace_val_same		:= False	; Default = False	Brace and first value share same line
			,cb_new_line		:= False	; Default = True	Close brace is put on a new line
			,cb_val_inline		:= False	; Default = False	Close brace indented to match value indent
			,no_brace_ws		:= True		; Default = True	Remove whitespace from empty braces
			,no_braces			:= False	; Default = False	Messes up your teeth. JK. It removes all braces
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
					? this.esc_char_decode(value)
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
		;,obj.SetCapacity(1000)	; Does setting a large object size speed up performance?
		,path	:= []			; Path value should be stored in the object
		,path_a	:= []			; Tracks if current path is an array (true) or object (false)
		,i		:= 0			; Tracks current position in the json string
		,char	:= ""			; Current character
		,next	:= "s"			; Next expected action: (s)tart, (e)nder, (k)ey, (v)alue
		,max 	:= StrLen(json)	; Total number of characters in JSON
		,m_		:= ""			; Stores regex matches
		,m_str	:= ""			; Stores substring and regex matches
		,rgx_key:= ""			; Tracks what regex pattern to use
		; RegEx bank
		,rgx	:=	{k	: "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*?:)"
					,n	: "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))"
					,s	: "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))"
					,b	: "(?P<str>true|false|null)"	}
		; Whitespace checker
		,is_ws	:=	{" "	:True		; Space
					,"`t"	:True		; Tab
					,"`n"	:True		; New Line
					,"`r"	:True	}	; Carriage Return
		; Object/array enders
		,is_end	:=	{"]"	:True
					,"}"	:True	}
		; Error messages and expectations
		,err	:=	{snb	:{msg	: "Invalid string|number|true|false|null."
									. "`nNeed to write a function that auto-detects this for me."
							,exp	: "string number true false null"}
					,val	:{msg	: "Invalid value."
									. "`nNeed to write a function that auto-detects this for me."
							,exp	: "string number true false null object array"}
					,end	:{msg	: "Invalid char following a value."
									. "`nValues always have a comma or closing brace after them."
							,exp	: ", ] }"}
					,key	:{msg	: "Invalid object key."
							,exp	: "See JSON.org for rules on object keys [strings]."}
					,jsn	:{msg	: "Invalid JSON file."
									. "`nJSON data starts with a brace."
							,exp	: "[ {"}
					,nxt	:{msg	: "YA MESSED UP!!!`nInvalid next variable."
							,exp	: "`n`tb - Beginning" . "`n`te - Ending" . "`n`tk - Key" . "`n`tv - Value"}	}
		; value validator and regex key assigner
		,is_val	:=	{""""	: "s"	
					,"-"	: "n"
					,"t"	: "b"
					,"f"	: "b"
					,"n"	: "b"	}
		; Add values 0-9 to is_val needing number regex
		Loop, 10
			is_val[(A_Index-1)] := "n"
		
		;~ ; Consider converting these prior to 
		;~ ; Convert escape characters except \" and \\
		;~ 	; Converting \" will interfere with string parsing
		;~ 	; Converting \\ can create false string markers interfering with parsing
		;~ json:= StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(json
			;~ ,"\b"	,"`b")	; Backspace
			;~ ,"\f"	,"`f")  ; Formfeed
			;~ ,"\n"	,"`n")  ; Linefeed
			;~ ,"\r"	,"`r")  ; Carriage Return
			;~ ,"\t"	,"`t")  ; Tab
			;~ ,"\/"	,"/")   ; Slash / Solidus
		
		; For tracking object path, would using a string with substring be faster than array and push/pop?
		; Can bit shifting be used as a replacement for path_a (tracks if current path is an array or object so a bunch of true/false)?
		While (i < max)
			is_ws[(char := SubStr(json, ++i, 1))]							; Get next char and skip all non-string whitespace
				? ""
			: (next == "v")													; Get a value
				? (rgx_key := is_val[char])									; Check if first char is a valid non-object value start
					? RegExMatch(json, rgx[rgx_key], m_, i)					; Get and validate the value type using the right regex
						? (obj[path*] := (rgx_key=="s" && InStr(m_str, "\")	; Add value to object
										? this.string_decode(m_str)			; If value is a string with an escape char in it, decode it
										: m_str)
							, i += StrLen(m_str) - 1						; Increment index and check for value ender
							, next := "e"	)
					: this.error(json, i, err.snb.msg, err.snb.exp, m_)		; Otherwise, throw error for invalid value
				: (char == "{")												; If value is new object
					? next := "k"											; Get a new key
				: (char == "[")												; If value is new array
					? (path.Push(1)											; Add array and update path
						, path_a.Push(True)
						, obj[path*] := []
						, next := "v"	)
				: is_end[char]												; If value is end of object or array
					? (path.Pop()											; Get rid of last path
						, path_a.Pop()
						, next := "e"	)
				: this.error(json, i, err.val.msg, err.val.exp, char)		; Otherwise, error b/c not a valid value
			: (next == "e")													; Check for a value ending (comma or closing brace)
				? (char == ",")												; If comma, another value is expected
					? path_a[path_a.MaxIndex()]								; If current path is an array
						? (path[path.MaxIndex()]++							; Increment index and get another value
							, next := "v")
					: (path.Pop()											; If current path is an object
						, path_a.Pop()										; Remove key and get a new one
						, next := "k")
				: is_end[char]												; If closing object
					? (path.Pop()											; Get rid of index/key and leave next as e
						, path_a.Pop()	)
				: this.error(json, i, err.end.msg, err.end.exp, char)		; Otherwise, error b/c invalid ending char
			: (next == "k")													; Get an object key
				? (char == "}")												; If empty object
					? (obj[path*] := {}										; Add new object and check for ending
						, next := "e")
				: RegExMatch(json, rgx.k, m_, i)							; Get and validate a key
					? (path.Push(m_str)										; If valid, update path
						, path_a.Push(False)
						, i += StrLen(m_) - 1
						, next := "v"	)
				: this.error(json, i, err.key.msg, err.key.exp, char)		; Throw error for invalid key
			: (next == "s")													; Start checks for initial object or array
				? (char == "{" || char == "[")								; Validate JSON file starts with an object or array
					? (next := "v"											; Get value
						, i--)												; Index decrement is necessary or parse can fail
				: this.error(json, i, err.jsn.msg, err.jsn.exp, char)		; Throw error for invalid start of JSON file
			: this.error(json, i, err.nxt.msg, err.nxt.exp, next)			; Throw error for invalid next [Troubleshooter]
		
		Return obj
	}
	
	string_decode_alt(txt){
		; Try running multiple string replaces to see if it works faster.
		;~ json:= StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(json
			;~ ,"\b"	,"`b")	; Backspace
			;~ ,"\f"	,"`f")  ; Formfeed
			;~ ,"\n"	,"`n")  ; Linefeed
			;~ ,"\r"	,"`r")  ; Carriage Return
			;~ ,"\t"	,"`t")  ; Tab
			;~ ,"\/"	,"/")   ; Slash / Solidus
			;~ ,"\\"	,"\")   ; Backslash / Reverse Solidus
			;~ ,"\"""	,"""")   ; Double Quotes
		
		Return
	}
	
	decode(txt){
		Local
		
		If !InStr(txt, "\")
			Return txt
		
		str		:= ""				; String with converted escape chars
		,char	:= ""				; Current char
		,nxt	:= ""				; Next char in text
		,code	:= ""				; Converted character
		,i		:= 0				; Index in string
		,pos	:= 1				; Tracks index after last escape char
		,max	:= StrLen(txt)		; Max index amount
		,is_esc	:=	{"b"	: "`b"	; Backspace
					,"r"	: "`r"	; Carriage return
					,"n"	: "`n"	; Linefeed
					,"t"	: "`t"	; Tab
					,"f"	: "`f"	; Formfeed
					,""""	: """"	; Double quote
					,"\"	: "\"	; Backslash / Reverse Solidus
					,"/"	: "/" }	; Slash / Solidus
		
		While (i < max)
			If ((char := SubStr(txt, ++i, 1)) == "\")			; Get next char and check if escape char
				(code := is_esc[(nxt := SubStr(txt,i+1,1))])	; Check if next value is a valid code and save
					? (str .= SubStr(txt, pos, i-pos) . code	; Append prior text and escape code
						, pos := (i+=1)+1	)					; Update index and pos
				: (nxt == "u")									; Check if unicode
					? (code := "0x" SubStr(txt, i+2, 4)			; If yes, get next 4 chars
						, code += 0x0							; Force conversion to hex if possible
						, (code >= 0x0000 && code <= 0xFFFF)	; If valid hex
							? (str .= SubStr(txt, pos, i-pos)	; Append text up to this point
								. Chr(code)						; Add unicode char
								, pos := (i+=4)+1	)			; Update index and pos
							: msg("Invalid hex range: " code)	)
				: msg("Invalid escape char: " nxt)				; Invalid unicode number or out of range	;~ : this.error(txt, i, "Invalid unicode number.", "Format must be: \uNNNN" . "`nNNNN >= 0x0000" . "`nNNNN <= 0xFFFF", code)	)
		
		; Add any remaining chars
		Return str . SubStr(txt, pos, max)
	}
	
	; Encodes specific chars to escaped chars
	esc_char_encode(txt) {
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
		offset	:= 0
		,pass	:= 1
		
		For k, v in obj
			min := k
		Until (A_Index)
		
		(min == 0) ? offset++
			: !(min == 1) ? pass := 0
			: ""
		
		For k, v in obj
			If (min == k - offset)
				min++
			Else pass := 0
		Until (pass == 0)
		
		Return pass
	}
	
	basic_error(msg) {
		MsgBox, % msg
		Return False
	}
	
	error(txt, index, msg, expected, found, extra:="", offset:=90) {
		txt_display	:= ""
		,error_sec	:= ""
		,start		:= ((index - offset) < 0)
						? 0
						: (index - offset)
		,stop		:= index + offset
		
		; Error display
		Loop, Parse, % txt
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
				? "`n" indent key ":`n" %A_ThisFunc%(value, i+1)
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
