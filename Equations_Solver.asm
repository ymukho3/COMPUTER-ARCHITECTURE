# Yara Darabumukho 1211269 and Enas Qutit 1210236
# Section 2
.data
    opI: .asciiz "\nIf u want to enter input file name press c,C and e,E for exit\n" 
    
    opSF: .asciiz "\nFile or Screen printing\n"
    opD: .asciiz "\nEnter a valid char!!!"
    
    printDiv: .asciiz " / "  
    bufferINT: .space 20  # Buffer to store the number
    outFile: .asciiz "output.txt"
    
    
    Darray: .space 40   # D matrix 
    DD: .space 40      # referace  
    DXYZ: .word 0, 0, 0, 0  # to store the outputs of the Cramer?s Rule D, Dx, Dy, Dz if exisit 
    out: .space 16	 # matrix outputs 
    
    divbyzero: .asciiz "Error: Division by zero\n"
    PrintX: .asciiz "\n\n\nX = "
    PrintY: .asciiz "\nY = "
    PrintZ: .asciiz "\nZ = " 
    
    prompt_msg: .asciiz "\nEnter file path: "        # Prompt message for the user
    buffer: .space 30                             # Buffer to store the file path
    file_content: .space 148                       # Buffer to store the lines read from the file
    error_open_msg: .asciiz "Error:  character a is not allowed \n"  # Error message
    empty_input_error: .asciiz "Error: No input \n" # Empty input error message
    file_open_error: .asciiz "Error: can't open file \n" 
    

.text
j menu 

# Reading from the input File 
  
main:
    # Clear buffer (30 bytes)
    la $t1, buffer      # Load address of buffer into $t1
    li $t2, 30          # Set counter to 30 
    li $t0, 0           
clear_buffer:
    beq $t2, 0, clear_file_content 
    sb $t0, 0($t1)     # Store zero at address in $t1
    addi $t1, $t1, 1   
    subi $t2, $t2, 1   
    j clear_buffer     # Repeat until counter is zero

# Clear file_content (128 bytes)
clear_file_content:
    la $t1, file_content # Load address of file_content into $t1
    li $t2, 148          # Set counter to 128 (size of file_content)
clear_content:
    beq $t2, 0, end      
    sb $t0, 0($t1)       
    addi $t1, $t1, 1    
    subi $t2, $t2, 1     
    j clear_content      


end:
# make the initial value to zero 
    li $t0, 0
    li $t1, 0
    li $t2, 0
    li $t3, 0
    li $t4, 0
    li $t5, 0
    li $t6, 0
    li $t7, 0
    li $t8, 0
    li $t9, 0

    li $s0, 0
    li $s1, 0
    li $s2, 0
    li $s4, 0
    li $s5, 0
    li $s6, 0

    li $a0, 0
    li $a1, 0
    li $a2, 0
    li $a3, 0

    li $v0, 0

# Ask the user about the result printing
    li $v0, 4  # Load system call for string printing 
    la $a0, opSF
    syscall 
    
    li $v0, 12 # Read char 
    syscall 
    
    # Compare the input char with 'f' or 'F'
    beq $v0, 'f', eqfF 
    beq $v0, 'F', eqfF

    # Compare the input char with 's' or 'S'
    beq $v0, 's', eqsS
    beq $v0, 'S', eqsS
    
    # Default case if input is not one of the valid char 
    j default_case

eqsS: 
    li $s7, 1  # Change the flag to 1 if the user choose a screen printing 
    b afterASK   # continus for input file reading 
   
eqfF: 
    li $s7, 0 # Change the flag to 0 if the user choose a file printing 
    
    # Open file for writing
    li   $v0, 13  # System call for open file
    la   $a0, outFile  # Load output file address
    li   $a1, 1  # Flag for write-only 
    li   $a2, 0  # Mode is ignored
    syscall
    move $s3, $v0  # Save file descriptor
    
    b afterASK # continus for input file reading 

# Print an error message for the user due to the invalid input char 
default_case:
    li $v0, 4  # Load system call for string printing 
    la $a0, opD
    syscall 
    j menu  # go back to the menu 
   
   
afterASK:

    # Prompt user for file path
    li $v0, 4                      # Syscall 4: Print string
    la $a0, prompt_msg             # Load address of prompt message
    syscall

    # Read the user input file path
    li $v0, 8                      # Syscall 8: Read string
    la $a0, buffer                
    li $a1, 30                    
    syscall

    # Check if the user entered anything
    lb $t2, buffer                 
    li $t3, 10                     # ASCII value of newline '\n'
    beq $t2, $t3, empty_input_error  # If first character is newline, go to error

    # Remove the newline character if present
    li $s6, 0   # Initialize index for scanning the buffer
    
find_length:
    lb $t2, buffer($s6)            
    beqz $t2, open_file           
    addi $s6, $s6, 1               
    j find_length                 

open_file:
    # Check if the last character is a newline
    addi $s6, $s6, -1              # Move back to the last character
    lb $t2, buffer($s6)            
    beq $t2, 10, replace_null      # If it's a newline (ASCII 10), replace it

    # Proceed to open the file
    la $a0, buffer                 # Load address of the filename from user input
    li $a1, 0                      # Mode 0 for read-only
    li $v0, 13                     # Syscall 13: Open file
    syscall

    move $t0, $v0                  # Store file descriptor in $t0

    # Check if the file opened successfully
    bltz $t0, file_open_error      # If $t0 < 0, jump to error handler

    # Initialize index and flags
    li $t3, 0                      # Index for Darray
    li $t6, 0                      # Negative flag (0 for positive, 1 for negative)
    li $t8, 0                      # Integer flag (0 if no integer before variable)
    li $s0,0                       #flag for char " = "
    li $s1,0                       # Index for out array
    li $s4,0                       # empty line
    li $s5,0                       #counter
    
read_loop:

    # Read a line from the file
    li $s0,0
    li $t8,0
    li $t6 ,0
    li $v0, 14                     # Syscall 14: Read from file
    move $a0, $t0                  # File descriptor
    la $a1, file_content           # Load address 
    li $a2, 148                    
    syscall

    # Check for end of file or read error
    blez $v0, close_file           # If $v0 <= 0, end of file or error

    #Parse the line
    li $s6, 0                      # Initialize index for line parsing


parse_line:
    lb $t2, file_content($s6)      
    beqz $t2, read_loop            # If end of line, read next line
    li $s2, 10                    # Load ASCII value ('\n')
    beq $t2, $s2, end_of_line     
       
   
    # Check if the character is '-'
    li $t7, '-'                    
    beq $t2, $t7, set_negative     # If '-', set negative flag

    # Check if the character is a digit (0-9)
    li $t4, '0'
    li $t5, '9'
    blt $t2, $t4, check_variable   # If char < '0', check if it's a variable (x, y, z)
    bgt $t2, $t5, check_variable   # If char > '9', check if it's a variable (x, y, z)

    # Convert char to integer
    sub $t2, $t2, '0'              # ASCII to int
    bnez $s0 , addtooutarray
    bnez $t8,mull                  #if the previous char was int then go to mull function
    li $t8, 1                      # Set integer flag

    # Apply negation if needed
    beqz $t6, store_value          # If flag is 0 (positive), store directly
    sub $t2, $zero, $t2            
    li $t6, 0                     

store_value:
    sw $t2, Darray($t3)            # Store word (4 bytes) in Darray
    addi $t3, $t3, 4              
    j next_char                   
#if hte  previous char was int then mul the last int saved in Darray and add to it the current int   
mull:
    subi $t3, $t3, 2
    lh $t4, Darray($t3) 
    mul $t4, $t4 ,10
    bgtz $t4 , positve
    sub $t2 , $zero , $t2         #if the previous int was grater then zero then go to psitive function if not make the int negative

# store the value of the int if its two digits  in Darray  
positve:    
    add $t2,$t4,$t2
    sw $t2, Darray($t3)           
    addi $t3, $t3, 4              
    li $t6 , 0
    j next_char   
                     
# store the value of the int in out array      
addtooutarray:
    bnez $t8,mullout
    beqz $t6, store_valueout          # If flag is 0 (positive), store directly
    sub $t2, $zero, $t2            # Make the number negative
    
store_valueout :    
    li $t8 ,1
    sw $t2, out($s1)            
    addi $s1, $s1, 4               
    j next_char                   
    
# store the value of the int if its two digits  in out array          
mullout:
     
    subi $s1 ,$s1, 4
    lh $t4, out($s1) 
    mul $t4, $t4 ,10
    bgtz $t4 , positveout
    sub $t2 , $zero , $t2
positveout:    
    add $t2,$t4,$t2
    sw $t2, out($s1)            
    addi $s1, $s1, 4              
    li $t6 , 0
    li $t8 ,0
    j next_char                    
    
check_variable:
    # Check if the character is 'x', 'y', or 'z' '='
    li $t9, 'x'
    beq $t2, $t9, store_default    # If 'x', handle variable logic
    li $t9, 'y'
    beq $t2, $t9, store_default    # If 'y', handle variable logic
    li $t9, 'z'
    beq $t2, $t9, store_default    # If 'z', handle variable logic
    li $t9 ,'$'                    
    beq $t2, $t9, ww               # If '$', there is wrong in the equation will print error
    li $t9 ,'='
    beq $t2, $t9, setequalflage
    li $t9 ,'&'                   # If '&', then we reach to the end of file
    beq $t2, $t9, end_of_file
    li $t9 ,'!'
    beq $t2, $t9, copy_Darray_to_DD #   If '!', we got the first set of equations ready to solve

    li $t8, 0                      # Reset integer flag for the next term
    j next_char                    

store_default:
    # Only store default value of 1 if no integer precedes this variable
    beq $t8, 1, skip_default       # If integer flag is set, skip adding 1
    li $t2, 1                      # Set default value of 1
    beqz $t6, store_value          # If flag is 0 (positive), store directly
    sub $t2, $zero, $t2            
    li $t6, 0                      # Reset negative flag
    sw $t2, Darray($t3)            
    addi $t3, $t3, 4              
    
skip_default:
    li $t8, 0                      # Reset integer flag for the next term
    j next_char                    

set_negative:
    li $t6, 1                      # Set negative flag
    j next_char                    
    
# to close the output file after the end of the file process 
end_of_file:
    # Close the file
    li   $v0, 16                   # System call for close file
    move $a0, $s3                  # File descriptor
    syscall
    j menu # Go to the menu to accept a new input file

# printig the error massage if there is $ in the equations then go to menu        
ww:
  la $a0, error_open_msg  
  li $v0, 4              
  syscall                 
  j menu

#make equal flage  =1 when see this char '='  
setequalflage:
    li $s0 ,1  
    addi $s5 ,$s5,1  
    j next_char 

end_of_line:
    li $s0, 0                       # Set $s0 to 0 at the end of the line 


next_char:
    addi $s6, $s6, 1               # Move to next character in line
    j parse_line                   # Repeat until end of line
        

replace_null:
    sb $zero, buffer($s6)          # Replace newline with null terminator (0)
    j open_file                    # Now proceed to open the file

close_file:
    # Close the file
    move $a0, $t0                  # File descriptor
    li $v0, 16                     # Syscall 16: Close file
    syscall

#copy_Darray_to_DD 
copy_Darray_to_DD:
    li $t7, 0              
    li $t3,0

copy_loop_DD:
    lw $t2, Darray($t3)     
    beqz $t2, next   
   
    sw $t2, DD($t7)          
    addi $t7, $t7, 4        
    addi $t3, $t3, 4 
    j copy_loop_DD  
           
#to set all the regesters to zero to handel the next set of equations in the same file
part2:
    li $t3, 0                      # Index for Darray
    li $t6, 0                      # Negative flag (0 for positive, 1 for negative)
    li $t8, 0                      # Integer flag (0 if no integer before variable)
    li $s0,0                       #flag for char " = "
    li $s1,0                       # Index for out array
    li $s4,0                       # empty line
    li $s5,0                        #counter
    li $t3,0
    li $t7,0
    li $s1,0
    li $s5 ,0
    j next_char 
    
# Initialise the registers with the right data         
next: 
    la $t0, Darray # determinant 
    la $t7, DD # determinant copy 
    la $t9, out # the output of the equations 
    la $t8, DXYZ # to store the results of the determinant
    li $a3, 0	# counter, that help in the functions sequence 
    # Decide the determinant type based on the equations number of lines 
    beq $s5, 2, func2 # 2x2
    beq $s5, 3, func3 # 3x3 
    
    ####### menu #######
    
menu: 
    # print the options 
    li $v0, 4        
    la $a0, opI 
    syscall 
    
    li $v0, 12 # Read char 
    syscall 
    
    # Compare the input char with 'e' or 'E'
    # Exit the program 
    beq $v0, 'e', exit 
    beq $v0, 'E', exit 

    # Compare the input char with 'c' or 'C'
    # Go to the main function to ask about the printing type and the input file name 
    # read the input file, solve the systems and so on...
    beq $v0, 'c', main
    beq $v0, 'C', main
    
    # Default case if input is not one of the valid char 
    j default_case 
    

    ####### File Prinitg #######
FilePrinting:

    ############# X = #############
    # Load the address of the matrix 
    la   $t8, DXYZ 
    # Load the number to convert
    lw   $t0, 4($t8) # Dx value 

    # Initialize buffer pointer
    la   $t1, bufferINT # Load bufferaddress
    add  $t1, $t1, 11 # Point to end of bufferINT
    sb   $zero, ($t1) # Null terminate the string
    sub  $t1, $t1, 1 # Move pointer back
    
    jal INTtoSTR_convert 
    
    # Write "X = " to the file
    li   $v0, 15 # System call for write to file
    move $a0, $s3 # File descriptor
    la   $a1, PrintX              
    li   $a2, 8 # Length of "\n\n\nX = "
    syscall

    # Write the number to the file
    li   $v0, 15  # System call for write to file
    move $a0, $s3  # File descriptor
    move $a1, $t1  # Pointer to the number string
    la   $t2, bufferINT
    add  $t2, $t2, 11  # Point to end of bufferINT
    sub  $a2, $t2, $t1  # Length = end - start
    syscall
    
    # Write " / " to the file
    li   $v0, 15  
    move $a0, $s3                 
    la   $a1, printDiv 
    li   $a2, 3 # Length of " / "
    syscall
    
    # Load the second number to convert
    lw   $t0, 0($t8) # D value 

    # Initialize bufferINT pointer
    la   $t1, bufferINT  # Load buffer address
    add  $t1, $t1, 11  # Point to end of buffer
    sb   $zero, ($t1)  # Null terminate the string
    sub  $t1, $t1, 1  # Move pointer back
    
    jal INTtoSTR_convert 
    
    # Write the number to the file
    li   $v0, 15                
    move $a0, $s3 
    move $a1, $t1  # Pointer to the number string
    la   $t2, bufferINT
    add  $t2, $t2, 11  # Point to end of buffer
    sub  $a2, $t2, $t1  # Length = end - start
    syscall
    
    ############# Y = #############
    # Load the number to convert
    lw   $t0, 8($t8) # Dy value 

    # Initialize buffer pointer
    la   $t1, bufferINT # Load bufferaddress
    add  $t1, $t1, 11 # Point to end of bufferINT
    sb   $zero, ($t1) # Null terminate the string
    sub  $t1, $t1, 1 # Move pointer back
    
    jal INTtoSTR_convert 
    
    # Write "Y = " to the file
    li   $v0, 15 # System call for write to file
    move $a0, $s3 # File descriptor
    la   $a1, PrintY              
    li   $a2, 5 # Length of "\nY = "
    syscall

    # Write the number to the file
    li   $v0, 15  # System call for write to file
    move $a0, $s3  # File descriptor
    move $a1, $t1  # Pointer to the number string
    la   $t2, bufferINT
    add  $t2, $t2, 11  # Point to end of bufferINT
    sub  $a2, $t2, $t1  # Length = end - start
    syscall
    
    # Write " / " to the file
    li   $v0, 15  
    move $a0, $s3                 
    la   $a1, printDiv 
    li   $a2, 3 # Length of " / "
    syscall
    
    # Load the second number to convert
    lw   $t0, 0($t8) # D value 

    # Initialize bufferINT pointer
    la   $t1, bufferINT  # Load buffer address
    add  $t1, $t1, 11  # Point to end of buffer
    sb   $zero, ($t1)  # Null terminate the string
    sub  $t1, $t1, 1  # Move pointer back
    
    jal INTtoSTR_convert 
    
    # Write the number to the file
    li   $v0, 15                
    move $a0, $s3 
    move $a1, $t1  # Pointer to the number string
    la   $t2, bufferINT
    add  $t2, $t2, 11  # Point to end of buffer
    sub  $a2, $t2, $t1  # Length = end - start
    syscall
    
    #### 
    
    beq $a3, 3, PrintZtoFILE  # if the system is 3x3 go to print Z value  

    j part2 # go to the next system or display the menu
    
    
PrintZtoFILE: 
    ############# Z = #############
    # Load the number to convert
    lw   $t0, 12($t8) # Dz value 

    # Initialize buffer pointer
    la   $t1, bufferINT # Load bufferaddress
    add  $t1, $t1, 11 # Point to end of bufferINT
    sb   $zero, ($t1) # Null terminate the string
    sub  $t1, $t1, 1 # Move pointer back
    
    jal INTtoSTR_convert 
    
    # Write "Z = " to the file
    li   $v0, 15 # System call for write to file
    move $a0, $s3 # File descriptor
    la   $a1, PrintZ              
    li   $a2, 5 # Length of "\nY = "
    syscall

    # Write the number to the file
    li   $v0, 15  # System call for write to file
    move $a0, $s3  # File descriptor
    move $a1, $t1  # Pointer to the number string
    la   $t2, bufferINT
    add  $t2, $t2, 11  # Point to end of bufferINT
    sub  $a2, $t2, $t1  # Length = end - start
    syscall
    
    # Write " / " to the file
    li   $v0, 15  
    move $a0, $s3                 
    la   $a1, printDiv
    li   $a2, 3 # Length of " / "
    syscall
    
    # Load the second number to convert
    lw   $t0, 0($t8) # D value 

    # Initialize bufferINT pointer
    la   $t1, bufferINT  # Load buffer address
    add  $t1, $t1, 11  # Point to end of buffer
    sb   $zero, ($t1)  # Null terminate the string
    sub  $t1, $t1, 1  # Move pointer back
    
    jal INTtoSTR_convert 
    
    # Write the number to the file
    li   $v0, 15                
    move $a0, $s3 
    move $a1, $t1  # Pointer to the number string
    la   $t2, bufferINT
    add  $t2, $t2, 11  # Point to end of buffer
    sub  $a2, $t2, $t1  # Length = end - start
    syscall

    j part2  # go to the next system or display the menu

INTtoSTR_convert:
    # Handle zero case first
    beqz $t0, handle_zero

    # Determine if number is negative
    bltz $t0, handle_negative

# Positive number conversion
positive_conversion:
    # Divide number by 10
    li   $t2, 10
    div  $t0, $t2
    mfhi $t3  # Get remainder (last digit)
    mflo $t0  # Get quotient for next iteration

    # Convert digit to ASCII and store
    addi $t3, $t3, 48 # Convert to ASCII
    sb   $t3, ($t1)  # Store digit in buffer
    sub  $t1, $t1, 1 # Move bufferINT pointer back

    # Continue if quotient is not zero
    bnez $t0, positive_conversion

    # Adjust pointer to start of number
    addi $t1, $t1, 1 # Move to first digit

    jr $ra

# Convert to positive for conversion
handle_negative:
    mul $t0, $t0, -1               # Make positive
    # Do conversion as normal
    j positive_conversion

handle_zero:
    # Store '0' directly
    li   $t3, 48                   # ASCII for '0'
    sb   $t3, ($t1)                # Store '0'
    sub  $t1, $t1, 1               # Move bufferINT pointer back
    
    # Adjust pointer to start of number
    addi $t1, $t1, 1               # Move to first digit

    jr $ra 

    ####### Screen Prinitg #######
ScreenPrinting: 
    # Print X = 
    li $v0, 4                 # printing a string
    la $a0, PrintX         
    syscall

    # Load the Value of X
    la $t0, out    # load address of the output array 
    lwc1 $f12, 0($t0)  # load the value of X from the outputs array 
    li $v0, 2   
    syscall

    # Print Y =  
    li $v0, 4        
    la $a0, PrintY 
    syscall

    # Load the Value of Y
    lwc1 $f12, 4($t0)  # load the value of Y from the outputs array 
    li $v0, 2   
    syscall
    
    beq $a3, 3, printZfun # if the system is 3x3 go to print Z value 
    
    j part2 # go to the next system or display the menu
    
printZfun:
    # Print Z = 
    li $v0, 4        
    la $a0, PrintZ 
    syscall

    # Load the Value of Z
    lwc1 $f12, 8($t0) # load the value of Z from the outputs array 
    li $v0, 2   
    syscall
    
    j part2 # go to the next system or display the menu

 
    ####### 3x3 Functions ####### 

aftD3:     # this function called after the first iteration 
    sw $t3, 0($t8)	# store the value of D determinant 
    
    # to create Dx 
    lw $t6, 0($t9)	# d0 - a0 
    sw $t6, 0($t0)
    lw $t6, 4($t9)	# d1 - a3
    sw $t6, 12($t0)
    lw $t6, 8($t9)	# d2 - a6
    sw $t6, 24($t0)
 
    add $a3, $a3, 1   # increase the counter 
    j func3	      # call the function to find the value of Dx determinant 
    
aftX3:    # this function called after the second iteration 
    sw $t3, 4($t8)   # store the value of Dx determinant 
        
    # return the matrix to D => to change it into Dy in the exit step 
    lw $t6, 0($t7)	# 0 
    sw $t6, 0($t0)
    lw $t6, 12($t7)	# 3
    sw $t6, 12($t0)
    lw $t6, 24($t7)	# 6
    sw $t6, 24($t0)
    
    # to create Dy
    lw $t6, 0($t9)	# d0 - a1 
    sw $t6, 4($t0)
    lw $t6, 4($t9)	# d1 - a4
    sw $t6, 16($t0)    
    lw $t6, 8($t9)	# d2 - a7
    sw $t6, 28($t0)
 
    add $a3, $a3, 1   # increase the counter 
    j func3	      # call the function to find the value of Dy determinant 
    
aftY3:    # this function called after the third iteration 
    sw $t3, 8($t8)   # store the value of Dy determinant 
        
    # return the matrix to D => to change it into Dz in the exit step 
    lw $t6, 4($t7)	# 1
    sw $t6, 4($t0)
    lw $t6, 16($t7)	# 4
    sw $t6, 16($t0)
    lw $t6, 28($t7)	# 7
    sw $t6, 28($t0)
    
    # to create DZ
    lw $t6, 0($t9)	# d0 - a2
    sw $t6, 8($t0)
    lw $t6, 4($t9)	# d1 - a5
    sw $t6, 20($t0)    
    lw $t6, 8($t9)	# d2 - a8
    sw $t6, 32($t0)
 
    add $a3, $a3, 1   # increase the counter 
    j func3	      # call the function to find the value of Dz determinant  
    
aftZ3:    # this function called after the forth iteration 
    sw $t3, 12($t8)   # store the value of Dz determinant 
    # add $a1, $a1, 1   
    
    ######## Calculate the values of X, Y, and Z ########
    
    lw $t2, 0($t8)          # Load the value of D into $t2 reg.
    mtc1 $t2, $f2           # Move the integer into floating-point reg. $f2
    cvt.s.w $f2, $f2        # Convert the integer in $f1 to single-precision float in $f2
    # division by zero detection 
    beq $t2, $zero, divzeroDet 
    
    # this part to calculate X which equal to Dx / D 
    
    lw $t1, 4($t8)          # Load the value of Dx into $t1 reg. 
    mtc1 $t1, $f1           # Move the integer into floating-point reg. $f1
    cvt.s.w $f1, $f1        # Convert the integer in $f1 to single-precision float in $f1

    div.s $f12, $f1, $f2    # $f12 = $f1 / $f2 
    s.s $f12, 0($t9)	    # store single-precision float from $f12 to output matrix in the memory 

    # this part to calculate Y which equal to Dy / D  
    
    lw $t1, 8($t8)          # Load the value of Dy into $t1 reg. 
    mtc1 $t1, $f1           # Move the integer into floating-point reg. $f1
    cvt.s.w $f1, $f1        # Convert the integer in $f1 to single-precision float in $f1

    div.s $f12, $f1, $f2    # $f12 = $f1 / $f2 
    s.s $f12, 4($t9)	    # store single-precision float from $f12 to output matrix in the memory 
    
    ### 
    
    lw $t1, 12($t8)          # Load the value of Dz into $t1 reg. 
    mtc1 $t1, $f1           # Move the integer into floating-point reg. $f1
    cvt.s.w $f1, $f1        # Convert the integer in $f1 to single-precision float in $f1

    div.s $f12, $f1, $f2    # $f12 = $f1 / $f2 
    s.s $f12, 8($t9)	    # store single-precision float from $f12 to output matrix in the memory 
    
    # go to the right functions based on the type of printing 
    beq $s7, 1, ScreenPrinting
    beq $s7, 0, FilePrinting
    
divzeroDet:
    li $v0, 4      # 4 => code for print_string
    la $a0, divbyzero    # Load address of the error message
    syscall    
    j menu  # go back to the menu 
	

exit:     
    li $v0, 10   # to exit the program 
    syscall                
	  
func3:	# the function that calculate the determinant
	
    # a0, a1, a2
    # a3, a4, a5 
    # a6, a7, a8 
	
    # a0 * [ (a4 * a8) - (a5 * a7) ] 
    
    lw $t1, 16($t0)   # Lode a4 into $t1 
    lw $t2, 32($t0)   # Lode a8 into $t2     
    mul $t3, $t1, $t2   # $t3 = a4 * a8 
    
    lw $t1, 20($t0)   # Lode a5 into $t1  
    lw $t2, 28($t0)   # Lode a7 into $t2     
    mul $t4, $t1, $t2   # $t4 = a5 * a7
    mul $t4, $t4, -1    # $t4 => - (a5 * a7) 
    
    add $t3, $t3, $t4   # $t3 = $t3 + $t4 
    
    lw $t1, 0($t0)  # Lode a0 into $t1  
    mul $t3, $t3, $t1  # $t3 = $t3 * $t1 
    
    # a1 * [ (a3 * a8) - (a5 * a6) ]
    
    lw $t1, 12($t0)  # Lode a3 into $t1      
    lw $t2, 32($t0)   # Lode a8 into $t2 
    mul $t4, $t1, $t2  # $t4 = a3 * a8  
    
    lw $t1, 20($t0)  # Lode a5 into $t1      
    lw $t2, 24($t0)    # Lode a6 into $t2
    mul $t5, $t1, $t2   # $t5 = a5 * a6    
    mul $t5, $t5, -1   # $t5 => - (a5 * a6)   
    
    add $t4, $t4, $t5   # $t4 = $t4 + $t5 
    
    lw $t1, 4($t0)  # Lode a1 into $t1
    mul $t4, $t4, $t1  # $t4 = $t4 * $t1      
    
    # a2 * [ (a3 * a7) - (a4 * a6) ]
    
    lw $t1, 12($t0)    # Lode a3 into $t1     
    lw $t2, 28($t0)    # Lode a7 into $t2   
    mul $t5, $t1, $t2  # $t5 = a3 * a7   
    
    lw $t1, 16($t0)    # Lode a4 into $t2    
    lw $t2, 24($t0)    # Lode a6 into $t2 
    mul $t6, $t1, $t2  # $t6 = a4 * a6   
    mul $t6, $t6, -1   # $t6 => - (a4 * a6)     
    
    add $t5, $t5, $t6    # $t5 = $t5 + $t6    
    
    lw $t1, 8($t0)  # Lode a2 into $t1
    mul $t5, $t5, $t1     # $t5 = $t5 * $t1 
    
    # a0 * [ (a4 * a8) - (a5 * a7) ] - a1 * [ (a3 * a8) - (a5 * a6) ] + a2 * [ (a3 * a7) - (a4 * a6) ] 
    # $t3 - $t4 + $t5 
    sub $t3, $t3, $t4    
    add $t3, $t3, $t5       
    
    beq $a3, 0, aftD3  # after the first iteration 
    beq $a3, 1, aftX3  # after the second iteration 
    beq $a3, 2, aftY3  # after the third iteration 
    beq $a3, 3, aftZ3  # after the forth iteration 
    
    
    ####### 2x2 Functions ####### 
    
aftD2:  # this function called after the first iteration
    sw $t3, 0($t8)  # store the value of D determinant
    
    # to create Dx
    lw $t6, 0($t9)	# d0 - a0 
    sw $t6, 0($t0)
    lw $t6, 4($t9)	# d1 - a1
    sw $t6, 8($t0)
 
    add $a3, $a3, 1   # increase the counter 
    j func2           # call the function to find the value of Dx determinant
    
aftX2:   # this function called after the second iteration
    sw $t3, 4($t8)  # store the value of Dx determinant 
        
    # return the matrix to D => to change it into Dy in the exit step 
    lw $t6, 0($t7)	# 0 
    sw $t6, 0($t0)
    lw $t6, 8($t7)	# 2
    sw $t6, 8($t0)
    
    # to create Dy
    lw $t6, 0($t9)	# d0 - a1 
    sw $t6, 4($t0)
    lw $t6, 4($t9)	# d1 - a3
    sw $t6, 12($t0)    
 
    add $a3, $a3, 1   # increase the counter
    j func2           # call the function to find the value of Dy determinant
    
aftY2:    # this function called after the third iteration
    sw $t3, 8($t8)  # store the value of Dy determinant
    # add $a1, $a1, 1   
    
    ######## Calculate the values of X, and Y ######## 
    
    lw $t2, 0($t8)          # Load the value of D into $t2 reg.
    mtc1 $t2, $f2           # Move the integer into floating-point reg. $f2
    cvt.s.w $f2, $f2        # Convert the integer in $f1 to single-precision float in $f2
    # division by zero detection 
    beq $t2, $zero, divzeroDet
    
    # this part to calculate X which equal to Dx / D
    
    lw $t1, 4($t8)          # Load the value of Dx into $t1 reg. 
    mtc1 $t1, $f1           # Move the integer into floating-point reg. $f1
    cvt.s.w $f1, $f1        # Convert the integer in $f1 to single-precision float in $f1

    div.s $f12, $f1, $f2    # $f12 = $f1 / $f2 
    s.s $f12, 0($t9)        # store single-precision float from $f12 to output matrix in the memory 

    # this part to calculate Y which equal to Dy / D 
    
    lw $t1, 8($t8)          # Load the value of Dy into $t1 reg.
    mtc1 $t1, $f1           # Move the integer into floating-point reg. $f1
    cvt.s.w $f1, $f1        # Convert the integer in $f1 to single-precision float in $f1

    div.s $f12, $f1, $f2    # $f12 = $f1 / $f2 
    s.s $f12, 4($t9)        # store single-precision float from $f12 to output matrix in the memory 
    
    # go to the right functions based on the type of printing 
    beq $s7, 1, ScreenPrinting
    beq $s7, 0, FilePrinting
    
          
func2:  # the function that calculate the determinant

    # a0, a1
    # a2, a3 
    
    # ( a0 * a3 ) -  ( a1 * a2 )
    
    lw $t1, 0($t0)   # Lode a0 into $t1
    lw $t2, 12($t0)  # Lode a3 into $t2
    mul $t3, $t1, $t2   # $t3 = $t1 * $t2    
    
    lw $t1, 4($t0)   # Lode a1 into $t1
    lw $t2, 8($t0)   # Lode a2 into $t2 
    mul $t4, $t1, $t2   # $t4 = $t1 * $t2 
    mul $t4, $t4, -1    # $t4 => -  ( a1 * a2 ) 
    
    # ( a0 * a3 ) -  ( a1 * a2 )
    # $t3 + $t4 "the negative assigned by the multiplication above"
    add $t3, $t3, $t4     # $t3 = $t3 + $t4             
    
    beq $a3, 0, aftD2  # after the first iteration
    beq $a3, 1, aftX2  # after the second iteration
    beq $a3, 2, aftY2  # after the third iteration
