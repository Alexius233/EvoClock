;可调整的多功能电子时钟
ASSUME CS:CODE,DS:DATA,SS:STACK
;***************************************************
;各个常量的定义
;秒分时在存储体中的段地址
A_SMH	EQU 8000h
;秒分时在存储体中的偏移地址
A_SECOND EQU 0100H
A_MINUTE EQU 0200H
A_HOUR 	 EQU 0300H

;8255_1工作方式
MODE8255_1 EQU 10001001B
;8255_1各个口地址
PA8255_1 EQU 8000H
PB8255_1 EQU 8002H
PC8255_1 EQU 8004H
CON8255_1 EQU 8006H
;8255_2工作方式
MODE8255_2 EQU 10000010B
;8255_2各个口地址
PA8255_2 EQU 9000H
PB8255_2 EQU 9002H
PC8255_2 EQU 9004H
CON8255_2 EQU 9006H

;8259_1主片偶端口
CS8259_1A EQU 0A000H
;8259_1主片奇端口
CS8259_1B EQU 0A002H
;8259_1的各个操作字
AICW1 EQU 00010001B
AICW2 EQU 00100000B
AICW3 EQU 10000000B
AICW4 EQU 00010001B
AOCW1 EQU 00000000B
;8259_2从片偶端口
CS8259_2A EQU 0B000H
;8259_2从片奇端口
CS8259_2B EQU 0B002H
;8259_2的各个操作字
BICW1 EQU 00010001B
BICW2 EQU 00110000B
BICW3 EQU 00000111B
BICW4 EQU 00000001B
BOCW1 EQU 00000001B;初始默认为暂停计数，屏蔽CLOCK中断

;8253的端口地址
TCON0 EQU 0C000H
TCON1 EQU 0C002H
TCON2 EQU 0C004H
CONTR EQU 0C006H
;8253控制字
CON8253 EQU 00110100B
;计数初值
CONDATA EQU 000AH
;***************************************************
;***************************************************
;数据段
DATA SEGMENT
   FLAG DB 01H
   ;标志位，00H表示计数不暂停，01H表示计数暂停
   CLOCK_SPEED DB 0AH
   ;用于显示当前计数速度
DATA ENDS
;***************************************************
;***************************************************
;栈段
STACK SEGMENT
   STA DB 100 DUP(?)
   TOP EQU LENGTH STA
STACK ENDS
;***************************************************
;***************************************************
;代码段
CODE SEGMENT

START:
   ORG 800H
   MOV AX,DATA
   MOV DS,AX
   MOV AX,STACK
   MOV SS,AX
   MOV AX,TOP
   MOV SP,AX
   ;初始化8255
INIT8255:
   ;8255_1
   MOV AL,MODE8255_1
   MOV DX,CON8255_1
   OUT DX,AL
   ;8255_2
   MOV AL,MODE8255_2
   MOV DX,CON8255_2
   OUT DX,AL
   ;中断向量表
   CLI
   MOV AX,0000H
   MOV ES,AX
   MOV BX,CS
   MOV AX,OFFSET OP_START
   MOV ES:[128],AX
   MOV ES:[128+2],BX
   MOV BX,CS
   MOV AX,OFFSET OP_PAUSE
   MOV ES:[132],AX
   MOV ES:[132+2],BX
   MOV BX,CS
   MOV AX,OFFSET CLOCK
   MOV ES:[192],AX
   MOV ES:[192+2],BX
   MOV BX,CS
   MOV AX,OFFSET OP_INC
   MOV ES:[216],AX
   MOV ES:[216+2],BX
   MOV BX,CS
   MOV AX,OFFSET OP_DEC
   MOV ES:[220],AX
   MOV ES:[220+2],BX
   MOV BX,CS
   MOV AX,OFFSET SPEED_UP
   MOV ES:[208],AX
   MOV ES:[208+2],BX
   MOV BX,CS
   MOV AX,OFFSET SPEED_DOWN
   MOV ES:[212],AX
   MOV ES:[212+2],BX
   MOV BX,CS
   MOV AX,OFFSET SPEED_INIT
   MOV ES:[196],AX
   MOV ES:[196+2],BX
   MOV BX,CS
   MOV AX,OFFSET OP_ZERO
   MOV ES:[200],AX
   MOV ES:[200+2],BX
   MOV BX,CS
   MOV AX,OFFSET OP_LOAD
   MOV ES:[204],AX
   MOV ES:[204+2],BX
   STI
   ;初始化8259
INIT8259:
   ;8259_1
   MOV DX,CS8259_1A
   MOV AL,AICW1
   OUT DX,AL
   MOV DX,CS8259_1B
   MOV AL,AICW2
   OUT DX,AL
   MOV AL,AICW3
   OUT DX,AL
   MOV AL,AICW4
   OUT DX,AL
   MOV AL,AOCW1
   OUT DX,AL
   ;8259_2
   MOV DX,CS8259_2A
   MOV AL,BICW1
   OUT DX,AL
   MOV DX,CS8259_2B
   MOV AL,BICW2
   OUT DX,AL
   MOV AL,BICW3
   OUT DX,AL
   MOV AL,BICW4
   OUT DX,AL
   MOV AL,BOCW1
   OUT DX,AL
   ;初始化时钟存储
INIT_CLOCK:
   ;初始化时分秒
   MOV AX,A_SMH
   MOV ES,AX
   MOV AX,0000H
   MOV BX,A_SECOND
   MOV ES:[BX],AX
   MOV BX,A_MINUTE
   MOV ES:[BX],AX
   MOV BX,A_HOUR
   MOV ES:[BX],AX
   ;初始化8253
INIT8253:
   MOV AL,CON8253
   MOV DX,CONTR
   OUT DX,AL
   MOV AX,CONDATA
   MOV DX,TCON0
   OUT DX,AL
   MOV AL,AH
   OUT DX,AL
   ;更新标志位
   MOV AL,01H
   MOV BX,OFFSET DATA
   MOV DS:[BX],AL
   ;循环显示
LP:
   ;读DATA段，显示当前状态
   MOV BX,OFFSET CLOCK_SPEED
   MOV AL,DS:[BX];读当前计数初值
   MOV AH,00H
   MOV BX,AX
   MOV AX,000FH
   SUB AX,BX;转换为计数速度=0FH-计数初值
   SHL AX,1
   SHL AX,1
   SHL AX,1
   SHL AX,1;在AX中左移4位，使得能在8255_2C端口高四位输出
   MOV BX,OFFSET DATA
   MOV DL,DS:[BX];读当前状态
   ADD AL,DL;AL=计数速度(四位二进制)0000B+0000000当前状态(一位二进制)B
   ;从而实现8255_2C端口能同时读出计数速度与当前状态
   MOV DX,PC8255_2
   OUT DX,AL;同时读出计数速度与当前状态
   ;读存储体，并显示计时
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_SECOND
   MOV AX,ES:[BX]
   MOV DX,PA8255_1
   OUT DX,AL
   MOV BX,A_MINUTE
   MOV AX,ES:[BX]
   MOV DX,PB8255_1
   OUT DX,AL
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   MOV DX,PA8255_2
   OUT DX,AL
   JMP LP

;-------------恢复计数中断服务子程序 
OP_START:
   CLI
   MOV BX,OFFSET DATA
   MOV AL,DS:[BX];读当前状态
   MOV AH,00H
   CMP AX,0000H
   JZ START_END;不是暂停则关中断
   JMP _START;结束暂停并修改标志位
_START:
   ;屏蔽各个时钟调整程序的中断，取消屏蔽CLOCK中断
   MOV DX,CS8259_2B
   MOV AL,BICW2
   OUT DX,AL
   MOV AL,BICW3
   OUT DX,AL
   MOV AL,BICW4
   OUT DX,AL
   MOV AL,11111110B;仅不屏蔽CLOCK中断
   OUT DX,AL
   ;更新标志位
   MOV AL,00H
   MOV BX,OFFSET DATA
   MOV DS:[BX],AL
   JMP START_END
START_END:;关中断
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
   
;-------------暂停中断服务子程序 
OP_PAUSE:
   CLI
   MOV BX,OFFSET DATA
   MOV AL,DS:[BX];读当前状态
   MOV AH,00H
   CMP AX,0001H
   JZ PAUSE_END;是暂停则关中断
   JMP _PAUSE;暂停计数并修改标志位
_PAUSE:
   ;取消屏蔽各个时钟调整程序的中断，屏蔽CLOCK中断
   MOV DX,CS8259_2B
   MOV AL,BICW2
   OUT DX,AL
   MOV AL,BICW3
   OUT DX,AL
   MOV AL,BICW4
   OUT DX,AL
   MOV AL,00000001B;仅屏蔽CLOCK中断
   OUT DX,AL
   ;更新标志位
   MOV AL,01H
   MOV BX,OFFSET DATA
   MOV DS:[BX],AL
   JMP PAUSE_END
PAUSE_END:;关中断
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
OP_END:
   CLI
   MOV AX,0000H
   MOV BX,0020H
   ADD AL,BL
   DAA
   MOV DX,PA8255_1
   OUT DX,AL
   
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
   
;-------------时钟中断服务子程序
CLOCK:
   CLI
   ;秒级计数器加一
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_SECOND
   MOV AX,ES:[BX]
   ADD AX,0001H
   DAA
   MOV ES:[BX],AX
   ;调用时钟数规则化函数，进行进位处理
   CALL FAR PTR SAMPLE
   ;关中断
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
   
;-------------自增中断子程序
OP_INC:
   CLI
   ;读8255_1PC端口
   MOV DX,PC8255_1
   IN AL,DX
   MOV AH,00H
   ;根据8255_1PC口的输入来判断是给哪一位自增
   CMP AX,0000H
   JZ SECOND_INC
   CMP AX,0001H
   JZ MINUTE_INC
   CMP AX,0002H
   JZ HOUR_INC
   JMP SECOND_INC
END_INC: 
   ;规则化处理
   CALL FAR PTR SAMPLE
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
SECOND_INC:
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_SECOND
   MOV AX,ES:[BX]
   ADD AX,1
   DAA
   MOV ES:[BX],AX
   JMP END_INC
MINUTE_INC:
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_MINUTE
   MOV AX,ES:[BX]
   ADD AX,1
   DAA
   MOV ES:[BX],AX
   JMP END_INC
HOUR_INC:
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   ADD AX,1
   DAA
   MOV ES:[BX],AX
   JMP END_INC
   
;-------------自减中断子程序
OP_DEC:
   CLI
   ;读8255_1PC端口
   MOV DX,PC8255_1
   IN AL,DX
   MOV AH,00H
   ;根据8255_1PC口的输入来判断是给哪一位自增
   CMP AX,0000H
   JZ SECOND_DEC
   CMP AX,0001H
   JZ MINUTE_DEC
   CMP AX,0002H
   JZ HOUR_DEC
   JMP SECOND_DEC
END_DEC:
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
SECOND_DEC:;秒位自减
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_SECOND
   MOV AX,ES:[BX]
   CMP AX,0;先判断秒是否为零
   JZ SECOND_ZERO_1
   SUB AX,1;秒不为零则减一
   DAS
   MOV ES:[BX],AX
   JMP END_DEC
SECOND_ZERO_1:;秒位为零时
   MOV BX,A_MINUTE
   MOV AX,ES:[BX]
   CMP AX,0;先判断分是否为零
   JZ MINUTE_ZERO_1
   SUB AX,1;分不为零则减一
   DAS
   MOV ES:[BX],AX
   MOV AX,0059H;然后将秒置59
   MOV BX,A_SECOND
   MOV ES:[BX],AX
   JMP END_DEC
MINUTE_ZERO_1:;分秒都为零时
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   CMP AX,0;先判断时是否为零
   JZ HOUR_ZERO_1
   SUB AX,1;时不为零则减一
   DAS
   MOV ES:[BX],AX
   MOV AX,0059H;然后将秒与分置59
   MOV BX,A_SECOND
   MOV ES:[BX],AX
   MOV BX,A_MINUTE
   MOV ES:[BX],AX
   JMP END_DEC
HOUR_ZERO_1:;时分秒都为零时
   ;不做修改
   JMP END_DEC
MINUTE_DEC:;分位自减
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_MINUTE
   MOV AX,ES:[BX]
   CMP AX,0;先判断分是否为零
   JZ MINUTE_ZERO_2
   SUB AX,1;不为零则减一
   DAS
   MOV ES:[BX],AX
   JMP END_DEC
MINUTE_ZERO_2:
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   CMP AX,0;先判断时是否为零
   JZ HOUR_ZERO_2
   SUB AX,1
   DAS
   MOV ES:[BX],AX
   MOV BX,A_MINUTE
   MOV AX,0059H;然后将分置为59
   MOV ES:[BX],AX
   JMP END_DEC
HOUR_ZERO_2:;时和分都为零时
   ;不做修改
   JMP END_DEC
HOUR_DEC:;时位自减
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   CMP AX,0;先判断时是否为零
   JZ HOUR_ZERO_3
   SUB AX,1;不为零则减一
   DAS
   MOV ES:[BX],AX
   JMP END_DEC
HOUR_ZERO_3:;时都为零时
   ;不做修改
   JMP END_DEC
   
;-------------复位中断子程序
OP_ZERO:
   CLI
   ;将存储体内的对应时分秒复位到00:00:00
   MOV AX,A_SMH
   MOV ES,AX
   MOV AX,0000H
   MOV BX,A_SECOND
   MOV ES:[BX],AX
   MOV BX,A_MINUTE
   MOV ES:[BX],AX
   MOV BX,A_HOUR
   MOV ES:[BX],AX
   ;关中断
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
   
;-------------置数中断子程序
OP_LOAD:
   CLI
   ;读8255_1PC端口
   MOV DX,PC8255_1
   IN AL,DX
   MOV AH,00H
   ;根据8255_1PC口的输入来判断是给哪一位置数
   CMP AX,0000H
   JZ LOAD_SECOND
   CMP AX,0001H
   JZ LOAD_MINUTE
   CMP AX,0002H
   JZ LOAD_HOUR
   JMP LOAD_SECOND
NEXT_LOAD:
   ;关中断
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
LOAD_SECOND:
   MOV DX,PB8255_2
   IN AL,DX
   MOV AH,00H
   CMP AX,60H
   JAE SECOND_1
SECOND_2:
   ADD AX,0
   DAA
   MOV DX,AX
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_SECOND
   MOV ES:[BX],DX
   JMP NEXT_LOAD
SECOND_1:
   MOV AX,59H
   JMP SECOND_2
LOAD_MINUTE:
   MOV DX,PB8255_2
   IN AL,DX
   MOV AH,00H
   CMP AX,60H
   JAE MINUTE_1
MINUTE_2:
   ADD AX,0
   DAA
   MOV DX,AX
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_MINUTE
   MOV ES:[BX],DX
   JMP NEXT_LOAD
MINUTE_1:
   MOV AX,59H
   JMP MINUTE_2
LOAD_HOUR:
   MOV DX,PB8255_2
   IN AL,DX
   MOV AH,00H
   CMP AX,24H
   JAE HOUR_1
HOUR_2:
   ADD AX,0
   DAA
   MOV DX,AX
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_HOUR
   MOV ES:[BX],DX
   JMP NEXT_LOAD
HOUR_1:
   MOV AX,23H
   JMP HOUR_2

;-------------计时速度复位函数
INITCLOCK:
   MOV BX,OFFSET CLOCK_SPEED
   MOV AX,CONDATA
   MOV AH,00H
   MOV DS:[BX],AL;更新后的计时速度写入data段
   MOV DX,TCON0;修改计数初值
   OUT DX,AL
   MOV AL,AH
   OUT DX,AL
   RETF
;-------------提高速度中断子程序
SPEED_UP:
   CLI
   MOV BX,OFFSET CLOCK_SPEED
   MOV AH,00H
   MOV AL,DS:[BX]
   CMP AX,0005H
   JZ INITCLOCK_UP
   SUB AX,1;计数速度增加1
   MOV DS:[BX],AL;修改后的速度存入data段
   MOV DX,TCON0;修改计数初值
   OUT DX,AL
   MOV AL,AH
   OUT DX,AL
   JMP END_UP
INITCLOCK_UP:
   CALL FAR PTR INITCLOCK
   ;关中断
END_UP:
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
   
;-------------降低速度中断子程序
SPEED_DOWN:
   CLI
   MOV BX,OFFSET CLOCK_SPEED
   MOV AH,00H
   MOV AL,DS:[BX]
   CMP AX,000FH
   JZ INITCLOCK_DOWN
   ADD AX,1;计数速度减1
   MOV DS:[BX],AL;修改后的速度存入data段
   MOV DX,TCON0;修改计数初值
   OUT DX,AL
   MOV AL,AH
   OUT DX,AL
   JMP END_DOWN
INITCLOCK_DOWN:
   CALL FAR PTR INITCLOCK
   ;关中断
END_DOWN:
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET

;-------------复位速度中断子程序
SPEED_INIT:
   CLI
   CALL FAR PTR INITCLOCK
   ;关中断
END_INIT:
   MOV DX,CS8259_2A
   MOV AL,20H
   OUT DX,AL
   MOV DX,CS8259_1A
   MOV AL,20H
   OUT DX,AL
   STI
   IRET
   
;-------------时钟记录标准化函数
SAMPLE:
   MOV AX,A_SMH
   MOV ES,AX
   MOV BX,A_SECOND
   MOV AX,ES:[BX]
   CMP AX,0060H
   JAE SAMPLE_SECOND
SAMPLE_NEXT_1:
   MOV BX,A_MINUTE
   MOV AX,ES:[BX]
   CMP AX,0060H
   JAE SAMPLE_MINUTE
SAMPLE_NEXT_2:
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   CMP AX,0024H
   JAE SAMPLE_HOUR 
SAMPLE_NEXT_3:
   RETF
SAMPLE_SECOND:
   MOV AX,0
   MOV ES:[BX],AX
   MOV BX,A_MINUTE
   MOV AX,ES:[BX]
   ADD AX,0001H
   DAA
   MOV ES:[BX],AX
   JMP SAMPLE_NEXT_1
SAMPLE_MINUTE:
   MOV AX,0
   MOV ES:[BX],AX
   MOV BX,A_HOUR
   MOV AX,ES:[BX]
   ADD AX,0001H
   DAA
   MOV ES:[BX],AX
   JMP SAMPLE_NEXT_2
SAMPLE_HOUR:
   MOV AX,0   
   MOV BX,A_SECOND
   MOV ES:[BX],AX
   MOV BX,A_MINUTE
   MOV ES:[BX],AX
   MOV BX,A_HOUR
   MOV ES:[BX],AX
   JMP SAMPLE_NEXT_3
   
CODE ENDS
;***************************************************
   END START