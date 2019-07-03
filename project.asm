StSeg Segment
    DB 100H DUP (?)
StSeg ENDS

DtSeg Segment
    
    ;reading file
    fileHandler DW ?
    buffer DB 30000  DUP (?)
    fileName DB 'data.txt',0
       
       
    ;output
    outbuffer DB 1000 DUP (?)
    outFile DB 'out.txt',0
    outlen DW 0
    outHandler DW ?
    
    ;print IEEE values.
    p_exp DW ?
    p_f DW ?
    
    ;info of number of occurness of each digit at begining of datas.
    count_of_digits DW 10 DUP (0)
    count_of_numbers DW 0 ;number of all datas in normal format.
    count_float DW ? ;number of all datas in IEEE format. 
    curr_count DW ?
       
    
    ;change integer into IEEE format.
    input DW ?
    digits DB 100 DUP (?)
    curr_len DW ?
    
    ;preprocess of each of digits from 1,...,9 in IEEE format.
    values DW 11 DUP (?) 
    float_ten DW ?
    float_one DW ?
    
    ;storing floats in data at this array in IEEE format.
    floats DW 10000 DUP (?)
    leading DW ? ; will store leading digit of input as function called.
    
    ;change a float number in base 10 two IEEE format.
    address DW ?
    i DW 0
    j DW 0
    L DW 0
    R DW 0
    ptr1 DW 0 
    ptr2 dW 0
    integer_part DW 0
    
    ten DW 10
    two DW 2
    
    curr DW ?
    carry DB ?
    
    ;for making IEEE format.
    base2 DB 100 DUP (?) 
    length1 DW 0
    length1_cpy DW 0
    length2 DW 0
    
    result DW 0
    count DW 0
    prec DW 0
    
    ;float computing
    f1 DW 0
    f2 DW 0
    f12 DW 0
    
    ;mul
    m_exp1 DW ?
    m_exp2 DW ?
    m_f1 DW ?
    m_f2 DW ?
    
    ;division
    d_exp1 DW ?
    d_exp2 DW ?
    d_f1 DW ?
    d_f2 DW ?
    
    
DtSeg ENDS

CdSeg Segment
    ASSUME CS:CdSeg, DS:DtSeg, SS:StSeg
start:
    MOV AX, DtSeg
    MOV DS, AX
    
    CALL INITIALIZE
    
    CALL READ_FLOATS
    
    CALL SHOW_RESULT
    
    CALL STORE_RESULT
    
    MOV AH, 4CH
    MOV AL, 0
    INT 21H             

STORE_RESULT PROC NEAR
    
    MOV  AH, 3CH
    MOV  CX, 0
    MOV  DX, offset outFile
    INT  21H  

    MOV  outHandler, AX

    MOV  AH, 40H
    MOV  BX, outHandler
    MOV  CX, outlen
    MOV  DX, offset outbuffer
    INT 21H

    MOV  AH, 3EH
    MOV  BX, outHandler
    INT 21H
    
    RET
STORE_RESULT ENDP    
    
SHOW_RESULT PROC NEAR
    LEA BX, outbuffer
    MOV SI, outlen
    MOV DL, '$'
    MOV [BX][SI], DL
    
    LEA DX, outbuffer
    MOV AH, 09H
    INT 21H
    
    RET
SHOW_RESULT ENDP
    
;print input. number. just between [0, 1] 
;byte by byte in outbuffer.
PRINT_IEEE PROC NEAR
    
    ;if it's equal to zero.
    CMP input, 0
    
    JNE pic1
                         
    MOV DL, '0'                     
    CALL PRINT_OUT_BUFFER
    RET
    
    ;if it's equal to one.
    pic1:
    MOV AX, float_one
    JNE pic2
    
    MOV DL, '1'
    CALL PRINT_OUT_BUFFER 
    RET
    
    pic2:
    
    MOV AX, input
    MOV p_exp, AX
    SHR p_exp, 10
    SUB p_exp, 15
    
    NEG p_exp
    
    ;now power is in p_exp.
    
    MOV AX, input
    MOV p_f, AX
    SHL p_f, 6
    SHR p_f, 6
    MOV AX, 1
    SHL AX, 10
    ADD p_f, AX
    SHL p_f, 5
    
    DEC p_exp
    
    MOV CX, p_exp
    
    SHR p_f, CL
    
    ;now the float part is in p_f.
    
    
    ;changing base.
    MOV CX, 0
    for16:
        CMP CX, 4
        JE end_for16
        
        MOV AX, p_f
        MUL ten
        
        MOV p_f, AX
        ADD DL, '0'
        
        CALL PRINT_OUT_BUFFER
        
        CMP CX, 1
        JNE pfc3
        
        MOV DL, '.'
        CALL PRINT_OUT_BUFFER   
       
        pfc3:
           
        INC CX
        
        JMP for16
    end_for16:
        
    
    RET    

PRINT_IEEE ENDP    
    
;storing 1,2, ..., 9, 10 in values (IEEE format)
INITIALIZE PROC NEAR
    
    MOV CX, 1
    for12:
        
        CMP CX, 11
        JE end_for12
        
        MOV input, CX
        
        PUSH CX
        
        CALL CHANGE_INT_TO_TWO
        
        POP CX
        
        LEA BX, values
        
        MOV SI, CX
        SHL SI, 1
        
        MOV AX, result
        MOV [BX][SI], AX
        
        INC CX
        JMP for12
    
    end_for12:
    
    MOV SI, 2
    LEA BX, values
    MOV AX, [BX][SI]
    MOV float_one, AX
    
    MOV SI, 20
    LEA BX, values
    MOV AX, [BX][SI]
    MOV float_ten, AX
    
    
    RET    

INITIALIZE ENDP
    
;find leading zero of input (IEEE)
;this function first multiply number by 10 until it get's bigger or equal to one.
;the divide number by 10 until it comes between [1, 10)
;and then 1st digit is what we want.

FIND_LEADING_DIGIT PROC NEAR
    
    for13:
        
        MOV AX, input
        CMP AX, float_one
        JNB end_for13
        
        MOV AX, input
        MOV f1, AX
        
        MOV AX, float_ten
        MOV f2, AX
        
        CALL MUL_FLOAT
        MOV AX, f12
        MOV input, AX 
    
        JMP for13
        
    end_for13:
    
    for14:
        MOV AX, input
        CMP AX, float_ten 
        JB end_for14
        
        MOV AX, input
        MOV f1, AX
        
        MOV AX, float_ten
        MOV f2, AX
        
        CALL DIV_FLOAT
        MOV AX, f12
        MOV input, AX
         
        JMP for14 
    end_for14:
    
    ;here we check what's the biggest integer n in [1, 9] which is less than or equal to number.
    
    MOV SI, 18
    
    for15:
        LEA BX, values
        MOV AX, [BX][SI]
        
        CMP AX, input
        JNA end_for15
        
        SUB SI, 2 
        
        JMP for15
    
    end_for15:
    
    SHR SI, 1
    
    MOV leading, SI
        
    RET

FIND_LEADING_DIGIT ENDP
    
;will divide f1/f2 and result in f12
;at first we find exp of result
;then we divide float parts of f1 and f2 and do some carry things if neccessary.

DIV_FLOAT PROC NEAR                 
    
    MOV f12, 0
    
    ;if f1 is zero.
    
    CMP f1, 0
    JNE dfc
    
    MOV f12, 0
    RET
    
    dfc:
              
              
    MOV AX, f1
    MOV d_exp1, AX
    SHR d_exp1, 10
    
    MOV AX, f2
    MOV d_exp2, AX
    SHR d_exp2, 10
    
    MOV AX, d_exp1
    ADD AX, 15
    SUB AX, d_exp2
    MOV d_exp2, AX
    
    
    MOV AX, f1
    MOV d_f1, AX
    SHL d_f1, 6
    SHR d_f1, 6
    
    MOV AX, 1
    SHL AX, 10
    ADD d_f1, AX
    
    
    MOV AX, f2
    MOV d_f2, AX
    SHL d_f2, 6
    SHR d_f2, 6
    
    MOV AX, 1
    SHL AX, 10
    ADD d_f2, AX
    
    
    MOV AX, d_f1
    MOV DX, 0
    DIV d_f2
    
    MOV f12 , AX
    MOV d_f1, DX
    
    MOV CX, 11
   
    for11:
        
        CMP CX, 0
        JE end_for11
        
        MOV AX, f12
        ADD f12, AX
        
        MOV AX, d_f1
        ADD d_f1, AX
        
        MOV AX, d_f1
        MOV DX, 0
        DIV d_f2
        
        MOV d_f1, DX
        ADD f12, AX
        
        DEC CX
    
        JMP for11
    
    end_for11:
    
    MOV AX, 1
    SHL AX, 11
    
    CMP f12, AX
    JL d_not_carry
    
    SHR f12, 1
    INC d_exp2
    
    d_not_carry:
    DEC d_exp2
    
    SHL f12, 6
    SHR f12, 6
    SHL d_exp2, 10
    
    MOV AX, d_exp2
    ADD f12, AX
    
    RET
    
DIV_FLOAT ENDP

    
;will multiply f1, f2 and result in f12
MUL_FLOAT PROC NEAR
    
    MOV f12, 0
    
    ;if one of f1 or f2 is equal to zero.
    
    CMP f1, 0
    JNE mfc1
    
    MOV f12, 0
    RET
    
    mfc1:
    CMP f2, 0
    JNE mfc2
    
    MOV f12, 0
    RET
    
    mfc2:
    
    MOV AX, f1
    MOV m_exp1, AX
    SHR m_exp1, 10
    
    MOV AX, f2
    MOV m_exp2, AX
    SHR m_exp2, 10
    
    ;f12_exp is ready.
    MOV AX, m_exp1
    ADD m_exp2, AX
    SUB m_exp2, 15
    
    
    MOV AX, f1
    MOV m_f1, AX 
    SHL m_f1, 6
    SHR m_f1, 6
    
    MOV AX, 1
    SHL AX, 10
    ADD m_f1, AX
    
    MOV AX, f2
    MOV m_f2, AX
    SHL m_f2, 6
    SHR m_f2, 6
    
    MOV AX, 1
    SHL AX, 10
    ADD m_f2, AX
    
    
    MOV AX, m_f1
    MUL m_f2
    
    SHR AX, 10
    SHL DX, 6
    ADD AX, DX
    
    MOV DX, 1
    SHL DX, 11
    
    CMP AX, DX
    JL m_not_carry
    
    SHR AX, 1
    INC m_exp2
    
        
    m_not_carry:
    
    SHL AX, 6
    SHR AX, 6
    
    SHL m_exp2, 10
    ADD AX, m_exp2
    
    MOV f12, AX
    
    
    RET
MUL_FLOAT ENDP    

;store DL in outbuffer
PRINT_OUT_BUFFER PROC NEAR
    
    LEA BX, outbuffer
    MOV SI, outlen
    MOV [BX][SI], DL
    INC outlen 
    
    RET
PRINT_OUT_BUFFER ENDP    
    
;a function that read floats from buffer and store them in IEEE format in array floats.
;also store number of occurness of integers [1, 9] as leading digit.
READ_FLOATS PROC NEAR
    
    MOV AH, 3DH
    MOV AL, 0
    LEA DX, fileName
    INT 21H
    
    MOV fileHandler, AX
    
    
    MOV AH, 3FH    
    MOV BX, fileHandler
    MOV CX, 32000
    LEA DX, buffer
    INT 21H
    
    while1:
        
        MOV AX, i
        MOV j, AX 
        
        while2:
            LEA BX, buffer
            MOV SI, j
            MOV DL, [BX][SI]
        
            CMP DL, 13
        
            JE end_while2
            
            INC j
        
            JMP while2
            
        end_while2:
                                                                            
                                                                            
        ;solve will read float number in addres [i, j) and return in result.
        ;address of data should be in address
        
        LEA BX, buffer
        MOV address, BX
        CALL CHANGE_BASE_FROM_TEN_TO_TWO
        
        LEA BX, floats
        MOV SI, count
        MOV AX, result
        MOV [BX][SI], AX
        
        MOV input, AX
        
        PUSH CX
        
        CALL FIND_LEADING_DIGIT
        
        LEA BX, count_of_digits
        MOV SI, leading
        ADD SI, SI
        
        MOV AX, [BX][SI]
        INC AX
        MOV [BX][SI], AX
        INC count_of_numbers
        
        
          
        
        POP CX
        
        ADD count, 2
        
        ADD j, 2
        
        MOV AX, j
        MOV i, AX
        
        ;check to reach end of file.
        LEA BX, buffer
        MOV SI, i
        MOV DL, [BX][SI]
        CMP DL, 0
        JE end_while1
        CMP DL, 10
        JE end_while1
        CMP DL, 13
        JE end_while1
        
        JMP while1
    
    end_while1:
    
    MOV AX, count_of_numbers
    MOV input, AX
    CALL CHANGE_INT_TO_TWO
    MOV AX, result
    MOV count_float, AX 
    MOV CX, 2

    
    for_final:
        
        CMP CX, 20
        JE end_for_final
        
        LEA BX, count_of_digits
        MOV SI, CX
        MOV AX, [BX][SI]
        MOV curr_count, AX
        MOV AX, SI
        SHR AX, 1
        
        
        MOV DX, AX
        ADD DL, '0'
        CALL PRINT_OUT_BUFFER
        
        
        MOV DL, ' '
        CALL PRINT_OUT_BUFFER
        
        MOV AX, curr_count
        MOV input, AX
        
        PUSH CX
        
        CALL CHANGE_INT_TO_TWO
        
        
        MOV AX, result
        MOV f1, AX
        
        MOV AX, count_float
        MOV f2, AX
        
        CALL DIV_FLOAT
        MOV AX, f12
        MOV input, AX        
        
        
        CALL PRINT_IEEE
        
        MOV DL, 13
        CALL PRINT_OUT_BUFFER
        
        MOV DL, 10
        CALL PRINT_OUT_BUFFER 
        
        POP CX
        
        ADD CX, 2
        JMP for_final
    end_for_final:
    
    
    RET

READ_FLOATS ENDP

;int stored in input
; will be in format IEEE at result.
CHANGE_INT_TO_TWO PROC NEAR
    
    MOV curr_len, 0
    
    MOV AX, input
    MOV curr, AX
    
    ;if number is 0.
    CMP AX, 0
    JNE citt_continue
    
    MOV result, 0
    RET
    
    citt_continue:
    
    
    for9:
        CMP curr, 0
        JE end_for9
        
        MOV AX, curr
        MOV DX, 0
        
        DIV ten
        
        MOV curr, AX
        
        INC curr_len
        
        JMP for9
    
    end_for9:
    
    MOV AX, input
    MOV curr, AX
    
    MOV SI, curr_len
    
    for10:
        CMP curr, 0
        JE end_for10
        
        MOV AX, curr
        MOV DX, 0
        
        DIV ten
        
        MOV curr, AX
        
        ADD DL, '0'
        
        DEC SI
        LEA BX, digits
        
        MOV [BX][SI], DL
        
        JMP for10
    
    end_for10:
            
    MOV DL, '.'
    MOV SI, curr_len
    LEA BX, digits
    MOV [BX][SI], DL
    
    MOV DL, '0'
    INC SI
    MOV [BX][SI], DL
    
    LEA BX, digits
    MOV address, BX
    
    MOV i, 0
    INC SI
    MOV j, SI
    
    CALL CHANGE_BASE_FROM_TEN_TO_TWO        
    
    RET

CHANGE_INT_TO_TWO ENDP    
; read flaot in adress [i, j) in place address (adress + i to address + j)

CHANGE_BASE_FROM_TEN_TO_TWO PROC NEAR
    
    MOV AX, i
    MOV L, AX
    MOV ptr1, AX
    
    MOV AX, j
    MOV R, AX
    
  
    MOV integer_part, 0
    
    
    for1:
        ;LEA BX, buffer
        MOV BX, address
        
        MOV SI, ptr1
        MOV DL, [BX][SI]
        
        CMP DL, '.'
        JE end_for1
                
        SUB DL, '0'
        MOV DH, 0
        
        MOV curr, DX
        
        MOV AX, integer_part
        MUL ten
        ADD AX, curr
        MOV integer_part, AX
        
        INC ptr1
        JMP for1      
    
    end_for1:
    
    
    MOV length1, 0
    MOV length2, 0
    
    for2:
        CMP integer_part, 0
        JE end_for2
        
        MOV AX, integer_part
        MOV DX, 0
        DIV two
        
        
        MOV integer_part, AX
        
        PUSH DX
        
        INC length1
        
        JMP for2
    
    end_for2:
    
    MOV AX, length1
    MOV length1_cpy, AX
    
    MOV SI, 0
    for3:
    
        CMP length1, 0
        JE end_for3
        
        POP DX
        LEA BX, base2
        MOV [BX][SI], DL
        
        INC SI
        DEC length1
        
        JMP for3
    
    end_for3:
        
    
    MOV AX, length1_cpy
    MOV length1, AX
    
    MOV CX, 0
    
    
    
    for4:
        CMP CX, 24
        JE end_for4
        
        MOV AX, R
        MOV ptr2, AX
        DEC ptr2    
    
        
        MOV carry, 0
        
        for5:
            ;LEA BX, buffer
            MOV BX, address
            
            MOV SI, ptr2
            MOV DL, [BX][SI]
            
            CMP DL, '.'
            JE end_for5
            
            SUB DL, '0'
            ADD DL, DL
            ADD DL, carry
            
            CMP DL, 10
            JGE hasCarry
            
            MOV carry, 0
            JMP end_if
            
            hasCarry:
            MOV carry, 1
            SUB DL, 10
            
            end_if:         
            ADD DL, '0'
            MOV [BX][SI], DL
            
            DEC ptr2
            
            JMP for5
        
        end_for5:
        
        MOV SI, CX
        ADD SI, length1
        LEA BX, base2
        
        CMP carry, 1
        JE add1
        
        MOV DL, 0
        MOV [BX][SI], DL
        JMP end_if2
        
        add1:
        MOV DL, 1
        MOV [BX][SI], DL
        
        end_if2:
        
        
        INC CX
        
        JMP for4
                
    end_for4:
    
    ;now number is in base2. length1 for before '.' and 24 decimal number after that.
    CALL MAKE_IEEE    
    
    RET
CHANGE_BASE_FROM_TEN_TO_TWO ENDP

;will store IEEE format of number store in base2 (length1, 24) into result.
MAKE_IEEE PROC NEAR
    
    
    CMP length1, 0
    JE lessThanOne
    
    
    MOV AX,length1
    DEC AX
    MOV result, AX
    
    ADD result, 15
    
    SAL result, 10
    
    
    MOV SI, 1
    LEA BX, base2
    
    MOV CX, 0
    MOV prec, 0
    
    for6:
        CMP CX, 10
        JE end_for6
        
        LEA BX, base2
        
        MOV DL, [BX][SI]
        
        CMP DL, 0
        JE __nothing
        
        MOV AX, SI
        MOV AH, 10
        SUB AH, AL
                 
        MOV BX, CX         
        MOV CL, AH
                 
        MOV DX, 1
        SAL DX, CL
        
        MOV CX, BX 
        
        ADD result, DX     
        
        __nothing:
        
        INC SI
        INC CX
    
        JMP for6
        
    
    end_for6:
          
    
    RET
    
    
    lessThanOne:
    
    LEA BX, base2
    MOV SI, 0
    
    for7:
        
        CMP SI, 24
        JE end_for7
        
        MOV DL, [BX][SI]
        CMP DL, 1
        
        JE end_for7
        
        
        INC SI
        
        JMP for7
    
    end_for7:
    
    INC SI
    
    CMP SI, 15
    JL nothing2
    
    MOV SI, 15
    
    nothing2:
    
    MOV curr, SI
    
    NEG SI
    MOV result, SI
    
    ADD result, 15
    SAL result, 10
    
    
    MOV SI, curr
    LEA BX, base2
    
    MOV CX, 0
    for8:
            
        CMP CX, 10
        JE end_for8     
            
        LEA BX, base2
        MOV DL, [BX][SI]
        
        
        CMP DL, 0
        JE nothing3
        
         
        MOV AX, CX
        MOV AH, 9
        SUB AH, AL
        
        MOV DX, 1
        
        MOV BX, CX
        MOV CL, AH
        SAL DX, CL
        MOV CX, BX
        
        ADD result, DX  
        
        nothing3:
        
        INC CX
        INC SI
        
        JMP for8 
    
    end_for8: 
    
    RET

MAKE_IEEE ENDP    

CdSeg ENDS
END start
