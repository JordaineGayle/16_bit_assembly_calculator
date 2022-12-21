;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Problem Statment: Write a program that accepts a mathematical expression and evalute it.            ;
;                                                                                                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Group Members                                   ;
;   ----------------------------------------------- ;
;   Name                ID#                         ;  
;   ----------------------------------------------- ;                           
;   Jordaine Gayle      1800708                     ;
;   Tanjay Lindsay      1900637                     ;
;   Rianna Chin         1901696                     ;
;   Alliah Mendez       1902129                     ;
;   Leigh-Ann Dixon     1908852                     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;defines the prgram enviroment capbilities
.MODEL SMALL 

;stack segment
.STACK 100h

;data segment
.DATA 
    program_name db 10, 13, "Single Digit Calculator Prototype", '$'   
    valid_symbols db 10, 13, "Valid characters )0123456789-*/+(", '$'
    menu db 10, 13, "To end the program press 'esc key on keyboard'", '$'
    user_input_prompt db 10, 13, "Enter a mathematical expression eg (2 + 3 - 1): ", '$'  
    display_expression db 10, 13, "Expression = ", '$' 
    display_result db 10, 13, "Result: ", '$'
    new_line db 10, 13, "", '$'
    infix_expression db 100, ?, 100 dup('0')
    posfix_expression db 100, ?, 100 dup('0')
    posfix_size db 0h
    infix_size db 0h
    operators_count db 0h
    precedence db 0, 0 
    calculated_value dw 0000h
    number_is_signed db 0h
    

;code segment   
.CODE
    
    ;program start
    START:
        
        ;intialized data segment
        call load_data_segment
        
        ;output main program instructions
        call print_program_instruction
        
        ;program loop
        call main
        
        
        ;loading data segment in accumulator
        load_data_segment:
            mov ax, @DATA
            mov ds, ax
            ret
        
        ;program loop            
        main:
            
            ;reset the general registers
            call reset_registers
            
            ;prompt user for input
            call accept_user_input
            
            ;convert user input to posfix expression for ease of processing
            call convert_to_posfix_expression
            
            ;evaluting posfix expression after entry
            call evaluate_posfix_expression
            
            ;print's the result of the evaluation back to the user
            call process_ascii_conversion
            
            ;prints sub menu options
            call menu_options
            
            ;reset program variables
            call reset_variables
            
            ;re run program until user press the escape key
            jmp main
        
        ;prints the actual program instruction      
        print_program_instruction:
            xor dx, dx
            xor ax, ax
            mov dx, offset [program_name]
            mov ah, 09h
            int 21h
            
            xor dx, dx
            xor ax, ax
            mov dx, offset [valid_symbols]
            mov ah, 09h
            int 21h
            ret
        
        ;prints sub menu     
        menu_options: 
            xor dx, dx
            xor ax, ax
            mov dx, offset [menu]
            mov ah, 09h
            int 21h
            ret
            
        ;resets the actual registers     
        reset_registers:
            xor dx, dx
            xor cx, cx
            xor bx, bx
            xor ax, ax
            ret
         
        ;resets the actual program variables   
        reset_variables:
            mov operators_count[0], 0h
            mov precedence[0], 0h
            mov precedence[1], 0h 
            mov [calculated_value], 0000h
            call reset_infix_expression
            call reset_posfix_expression
            ret
        
        ;resets the infix expression for the nth execution
        reset_infix_expression:
            xor bx, bx
            mov bl, infix_size[0]
            mov [infix_expression+bx], 0h
            dec infix_size[0]
            cmp infix_size[0], 0h
            jne reset_infix_expression
            ret
        
        ;resets the posfix expression for the nth execution
        reset_posfix_expression:
            xor bx, bx
            mov bl, posfix_size[0]
            mov [posfix_expression+bx], 0h
            dec posfix_size[0]
            cmp posfix_size[0], 0h
            jne reset_posfix_expression
            ret
        
        ;prompts and accepts the actual user input
        accept_user_input: 
            call print_new_line 
            call print_new_line
            call menu_options  
            xor dx, dx
            xor ax, ax
            mov dx, offset [user_input_prompt]
            mov ah, 09h
            int 21h
            xor cx, cx
            call read_user_input
            ret
        
        ;validates and stores the user input
        read_user_input:
            xor ax, ax
            mov ah, 07h
            int 21h
            
            cmp al, 1Bh
            je exit
            
            cmp al, 20h
            je  print_character_without_increment
            
            cmp al, 08h
            je  print_character_without_increment
            
            cmp al, 02Ch
            je  read_user_input
            
            cmp al, 02Eh
            je  read_user_input
            
            cmp al, 28h
            jl  handle_end_of_input
            
            cmp al, 39h
            jg  read_user_input
            
            jmp print_character_and_increment_counter
        
        ;return program control back to the operating system
        exit:
            call reset_registers
            mov ah, 4ch
            int 21h
            ret
        
        ;prints the actual character, subtracts 30h and save to infix variable   
        print_character_and_increment_counter:
            xor dx, dx
            xor bx, bx
            mov dl, al
            mov ah, 02h
            int 21h
            cmp al, 30h
            jge format_character
            mov bx, cx
            mov infix_expression[bx], al
            inc cx
            jmp read_user_input
        
        ;subtractrs 30h from the user input if it is a numerical  
        format_character:
            sub al, 30h
            mov bx, cx
            mov infix_expression[bx], al
            inc cx
            jmp read_user_input
        
        ;print character to the screen without saving
        print_character_without_increment:
            xor dx, dx
            mov dl, al
            mov ah, 02h
            int 21h
            jmp read_user_input 
        
        ;decrement the character counter when back space is pressed
        decrement_counter_on_backspace:
            dec cx
            jmp print_character_without_increment
        
        ;prevent further user input when enter key is pressed   
        handle_end_of_input:
            cmp al, 0DH
            jne read_user_input
            xor bx, bx
            mov bx, cx
            mov infix_expression[bx], 24h
            mov [infix_size], cl
            ret
        
        ;converts the infix expression to a posfix expression
        convert_to_posfix_expression:
            xor cx, cx
            mov si, offset [infix_expression]
            mov di, offset [posfix_expression]
            call read_and_compare_byte
            ret
        
        ;read and compare each byte sequence in infix expression
        read_and_compare_byte:
            xor ax, ax
            mov al, byte ptr[si]
            
            cmp byte ptr[si], 9h
            jle handle_infix_numerical_byte_sequence
            
            cmp byte ptr[si], 28h
            je push_left_bracket_to_stack
            
            cmp byte ptr[si], 29h
            je handle_right_bracket_operation 

            cmp byte ptr[si], 2Ah
            je handle_operator_operation
            
            cmp byte ptr[si], 2Bh
            je handle_operator_operation
            
            cmp byte ptr[si], 2Dh
            je handle_operator_operation
            
            cmp byte ptr[si], 2Fh
            je handle_operator_operation
            
            call calculate_and_increment_infix
            
            cmp cl, [infix_size]
            jl read_and_compare_byte
            
            cmp operators_count, 0h
            jne empty_stack

            ret
        
        ;empty the stack and update posfix expression if stack not empty on end of infix expression   
        empty_stack:
            xor dx, dx
            pop dx
            mov byte ptr[di], dl
            inc posfix_size[0]
            call determine_posfix_index   
            dec operators_count
            cmp operators_count, 0h
            jne empty_stack
            ret 
        
        ;pushes numerical value to the posfix expression    
        handle_infix_numerical_byte_sequence:
            xor dx, dx 
            mov dl, byte ptr[si]
            mov byte ptr[di], dl
            inc posfix_size[0]
            call determine_posfix_index
            call calculate_and_increment_infix
            jmp read_and_compare_byte
        
        ;pushing left parenthesis to the operator stack  
        push_left_bracket_to_stack:
            xor dx, dx
            mov dl, byte ptr[si]
            push dx
            inc operators_count
            call calculate_and_increment_infix
            jmp read_and_compare_byte
            
        ;reading operators from the stack and push to the posfix expression
        handle_right_bracket_operation:
            xor dx, dx
            pop dx
            dec operators_count
            cmp dx, 28h
            jne if_not_left_braket_push_to_posfix
            call calculate_and_increment_infix
            jmp read_and_compare_byte
            ret
         
        ;push until left bracket is encountered   
        if_not_left_braket_push_to_posfix:
            mov byte ptr[di], dl
            inc posfix_size[0]
            call determine_posfix_index
            jmp handle_right_bracket_operation
            ret
        
        ;push operator to the stack if lesser than stack or break them on posfix expression    
        handle_operator_operation:
            cmp operators_count, 0h
            jne push_operator_to_posfix_if_less_than_stack_top
            xor dx, dx
            mov dl, byte ptr[si]
            push dx
            inc operators_count
            call calculate_and_increment_infix
            jmp read_and_compare_byte
        
        ;pop operator on stack top and compare with incoming character
        push_operator_to_posfix_if_less_than_stack_top:
            xor ax, ax
            xor dx, dx
            xor bx, bx
            pop ax
            mov dl, byte ptr[si]
            xor bx, bx
            call determine_precedence
            mov precedence[0], bl
            mov dx, ax
            xor bx, bx
            call determine_precedence
            mov precedence[1], bl
            xor dx, dx
            mov dh, precedence[0]
            mov dl, precedence[1]
            cmp dh, dl
            mov precedence[0], 00h
            mov precedence[1], 00h
            jle push_operator_to_posfix_expression
            push ax
            xor dx, dx
            mov dl, byte ptr[si]
            push dx
            inc operators_count
            call calculate_and_increment_infix
            jmp read_and_compare_byte
            
        
        ;pushing operator to posfix expression
        push_operator_to_posfix_expression:
            mov byte ptr[di], al
            inc posfix_size
            dec operators_count
            call determine_posfix_index
            jmp handle_operator_operation
            ret
        
        ;determine operator precedence
        determine_precedence:
            cmp dx, 2Ah
            je highest_order
            
            cmp dx, 2Fh
            je highest_order
            
            cmp dx, 2Dh
            je low_order
            
            cmp dx, 2Bh
            je low_order
            
            ret
        
        ;return 2 for high precedence operator    
        highest_order:
            xor bx, bx
            mov bx, 2h
            ret
        
        ;return 1 for low precedence operator   
        low_order:
            xor bx, bx
            mov bx, 1h
            ret
        
         ;increment posfix index
        determine_posfix_index:
            inc di
            ret
        
        ;increment infix index and program counter    
        calculate_and_increment_infix:
            inc si
            inc cx
            ret  
       
        ;evaluating posfix expression    
        evaluate_posfix_expression:
            xor cx, cx 
            mov di, offset [posfix_expression]
            call read_posfix_expression
            ret
        
        ;read posfix expression and perform calulations when operator is encountered and store result in variable for fruther display   
        read_posfix_expression:
            cmp byte ptr [di], 2Ah
            je perform_multiplication
            
            cmp byte ptr [di], 2Fh
            je perform_division
            
            cmp byte ptr [di], 2Dh
            je perform_subtraction
            
            cmp byte ptr [di], 2Bh
            je perform_addition
            
            inc cx
            cmp cl, posfix_size 
            jl push_number_to_stack
            
            mov calculated_value, 0000h
            xor dx, dx
            pop dx
            mov calculated_value, dx
            xor dx, dx
            cmp number_is_signed[0], 1h
            je  process_signed_value
            ret
            
        
        
        ;pushes a numerical value to the stack    
        push_number_to_stack:
            xor ax, ax
            mov al, byte ptr [di]
            push ax
            call determine_posfix_index
            jmp read_posfix_expression

        ;performs an addition operation on the last two elements on the stack
        perform_addition:
            xor ax, ax
            xor dx, dx 
            pop dx
            pop ax
            add ax, dx
            push ax
            call handle_signed
            xor ax, ax
            xor dx, dx
            inc cx
            call determine_posfix_index
            jmp read_posfix_expression
            ret
        
        ;performs a minus operation on the last two elements on the stack
        perform_subtraction:
            xor ax, ax
            xor dx, dx
            pop dx
            pop ax
            sub ax, dx
            push ax
            call handle_signed
            xor ax, ax
            xor dx, dx 
            inc cx
            call determine_posfix_index
            jmp read_posfix_expression
            ret
            
        ;performs an division operation on the last two elements on the stack
        perform_division:
            xor ax, ax
            xor dx, dx
            pop dx
            pop ax
            div dl
            push ax
            call handle_signed
            xor ax, ax
            xor dx, dx
            inc cx
            call determine_posfix_index
            jmp read_posfix_expression
            ret
            
        ;performs an multiplication operation on the last two elements on the stack    
        perform_multiplication:
            xor ax, ax
            xor dx, dx
            pop dx
            pop ax
            mul dx
            push ax
            call handle_signed
            xor ax, ax
            xor dx, dx
            inc cx 
            call determine_posfix_index
            jmp read_posfix_expression
            ret
            
        process_signed_value:
            xor ax, ax
            xor dx, dx 
            mov dx, 0FFFFh
            mov ax, [calculated_value] 
            sub dx, ax 
            add dx, 1
            mov [calculated_value], dx
            xor ax, ax
            xor dx, dx
            ret
            
        handle_signed:
           js set_signed_value
           jns set_not_signed_value
           ret 
        
        set_signed_value:
            mov [number_is_signed], 1h
            ret
        
        set_not_signed_value:
            mov [number_is_signed], 0h
            ret 
       
       ;prints a new line to the console     
       print_new_line:
            xor dx, dx
            xor ax, ax
            mov dx, offset new_line
            mov ah, 09h
            int 21h
            ret 
       
       ;converts ascii to decimal and display results to the user
       process_ascii_conversion:
            call print_new_line
            call print_new_line
            xor dx, dx
            mov dx, offset display_result
            mov ah, 9h
            int 21h
            call handle_negative_sign
            xor cx, cx
            xor bx, bx
            mov bx, 10d
            xor ax, ax
            mov ax, [calculated_value]
            call convert_to_ascii
            xor ax, ax
            ret
        
       ;ascii to decimal converter
       convert_to_ascii:
            xor dx, dx
            div bx
            add dx, 30h
            push dx
            inc cx
            cmp ax, 0h
            jnz convert_to_ascii
            je display_character_on_stack
            ret
        
       ;reads characters from the stack and display to user
       display_character_on_stack:
             
            xor dx, dx
            xor ax, ax
            pop dx
            mov ah, 02h
            int 21h
            dec cx 
            cmp cx, 0h
            jne display_character_on_stack 
            ret
       
       handle_negative_sign:
            cmp number_is_signed[0], 1h
            je print_negative_sign
            ret
                 
       print_negative_sign:
           xor dx, dx 
           xor ax, ax
           mov dx, 2Dh
           mov ah, 02h
           int 21h
           ret
            
            
    END START