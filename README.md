## PLEASE NOTE THAT THIS IS A WIP!! It is not completed as of yet.
When it is in a fully functional state, I'll update this.
(Felt it necessary to mention this after someone randomly starred this page haha.)

# JSON_AHK

This is a library written for AutoHotkey that provides JSON support.
JSON_AHK is able to convert JSON text into a valid AHK object as well as converting any AHK object/array into JSON text.

This library comes with multiple methods as well as quite a few properties that can be set to customize the JSON text output.


## Methods  
```AutoHotkey
	.to_JSON(obj)		; Converts an AHK object and returns JSON text  
	.to_AHK(json)		; Converts JSON text and returns an AHK object  
	.stringify(json)	; Organizes code into one single line  
	.readable(json)		; Organizes code into indented, readable lines  
	.validate(json)		; Validates a json file and retruns true or fa  
	.import()		; Returns JSON text from a file  
```

## Properties  
```AutoHotkey
	.indent_unit		; Set to the desired indent character(s). Default=Tab  
	.no_indent		; Enables indenting of exported JSON files. Default=True  
	.ob_new_line		; Open brace is put on a new line. Default=True  
	.cb_new_line		; Close brace is put on a new line. Default=True  
	.ob_value_inline	; Open brace indented to match value indent. Default=False  
	.cb_value_inline	; Close brace indented to match value indent. Default=False  
	.ob_value_new		; First value is put on new line. Default=True  
	.no_braces		; Messes up your teeth. Kidding. It removes all braces. Default=False  
```

