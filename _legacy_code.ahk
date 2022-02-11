; Gobs of old code and different things I've tried over the course of writing JSON_AHK

/*
    ;~ ; Convert AHK object to JSON string
    ;~ to_json(obj) {
        ;~ ; User settings for forward slash escaping
        ;~ this.esc_slash_search := (this.esc_slash ? "/" : "")
        ;~ this.esc_slash_replace := (this.esc_slash ? "\/" : "")
        
        ;~ IsObject(obj)
            ;~ ? str := this.to_json_extract(obj, this.is_array(obj))
            ;~ : this.basic_error("You did not supply a valid object or array")
        
        ;~ ; Clean up outside of JSON
        ;~ str := Trim(str, "`n`t`r ")
        
        ;~ ; Fix last brace if cb_val_inline is used
        ;~ (this.cb_new_line && this.cb_val_inline)
            ;~ ? str := RegExReplace(str, "^(.*?)[ |\t]*(\}|\])$", "$1$2")
            ;~ : ""
        
        ;~ Return str
    ;~ }

    
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
    
    
    
    
    
    
    ; LATER STUFF
    ; Preview JSON text with current settings
    ;~ preview() {
        ;~ Return txt
    ;~ }

    
    
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
    
    
    ; Old error handling
    ; Come back to see if this can be salvaged
    ;~ error(txt, index, msg, expected, found, extra:="", delim:="", offset:=90) {
        ;~ txt_display	:= ""
        ;~ ,error_sec	:= ""
        ;~ ,start		:= ((index - offset) < 0) ? 0
                        ;~ : (index - offset)
        ;~ ,stop		:= index + offset
        
        ;~ ; Error display
        ;~ Loop, Parse, % txt, % delim
            ;~ If (A_Index < start)
                ;~ Continue
            ;~ Else If (A_Index > stop)
                ;~ Break
            ;~ Else error_sec .= A_LoopField
        
        ;~ ; Highlight problem
        ;~ Loop, Parse, % txt
        ;~ {
            ;~ If (A_Index > stop)
                ;~ Break
            ;~ Else If (A_Index < start)
                ;~ Continue
            ;~ Else If (A_Index = index)
                ;~ txt_display .= ">> " A_LoopField " <<"
            ;~ Else txt_display .= A_LoopField
        ;~ }
        
        ;~ MsgBox, 0x0, Error, % msg
            ;~ . "`nExpected: " expected
            ;~ . "`nFound: " found
            ;~ . "`nIndex: " index
            ;~ . "`nTxt: " error_sec
            ;~ . "`nError: " txt_display
            ;~ . (extra = "" ? "" : "`n" extra)
        ;~ Exit
    ;~ }
    
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

    ;~ ; Validates JSON text
    ;~ validate(json)
    ;~ {
        ;~ Local
         ;~ json      := this.strip_ws(json)       ; Strip whitespace to speed up validation
        ;~ ,path      := []                        ; Stores the current object path
        ;~ ,is_arr    := []                        ; Track if path is in an array (1) or an object (0)
        ;~ ,p_index   := 0                         ; Tracks path index
        ;~ ,char      := ""                        ; Current character of json text
        ;~ ,next      := "s"                       ; Next expected action: (s)tart, (k)ey, (v)alue, (a)rray, (e)nder
        ;~ ,m_        := ""                        ; Stores regex matches
        ;~ ,m_str     := ""                        ; Stores regex match subpattern
        ;~ ,max       := StrLen(json)              ; Track total characters in json
        ;~ ,err       := 0                         ; Track if an error occurs
        ;~ ,index     := 0                         ; Tracks position in JSON string
        ;~ ,this.jbak := json                      ; Backup json for error detection reporting
        
        ;~ ; Verify JSON text
        ;~ While (index < max) && (err < 1)                                                            ; Start parsing JSON file
        ;~ {
            ;~ (char := SubStr(json,++index,1)) = " "
                ;~ ? ""
            ;~ : next == "v"                                                                           ; If next expected is a value...
                ;~ ? this.is_val[char]                                                                     ; Check if char is valid start to a value
                    ;~ ? RegExMatch(json, this.rgx[this.is_val[char]], m_, index)                          ; Validate value
                        ;~ ? (index += StrLen(m_)-1, next := "e")                                          ; If valid, update index and next and continue
                        ;~ : err := this.val_err(index, path, "Error finding valid value."                 ; If not valid, error out
                            ;~ , "string number true false null")
                ;~ : char == "{" ? next := "k"                                                             ; Else if char is open curly brace, create new object and set next to key
                ;~ : char == "[" ? next := "a"                                                             ; Else if char is open square brace, create new array and set next to array
                ;~ : err := this.val_err(index, path, "Invalid JSON value at index " index "."             ; If no char match, error out
                    ;~ , "string number object array true false null")
            ;~ : next == "e"                                                                           ; If next expected is ender (end of a piece of data)...
                ;~ ? char == ","                                                                           ; If char is comma, another value is expected
                    ;~ ? is_arr[p_index] ? (path[p_index]++, next := "v")                                  ; If current path is array, expect a value
                    ;~ : (path.Pop(), --p_index, next := "k")                                              ; Else if current path is object, expect a key
                ;~ : (char == "]" && is_arr[p_index])                                                      ; If char is close square bracket and path is array
                ;~ || (char == "}" && !is_arr[p_index])                                                    ; OR if char is close curly brace and path is object
                    ;~ ? (path.Pop(), --p_index)                                                           ; Update path, is_arr, and path index
                ;~ : err := this.val_err(index, path, "Invalid ending character."                          ; Otherwise, error out
                    ;~ , ", ] }")
            ;~ : next == "k"                                                                           ; If next expected is start of object (key)
                ;~ ? char == "}" ? (next := "e")                                                           ; If char is closing curly brace, add empty object and expect ender
                ;~ : RegExMatch(json, this.rgx.k, m_, index)                                               ; Else check if valid key
                    ;~ ? (++p_index, path[p_index] := m_str, is_arr[p_index] := 0                          ; If valid, increment path index, update path is_arr to object, add key to path...
                        ;~ ,index += StrLen(m_) - 1, next := "v" )                                         ; ...update index, and a value should be expected next
                    ;~ : err := this.val_err(index, path, "Invalid character after start of object."       ; Otherwise, error out
                        ;~ , "string }")
            ;~ : next == "a"                                                                           ; If next expected is start of an array
                ;~ ? char == "]" ? (next := "e")                                                           ; If closing square bracket, add empty array and expect ender
                ;~ : (path[p_index] := is_arr[++p_index] := 1, next := "v", --index)                       ; Otherwise, path, is_arr, expect a value, and decrment index b/c we're currently on the first char of the value
            ;~ : next == "s"                                                                           ; If next expected is start of JSON
                ;~ ? char == "{" ? next := "k"                                                             ; If open curly brace, expect a key (start of object)
                ;~ : char == "[" ? next := "a"                                                             ; If open square braace, expect start of an array
                ;~ : err := this.val_err(index, path, "A JSON file must start with a square bracket "      ; Otherwise, error out
                    ;~ . "or a curly brace.", "{ [")
            ;~ : err := this.val_err(index, path, "Invalid next variable during parse value."              ; Final catch error. This should never show up. 
                ;~ , "The end user should never see this message.")
        ;~ }
        
        ;~ (p_index != 0)                              ; p_index being 0 means all paths were successfully closed
            ;~ ? err := this.val_err(index, path, "Open arrays or objects."
                ;~ , "All open brackets/braces must have an accompanying closing bracket/brace")
            ;~ : ""
        
        ;~ MsgBox, % "ALL DONE"
            ;~ . "`nValidation: " (err > 0 ? "Failed" : "Passed")
        
        ;~ Return (err > 0 ? 0 : 1)
    ;~ }
    
    ;~ val_err(index, path, msg, expected)
    ;~ {
        ;~ path_full := ""
        ;~ , max     := StrLen(this.jbak)
        ;~ , offset  := this.error_offset
        
        ;~ For k, v in path
            ;~ path_full .= (A_Index > 1 ? "." : "") v
        
        ;~ MsgBox, % "Error at index: " index
            ;~ . "`nCharacter: " SubStr(this.jbak, index, 1)
            ;~ . "`nPath: " path_full
            ;~ . "`nError Message: " msg
            ;~ . "`nExpected: " expected
            ;~ . "`n`n" SubStr(this.jbak
                ;~ , (index - offset < 1 ? 1 : index - offset)
                ;~ , (index - offset < 1 ? index-1 : offset))
            ;~ . " >>>" SubStr(this.jbak, index, 1) "<<< "
            ;~ . SubStr(this.jbak, index+1, (index + offset > max ? "" : offset))
        ;~ Return 1
    ;~ }
    
    ;~ to_object(json)
    ;~ {
        ;~ Local
         ;~ json      := this.strip_ws(json)       ; Strip whitespace to speed up validation
        ;~ ,path      := []                        ; Stores the current object path
        ;~ ,is_arr    := []                        ; Track if path is in an array (1) or an object (0)
        ;~ ,p_index   := 0                         ; Tracks path index
        ;~ ,char      := ""                        ; Current character of json text
        ;~ ,next      := "s"                       ; Next expected action: (s)tart, (k)ey, (v)alue, (a)rray, (e)nder
        ;~ ,m_        := ""                        ; Stores regex matches
        ;~ ,m_str     := ""                        ; Stores regex match subpattern
        ;~ ,max       := StrLen(json)              ; Track total characters in json
        ;~ ,err       := 0                         ; Track if an error occurs
        ;~ ,index     := 0                         ; Tracks position in JSON string
        ;~ ,obj       := {}                        ; Base object to be built
        ;~ ,this.jbak := json                      ; Backup json for error detection reporting
        
        ;~ While (index < max) && (err < 1)                                                            ; Start parsing JSON file
        ;~ {
            ;~ (char := SubStr(json,++index,1)) = " "
                ;~ ? ""
            ;~ : next == "v"                                                                           ; If next expected is a value...
                ;~ ? this.is_val[char]                                                                     ; Check if char is valid start to a value
                    ;~ ? RegExMatch(json, this.rgx[this.is_val[char]], m_, index)                          ; Validate value
                        ;~ ? (index += StrLen(m_)-1, next := "e"                                           ; If valid, update index and next
                            ;~ , obj[path*] := (this.is_val[char] == "s"                                   ; Add value to object and if string...
                                ;~ ? this.json_encode(m_str)                                               ; ...encode string properly and quote
                                ;~ : m_str) )                                                              ; Otherwise, add value
                        ;~ : err := this.val_err(index, path, "Error finding valid value.`nFound: " m_str  ; If not valid, error out
                            ;~ , "string number true false null")
                ;~ : char == "{" ? next := "k"                                                             ; Else if char is open curly brace, create new object and set next to key
                ;~ : char == "[" ? next := "a"                                                             ; Else if char is open square brace, create new array and set next to array
                ;~ : err := this.val_err(index, path, "Invalid JSON value at index " index "."             ; If no char match, error out
                    ;~ , "string number object array true false null")
            ;~ : next == "e"                                                                           ; If next expected is ender (end of a piece of data)...
                ;~ ? char == ","                                                                           ; If char is comma, another value is expected
                    ;~ ? is_arr[p_index] ? (path[p_index]++, next := "v")                                  ; If current path is array, expect a value
                    ;~ : (path.Pop(), --p_index, next := "k")                                              ; Else if current path is object, expect a key
                ;~ : (char == "]" &&  is_arr[p_index])                                                     ; If char is close square bracket and path is array
                ;~ ||(char == "}" && !is_arr[p_index])                                                     ; OR if char is close curly brace and path is object
                    ;~ ? (path.Pop(), --p_index)                                                           ; Update path, is_arr, and path index
                ;~ : err := this.val_err(index, path, "Invalid ending character."                          ; Otherwise, error out
                    ;~ , ", ] }")
            ;~ : next == "k"                                                                           ; If next expected is start of object (key)
                ;~ ? char == "}" ? (next := "e")                                                           ; If char is closing curly brace, add empty object and expect ender
                ;~ : RegExMatch(json, this.rgx.k, m_, index)                                               ; Else check if valid key
                    ;~ ? (++p_index, path[p_index] := m_str, is_arr[p_index] := 0                          ; If valid, increment path index, update path is_arr to object, add key to path...
                        ;~ ,index += StrLen(m_) - 1, next := "v" )                                         ; ...update index, and a value should be expected next
                    ;~ : err := this.val_err(index, path, "Invalid character after start of object."       ; Otherwise, error out
                        ;~ , "string }")
            ;~ : next == "a"                                                                           ; If next expected is start of an array
                ;~ ? char == "]" ? (next := "e")                                                           ; If closing square bracket, add empty array and expect ender
                ;~ : (path[p_index] := is_arr[++p_index] := 1, next := "v", --index)                       ; Otherwise, path, is_arr, expect a value, and decrment index b/c we're currently on the first char of the value
            ;~ : next == "s"                                                                           ; If next expected is start of JSON
                ;~ ? char == "{" ? next := "k"                                                             ; If open curly brace, expect a key (start of object)
                ;~ : char == "[" ? next := "a"                                                             ; If open square braace, expect start of an array
                ;~ : err := this.val_err(index, path, "A JSON file must start with a square bracket "      ; Otherwise, error out
                    ;~ . "or a curly brace.", "{ [")
            ;~ : err := this.val_err(index, path, "Invalid next variable during parse value."              ; Final catch error. This should never show up. 
                ;~ , "The end user should never see this message.")
        ;~ }
        
        ;~ (p_index != 0)                                                                              ; p_index being 0 means all paths were successfully closed
            ;~ ? err := this.val_err(index, path, "Open arrays or objects."
                ;~ , "All open brackets/braces must have an accompanying closing bracket/brace")
            ;~ : ""
        
        ;~ Return (err > 0 ? 0 : obj)
    ;~ }






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
    ; .array_one_line           | True:         "key": ["value1", "value2"]                                                                       |
    ;                           | False: [DEF]  "key": [                                                                                          |
    ;                           |                   "value1",                                                                                     |
    ;                           |                   "value2"                                                                                      |
    ;___________________________|_________________________________________________________________________________________________________________|

