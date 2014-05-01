<pre>
Archi_project_tool 

================== 
Content 2 script file: 
1. assembler.pl 
2. dimageMaker.pl 
 
Assembler for 32-bit MIPS simulator, supports instructions in the bellow: 
  R type: 
                      opcode (6)  rs (5)  rt(5)   rd (5)  shamt(5)  funct(6)  action 
  bit interval        31-26       25-21   20-16   15-11   10-6      5-0 
  add rd, rs, rt      0x00        v       v       v       x         0x20      $d = $s + $t 
  sub rd, rs, rt      0x00        v       v       v       x         0x22      $d = $s - $t 
  and rd, rs, rt      0x00        v       v       v       x         0x24      $d = $s & $t 
  or  rd, rs, rt      0x00        v       v       v       x         0x25      $d = $s | $t 
  xor rd, rs, rt      0x00        v       v       v       x         0x26      $d = $s ^ $t 
  nor rd, rs, rt      0x00        v       v       v       x         0x27      $d = ~($s | $t) 
  nand  rd, rs, rt    0x00        v       v       v       x         0x28      $d = ~($s & $t) 
  slt rd, rs, rt      0x00        v       v       v       x         0x2A      $d = ($s < $t) 
  sll rd, rt, shamt   0x00        x       v       v       v         0x00      $d = $t << shamt 
  srl rd, rt, shamt   0x00        x       v       v       v         0x02      $d = $t >> shamt 
  sra rd, rt, shamt   0x00        x       v       v       v         0x03      $d = $t >> shamt (with sign extension) 
  jr  rs              0x00        v       x       x       x         0x08      PC = $s 
 
  I type:  
                      opcode (6)  rs (5)  rt(5)   immediate(16)   action 
  bit interval        31-26       25-21   20-16   15-0 
  addi rt, rs, imm    0x08        v       v       v               $d = $s + $t 
  lw  rt, rs, imm     0x23        v       v       v               $t = mem[$s+imm] (4 bytes) 
  lh  rt, rs, imm     0x21        v       v       v               $t = mem[$s+imm] (2 bytes) (with sign extension) 
  lhu rt, rs, imm     0x25        v       v       v               $t = mem[$s+imm] (2 bytes) 
  lb  rt, rs, imm     0x20        v       v       v               $t = mem[$s+imm] (1 bytes) (with sign extension) 
  lbu rt, rs, imm     0x24        v       v       v               $t = mem[$s+imm] (1 bytes) 
  sw  rt, rs, imm     0x2B        v       v       v               mem[$s+imm] = $t (4 bytes) 
  sh  rt, rs, imm     0x29        v       v       v               mem[$s+imm] = $t (2 bytes) 
  sb  rt, rs, imm     0x28        v       v       v               mem[$s+imm] = $t (1 bytes) 
  lui rt, imm         0x0F        x       v       v               $t = imm << 16 
  andi  rt, rs, imm   0x0C        v       v       v               $t = $s & imm 
  ori rt, rs, imm     0x0D        v       v       v               $t = $s | imm 
  nori  rt, rs, imm   0x0E        v       v       v               $t = ~($s | imm) 
  slti  rt, rs, imm   0x0A        v       v       v               $t = ($s < imm) 
  beq rs, rt, imm     0x04        v       v       v               PC = PC+4+imm if ($s == $t) 
  bne rs, rt, imm     0x05        v       v       v               PC = PC+4+imm if ($s != $t) 
   
  J type & Special type:  
                      opcode (6)  address(26)     action 
  bit interval        31-26       25-0 
  j addr              0x02        v               PC = (PC+4 & 0xF0000000) | (4*addr) 
  jal addr            0x03        v               $31 = PC+4; PC = (PC+4 & 0xF0000000) | (4*addr) 
  halt                0x3F        x               halt the simulator 
  
  
  1  **** 
 
Script name: assembler.pl 
  
  Created by ken hua on 2014/4/16 
  Usage: 
    Input format:  
      perl assembler.pl [S file path] [start PC] 
      * example:  perl assembler.pl test.S 12 
                  perl assembler.pl test.S 0x200 
      warning: it doesn't work for -0x format 
    Output: a iimage.bin file 
      
  S file content: 
    Note: One line for one instruction. 
 
    Registers format: 
          It works using register number: $0~$31 
          or register name: $zero $at $t0~$t9 $s0~$s7 $a0~$a3 
                          $v0~$v1 $k1~$k2 $sp $fp $gp $ra 
          * example: add $t9, $15, $16 
 
    Instructions: 
          space by "," or blanks 
          *example: add $9, $9, $9 
                    add $9  $9 $9 
                    add $9, $9 $9 
 
    Values:
          You can use the expression of hexadecimal or decimal: 
          * example:  slti $9, $8, 0x88 
                      lw   $20,-0x20($0) 
                      addi $29, $29, 4 
          warning: it doesn't work for -0x80000000 
 
    Lables: 
          A valid label followed by a colon, 
           so you can use it in the branch and jump instruction or not. 
          * example: for1st:  add $11, $12, $13 
                              j   for1st 
                              beq $12, $13, -2 
    Comments: 
          Words behind a comment sign will be ignored 
          * example: add $1, $1 ,$0  # this is a comment 
  
  2  **** 
Script name: dimageMaker.pl 
 Created by ken hua on 2014/4/16 
 Usage: 
     Input format:
         perl dimageMaker.pl [data file path] [start sp] 
         * example: perl dimageMaker.pl dataMem 0x200 
                    perl dimageMaker.pl dataMem 12 
         warning: it doesn't work for -0x format 
     Output: a dimage.bin file 
 
 data file content: 
     hexadecimal or decimal numbers be spaced by a few blanks, tabs, and \n. 
     *example: 0x07        20 11       
               13 
     warning: it doesn't work for -0x80000000 
 
</pre>
