module Pipeline_MIPS32(clock_1, clock_2);

input clock_1, clock_2;

reg [31:0] IF_EX_IR, IF_EX_NPC, PC;
reg [31:0] ID_EX_A, ID_EX_B, ID_EX_IR, ID_EX_NPC, ID_EX_IMM;
reg [31:0] EX_MEM_ALUOUT, EX_MEM_B, EX_MEM_IR, EX_MEM_COND;
reg [31:0] MEM_WB_LMD, MEM_WB_ALUOUT, MEM_WB_IR;

reg [2:0] ID_EX_REG_TYPE, EX_MEM_REG_TYPE, MEM_WB_REG_TYPE;

reg [31:0] REG [31:0];
reg [31:0] MEM [1023:0];

parameter  ADD = 6'b000_000, SUB = 6'b000001, AND = 6'b000010, 
           OR = 6'b000100 , SLT = 6'b000101, MUL = 6'b000110, 
           HLT = 6'b111111, LW = 6'b001000, SW = 6'b001001,
           ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
           BNEQZ = 6'b001101, BEQZ = 6'b001110;

parameter RR_ALU = 3'B000, RI_ALU = 3'B001, LOAD = 3'B010, STORE = 3'B011, BRANCH = 3'B100, HALT = 3'B111;

reg HALTED;

reg TYPE_BRANCH;


always @(negedge clock_1)                 /// AT NEGEDGE WE USE CLOCK_1 OF FETCH INSTRUCTION CYCLE
begin
   if(HALTED == 0)                        /// IF HALT IS HIGH WE DONT DO ANY FURTHER OPERATION
begin
    if((EX_MEM_ALUOUT[31:26] == BNEQZ) && (EX_MEM_COND == 0)) || 
           ((EX_MEM_ALUOUT[31:26] == BEQZ) && (EX_MEM_COND == 1)) /// CHECK WEATHER THE CODE HAVE BRANCH INSTRUCTION
     begin                                                        /// IF YES DO WHAT IS THERE IN BRANCH INSTRUCTION
        IF_ID_IR <= #3 MEM[EX_MEM_ALUOUT];                        /// INSTRUCTION REG IS STORED IN IMMEDIATE ADDRESS
        TYPE_BRANCH <= #3 1'b1;                                   /// INFORM THAT THERE IS A BRANCH INSTRUCTION SO WE 
        IF_ID_NPC <= #3 EX_MEM_ALUOUT + 1;                        /// DONT WRITE ANYTHING TO MEMORY 
        PC <= #3 EX_MEM_ALUOUT + 1;                               /// INCREMENT THE PC AND NPC
     end
   else 
      begin
       PC <= #3 PC + 1;                                           /// IF NO BRANCE, DO NORMAL OPERATION
       NPC <= #3 PC + 1;                                          /// INCREMENT PC AND NPC
       IF_ID_IR <= #3 MEM[PC];                                    /// STORE THE MEMORY DATA(BASICALLY INSTRUCTION'S) 
       end                                                        /// INSTRUCTION REGISTER
end
else
     HALTED = 1;                                                  /// ELSE DO HALT OPERATION
end


always @(negedge clock_2)                            /// AT NEGEDGE WE USE CLOCK_2 OF DECODE INSTRUCTION CYCLE
begin
  if(IF_ID_IR[25:21] == 5'b00000)  ID_EX_A <= #3 0;              /// IF SOURCE_REG[25:21] IS ZERO WE MAKE 'A' ZERO
   else ID_EX_A <= #3 REG[IF_ID_IR[25:21]];                      /// ELSE WE WRITE WHAT EVER THERE IN IR INTO 'A'
 
  if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= #3 0;               /// IF SOURCE_REG[25:21] IS ZERO WE MAKE 'B' ZERO
   else ID_EX_B <= #3 REG[IF_ID_IR[20:16]];                      /// ELSE WE WRITE WHAT EVER THERE IN IR INTO 'B'

   ID_EX_IR <= #3 IF_ID_IR;                                      /// JUST PASS THE VALUE IN IR REG TO NEXT REG
   ID_EX_NPC <= #3 IF_ID_NPC;                                    /// JUST PASS THE VLAUE IN NPC REG TO NEXT REG
   ID_EX_IMM <= { {16 {IF_ID_IR[15]} } , {IF_ID_IR[15:0]} };     /// IF THERE IS ANY IMMEDIATE OPERATION WE APPEND THE
                                                                 /// REST WITH THE MSB DATA OF IR VALUE 
   case(IF_ID_IR[31:26])
      begin
         ADD, SUB, MUL, AND, OR, SLT : ID_EX_REG_TYPE <= #3 RR_ALU;  /// REG TO REG OPERATION
         LW                          : ID_EX_REG_TYPE <= #3 LOAD;    /// LOAD OPERATION
         SW                          : ID_EX_REG_TYPE <= #3 STORE;   /// STORE OPERATION
         ADDI, SUBI                  : ID_EX_REG_TYPE <= #3 RI_ALU;  /// REG TO IMM OPERATION
         BNEQZ, BEQZ                 : ID_EX_REG_TYPE <= #3 BRANCH;  /// BRANCH OPERATION
         HALT                        : ID_EX_REG_TYPE <= #3 HALT;    /// HALT OPEARTION
         default                     : ID_EX_REG_TYPE <= #3 HALT;
      endcase
end	


endmodule
 