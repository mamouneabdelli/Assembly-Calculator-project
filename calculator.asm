; ============================================
; 8086 Assembly Language Calculator
; Author: Your Name
; Compatible with TASM/MASM + DOSBox
; ============================================

.MODEL SMALL
.STACK 100H

.DATA
    ; Menu strings
    menu_msg    DB 13,10,'==== Calculator Menu ====',13,10
                DB '1. Add',13,10
                DB '2. Subtract',13,10
                DB '3. Multiply',13,10
                DB '4. Divide',13,10
                DB '5. Exit',13,10
                DB '========================',13,10
                DB 'Enter your choice: $'

    prompt1     DB 13,10,'Enter first number: $'
    prompt2     DB 13,10,'Enter second number: $'
    result_msg  DB 13,10,'Result: $'
    divzero_msg DB 13,10,'Error: Division by zero!$'
    invalid_msg DB 13,10,'Invalid choice! Try again.$'
    newline     DB 13,10,'$'
    again_msg   DB 13,10,'Press any key for menu...$'
    goodbye_msg DB 13,10,'Goodbye! Thanks for using the calculator.',13,10,'$'
    negative_msg DB '-$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

MENU_LOOP:
    ; Display menu
    LEA DX, menu_msg
    MOV AH, 09H
    INT 21H

    ; Get user choice
    MOV AH, 01H
    INT 21H
    MOV BL, AL         ; Save choice in BL

    ; Print newline
    LEA DX, newline
    MOV AH, 09H
    INT 21H

    ; Compare choice
    CMP BL, '1'
    JE  DO_ADD
    CMP BL, '2'
    JE  DO_SUB
    CMP BL, '3'
    JE  DO_MUL
    CMP BL, '4'
    JE  DO_DIV
    CMP BL, '5'
    JE  DO_EXIT

    ; Invalid choice
    LEA DX, invalid_msg
    MOV AH, 09H
    INT 21H
    JMP WAIT_KEY

; ---- ADDITION ----
DO_ADD:
    CALL GET_NUM1
    MOV CX, AX         ; Save num1 in CX
    CALL GET_NUM2
    ADD AX, CX         ; AX = num1 + num2
    CALL PRINT_RESULT
    JMP WAIT_KEY

; ---- SUBTRACTION ----
DO_SUB:
    CALL GET_NUM1
    MOV CX, AX
    CALL GET_NUM2
    XCHG AX, CX        ; AX = num1, CX = num2
    SUB AX, CX         ; AX = num1 - num2
    CALL PRINT_RESULT
    JMP WAIT_KEY

; ---- MULTIPLICATION ----
DO_MUL:
    CALL GET_NUM1
    MOV CX, AX
    CALL GET_NUM2
    IMUL CX            ; DX:AX = num2 * num1
    CALL PRINT_RESULT
    JMP WAIT_KEY

; ---- DIVISION ----
DO_DIV:
    CALL GET_NUM1
    MOV CX, AX         ; CX = num1 (dividend)
    CALL GET_NUM2
    CMP AX, 0
    JE  DIV_ZERO
    MOV BX, AX         ; BX = divisor
    MOV AX, CX         ; AX = dividend
    CWD                ; Sign-extend AX into DX:AX
    IDIV BX            ; AX = quotient, DX = remainder
    CALL PRINT_RESULT
    JMP WAIT_KEY

DIV_ZERO:
    LEA DX, divzero_msg
    MOV AH, 09H
    INT 21H
    JMP WAIT_KEY

DO_EXIT:
    LEA DX, goodbye_msg
    MOV AH, 09H
    INT 21H
    MOV AH, 4CH
    INT 21H

WAIT_KEY:
    LEA DX, again_msg
    MOV AH, 09H
    INT 21H
    MOV AH, 01H
    INT 21H
    JMP MENU_LOOP

MAIN ENDP

; ============================================
; PROCEDURE: GET_NUM1
; Prompts user and reads a signed integer
; Returns value in AX
; ============================================
GET_NUM1 PROC
    LEA DX, prompt1
    MOV AH, 09H
    INT 21H
    CALL READ_INT
    RET
GET_NUM1 ENDP

; ============================================
; PROCEDURE: GET_NUM2
; Prompts user and reads a signed integer
; Returns value in AX
; ============================================
GET_NUM2 PROC
    LEA DX, prompt2
    MOV AH, 09H
    INT 21H
    CALL READ_INT
    RET
GET_NUM2 ENDP

; ============================================
; PROCEDURE: READ_INT
; Reads a signed integer from keyboard
; Returns: AX = integer value
; Supports negative numbers with '-' prefix
; ============================================
READ_INT PROC
    PUSH BX
    PUSH CX
    PUSH DX

    XOR BX, BX          ; BX = accumulated value
    XOR CX, CX          ; CX = sign flag (0=pos, 1=neg)

    ; Read first character
    MOV AH, 01H
    INT 21H

    CMP AL, '-'
    JNE CHECK_FIRST
    MOV CX, 1           ; Set negative flag
    JMP NEXT_CHAR

CHECK_FIRST:
    SUB AL, '0'
    MOV BL, AL          ; Store first digit

NEXT_CHAR:
    MOV AH, 01H
    INT 21H
    CMP AL, 13          ; Enter key?
    JE  DONE_READING
    SUB AL, '0'         ; ASCII to digit
    MOV DL, AL          ; Save digit
    MOV AX, BX
    MOV DH, 10
    MUL DH              ; AX = BX * 10
    XOR DH, DH
    ADD AX, DX          ; AX = AX + new digit
    MOV BX, AX
    JMP NEXT_CHAR

DONE_READING:
    MOV AX, BX
    CMP CX, 1
    JNE SIGN_DONE
    NEG AX              ; Negate if negative flag set

SIGN_DONE:
    POP DX
    POP CX
    POP BX
    RET
READ_INT ENDP

; ============================================
; PROCEDURE: PRINT_RESULT
; Prints "Result: " followed by AX as decimal
; Handles negative numbers
; ============================================
PRINT_RESULT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    LEA DX, result_msg
    MOV AH, 09H
    INT 21H

    ; Check if negative
    CMP AX, 0
    JGE PRINT_POS
    PUSH AX
    LEA DX, negative_msg
    MOV AH, 09H
    INT 21H
    POP AX
    NEG AX              ; Make positive for digit extraction

PRINT_POS:
    ; Convert AX to decimal digits using stack
    MOV BX, 10
    XOR CX, CX          ; Digit counter

EXTRACT_DIGITS:
    XOR DX, DX
    DIV BX              ; AX = quotient, DX = remainder
    PUSH DX             ; Push digit onto stack
    INC CX
    CMP AX, 0
    JNE EXTRACT_DIGITS

PRINT_DIGITS:
    POP DX
    ADD DL, '0'         ; Convert to ASCII
    MOV AH, 02H
    INT 21H
    LOOP PRINT_DIGITS

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_RESULT ENDP

END MAIN
