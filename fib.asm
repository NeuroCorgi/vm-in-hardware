	set r8 20
	set r0 0
	set r1 1
	
:loop
	call print_number
	out 10
	
	set r2 r1
	add r1 r0 r1
	set r0 r2
	
	sub r8 r8 1
	jt r8 loop
	
	halt

:print_number
	push r0
	push r1
	
	set r7 0

:stack_number
	mod r1 r0 10
	call divide

	add r7 r7 1
	push r1
	
	jf r0 print
	jmp stack_number

:print
	pop r2
	call print_digit
	sub r7 r7 1
	jt r7 print

	pop r1
	pop r0
	ret

:print_digit
	add r2 r2 48
	out r2
	ret

:divide
	push r1

	set r1 0

	gt r5 r0 10
	jf r5 divide_end

:divide_loop

	sub r0 r0 10
	add r1 r1 1

	gt r5 r0 10
	jt r5 divide_loop

:divide_end
	set r0 r1
	
	pop r1
	ret
