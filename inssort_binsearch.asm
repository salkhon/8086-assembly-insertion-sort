.MODEL SNALL

.STACK 100H

.DATA
    LF DB 10
    CR DB 13    
    
    ARRAY DW 100 DUP(0)     ; intels 8086 architectures supported registers are bx, si, di, and bp only.
    ARR_MAX_SZ DW 100 
    CURR_SZ DW 0
    NUM_INTS DW 0
    NUM_SIGN_FLAG DB 0
    STRING DB "NOT FOUND$"
.CODE
                                ; PRINTING NEWLINE USES AH, WHICH MODIFIES AX, CHECK FOR THOSE BUGS

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    CALL INPUT_INT_IN_AX
    MOV BX, 2
    MUL BX
    MOV NUM_INTS, AX

    CALL TAKE_NUM_INTS_INPUTS_AND_PUT_IN_ARRAY

    CALL PRINT_NEWLINE
    CALL PRINT_ARRAY

    CALL INSERTION_SORT

    CALL PRINT_NEWLINE
    CALL PRINT_ARRAY 

    CALL BIN_SEARCH_INPUT_LOOP        
    
    MOV AH, 4CH
    INT 21H                    
ENDP



; INPUTS
INPUT_CHAR_IN_AL PROC
    MOV AH, 1
    INT 21H
    RET
ENDP


INPUT_INT_IN_AX PROC            ; MODIFIES AX, BX, CX 
    MOV BX, 0                   ; TEMP INPUT STORAGE
    MOV CX, 0                   ; ACCUMULATION
                                ; INITIAL INPUT, IF -, NEG AT THE END
    CALL INPUT_CHAR_IN_AL

    CMP AL, '-'
    JNE POS_NUM
    PUSH 1                      ; FLAG TO NEG IN THE END
    CALL INPUT_CHAR_IN_AL
    JMP INPUT_START

    POS_NUM:
    PUSH 0
    
    INPUT_START:
                                ; IF INPUT AT AL IS EQUAL TO LF, END INPUT
    CMP AL, CR
    JZ INPUT_END
                                ; CONVERT TO NUMBER
    MOV AH, 0
    SUB AL, '0'     
                                ; BX = AX, AX = 0010, AX = AX * CX + BX, CX = AX. 
    MOV BX, AX      
    MOV AX, 10           
    MUL CX                  
    ADD AX, BX          
    MOV CX, AX         

    CALL INPUT_CHAR_IN_AL
    JMP INPUT_START
    
    INPUT_END:
    POP BX
    CMP BX, 0
    JE MOVE_RES_IN_AX

    NEG CX

    MOVE_RES_IN_AX:
    MOV AX, CX
    RET                           
ENDP 
      

TAKE_NUM_INTS_INPUTS_AND_PUT_IN_ARRAY PROC      ; MODIFIES SI, CURR_SZ, AX, BX, CX, DX
    MOV SI, 0

    INPUT_LOOP:
    CMP SI, NUM_INTS
    JGE STOP_INPUT

    CALL PRINT_NEWLINE
    CALL INPUT_INT_IN_AX

    MOV ARRAY[SI], AX
    CALL WORDSIZE_INC_SI
    CALL INC_ARRAY_CURRENT_SIZE

    JMP INPUT_LOOP

    STOP_INPUT:
    RET
ENDP


BIN_SEARCH_INPUT_LOOP PROC          ; MODIFIES AX, BX, BP, SI, DI
    TAKE_INPUT:
    CALL PRINT_NEWLINE
    CALL INPUT_INT_IN_AX

    CALL BINARY_SEARCH_INT_IN_AX_INDEX_IN_SI
    CALL PRINT_NEWLINE

    CMP SI, 0
    JL NOT_FOUND
    
    MOV AX, SI                      ; FOUND
    SHR AX, 1
    CALL PRINT_INT_IN_AX

    JMP TAKE_INPUT

    NOT_FOUND:
    CALL PRINT_STRING

    JMP TAKE_INPUT

    END_INPUT:
    RET
ENDP




; OUTPUTS         
PRINT_INT_IN_AX PROC            ; MODIFIES AX, BX, CX, DX   
    MOV CX, 0                   ; NUM DIGITS
    MOV BX, 10                  ; DIVISOR

    TEST AX, AX                 ; IF AX IS NEG, SIGN BIT FLAG IS 1
    JNS POSITIVE_NUM
    MOV NUM_SIGN_FLAG, 1
    NEG AX
    JMP OUTPUT_STACK_START

    POSITIVE_NUM:
    MOV NUM_SIGN_FLAG, 0

    OUTPUT_STACK_START:      
    INC CX
    
    MOV DX, 0                   ; BX = 0010, DX = 0, AX = (DX:AX) / BX, DX = (DX:AX) % BX
    DIV BX                      ; DISCARDING HIGHER 2 BYTES, AND ONLY CONSIDERING 2 BYTE DIVIDENDS
                                
    PUSH DX                     ; PUSH REMAINDER
            
    CMP AX, 0                   ; NO MORE PRINT
    JNE OUTPUT_STACK_START               
    
    CMP NUM_SIGN_FLAG, 1
    JNE STACK_PRINT_LOOP
    MOV DX, -3                  ; ADDING '0' GIVES '-'
    PUSH DX
    INC CX

    STACK_PRINT_LOOP:           ; POP INTO DX (ASSUMING 1 BYTE DIG), MAKE DL ASCII, PRINT DX
    POP DX
    ADD DL, '0'      
    CALL PRINT_CHAR_IN_DL 
    LOOP STACK_PRINT_LOOP

    RET        
ENDP


PRINT_NEWLINE PROC              ; MODIFIES AH, DL
    MOV DL, CR
    MOV AH, 2 
    INT 21H   
    
    MOV DL, LF
    MOV AH, 2
    INT 21H        
    
    RET
ENDP            


PRINT_CHAR_IN_DL PROC           ; MODIFIES AH
    MOV AH, 2
    INT 21H
    RET    
ENDP

        
PRINT_ARRAY PROC                ; MODIFIES SI, DL, AX
    MOV SI, 0
    
    TRAVERSE:
    CMP SI, CURR_SZ
    JGE END_PRINT
    
    MOV DL, ' '
    CALL PRINT_CHAR_IN_DL
          
    MOV AX, ARRAY[SI]
    CALL PRINT_INT_IN_AX
    CALL WORDSIZE_INC_SI

    JMP TRAVERSE
    
    END_PRINT:
    RET    
ENDP   


PRINT_STRING PROC               ; MODIFIES DX, AH
    MOV DX, OFFSET STRING
    MOV AH, 9
    INT 21H
    RET
ENDP




; ARRAY UTILS
WORDSIZE_INC_SI PROC
    INC SI
    INC SI
    RET
ENDP


WORDSIZE_DEC_SI PROC
    DEC SI
    DEC SI
    RET
ENDP


WORDSIZE_INC_DI PROC
    INC DI
    INC DI
    RET
ENDP


WORDSIZE_DEC_DI PROC
    DEC DI
    DEC DI
    RET
ENDP


INC_ARRAY_CURRENT_SIZE PROC     ; MODIFIES DX, CURR_SZ VARIABLE.              
    MOV DX, CURR_SZ
    INC DX
    INC DX
    MOV CURR_SZ, DX
    RET
ENDP




; INSERTION SORT
INSERTION_SORT PROC             ; MODIFIES SI, CX, DI, DX, ARRAY          
    MOV SI, 2                   ; RUN INSERTION SORT ON CONSTRUCTED ARRAY, ARRAY INDEXED 0, CURR_SZ-1.    
    
    INSERTION_LOOP:
    CMP SI, CURR_SZ
    JGE END_SORT

    MOV CX, SI          
    CALL INSERT_INT_IN_ARRAY_SI_IN_SORTED_POSITION
    MOV SI, CX
    CALL WORDSIZE_INC_SI

    JMP INSERTION_LOOP

    END_SORT:
    RET 
ENDP 




; INSERTION SORT UTILS



INSERT_INT_IN_ARRAY_SI_IN_SORTED_POSITION PROC         ; MODIFIES SI, DI, DX AND ARRAY
                                    ; BUBBLE INT IN ARRAY[SI] TO IT'S SORT POSITION
    BUBBLE:
    CMP SI, 2
    JL STOP
    
    MOV DI, SI
    CALL WORDSIZE_DEC_DI 
     
    MOV DX, ARRAY[SI]
    CMP ARRAY[DI], DX
    JLE STOP
    
    CALL SWAP_INTS_IN_ARRAY
    CALL WORDSIZE_DEC_SI
    JMP BUBBLE
    
    STOP:
    RET    
ENDP 


SWAP_INTS_IN_ARRAY PROC             ; MODIFIES DX, ARRAY[SI], ARRAY[DI]
    MOV DX, ARRAY[SI]               ; SWAP VALUES OF ARRAY AT OFFSET SI AND DI
    XOR ARRAY[DI], DX
    MOV DX, ARRAY[DI]
    XOR ARRAY[SI], DX
    MOV DX, ARRAY[SI]
    XOR ARRAY[DI], DX
    
    RET   
ENDP




; BIN SEARCH
BINARY_SEARCH_INT_IN_AX_INDEX_IN_SI PROC        ; MODIFIES AX, BX, BP, SI, CX, DI
    MOV BX, AX                      
    MOV SI, 0
    MOV DI, CURR_SZ

    ITERATION:
    CMP SI, DI                      ; WHILE LEFT <= RIGHT
    JG NOT_IN_ARRAY

    MOV AX, SI                      ; AX = (SI + DI) / 2
    ADD AX, DI
    SHR AX, 1
    
    TEST AX, 1                      ; MAKING INDEX EVEN FOR WORD SIZED INDEX
    JZ EVEN
    DEC AX
    
    EVEN:

    MOV CX, SI                      ; TO INDEX
    MOV SI, AX

    CMP ARRAY[SI], BX               ; ONLY SI, DI ARE INDEXING REGISTERS
    MOV SI, CX
    JL MOVE_RIGHT
    JG MOVE_LEFT
    JMP EQUAL

    MOVE_RIGHT:
    MOV SI, AX
    CALL WORDSIZE_INC_SI

    JMP ITERATION

    MOVE_LEFT:
    MOV DI, AX
    CALL WORDSIZE_DEC_DI

    JMP ITERATION

    EQUAL:
    MOV SI, AX
    JMP DONE

    JMP ITERATION

    NOT_IN_ARRAY:
    MOV SI, -1

    DONE:
    RET
ENDP


END MAIN
