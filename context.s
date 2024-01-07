NO EQU 0x0
YES EQU 0x1
IS_C_AIDED EQU NO
	

	AREA context_related_variables
process_id DCB 0x00
	ALIGN
process_id_of_process_to_run DCB 0x00
	AREA context_related_constants
struct_size DCB 0x0C
stack_pointer_relativ_offset DCB 0x08
	
	AREA context_related_procedures, CODE, READONLY
	PRESERVE8
	IMPORT secure_the_process_stack_pointer_over_c
	IMPORT retrieve_the_process_stack_pointer_over_c

	
retrieve_the_process_stack_pointer PROC
	PUSH{LR}
	BL get_address_of_the_process_stack_pointer
	POP{LR}
	LDR R1, [R0]
	MOV R0, R1
	
	BX LR
	ENDP
		
secure_the_process_stack_pointer PROC
	PUSH{LR}
	PUSH{R1}
	BL get_address_of_the_process_stack_pointer
	POP{R1}
	POP{LR}
	STR R1, [R0]
	
	BX LR
	ENDP

get_address_of_the_process_stack_pointer PROC
	IMPORT process_list
		
	LDR R3, =process_list
	LDR R1, =struct_size
	LDRB R2, [R1]
	MUL R0, R2
	LDR R1, =stack_pointer_relativ_offset
	LDRB R2, [R1]
	ADD R0, R2
	ADD R0, R3
	
	BX LR
	ENDP

take_care_of_stack_pointer_retrieval PROC
	PUSH{LR}
	LDR R2, =process_id
	LDRB R0, [R2]
	IF IS_C_AIDED == YES
	BL retrieve_the_process_stack_pointer_over_c
	ELSE
	BL retrieve_the_process_stack_pointer
	ENDIF
	POP{LR}
	MOV SP, R0
	BX LR
	ENDP
		
take_care_of_stack_pointer_securing PROC
	PUSH{LR}
	
	ADD R1, SP, #24
	LDR R2, =process_id
	LDRB R0, [R2]
	IF IS_C_AIDED == YES
	BL secure_the_process_stack_pointer_over_c
	ELSE
	BL secure_the_process_stack_pointer
	ENDIF
	
	POP{PC}
	ENDP

load_first_context PROC
	EXPORT load_first_context
		
	LDR R1, =process_id
	STRB R0, [R1]
	
	PUSH{R0-R3}
	BL take_care_of_stack_pointer_retrieval
	POP{R0-R3}
	SUB SP, #16
	POP{R4-R11}
	POP{R0-R3, R12, LR}
	
	PUSH{R0-R3, LR}
	BL take_care_of_stack_pointer_securing 
	POP{R0-R3, LR}
	
	BX LR
	ENDP
		
switch_context PROC
	EXPORT switch_context

	LDR R2, =process_id
	STRB R0, [R2]
	
	LDR R2, =process_id_of_process_to_run
	STRB R1, [R2]
	
	PUSH{R0-R3}
	BL take_care_of_stack_pointer_retrieval
	POP{R0-R3}
	SUB SP, #16
	SUB SP, #4
	PUSH{R0-R3, R12}	
	PUSH{R4-R11}

	PUSH{R0-R3, LR}
	BL take_care_of_stack_pointer_securing 
	POP{R0-R3, LR}
	
	LDR R2, =process_id_of_process_to_run
	LDRB R0, [R2]
	BL load_first_context
	
	BX LR
	ENDP
		
	END
		