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
	FileRead, jtxt, D:\Scripts\JSON_Test_File.json
	if (jtxt = "")
		jtxt := json_ahk.import()
	obj		:= json_ahk.to_ahk(jtxt)
	total	:= 0
	i		:= 1
	
	total -= A_TickCount
	Loop, % i
		str := JSON_AHK.to_json(obj)
	total += A_TickCount
	
	;MsgBox, % "Time to convert: " total/i " ms"
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
	;	.ob_new_line			; Open brace is put on a new line. Default=
	;							; True:		"key":
	;							; 			[
	;							; 				"value",
	;							; False:	"key":[
	;							; 				"value",
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
	;	.brace_val_same			; Brace and first value share same line. Default=
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
	;							; this:		"value1",
	;							; 			"value2"}
	;							;
	;	.cb_val_inline			; ; Close brace indented to match value indent. Default=
	;							; True:			"value1",
	;							; 				"value2"
	;							; 				}
	;							; False:		"string1",
	;							; 				"string2"
	;							; 			}
	;=========================================================================================================
	
	; User Settings
	Static indent_unit		:= "`t"		; Set to the desired indent character(s). Default=1 tab
	Static ob_new_line		:= True		; Open brace is put on a new line. Default=True
	Static ob_val_inline	:= True		; Open brace indented to match value indent. Default=False
	Static brace_val_same	:= True		; Brace and first value share same line. Default=True
	Static cb_new_line		:= True		; Close brace is put on a new line. Default=True
	Static cb_val_inline	:= True		; Close brace indented to match value indent. Default=False
	Static no_brace_ws		:= True		; Remove whitespace from empty braces. Default = True
	Static no_brace_ws_all	:= True		; Remove whitespace from objects containing empty objects. Default = False
	Static no_indent		:= False	; Enable indenting of exported JSON files. Default=False
	Static no_braces		:= False	; Messes up your teeth. Kidding. It removes all braces. Default=False
	
	;=========================================================================================================
	; RegEx for matching empty obj/arr
	Static regex_empty_b	:= "^\s*(\[|\{)( |\t|\n|\r)*?(\]|\})\s*$"
	; Whitespace
	Static ws				:= " `t`n`r"
	
	; Import JSON file
	import() {
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
		Local
		txt := this.extract_obj(obj)
		Return Trim(txt, "`n,")
	}
	extract_obj(obj, indent:="") {
		type:= this.is_array(obj) ? "a"
			: IsObject(obj) ? "o"
			: "v"
		,ob	:= (type == "a" ? "[" : "{")
		,cb	:= (type=="a" ? "]" : "}")
		,str:= "`n"
			. indent
			. ob
		
		For key, value in obj
			str .= (IsObject(value)
				? (type == "o" ? key ": " : "")
				. this.extract_obj(value, indent this.indent_unit)
			: "`n"
				. indent
				. this.indent_unit
				. (type == "o" ? key ": " : "")
				. value
				. ","	)
		
		str := RTrim(str, ",")  						; Trim off last comma
			. "`n" indent cb ","
		
		Return str
		
		
		
		
		;~ ,str 			:= ((this.ob_new_line)			; Open brace on new line?
							;~ ? "`n" indent ((this.ob_val_inline) ; Check if brace and values should be inline
								;~ ? this.indent_unit
								;~ : "")
							;~ : "")
						;~ . brace_open
		
		;~ For k, v in obj									; Loop through object and build list of values
			;~ str .= (A_Index = 1	&& this.brace_val_same	; Should brace and value be on same line?
					;~ ? ""
					;~ : "`n" indent this.indent_unit)
				;~ . (type == "o"							; Include key if object
					;~ ? k ": "
					;~ : "")
				;~ . this.extract_obj(v, i+1) 		; Extract value (func returns value if not obj)
				;~ . ","									; Always add a comma
		
		;~ str := RTrim(str, ",")  						; Trim off last comma and add end brace
			;~ . (this.cb_new_line							; Should the closing brace be on a new line
				;~ ? "`n"
				;~ : "")
			;~ . indent (this.cb_val_inline				; Closing brace on same indent as value
				;~ ? this.indent_unit
				;~ : "")
			;~ . brace_close
		/*
		,this.no_brace_ws_all
			? str := this.collapse_multiple_objects(str)	; Remove whitespace from empty objects of objects
			: this.no_brace_ws								; Remove whitespace from empty object
				&& (str ~= this.regex_empty_b)
				? str := brace_open brace_close
				: ""
		*/
		Return str
	}
	
	collapse_multiple_objects(txt) {
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
		min		:= ""
		,offset	:= 0
		,pass	:= True
		
		For k, v in obj
			min := k
		Until (A_Index)
		
		(min == 0) ? offset++
			: !(min == 1) ? pass := False
			: ""
		
		For k, v in obj
			If (min == k - offset)
				min++
			Else pass := False
		Until (pass == False)
		
		Return pass
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

