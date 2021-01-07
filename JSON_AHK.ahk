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
	jtxt	:= JSON_AHK.import()
	obj		:= json_ahk.to_ahk(jtxt)
	total	:= 0
	i		:= 1
	
	total -= A_TickCount
	Loop, % i
		str := JSON_AHK.to_json(obj)
	total += A_TickCount
	
	MsgBox, % "Time to convert: " total/i " ms"
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
	;	.to_JSON(ahk_object)		; Converts an AHK object and returns JSON text
	;	.to_AHK(json_txt)			; Converts JSON text and returns an AHK object
	;	.stringify(json_txt)		; Organizes code into one single line
	;	.readable(json_txt)			; Organizes code into indented, readable lines
	;	.validate(json_txt)			; Validates a json file and retruns true or false
	;	.import()					; Returns JSON text from a file
	;
	; Properties:
	;	.json_indent				; True/False. Enables indenting of exported JSON files. Default=True
	;	.json_indent_unit			; Set to the desired indent character(s). Default=1 tab
	;	.json_ob_new_line			; If true, put first brace on new line. Default=True
	;	.json_ob_value_inline			; If true, open brace and values are on same indent. Default=False
	;	.json_ob_value_line		; If true, puts first value on same line as first brace. Default=False
	;	.json_close_new_line		; If true, put last brace on new line. Default=True
	;	.json_close_indent			; If true, end brace and values are on same indent. Default=False
	;	.json_no_braces				; If true, Results in messed up teeth. Haha. It really just removes braces.
	;=========================================================================================================
	
	;~ Static indent_unit		:= "`t"     ; Set to the desired indent character(s). Default=1 tab
	;~ Static no_indent		:= False	; Enables indenting of exported JSON files. Default=True
	;~ Static ob_new_line	:= True     ; Put first brace on new line. Default=
	;~ Static ob_value_inline		:= False    ; Indent first brace to match values. Default=
	;~ Static ob_value_line	:= False    ; Puts first value on same line as first brace. Default=
	;~ Static close_new_line	:= False    ; Put last brace on new line. Default=
	;~ Static close_indent		:= False    ; Indent last brace to match values. Default=
	;~ Static no_braces		:= False    ; Messes up your teeth. Kidding. It removes all braces.
	
	Static 	indent_unit		:= "`t"     ; Set to the desired indent character(s). Default=1 tab
	Static 	no_indent		:= False	; Enables indenting of exported JSON files. Default=True
	Static 	ob_new_line		:= True     ; Open brace is put on a new line. Default=
	Static 	cb_new_line		:= False    ; Close brace is put on a new line. Default=
	Static 	ob_value_inline	:= False    ; Open brace indented to match value indent. Default=
	Static 	cb_value_inline	:= False    ; Close brace indented to match value indent. Default=
	Static 	ob_value_new		:= False    ; First value is put on new line. Default=
	Static 	no_braces		:= False    ; Messes up your teeth. Kidding. It removes all braces.
	
	; Import JSON file
	import() {
		FileSelectFile, path, 3,, Select JSON file, JSON (*.json)
		FileRead, json, % path
		Return json
	}
	
	; Convert AHK object to JSON string
	to_json(obj) {
		Return Trim(this.json_extract_obj(obj), " `t`n`r")
	}
	json_extract_obj(obj, i:=0) {
		If !IsObject(obj)								; Kick back any non-objects
			Return obj
		
		indent := ""									; Stores proper indent length
		If !(this.no_indent)							; Sets indent based on settings
			Loop, % i
				indent .= this.indent_unit
		
		regex_e_arr		:= "^\[( |\t|\n|\r)*?\]$"		; RegEx for matching empty arrays
		, regex_e_obj	:= "^\{( |\t|\n|\r)*?\}$"		; RegEx for matching empty objects
		, ws			:= " `t`n`r"					; Define whitespace
		, type 			:= this.is_array(obj)			; Track if object or array
							? "a"
							: "o"
		, brace_open	:= (this.no_braces				; Set opening brace
							? ""
						: (type == "a")
							? "["
							: "{")
		, brace_end		:= (this.no_braces				; Set closing brace
							? ""
						: (type == "a")
							? "]"
							: "}")
		, str 			:= (this.ob_new_line			; Should the open brace be on a new line
							? "`n"
							: "")
						. indent
						. (this.ob_value_inline			; Should values and open brace be on the same indent
							? this.indent_unit
							: "")
						. brace_open
		
		For k, v in obj									; Loop through object and build list of values
			str .= (A_Index = 1							; Should first line be on same line as brace
					&& this.ob_value_line
					? "`n"
					: "")
				. indent this.indent_unit				; Indent line
				. (type == "o" ? k ": " : "")			; Include key: if object
				. this.json_extract_obj(v, i+1) 		; Extract value (func returns value if not obj)
				. ","									; Always add a comma
		
		str := RTrim(str, ",")  						; Trim off last comma and add end brace
			. (this.close_new_line
				? "`n"
				: "")
			. (this.close_indent
				? indent
				: "")
			. (type == "a" ? "]" : "}")
		
		Return (str ~= regex_e_arr)						; If an empty array
			? "[]"										; Send back 2 square braces
		: (str ~= regex_e_obj)							; If an empty objec
			? "{}"										; Send back 2 curly braces
			: str
	}
	
	; Converts a json file into a single string
	stringify(json) {
		
		/* Account for objects or text
		If IsObj(json)
			; Convert obj
		Else
			; Convert txt
		*/
		
		; Convert text
		str			:= ""
		,char		:= ""
		,last		:= ""
		,VarSetCapacity(str, 10240)
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
	
	; Convert json text in an ahk object
	to_ahk(json){
		; Loop parse method
		obj			:= {}			; Main object to build and return
		,path		:= []			; Path value should be stored in the object
		,path_arr	:= []			; Tracks if current path is an array (true) or object (false)
		,index		:= 0			; Tracks current position in the json string
		,do_next	:= "s"			; Next expected action: (s)tart, (e)nder, (k)ey, (v)alue
		,match_		:= ""			; RegEx match variable
		,char		:= ""			; Current character
		,char_total := StrLen(json)	; Total number of characters in JSON
		
		obj.SetCapacity(1000)
		
		; Validation/conversion arrays
		; Whitespace
		is_ws		:=	{" "	:True		; Space
						,"`t"	:True		; Tab
						,"`n"	:True		; New Line
						,"`r"	:True	}	; Carriage Return
		; Number chars
		,is_num		:=	{0	:True	,1	:True	,2	:True	,3	:True	,4	:True
						,5	:True	,6	:True	,7	:True	,8	:True	,9	:True
						,"e":True	,"E":True	,".":True	,"-":True	,"+":True	}
		; Object/array enders
		,is_end		:=	{"]"	:True
						,"}"	:True	}
		; Beginning value validation
		,is_value	:=	{0	:"num"	,1	:"num"	,2	:"num"	,3	:"num"	,4	:"num"
						,5	:"num"	,6	:"num"	,7	:"num"	,8	:"num"	,9	:"num"
						,"""":"str"	,"-":"num"	,"t":"tfn"	,"f":"tfn"	,"n":"tfn"	}	
		; RegEx bank
		,regex_arr	:=	{key : "((?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))[ |\t|\n|\r]*?:)"
						,str : "(?P<str>(?>""(?>\\(?>[""\\\/bfnrt]|u[a-fA-F0-9]{4})|[^""\\\0-\x1F\x7F]+)*""))"
						,num : "(?P<str>(?>-?(?>0|[1-9][0-9]*)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?))"
						,tfn : "(?P<str>true|false|null)"}
		
		While (index < char_total)
		{
			; Get next char
			char := SubStr(json, ++index, 1)
			; Skip all non-string whitespace
			,is_ws[char]
				? Continue
			; Check for a value
			: (do_next == "v")
				; If value is str/num/tfn
				? is_value[char]
					; Get data and validate
					? RegExMatch(json, regex_arr[is_value[char]], match_, index)
						; If valid, add it
						? (obj[path*] := match_str
							, index += StrLen(match_) - 1
							, do_next := "e"	)
						; If notv valid, throw an error
						: this.error(json, index
							, "Invalid string/number/tfn"
							, "See json.org for specifics on strings, numbers, and true/false/null"
							, char)
				; If value is new object
				: (char == "{")
					? do_next := "k"
				; If value is new array
				: (char == "[")
					? (path.Push(1)
						, path_arr.Push(True)
						, obj[path*] := []
						, do_next := "v"	)
				; If value is end of object or array
				: is_end[char]
					? (path.Pop()
						, path_arr.Pop()
						, do_next := "e"	)
				; Otherwise, not a valid value
				: this.error(json, index
					, "Not a valid character for a value."
					, "0123456789tfn-{}[]"
					, char	)
			; Check for a value ending (comma or object closing brace)
			: (do_next == "e")
				; If comma
				? (char == ",")
					? path_arr[path_arr.MaxIndex()]
						? (path[path.MaxIndex()]++
							, do_next := "v")
						: (path.Pop()
							, path_arr.Pop()
							, do_next := "k")
				; If closing object
				: is_end[char]
					? (path.Pop()
						, path_arr.Pop()	)
				; Otherwise, invalid ending char
				: this.error(json, index
					,"A comma or closing squar/curly brace must come after all values."
					,", ] }"
					,char	)
			; Get an object key
			: (do_next == "k")
				; Check if empty object
				? (char == "}")
					? (obj[path*] := {}
						, do_next := "e")
				; Get and validate a key
				: RegExMatch(json, regex_arr.key, match_, index)
					; If valid, update path
					? (path.Push(match_str)
						, path_arr.Push(False)
						, index += StrLen(match_) - 1
						, do_next := "v")
					; Throw error for invalid key
					: this.error(json, index
						,"Invalid key for object"
						,"See JSON.org for rules on strings.")
			; Start checks for initial object or array
			: (do_next == "s")
				; Is object
				? InStr("{[", char)
					? (do_next := "v"
						, index--)
					; Throw error for invalid start of JSON file
					: this.error(json, index
						,"Objects must start with an opening curly/square brace."
						,"{ ["
						,char	)
			; Throw error for invalid do_next
			: this.error(json, index
				, "Invalid do_next"
				, "`n`tb - Beginning"
					. "`n`te - Ending"
					. "`n`tk - Key"
					. "`n`tv - Value"
				, do_next)
		}
		Return obj
	}
	
	; Converts JSON escape characters
	decode_esc_chars(txt) {
		esc_chars	:=	{"\/"	: "/"		; Slash\Solidus
						,"\\"	: "\"		; Backslash\Reverse Solidus
						,"\"""	: """"		; Double Quotes
						,"\b"	: "`b"		; Backspace
						,"\f"	: "`f"		; Formfeed
						,"\n"	: "`n"		; Linefeed
						,"\r"	: "`r"		; Carriage return
						,"\t"	: "`t"	}	; Horizontal Tab
		
		For replace, find in esc_chars
			txt := StrReplace(txt, find, replace)
		
		Return txt
	}
	
	; Converts JSON escape characters
	encode_esc_chars(txt) {
		esc_chars	:=	{"\/"	: "/"		; Slash\Solidus
						,"\\"	: "\"		; Backslash\Reverse Solidus
						,"\"""	: """"		; Double Quotes
						,"\b"	: "`b"		; Backspace
						,"\f"	: "`f"		; Formfeed
						,"\n"	: "`n"		; Linefeed
						,"\r"	: "`r"		; Carriage return
						,"\t"	: "`t"	}	; Horizontal Tab
		
		For find, replace in esc_chars
			txt := StrReplace(txt, find, replace)
		
		Return txt
	}
	
	;==============================\
	;          Hannah...           |
	;          You still           |
	;         a bee~itch!          |
	;==============================/
	
	; Check if object is an array
	is_array(obj) {
		min =
		offset = 0
		For k, v in obj
		{
			min = %k%
			Break
		}
		
		If (min == 0)
			offset = 1
		Else If !(min == 1)
			Return False
		
		For k, v in obj
			If (min = A_Index - offset)
				min++
			Else Return False
		
		Return True
	}
	
	basic_error(msg) {
		MsgBox, % msg
		Return
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

