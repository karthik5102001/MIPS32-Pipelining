module MIPS32_Pipeline(clock_1, clock_2);

input clock_1, clock_2;

reg [31:0] IF_ID_IR, IF_ID_NPC, PC;
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
    if(((EX_MEM_ALUOUT[31:26] == BNEQZ) && (EX_MEM_COND == 0)) || 
           ((EX_MEM_ALUOUT[31:26] == BEQZ) && (EX_MEM_COND == 1))) /// CHECK WEATHER THE CODE HAVE BRANCH INSTRUCTION
     begin                                                        /// IF YES DO WHAT IS THERE IN BRANCH INSTRUCTION
        IF_ID_IR <= #3 MEM[EX_MEM_ALUOUT];                        /// INSTRUCTION REG IS STORED IN IMMEDIATE ADDRESS
        TYPE_BRANCH <= #3 1'b1;                                   /// INFORM THAT THERE IS A BRANCH INSTRUCTION SO WE 
        IF_ID_NPC <= #3 EX_MEM_ALUOUT + 1;                        /// DONT WRITE ANYTHING TO MEMORY 
        PC <= #3 EX_MEM_ALUOUT + 1;                               /// INCREMENT THE PC AND NPC
     end
   else 
      begin
       PC <= #3 PC + 1;                                           /// IF NO BRANCE, DO NORMAL OPERATION
       IF_ID_NPC <= #3 PC + 1;                                          /// INCREMENT PC AND NPC
       IF_ID_IR <= #3 MEM[PC];                                    /// STORE THE MEMORY DATA(BASICALLY INSTRUCTION'S) 
       end                                                        /// INSTRUCTION REGISTER
end
else
     HALTED <= #3 1;                                                  /// ELSE DO HALT OPERATION
end


always @(negedge clock_2)                 /// AT NEGEDGE WE USE CLOCK_2 OF DECODE INSTRUCTION CYCLE
begin
  if(HALTED == 0)
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
      
         ADD, SUB, MUL, AND, OR, SLT : ID_EX_REG_TYPE <= #3 RR_ALU;  /// REG TO REG OPERATION
         LW                          : ID_EX_REG_TYPE <= #3 LOAD;    /// LOAD OPERATION
         SW                          : ID_EX_REG_TYPE <= #3 STORE;   /// STORE OPERATION
         ADDI, SUBI                  : ID_EX_REG_TYPE <= #3 RI_ALU;  /// REG TO IMM OPERATION
         BNEQZ, BEQZ                 : ID_EX_REG_TYPE <= #3 BRANCH;  /// BRANCH OPERATION
         HALT                        : ID_EX_REG_TYPE <= #3 HALT;    /// HALT OPEARTION
         default                     : ID_EX_REG_TYPE <= #3 HALT;
      
      endcase
end	
else HALTED <= #3  1;
end


always @(negedge clock_1)                /// AT NEGEDGE WE USE CLOCK_1 OF EXECUTE INSTRUCTION CYCLE
begin

if (HALTED == 0)
 begin
   case(ID_EX_REG_TYPE)                                          /// WE FIRST CHECK THE WHAT IS THE REGISTER TYPE WE 
                                                                 /// ARE ABOUT TO ENCOUNTER
        RR_ALU : case(ID_EX_IR[31:26])                               /// REG TO REG INSTRUCTION OPERATION
                   
                      ADD :  EX_MEM_ALUOUT <= #3 ID_EX_A + ID_EX_B;        /// ADDITION
                      SUB :  EX_MEM_ALUOUT <= #3 ID_EX_A - ID_EX_B;        /// SUBTRACTION
                      AND :  EX_MEM_ALUOUT <= #3 ID_EX_A & ID_EX_B;        /// AND                   
                       OR :  EX_MEM_ALUOUT <= #3 ID_EX_A | ID_EX_B;        /// OR
                      SLT :  EX_MEM_ALUOUT <= #3 ID_EX_A < ID_EX_B;        /// LESS THEN
                      MUL :  EX_MEM_ALUOUT <= #3 ID_EX_A * ID_EX_B;        /// DEFAULT
                  default :  EX_MEM_ALUOUT <= #3 32'bxxxxxxxx; 
                   
                 endcase

       RI_ALU : case(ID_EX_IR[31:26])                               /// REG TO IMMEDIATE OPERATION
                  
                     ADDI : EX_MEM_ALUOUT <= #3 ID_EX_A + ID_EX_IMM;       /// ADD IMMEDIATE
                     SUBI : EX_MEM_ALUOUT <= #3 ID_EX_B - ID_EX_IMM;       /// SUB IMMEDIATE
                     SLTI : EX_MEM_ALUOUT <= #3 ID_EX_A < ID_EX_IMM;       /// LESS THEN IMMEDIATE
                  default : EX_MEM_ALUOUT <= #3 32'bxxxxxxxx; 
                 
                endcase
 
       LOAD,  STORE : begin                                        /// LOAD AND STORE OPERATION
                     EX_MEM_ALUOUT  <= #3 ID_EX_A + ID_EX_IMM;             /// ADD 'A' WITH IMMEDIATE ADDRESS
                     EX_MEM_B      <= #3 ID_EX_B;                          /// TRANSFER 'B' VALUE TO NEXT REG
                       end
  
       BNEQZ, BEQZ :  begin                                        /// BRANCH EQ ZERO AND BRANCH NOT EQ
                    EX_MEM_ALUOUT  <= #3 ID_EX_NPC + ID_EX_IMM;            //// WITH NPC WE ADD IMMEDIATE ADDRESS 
                     EX_MEM_COND     <= #3  (ID_EX_A == 0);  /// A IS NOT ZERO MAKE COND = 1
                       end
        default    :  EX_MEM_ALUOUT <= #3 32'bxxxxxxxx;
         
      endcase

        EX_MEM_IR <= #3 ID_EX_IR;                                /// PASS IR VALUE TO NEXT REG
        EX_MEM_B  <= #3 ID_EX_B;
        EX_MEM_REG_TYPE <= #3 ID_EX_REG_TYPE;                    /// PASS THE TYPE ALSO FOR REFRENCE
        TYPE_BRANCH <= #3 0;                                     /// PUT TYPE_BRANCH AS ZERO 
end
else HALTED <= #3 1;

end



always @(negedge clock_2)                /// AT NEGEDGE WE USE CLOCK_2 OF MEMORY_WRITE INSTRUCTION CYCLE          
begin 
    if( HALTED == 0 )                        /// CHECK HALT SIGNAL
        begin
           case(EX_MEM_REG_TYPE)            
               
               RR_ALU , RI_ALU :  MEM_WB_ALUOUT <= #3 EX_MEM_ALUOUT;       /// IF IT IS RR AND RI PASS VALUE TO ANOTHER REG
               LOAD            :  MEM_WB_LMD    <= #3 MEM[EX_MEM_ALUOUT];  /// LOAD THE VALUE OF MEM AT LOACTION OF ALUOUT
               STORE           : if(TYPE_BRANCH == 0) MEM[EX_MEM_ALUOUT] <= #3 EX_MEM_B;  // IF TYPE BRANCH IS LOW ONLY WE WRITE INTO MEM
                                  else     MEM[EX_MEM_ALUOUT] <= #3 MEM[EX_MEM_ALUOUT];   // ELSE OF SYNCHESIS PURPOSE
               default         : MEM_WB_IR <= #3 EX_MEM_IR;
               
             endcase
              MEM_WB_REG_TYPE <= #3 EX_MEM_REG_TYPE;                               /// PASS THE TYPE TO NEXT REG
              MEM_WB_IR <= #3 EX_MEM_IR;                                   /// PASS THE IR TO NEXT REG
         end
     else  HALTED <= #3 1;    
end



always @(negedge clock_1)                /// AT NEGEDGE WE USE CLOCK_2 OF MEMORY_WRITE INSTRUCTION CYCLE 
begin
     if(TYPE_BRANCH == 0)            /// IF BRANCH IS NOT IN OPERATION ONLY WE TO STORING OPERATION
       begin
         case(MEM_WB_REG_TYPE)
           
              RR_ALU : REG[MEM_WB_IR[15:11]] <= #3 MEM_WB_ALUOUT;    // STORING INTO REG AT THE ADDRESS OF DESTINATION ADDRESS POINTS
              RI_ALU : REG[MEM_WB_IR[20:16]] <= #3 MEM_WB_ALUOUT;
              LOAD   : REG[MEM_WB_IR[20:16]] <= #3 MEM_WB_LMD;
              HALT   : HALTED <= #3 1'b1;
              default:  HALTED <= #3 1'b0;
           
         endcase           
       end
      else  HALTED <= #3 1'b0;
end         

endmodule 
