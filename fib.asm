								; Fibonacci Sequence with String Conversion

	; Initial setup
	set r0 0      ; First Fibonacci number (0)
	set r1 1      ; Second Fibonacci number (1)
	set r2 10     ; Number of Fibonacci numbers to generate

								; Fibonacci calculation loop
:fibonacci_loop
								; Print current Fibonacci number
    call convert_and_print

								; Calculate next Fibonacci number
    add r3 r0 r1    ; r3 = r0 + r1
    set r0 r1       ; r0 becomes previous second number
    set r1 r3       ; r1 becomes new Fibonacci number

								; Decrement counter
    sub r2 r2 1    ; Reduce count by 1

								; Check if we've generated all numbers
    jt r2 fibonacci_loop   ; If count > 0, continue loop

								; Terminate program
	halt


; Utility function to convert number to string and print
:convert_and_print
    ; Assumes number to convert is in r0
    ; Will use r4, r5, r6 as working registers
    set r4 0    ; Digit counter
    set r5 10   ; Divisor for extracting digits

    ; Special case for zero
    jt r0 digit_extract
    out 48      ; ASCII '0'
    ret

:digit_extract
    ; If number is zero, stop extracting
    jf r0 print_digits
    
    ; Extract last digit
    mod r6 r0 r5   ; r6 = r0 % 10
    add r6 r6 48   ; Convert to ASCII
    push r6        ; Save digit on stack
    add r4 r4 1    ; Increment digit count
    
    ; Divide by subtraction
    set r7 0       ; Quotient tracker
:subtract_loop
    gt r8 r0 r5    ; Check if r0 >= 10
    jf r8 digit_done
    sub r0 r0 10  ; Subtract 10
    add r7 r7 1    ; Increment quotient
    jmp subtract_loop

:digit_done
    set r0 r7      ; Update r0 with new quotient
    jmp digit_extract

:print_digits
    ; Print digits from stack
    jf r4 print_done

    ; Pop and print top digit
    pop r6
    out r6
    sub r4 r4 1
    jmp print_digits

:print_done
    ; Print newline
    out 10
    ret
