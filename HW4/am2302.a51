	ORG 0
	MOV R0,#250;
	DJNZ R0,$
	MOV R0,#250;
	DJNZ R0,$
	
	// start read AM2302	
	MOV 0E1H,#01H;   
	
j0:	MOV A,0E1H
	CJNE A,#11H,j0;
	
	// read AM2302 data
		
	MOV A,0E2H	
	MOV A,0E3H
	MOV A,0E4H
	MOV A,0E5H
	MOV A,0E6H
	
	//sim end
  JMP 0B16H
  
	END