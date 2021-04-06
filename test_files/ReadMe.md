#This folder contains multiple JSON test files.  

The error folder contains JSON files with titles defining the error.


Error file checklist:
JSON:
	No opening brace/bracket
	No closing brace/bracket
	Brace/bracket total mismatch
	Invalid whitespace (not spc/LF/CR/Tab)
Obj:
	Non-string for obj key
	Missing obj colon
	No comma between members
	Cloing bracket ] instead of brace }
	No closing brace }
Arr:
	Add a key
	No comma between values
	Cloing brace } instead of bracket ]
	No closing bracket ]
Value:
	String
		Invalid character (0x0-0x1F)
		Invalid unicode hex number
		String missing a quote
		Illegal escaped char (like \d)
	Number
		Number with a letter in it
		Number with 2 exponents
		Number starting with leading zeroes
		Number with nothing after the decimal
	TFN
		Capitalize a letter in each
		Misspelled t/f/n
