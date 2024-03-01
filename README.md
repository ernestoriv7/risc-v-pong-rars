# risc-v-pong-rars
This is a Pong game implemented in RISC-V assembly language using the RARS simulator.

#All rights reserved
#Copyright belongs to Ernesto Rivera
#You can use this code freely in your project(s) as long as credit is given :)

#Inspiration taken from a MIPS assembly version done by: https://github.com/AndrewHamm/MIPS-Pong for the 
#MARS emulator

#The official repository of the RARS emulator can be found in: https://github.com/TheThirdOne/rars

# To run the project:
# 1) In the upper bar go to Run->Assemble (f3)
# 2) In the upper bar go to Tools->Bitmap Display
# 3) Configure the following settings in in the Bitmap Display:
	# a) Unit Width: 8
	# b) Unit Height: 8
	# c) Display Width: 512
	# d) Display Height: 256
	# e) Base Address: gp
	# f) Press connect to program 
# 4) In the upper bar go to Tools->Keyboard and Display MMIO Simulator and press connect to MIPS
# 5) In the upper bar go to Run->Go (f5)
# 6) Click on the lower window of the Keyboard and Display simulator to produce inputs
