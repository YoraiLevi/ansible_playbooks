#Include ENV.ahk
#Include Clipboard.ahk
#c::
	EL =
	GetSelectedText()
    MsgBox %selection%
return
#q::
	EL =
	GetSelectedText()
    ; MsgBox %selection%
	Read(selection,"Microsoft Eva Mobile",1)
return
#w::
	EL =
	GetSelectedText()
    ; MsgBox %selection%
	Read(selection,"VE_Hebrew_Carmit_22kHz",1)
return
;   -l              : print list of voices
;   -s <integer>    : speed of speech (from -10 to 10)
;   -p <integer>    : pitch of speech (from -10 to 10)
;   -v <integer>    : volume of speech (from 0 to 100)
;   -e <integer>    : pause between sentences (in milliseconds)
;   -a <integer>    : pause between paragraphs (in milliseconds)
;   -k              : kill other copies of application
;   -ka             : kill active copy of application
;   -pr             : pause or resume reading by active copy of application
;   -q              : add application to queue

Read(transcript,voice,speed=0,pitch=0,volume=100,pause_sentence=0,pause_paragraphs=0){
	; see local ids:
	; https://www.science.co.il/language/Locale-codes.php
	; MsgBox speed: %speed% \n pitch: %pitch% \n volume: %volume% \n voice: %voice%
	args = -k -s "%speed%" -p "%pitch%" -v "%volume%" -n "%voice%" -t """%transcript%"""
	Run, balcon\balcon.exe %args%,,Hide
}

