################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    16
# - Display height in pixels:   24
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
############################################################################## 
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# The width of the tetris playing area including the borders
TETRIS_WIDTH:
    .word 16
# The height of the tetris playing area including the borders
TETRIS_HEIGHT:
    .word 24
# The location where the tetris playing area starts from (the memory address from where its starts to be drawn)
TETRIS_START:
    .word 0x10008000
##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initialize the game
    lw $t0, TETRIS_START
    Lw $t1, TETRIS_WIDTH    
    add $a0, $zero, $t1     # set width of border to tetris width
    Lw $t1, TETRIS_HEIGHT 
    add $a1, $zero, $t1     # set height of border to tetris height
    jal draw_border_with_checkered_pattern
    
game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop


# The code for drawing a border with checkered pattern
# - $a0: the width of the border in pixels
# - $a1: the height of the border in pixels
# - $t0: the address of the first pixel (top left) in the bitmap
# - $t1: the horizontal offset of the first pixel in the line.
# - $t2: the vertical offset of the first pixel in the line.
# - #t3: the location in bitmap memory of the current pixel to draw 
# - $t4: the bitmap location for the end of a row for the inner loop
# - $t5: the bitmap location for the end of the horizontal line for the outer loop
# - $t6: the colour to draw
# - $t7: stores $t4 - 4
# - $t8: stores $t5 - 64
# - $t9: stores a 1 or 0 if we have to draw light gray or dark gray
draw_border_with_checkered_pattern:
    add $t2, $zero, $zero   # set the vertical offset to zero
    sll $t5, $a1, 6         # set the height of rectangle from pixels to rows of bytes (by multiplying $a1 by 64) 
    addi $t8, $t5, -64      # stores $t5 - 64
    sll $t4, $a0, 2         # set width of line from pixels to bytes (by multiplying $a0 by 4)
    addi $t7, $t4, -4       # stores $t4 - 4
    add $t9, $zero, $zero  # sets $t9 to an initial value of 0
    
outer_top:
    add $t1, $zero, $zero   # set the horizontal offset to zero
    
    inner_top:
        add $t3, $t1, $t2           # store the total offset of the starting pixel (relative to $t0)
        add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
        
        # Check if we are drawing the border or the inner checkered pattern
        beq $t2, $zero, draw_border_pixel   # If vertical offset is zero, draw border pixel
        beq $t1, $zero, draw_border_pixel   # If horizontal offset is zero, draw border pixel
        beq $t2, $t8, draw_border_pixel   # If vertical offset is at the end, draw border pixel
        beq $t1, $t7, draw_border_pixel   # If horizontal offset is at the end, draw border pixel
    
    draw_inside_pixel:
        li $t6, 0xF7F4F4            # $t6 = very light gray so that when multiplied with not of zero gives a dark gray
        multu $t6, $t9              # choose the alternate colour
        mflo $t6                    # load the alternate colout into $t6
        nor $t9, $t9, $t9           # store the not value of $t9 into itself
        sw $t6, 0($t3)              # paint the current location white
        addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
        beq $t1, $t4, inner_end     # break out of the line-drawing loop
        j inner_top                 # jump to the start of the inner loop
    
    draw_border_pixel:
        li $t6, 0xFFFFFF            # $t6 = white
        sw $t6, 0($t3)              # paint the current location white
        addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
        beq $t1, $t4, inner_end     # break out of the line-drawing loop
        j inner_top                 # jump to the start of the inner loop
        
    inner_end:
        addi $t2, $t2, 64           # move vertical offset down by one line
        beq $t2, $t5, outer_end     # on last line, break out of the outer loop
        nor $t9, $t9, $t9           # store the not value of $t9 into itself
        j outer_top                 # jump to the top of the outer loop
outer_end:
    jr $ra                      # return to calling program

    