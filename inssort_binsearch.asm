.MODEL SNALL

.STACK 100H

.DATA
    LF DB 10
    CR DB 13    
    
    ARRAY DB 100 DUP(0)     ; intels 8086 architectures supported registers are bx, si, di, and bp only.
    ARR_MAX_SZ DW 100 
    CURR_SZ DW 0
    NUM_INTS DW 0
    STRING DB "NOT FOUND$"
.CODE


MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    CALL INPUT_INT_IN_AX
    MOV NUM_INTS, AX

    CALL TAKE_NUM_INTS_INPUTS_AND_PUT_IN_ARRAY

    CALL PRINT_NEWLINE
    CALL PRINT_ARRAY

    CALL INSERTION_SORT

    CALL PRINT_NEWLINE
    CALL PRINT_ARRAY 

    CALL PRINT_NEWLINE
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
    
    INPUT_START:
    CALL INPUT_CHAR_IN_AL
         
                                ; IF INPUT AT AL IS EQUAL TO LF, END INPUT
    CMP AL, CR
    JZ INPUT_END
    
                                ; CONVERT TO NUMBER
    SUB AL, 48      
    
                                ; BX = 00[AL], AX = 0010, AX = AX * CX + BX, CX = AX. 
    MOV BL, AL      
    MOV AX, 10           
    MUL CX                  
    ADD AX, BX          
    MOV CX, AX         
      
    JMP INPUT_START
    
    INPUT_END:
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
    MOV ARRAY[SI], AL           ; DISCARDING HIGHER INPUT BYTE
    INC SI
    CALL INC_ARRAY_CURRENT_SIZE

    JMP INPUT_LOOP

    STOP_INPUT:
    RET
ENDP


BIN_SEARCH_INPUT_LOOP PROC          ; MODIFIES AX, BX, BP, SI, DI
    TAKE_INPUT:
    CALL PRINT_NEWLINE
    CALL INPUT_INT_IN_AX
    MOV BX, AX

    CALL PRINT_NEWLINE
    MOV AX, BX
    CALL BINARY_SEARCH_INT_IN_AX_INDEX_IN_SI

    CMP SI, 0
    JL NOT_FOUND
    
    FOUND:
    MOV AX, SI
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
    OUTPUT_STACK_START:      
    INC CX
    
    MOV BX, 10                  ; BX = 0010, AL = AX / BL, AH = AX % BL
    DIV BL                       
                                
    MOV BL, AL                  ; BX = 00[AL], AX = 00[AH], PUSH AX, AX = BX 
    MOV AL, AH
    MOV AH, 0  
    PUSH AX    
    MOV AL, BL  
            
    CMP AL, 0                   ; NO MORE PRINT
    JNE OUTPUT_STACK_START               
    
    STACK_PRINT_LOOP:           ; POP INTO DX (ASSUMING 1 BYTE DIG), MAKE DL ASCII, PRINT DX
    POP DX
    ADD DL, 48      
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


PRINT_SPACE PROC                ; MODIFIES AH, DL
    MOV DL, 32
    CALL PRINT_CHAR_IN_DL   
    
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
    
    MOV DL, " "
    CALL PRINT_CHAR_IN_DL
          
    MOV AL, ARRAY[SI]
    MOV AH, 0
    CALL PRINT_INT_IN_AX
    INC SI 

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



           
; INSERTION SORT
INSERTION_SORT PROC         ; MODIFIES SI, CX, DI, DX, ARRAY          
    MOV SI, 1             ; RUN INSERTION SORT ON CONSTRUCTED ARRAY, ARRAY INDEXED 0, CURR_SZ-1.    
    
    INSERTION_LOOP:
    CMP SI, CURR_SZ
    JGE END_SORT

    MOV CX, SI          
    CALL INSERT_INT_IN_ARRAY_SI_IN_SORTED_POSITION
    MOV SI, CX
    INC SI

    JMP INSERTION_LOOP

    END_SORT:
    RET 
ENDP 




; INSERTION SORT UTILS
INC_ARRAY_CURRENT_SIZE PROC         ; MODIFIES DX, CURR_SZ VARIABLE.              
    MOV DX, CURR_SZ
    INC DX
    MOV CURR_SZ, DX
    RET
ENDP


INSERT_INT_IN_ARRAY_SI_IN_SORTED_POSITION PROC         ; MODIFIES SI, DI, DX AND ARRAY
                                    ; BUBBLE INT IN ARRAY[SI] TO IT'S SORT POSITION
    BUBBLE:
    CMP SI, 1
    JL STOP
    
    MOV DI, SI
    DEC DI  
     
    MOV DL, ARRAY[SI]
    CMP ARRAY[DI], DL
    JLE STOP
    
    CALL SWAP_INTS_IN_ARRAY
    DEC SI
    JMP BUBBLE
    
    STOP:
    RET    
ENDP 


SWAP_INTS_IN_ARRAY PROC             ; MODIFIES DX, ARRAY[SI], ARRAY[DI]
    MOV DL, ARRAY[SI]               ; SWAP VALUES OF ARRAY AT OFFSET SI AND DI
    MOV DH, ARRAY[DI]
    MOV ARRAY[SI], DH
    MOV ARRAY[DI], DL 
    
    RET   
ENDP




; BIN SEARCH
BINARY_SEARCH_INT_IN_AX_INDEX_IN_SI PROC        ; MODIFIES AX, BX, BP, SI, CL, DI
    MOV CL, 2
    MOV BL, AL                      ; DISCARDING INT HIGHER BYTE

    MOV SI, 0
    MOV DI, CURR_SZ

    ITERATION:
    CMP SI, DI                      ; WHILE LEFT <= RIGHT
    JG NOT_IN_ARRAY

    MOV AX, SI                  ; AX = (SI + DI) / 2
    ADD AX, DI  
    DIV CL
    MOV AH, 0
    MOV CX, SI
    MOV SI, AX

    CMP ARRAY[SI], BL           ; ONLY SI, DI ARE INDEXING REGISTERS
    MOV SI, CX
    MOV CL, 2
    JL MOVE_RIGHT
    JG MOVE_LEFT
    JMP EQUAL

    MOVE_RIGHT:
    MOV SI, AX
    INC SI

    JMP ITERATION

    MOVE_LEFT:
    MOV DI, AX
    DEC DI

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



; BIN SEARCH UTILS
   

END MAIN
