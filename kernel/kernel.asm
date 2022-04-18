
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	acc78793          	addi	a5,a5,-1332 # 80005b30 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	33a080e7          	jalr	826(ra) # 80002466 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e98080e7          	jalr	-360(ra) # 8000206c <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	200080e7          	jalr	512(ra) # 80002410 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	1ca080e7          	jalr	458(ra) # 800024bc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	db2080e7          	jalr	-590(ra) # 800021f8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	958080e7          	jalr	-1704(ra) # 800021f8 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	740080e7          	jalr	1856(ra) # 8000206c <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	728080e7          	jalr	1832(ra) # 800025fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	c94080e7          	jalr	-876(ra) # 80005b70 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fd6080e7          	jalr	-42(ra) # 80001eba <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	688080e7          	jalr	1672(ra) # 800025d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	6a8080e7          	jalr	1704(ra) # 800025fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	bfe080e7          	jalr	-1026(ra) # 80005b5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	c0c080e7          	jalr	-1012(ra) # 80005b70 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	dee080e7          	jalr	-530(ra) # 80002d5a <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	47e080e7          	jalr	1150(ra) # 800033f2 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	428080e7          	jalr	1064(ra) # 800043a4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	d0e080e7          	jalr	-754(ra) # 80005c92 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e207a783          	lw	a5,-480(a5) # 80008820 <first.1672>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	c0a080e7          	jalr	-1014(ra) # 80002614 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e007a323          	sw	zero,-506(a5) # 80008820 <first.1672>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	94e080e7          	jalr	-1714(ra) # 80003372 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	dd878793          	addi	a5,a5,-552 # 80008824 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	50290913          	addi	s2,s2,1282 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	b8858593          	addi	a1,a1,-1144 # 80008830 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	0ba080e7          	jalr	186(ra) # 80003da0 <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050b63          	beqz	a0,80001eb6 <fork+0x138>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054663          	bltz	a0,80001e04 <fork+0x86>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0589b703          	ld	a4,88(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df2:	0589b783          	ld	a5,88(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000a13          	li	s4,336
    80001e02:	a03d                	j	80001e30 <fork+0xb2>
    freeproc(np);
    80001e04:	854e                	mv	a0,s3
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d5c080e7          	jalr	-676(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e88080e7          	jalr	-376(ra) # 80000c98 <release>
    return -1;
    80001e18:	5a7d                	li	s4,-1
    80001e1a:	a069                	j	80001ea4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	61a080e7          	jalr	1562(ra) # 80004436 <filedup>
    80001e24:	009987b3          	add	a5,s3,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01448763          	beq	s1,s4,80001e3a <fork+0xbc>
    if(p->ofile[i])
    80001e30:	009907b3          	add	a5,s2,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0x9e>
    80001e38:	bfcd                	j	80001e2a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e3a:	15093503          	ld	a0,336(s2)
    80001e3e:	00001097          	auipc	ra,0x1
    80001e42:	76e080e7          	jalr	1902(ra) # 800035ac <idup>
    80001e46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	15890593          	addi	a1,s2,344
    80001e50:	15898513          	addi	a0,s3,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fde080e7          	jalr	-34(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e6a:	0000f497          	auipc	s1,0xf
    80001e6e:	44e48493          	addi	s1,s1,1102 # 800112b8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e7c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	70a2                	ld	ra,40(sp)
    80001ea8:	7402                	ld	s0,32(sp)
    80001eaa:	64e2                	ld	s1,24(sp)
    80001eac:	6942                	ld	s2,16(sp)
    80001eae:	69a2                	ld	s3,8(sp)
    80001eb0:	6a02                	ld	s4,0(sp)
    80001eb2:	6145                	addi	sp,sp,48
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	5a7d                	li	s4,-1
    80001eb8:	b7f5                	j	80001ea4 <fork+0x126>

0000000080001eba <scheduler>:
{
    80001eba:	7139                	addi	sp,sp,-64
    80001ebc:	fc06                	sd	ra,56(sp)
    80001ebe:	f822                	sd	s0,48(sp)
    80001ec0:	f426                	sd	s1,40(sp)
    80001ec2:	f04a                	sd	s2,32(sp)
    80001ec4:	ec4e                	sd	s3,24(sp)
    80001ec6:	e852                	sd	s4,16(sp)
    80001ec8:	e456                	sd	s5,8(sp)
    80001eca:	e05a                	sd	s6,0(sp)
    80001ecc:	0080                	addi	s0,sp,64
    80001ece:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed2:	00779a93          	slli	s5,a5,0x7
    80001ed6:	0000f717          	auipc	a4,0xf
    80001eda:	3ca70713          	addi	a4,a4,970 # 800112a0 <pid_lock>
    80001ede:	9756                	add	a4,a4,s5
    80001ee0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	3f470713          	addi	a4,a4,1012 # 800112d8 <cpus+0x8>
    80001eec:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eee:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef0:	4b11                	li	s6,4
        c->proc = p;
    80001ef2:	079e                	slli	a5,a5,0x7
    80001ef4:	0000fa17          	auipc	s4,0xf
    80001ef8:	3aca0a13          	addi	s4,s4,940 # 800112a0 <pid_lock>
    80001efc:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001efe:	00015917          	auipc	s2,0x15
    80001f02:	1d290913          	addi	s2,s2,466 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f06:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f0a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0e:	10079073          	csrw	sstatus,a5
    80001f12:	0000f497          	auipc	s1,0xf
    80001f16:	7be48493          	addi	s1,s1,1982 # 800116d0 <proc>
    80001f1a:	a03d                	j	80001f48 <scheduler+0x8e>
        p->state = RUNNING;
    80001f1c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f20:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f24:	06048593          	addi	a1,s1,96
    80001f28:	8556                	mv	a0,s5
    80001f2a:	00000097          	auipc	ra,0x0
    80001f2e:	640080e7          	jalr	1600(ra) # 8000256a <swtch>
        c->proc = 0;
    80001f32:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	d60080e7          	jalr	-672(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	16848493          	addi	s1,s1,360
    80001f44:	fd2481e3          	beq	s1,s2,80001f06 <scheduler+0x4c>
      acquire(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	c9a080e7          	jalr	-870(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f52:	4c9c                	lw	a5,24(s1)
    80001f54:	ff3791e3          	bne	a5,s3,80001f36 <scheduler+0x7c>
    80001f58:	b7d1                	j	80001f1c <scheduler+0x62>

0000000080001f5a <sched>:
{
    80001f5a:	7179                	addi	sp,sp,-48
    80001f5c:	f406                	sd	ra,40(sp)
    80001f5e:	f022                	sd	s0,32(sp)
    80001f60:	ec26                	sd	s1,24(sp)
    80001f62:	e84a                	sd	s2,16(sp)
    80001f64:	e44e                	sd	s3,8(sp)
    80001f66:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	a48080e7          	jalr	-1464(ra) # 800019b0 <myproc>
    80001f70:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	bf8080e7          	jalr	-1032(ra) # 80000b6a <holding>
    80001f7a:	c93d                	beqz	a0,80001ff0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f7e:	2781                	sext.w	a5,a5
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	0000f717          	auipc	a4,0xf
    80001f86:	31e70713          	addi	a4,a4,798 # 800112a0 <pid_lock>
    80001f8a:	97ba                	add	a5,a5,a4
    80001f8c:	0a87a703          	lw	a4,168(a5)
    80001f90:	4785                	li	a5,1
    80001f92:	06f71763          	bne	a4,a5,80002000 <sched+0xa6>
  if(p->state == RUNNING)
    80001f96:	4c98                	lw	a4,24(s1)
    80001f98:	4791                	li	a5,4
    80001f9a:	06f70b63          	beq	a4,a5,80002010 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fa4:	efb5                	bnez	a5,80002020 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa8:	0000f917          	auipc	s2,0xf
    80001fac:	2f890913          	addi	s2,s2,760 # 800112a0 <pid_lock>
    80001fb0:	2781                	sext.w	a5,a5
    80001fb2:	079e                	slli	a5,a5,0x7
    80001fb4:	97ca                	add	a5,a5,s2
    80001fb6:	0ac7a983          	lw	s3,172(a5)
    80001fba:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fbc:	2781                	sext.w	a5,a5
    80001fbe:	079e                	slli	a5,a5,0x7
    80001fc0:	0000f597          	auipc	a1,0xf
    80001fc4:	31858593          	addi	a1,a1,792 # 800112d8 <cpus+0x8>
    80001fc8:	95be                	add	a1,a1,a5
    80001fca:	06048513          	addi	a0,s1,96
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	59c080e7          	jalr	1436(ra) # 8000256a <swtch>
    80001fd6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd8:	2781                	sext.w	a5,a5
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	97ca                	add	a5,a5,s2
    80001fde:	0b37a623          	sw	s3,172(a5)
}
    80001fe2:	70a2                	ld	ra,40(sp)
    80001fe4:	7402                	ld	s0,32(sp)
    80001fe6:	64e2                	ld	s1,24(sp)
    80001fe8:	6942                	ld	s2,16(sp)
    80001fea:	69a2                	ld	s3,8(sp)
    80001fec:	6145                	addi	sp,sp,48
    80001fee:	8082                	ret
    panic("sched p->lock");
    80001ff0:	00006517          	auipc	a0,0x6
    80001ff4:	22850513          	addi	a0,a0,552 # 80008218 <digits+0x1d8>
    80001ff8:	ffffe097          	auipc	ra,0xffffe
    80001ffc:	546080e7          	jalr	1350(ra) # 8000053e <panic>
    panic("sched locks");
    80002000:	00006517          	auipc	a0,0x6
    80002004:	22850513          	addi	a0,a0,552 # 80008228 <digits+0x1e8>
    80002008:	ffffe097          	auipc	ra,0xffffe
    8000200c:	536080e7          	jalr	1334(ra) # 8000053e <panic>
    panic("sched running");
    80002010:	00006517          	auipc	a0,0x6
    80002014:	22850513          	addi	a0,a0,552 # 80008238 <digits+0x1f8>
    80002018:	ffffe097          	auipc	ra,0xffffe
    8000201c:	526080e7          	jalr	1318(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002020:	00006517          	auipc	a0,0x6
    80002024:	22850513          	addi	a0,a0,552 # 80008248 <digits+0x208>
    80002028:	ffffe097          	auipc	ra,0xffffe
    8000202c:	516080e7          	jalr	1302(ra) # 8000053e <panic>

0000000080002030 <yield>:
{
    80002030:	1101                	addi	sp,sp,-32
    80002032:	ec06                	sd	ra,24(sp)
    80002034:	e822                	sd	s0,16(sp)
    80002036:	e426                	sd	s1,8(sp)
    80002038:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	976080e7          	jalr	-1674(ra) # 800019b0 <myproc>
    80002042:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	ba0080e7          	jalr	-1120(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000204c:	478d                	li	a5,3
    8000204e:	cc9c                	sw	a5,24(s1)
  sched();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	f0a080e7          	jalr	-246(ra) # 80001f5a <sched>
  release(&p->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c3e080e7          	jalr	-962(ra) # 80000c98 <release>
}
    80002062:	60e2                	ld	ra,24(sp)
    80002064:	6442                	ld	s0,16(sp)
    80002066:	64a2                	ld	s1,8(sp)
    80002068:	6105                	addi	sp,sp,32
    8000206a:	8082                	ret

000000008000206c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000206c:	7179                	addi	sp,sp,-48
    8000206e:	f406                	sd	ra,40(sp)
    80002070:	f022                	sd	s0,32(sp)
    80002072:	ec26                	sd	s1,24(sp)
    80002074:	e84a                	sd	s2,16(sp)
    80002076:	e44e                	sd	s3,8(sp)
    80002078:	1800                	addi	s0,sp,48
    8000207a:	89aa                	mv	s3,a0
    8000207c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207e:	00000097          	auipc	ra,0x0
    80002082:	932080e7          	jalr	-1742(ra) # 800019b0 <myproc>
    80002086:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	b5c080e7          	jalr	-1188(ra) # 80000be4 <acquire>
  release(lk);
    80002090:	854a                	mv	a0,s2
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000209a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209e:	4789                	li	a5,2
    800020a0:	cc9c                	sw	a5,24(s1)

  sched();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	eb8080e7          	jalr	-328(ra) # 80001f5a <sched>

  // Tidy up.
  p->chan = 0;
    800020aa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ae:	8526                	mv	a0,s1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	be8080e7          	jalr	-1048(ra) # 80000c98 <release>
  acquire(lk);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
}
    800020c2:	70a2                	ld	ra,40(sp)
    800020c4:	7402                	ld	s0,32(sp)
    800020c6:	64e2                	ld	s1,24(sp)
    800020c8:	6942                	ld	s2,16(sp)
    800020ca:	69a2                	ld	s3,8(sp)
    800020cc:	6145                	addi	sp,sp,48
    800020ce:	8082                	ret

00000000800020d0 <wait>:
{
    800020d0:	715d                	addi	sp,sp,-80
    800020d2:	e486                	sd	ra,72(sp)
    800020d4:	e0a2                	sd	s0,64(sp)
    800020d6:	fc26                	sd	s1,56(sp)
    800020d8:	f84a                	sd	s2,48(sp)
    800020da:	f44e                	sd	s3,40(sp)
    800020dc:	f052                	sd	s4,32(sp)
    800020de:	ec56                	sd	s5,24(sp)
    800020e0:	e85a                	sd	s6,16(sp)
    800020e2:	e45e                	sd	s7,8(sp)
    800020e4:	e062                	sd	s8,0(sp)
    800020e6:	0880                	addi	s0,sp,80
    800020e8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	8c6080e7          	jalr	-1850(ra) # 800019b0 <myproc>
    800020f2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020f4:	0000f517          	auipc	a0,0xf
    800020f8:	1c450513          	addi	a0,a0,452 # 800112b8 <wait_lock>
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
    havekids = 0;
    80002104:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002106:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002108:	00015997          	auipc	s3,0x15
    8000210c:	fc898993          	addi	s3,s3,-56 # 800170d0 <tickslock>
        havekids = 1;
    80002110:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002112:	0000fc17          	auipc	s8,0xf
    80002116:	1a6c0c13          	addi	s8,s8,422 # 800112b8 <wait_lock>
    havekids = 0;
    8000211a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000211c:	0000f497          	auipc	s1,0xf
    80002120:	5b448493          	addi	s1,s1,1460 # 800116d0 <proc>
    80002124:	a0bd                	j	80002192 <wait+0xc2>
          pid = np->pid;
    80002126:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000212a:	000b0e63          	beqz	s6,80002146 <wait+0x76>
    8000212e:	4691                	li	a3,4
    80002130:	02c48613          	addi	a2,s1,44
    80002134:	85da                	mv	a1,s6
    80002136:	05093503          	ld	a0,80(s2)
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	538080e7          	jalr	1336(ra) # 80001672 <copyout>
    80002142:	02054563          	bltz	a0,8000216c <wait+0x9c>
          freeproc(np);
    80002146:	8526                	mv	a0,s1
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	a1a080e7          	jalr	-1510(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
          release(&wait_lock);
    8000215a:	0000f517          	auipc	a0,0xf
    8000215e:	15e50513          	addi	a0,a0,350 # 800112b8 <wait_lock>
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	b36080e7          	jalr	-1226(ra) # 80000c98 <release>
          return pid;
    8000216a:	a09d                	j	800021d0 <wait+0x100>
            release(&np->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>
            release(&wait_lock);
    80002176:	0000f517          	auipc	a0,0xf
    8000217a:	14250513          	addi	a0,a0,322 # 800112b8 <wait_lock>
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b1a080e7          	jalr	-1254(ra) # 80000c98 <release>
            return -1;
    80002186:	59fd                	li	s3,-1
    80002188:	a0a1                	j	800021d0 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000218a:	16848493          	addi	s1,s1,360
    8000218e:	03348463          	beq	s1,s3,800021b6 <wait+0xe6>
      if(np->parent == p){
    80002192:	7c9c                	ld	a5,56(s1)
    80002194:	ff279be3          	bne	a5,s2,8000218a <wait+0xba>
        acquire(&np->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a4a080e7          	jalr	-1462(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021a2:	4c9c                	lw	a5,24(s1)
    800021a4:	f94781e3          	beq	a5,s4,80002126 <wait+0x56>
        release(&np->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
        havekids = 1;
    800021b2:	8756                	mv	a4,s5
    800021b4:	bfd9                	j	8000218a <wait+0xba>
    if(!havekids || p->killed){
    800021b6:	c701                	beqz	a4,800021be <wait+0xee>
    800021b8:	02892783          	lw	a5,40(s2)
    800021bc:	c79d                	beqz	a5,800021ea <wait+0x11a>
      release(&wait_lock);
    800021be:	0000f517          	auipc	a0,0xf
    800021c2:	0fa50513          	addi	a0,a0,250 # 800112b8 <wait_lock>
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
      return -1;
    800021ce:	59fd                	li	s3,-1
}
    800021d0:	854e                	mv	a0,s3
    800021d2:	60a6                	ld	ra,72(sp)
    800021d4:	6406                	ld	s0,64(sp)
    800021d6:	74e2                	ld	s1,56(sp)
    800021d8:	7942                	ld	s2,48(sp)
    800021da:	79a2                	ld	s3,40(sp)
    800021dc:	7a02                	ld	s4,32(sp)
    800021de:	6ae2                	ld	s5,24(sp)
    800021e0:	6b42                	ld	s6,16(sp)
    800021e2:	6ba2                	ld	s7,8(sp)
    800021e4:	6c02                	ld	s8,0(sp)
    800021e6:	6161                	addi	sp,sp,80
    800021e8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021ea:	85e2                	mv	a1,s8
    800021ec:	854a                	mv	a0,s2
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	e7e080e7          	jalr	-386(ra) # 8000206c <sleep>
    havekids = 0;
    800021f6:	b715                	j	8000211a <wait+0x4a>

00000000800021f8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021f8:	7139                	addi	sp,sp,-64
    800021fa:	fc06                	sd	ra,56(sp)
    800021fc:	f822                	sd	s0,48(sp)
    800021fe:	f426                	sd	s1,40(sp)
    80002200:	f04a                	sd	s2,32(sp)
    80002202:	ec4e                	sd	s3,24(sp)
    80002204:	e852                	sd	s4,16(sp)
    80002206:	e456                	sd	s5,8(sp)
    80002208:	0080                	addi	s0,sp,64
    8000220a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000220c:	0000f497          	auipc	s1,0xf
    80002210:	4c448493          	addi	s1,s1,1220 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002214:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002216:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002218:	00015917          	auipc	s2,0x15
    8000221c:	eb890913          	addi	s2,s2,-328 # 800170d0 <tickslock>
    80002220:	a821                	j	80002238 <wakeup+0x40>
        p->state = RUNNABLE;
    80002222:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a70080e7          	jalr	-1424(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002230:	16848493          	addi	s1,s1,360
    80002234:	03248463          	beq	s1,s2,8000225c <wakeup+0x64>
    if(p != myproc()){
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	778080e7          	jalr	1912(ra) # 800019b0 <myproc>
    80002240:	fea488e3          	beq	s1,a0,80002230 <wakeup+0x38>
      acquire(&p->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	99e080e7          	jalr	-1634(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000224e:	4c9c                	lw	a5,24(s1)
    80002250:	fd379be3          	bne	a5,s3,80002226 <wakeup+0x2e>
    80002254:	709c                	ld	a5,32(s1)
    80002256:	fd4798e3          	bne	a5,s4,80002226 <wakeup+0x2e>
    8000225a:	b7e1                	j	80002222 <wakeup+0x2a>
    }
  }
}
    8000225c:	70e2                	ld	ra,56(sp)
    8000225e:	7442                	ld	s0,48(sp)
    80002260:	74a2                	ld	s1,40(sp)
    80002262:	7902                	ld	s2,32(sp)
    80002264:	69e2                	ld	s3,24(sp)
    80002266:	6a42                	ld	s4,16(sp)
    80002268:	6aa2                	ld	s5,8(sp)
    8000226a:	6121                	addi	sp,sp,64
    8000226c:	8082                	ret

000000008000226e <reparent>:
{
    8000226e:	7179                	addi	sp,sp,-48
    80002270:	f406                	sd	ra,40(sp)
    80002272:	f022                	sd	s0,32(sp)
    80002274:	ec26                	sd	s1,24(sp)
    80002276:	e84a                	sd	s2,16(sp)
    80002278:	e44e                	sd	s3,8(sp)
    8000227a:	e052                	sd	s4,0(sp)
    8000227c:	1800                	addi	s0,sp,48
    8000227e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002280:	0000f497          	auipc	s1,0xf
    80002284:	45048493          	addi	s1,s1,1104 # 800116d0 <proc>
      pp->parent = initproc;
    80002288:	00007a17          	auipc	s4,0x7
    8000228c:	da0a0a13          	addi	s4,s4,-608 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002290:	00015997          	auipc	s3,0x15
    80002294:	e4098993          	addi	s3,s3,-448 # 800170d0 <tickslock>
    80002298:	a029                	j	800022a2 <reparent+0x34>
    8000229a:	16848493          	addi	s1,s1,360
    8000229e:	01348d63          	beq	s1,s3,800022b8 <reparent+0x4a>
    if(pp->parent == p){
    800022a2:	7c9c                	ld	a5,56(s1)
    800022a4:	ff279be3          	bne	a5,s2,8000229a <reparent+0x2c>
      pp->parent = initproc;
    800022a8:	000a3503          	ld	a0,0(s4)
    800022ac:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	f4a080e7          	jalr	-182(ra) # 800021f8 <wakeup>
    800022b6:	b7d5                	j	8000229a <reparent+0x2c>
}
    800022b8:	70a2                	ld	ra,40(sp)
    800022ba:	7402                	ld	s0,32(sp)
    800022bc:	64e2                	ld	s1,24(sp)
    800022be:	6942                	ld	s2,16(sp)
    800022c0:	69a2                	ld	s3,8(sp)
    800022c2:	6a02                	ld	s4,0(sp)
    800022c4:	6145                	addi	sp,sp,48
    800022c6:	8082                	ret

00000000800022c8 <exit>:
{
    800022c8:	7179                	addi	sp,sp,-48
    800022ca:	f406                	sd	ra,40(sp)
    800022cc:	f022                	sd	s0,32(sp)
    800022ce:	ec26                	sd	s1,24(sp)
    800022d0:	e84a                	sd	s2,16(sp)
    800022d2:	e44e                	sd	s3,8(sp)
    800022d4:	e052                	sd	s4,0(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	6d6080e7          	jalr	1750(ra) # 800019b0 <myproc>
    800022e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800022e4:	00007797          	auipc	a5,0x7
    800022e8:	d447b783          	ld	a5,-700(a5) # 80009028 <initproc>
    800022ec:	0d050493          	addi	s1,a0,208
    800022f0:	15050913          	addi	s2,a0,336
    800022f4:	02a79363          	bne	a5,a0,8000231a <exit+0x52>
    panic("init exiting");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	f6850513          	addi	a0,a0,-152 # 80008260 <digits+0x220>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
      fileclose(f);
    80002308:	00002097          	auipc	ra,0x2
    8000230c:	180080e7          	jalr	384(ra) # 80004488 <fileclose>
      p->ofile[fd] = 0;
    80002310:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002314:	04a1                	addi	s1,s1,8
    80002316:	01248563          	beq	s1,s2,80002320 <exit+0x58>
    if(p->ofile[fd]){
    8000231a:	6088                	ld	a0,0(s1)
    8000231c:	f575                	bnez	a0,80002308 <exit+0x40>
    8000231e:	bfdd                	j	80002314 <exit+0x4c>
  begin_op();
    80002320:	00002097          	auipc	ra,0x2
    80002324:	c9c080e7          	jalr	-868(ra) # 80003fbc <begin_op>
  iput(p->cwd);
    80002328:	1509b503          	ld	a0,336(s3)
    8000232c:	00001097          	auipc	ra,0x1
    80002330:	478080e7          	jalr	1144(ra) # 800037a4 <iput>
  end_op();
    80002334:	00002097          	auipc	ra,0x2
    80002338:	d08080e7          	jalr	-760(ra) # 8000403c <end_op>
  p->cwd = 0;
    8000233c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002340:	0000f497          	auipc	s1,0xf
    80002344:	f7848493          	addi	s1,s1,-136 # 800112b8 <wait_lock>
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	89a080e7          	jalr	-1894(ra) # 80000be4 <acquire>
  reparent(p);
    80002352:	854e                	mv	a0,s3
    80002354:	00000097          	auipc	ra,0x0
    80002358:	f1a080e7          	jalr	-230(ra) # 8000226e <reparent>
  wakeup(p->parent);
    8000235c:	0389b503          	ld	a0,56(s3)
    80002360:	00000097          	auipc	ra,0x0
    80002364:	e98080e7          	jalr	-360(ra) # 800021f8 <wakeup>
  acquire(&p->lock);
    80002368:	854e                	mv	a0,s3
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	87a080e7          	jalr	-1926(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002372:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002376:	4795                	li	a5,5
    80002378:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
  sched();
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	bd4080e7          	jalr	-1068(ra) # 80001f5a <sched>
  panic("zombie exit");
    8000238e:	00006517          	auipc	a0,0x6
    80002392:	ee250513          	addi	a0,a0,-286 # 80008270 <digits+0x230>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>

000000008000239e <kill>:
// to user space (see usertrap() in trap.c).


int
kill(int pid)
{
    8000239e:	7179                	addi	sp,sp,-48
    800023a0:	f406                	sd	ra,40(sp)
    800023a2:	f022                	sd	s0,32(sp)
    800023a4:	ec26                	sd	s1,24(sp)
    800023a6:	e84a                	sd	s2,16(sp)
    800023a8:	e44e                	sd	s3,8(sp)
    800023aa:	1800                	addi	s0,sp,48
    800023ac:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023ae:	0000f497          	auipc	s1,0xf
    800023b2:	32248493          	addi	s1,s1,802 # 800116d0 <proc>
    800023b6:	00015997          	auipc	s3,0x15
    800023ba:	d1a98993          	addi	s3,s3,-742 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	824080e7          	jalr	-2012(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800023c8:	589c                	lw	a5,48(s1)
    800023ca:	01278d63          	beq	a5,s2,800023e4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8c8080e7          	jalr	-1848(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023d8:	16848493          	addi	s1,s1,360
    800023dc:	ff3491e3          	bne	s1,s3,800023be <kill+0x20>
  }
  return -1;
    800023e0:	557d                	li	a0,-1
    800023e2:	a829                	j	800023fc <kill+0x5e>
      p->killed = 1;
    800023e4:	4785                	li	a5,1
    800023e6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023e8:	4c98                	lw	a4,24(s1)
    800023ea:	4789                	li	a5,2
    800023ec:	00f70f63          	beq	a4,a5,8000240a <kill+0x6c>
      release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
      return 0;
    800023fa:	4501                	li	a0,0
}
    800023fc:	70a2                	ld	ra,40(sp)
    800023fe:	7402                	ld	s0,32(sp)
    80002400:	64e2                	ld	s1,24(sp)
    80002402:	6942                	ld	s2,16(sp)
    80002404:	69a2                	ld	s3,8(sp)
    80002406:	6145                	addi	sp,sp,48
    80002408:	8082                	ret
        p->state = RUNNABLE;
    8000240a:	478d                	li	a5,3
    8000240c:	cc9c                	sw	a5,24(s1)
    8000240e:	b7cd                	j	800023f0 <kill+0x52>

0000000080002410 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002410:	7179                	addi	sp,sp,-48
    80002412:	f406                	sd	ra,40(sp)
    80002414:	f022                	sd	s0,32(sp)
    80002416:	ec26                	sd	s1,24(sp)
    80002418:	e84a                	sd	s2,16(sp)
    8000241a:	e44e                	sd	s3,8(sp)
    8000241c:	e052                	sd	s4,0(sp)
    8000241e:	1800                	addi	s0,sp,48
    80002420:	84aa                	mv	s1,a0
    80002422:	892e                	mv	s2,a1
    80002424:	89b2                	mv	s3,a2
    80002426:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	588080e7          	jalr	1416(ra) # 800019b0 <myproc>
  if(user_dst){
    80002430:	c08d                	beqz	s1,80002452 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002432:	86d2                	mv	a3,s4
    80002434:	864e                	mv	a2,s3
    80002436:	85ca                	mv	a1,s2
    80002438:	6928                	ld	a0,80(a0)
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	238080e7          	jalr	568(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002442:	70a2                	ld	ra,40(sp)
    80002444:	7402                	ld	s0,32(sp)
    80002446:	64e2                	ld	s1,24(sp)
    80002448:	6942                	ld	s2,16(sp)
    8000244a:	69a2                	ld	s3,8(sp)
    8000244c:	6a02                	ld	s4,0(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret
    memmove((char *)dst, src, len);
    80002452:	000a061b          	sext.w	a2,s4
    80002456:	85ce                	mv	a1,s3
    80002458:	854a                	mv	a0,s2
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	8e6080e7          	jalr	-1818(ra) # 80000d40 <memmove>
    return 0;
    80002462:	8526                	mv	a0,s1
    80002464:	bff9                	j	80002442 <either_copyout+0x32>

0000000080002466 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	e052                	sd	s4,0(sp)
    80002474:	1800                	addi	s0,sp,48
    80002476:	892a                	mv	s2,a0
    80002478:	84ae                	mv	s1,a1
    8000247a:	89b2                	mv	s3,a2
    8000247c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	532080e7          	jalr	1330(ra) # 800019b0 <myproc>
  if(user_src){
    80002486:	c08d                	beqz	s1,800024a8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002488:	86d2                	mv	a3,s4
    8000248a:	864e                	mv	a2,s3
    8000248c:	85ca                	mv	a1,s2
    8000248e:	6928                	ld	a0,80(a0)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	26e080e7          	jalr	622(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002498:	70a2                	ld	ra,40(sp)
    8000249a:	7402                	ld	s0,32(sp)
    8000249c:	64e2                	ld	s1,24(sp)
    8000249e:	6942                	ld	s2,16(sp)
    800024a0:	69a2                	ld	s3,8(sp)
    800024a2:	6a02                	ld	s4,0(sp)
    800024a4:	6145                	addi	sp,sp,48
    800024a6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024a8:	000a061b          	sext.w	a2,s4
    800024ac:	85ce                	mv	a1,s3
    800024ae:	854a                	mv	a0,s2
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	890080e7          	jalr	-1904(ra) # 80000d40 <memmove>
    return 0;
    800024b8:	8526                	mv	a0,s1
    800024ba:	bff9                	j	80002498 <either_copyin+0x32>

00000000800024bc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024bc:	715d                	addi	sp,sp,-80
    800024be:	e486                	sd	ra,72(sp)
    800024c0:	e0a2                	sd	s0,64(sp)
    800024c2:	fc26                	sd	s1,56(sp)
    800024c4:	f84a                	sd	s2,48(sp)
    800024c6:	f44e                	sd	s3,40(sp)
    800024c8:	f052                	sd	s4,32(sp)
    800024ca:	ec56                	sd	s5,24(sp)
    800024cc:	e85a                	sd	s6,16(sp)
    800024ce:	e45e                	sd	s7,8(sp)
    800024d0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	bf650513          	addi	a0,a0,-1034 # 800080c8 <digits+0x88>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	0ae080e7          	jalr	174(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024e2:	0000f497          	auipc	s1,0xf
    800024e6:	34648493          	addi	s1,s1,838 # 80011828 <proc+0x158>
    800024ea:	00015917          	auipc	s2,0x15
    800024ee:	d3e90913          	addi	s2,s2,-706 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024f4:	00006997          	auipc	s3,0x6
    800024f8:	d8c98993          	addi	s3,s3,-628 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024fc:	00006a97          	auipc	s5,0x6
    80002500:	d8ca8a93          	addi	s5,s5,-628 # 80008288 <digits+0x248>
    printf("\n");
    80002504:	00006a17          	auipc	s4,0x6
    80002508:	bc4a0a13          	addi	s4,s4,-1084 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000250c:	00006b97          	auipc	s7,0x6
    80002510:	db4b8b93          	addi	s7,s7,-588 # 800082c0 <states.1709>
    80002514:	a00d                	j	80002536 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002516:	ed86a583          	lw	a1,-296(a3)
    8000251a:	8556                	mv	a0,s5
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	06c080e7          	jalr	108(ra) # 80000588 <printf>
    printf("\n");
    80002524:	8552                	mv	a0,s4
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	062080e7          	jalr	98(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	16848493          	addi	s1,s1,360
    80002532:	03248163          	beq	s1,s2,80002554 <procdump+0x98>
    if(p->state == UNUSED)
    80002536:	86a6                	mv	a3,s1
    80002538:	ec04a783          	lw	a5,-320(s1)
    8000253c:	dbed                	beqz	a5,8000252e <procdump+0x72>
      state = "???";
    8000253e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002540:	fcfb6be3          	bltu	s6,a5,80002516 <procdump+0x5a>
    80002544:	1782                	slli	a5,a5,0x20
    80002546:	9381                	srli	a5,a5,0x20
    80002548:	078e                	slli	a5,a5,0x3
    8000254a:	97de                	add	a5,a5,s7
    8000254c:	6390                	ld	a2,0(a5)
    8000254e:	f661                	bnez	a2,80002516 <procdump+0x5a>
      state = "???";
    80002550:	864e                	mv	a2,s3
    80002552:	b7d1                	j	80002516 <procdump+0x5a>
  }
}
    80002554:	60a6                	ld	ra,72(sp)
    80002556:	6406                	ld	s0,64(sp)
    80002558:	74e2                	ld	s1,56(sp)
    8000255a:	7942                	ld	s2,48(sp)
    8000255c:	79a2                	ld	s3,40(sp)
    8000255e:	7a02                	ld	s4,32(sp)
    80002560:	6ae2                	ld	s5,24(sp)
    80002562:	6b42                	ld	s6,16(sp)
    80002564:	6ba2                	ld	s7,8(sp)
    80002566:	6161                	addi	sp,sp,80
    80002568:	8082                	ret

000000008000256a <swtch>:
    8000256a:	00153023          	sd	ra,0(a0)
    8000256e:	00253423          	sd	sp,8(a0)
    80002572:	e900                	sd	s0,16(a0)
    80002574:	ed04                	sd	s1,24(a0)
    80002576:	03253023          	sd	s2,32(a0)
    8000257a:	03353423          	sd	s3,40(a0)
    8000257e:	03453823          	sd	s4,48(a0)
    80002582:	03553c23          	sd	s5,56(a0)
    80002586:	05653023          	sd	s6,64(a0)
    8000258a:	05753423          	sd	s7,72(a0)
    8000258e:	05853823          	sd	s8,80(a0)
    80002592:	05953c23          	sd	s9,88(a0)
    80002596:	07a53023          	sd	s10,96(a0)
    8000259a:	07b53423          	sd	s11,104(a0)
    8000259e:	0005b083          	ld	ra,0(a1)
    800025a2:	0085b103          	ld	sp,8(a1)
    800025a6:	6980                	ld	s0,16(a1)
    800025a8:	6d84                	ld	s1,24(a1)
    800025aa:	0205b903          	ld	s2,32(a1)
    800025ae:	0285b983          	ld	s3,40(a1)
    800025b2:	0305ba03          	ld	s4,48(a1)
    800025b6:	0385ba83          	ld	s5,56(a1)
    800025ba:	0405bb03          	ld	s6,64(a1)
    800025be:	0485bb83          	ld	s7,72(a1)
    800025c2:	0505bc03          	ld	s8,80(a1)
    800025c6:	0585bc83          	ld	s9,88(a1)
    800025ca:	0605bd03          	ld	s10,96(a1)
    800025ce:	0685bd83          	ld	s11,104(a1)
    800025d2:	8082                	ret

00000000800025d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025d4:	1141                	addi	sp,sp,-16
    800025d6:	e406                	sd	ra,8(sp)
    800025d8:	e022                	sd	s0,0(sp)
    800025da:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025dc:	00006597          	auipc	a1,0x6
    800025e0:	d1458593          	addi	a1,a1,-748 # 800082f0 <states.1709+0x30>
    800025e4:	00015517          	auipc	a0,0x15
    800025e8:	aec50513          	addi	a0,a0,-1300 # 800170d0 <tickslock>
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	568080e7          	jalr	1384(ra) # 80000b54 <initlock>
}
    800025f4:	60a2                	ld	ra,8(sp)
    800025f6:	6402                	ld	s0,0(sp)
    800025f8:	0141                	addi	sp,sp,16
    800025fa:	8082                	ret

00000000800025fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025fc:	1141                	addi	sp,sp,-16
    800025fe:	e422                	sd	s0,8(sp)
    80002600:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002602:	00003797          	auipc	a5,0x3
    80002606:	49e78793          	addi	a5,a5,1182 # 80005aa0 <kernelvec>
    8000260a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000260e:	6422                	ld	s0,8(sp)
    80002610:	0141                	addi	sp,sp,16
    80002612:	8082                	ret

0000000080002614 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002614:	1141                	addi	sp,sp,-16
    80002616:	e406                	sd	ra,8(sp)
    80002618:	e022                	sd	s0,0(sp)
    8000261a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	394080e7          	jalr	916(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002624:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002628:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000262a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000262e:	00005617          	auipc	a2,0x5
    80002632:	9d260613          	addi	a2,a2,-1582 # 80007000 <_trampoline>
    80002636:	00005697          	auipc	a3,0x5
    8000263a:	9ca68693          	addi	a3,a3,-1590 # 80007000 <_trampoline>
    8000263e:	8e91                	sub	a3,a3,a2
    80002640:	040007b7          	lui	a5,0x4000
    80002644:	17fd                	addi	a5,a5,-1
    80002646:	07b2                	slli	a5,a5,0xc
    80002648:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000264a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000264e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002650:	180026f3          	csrr	a3,satp
    80002654:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002656:	6d38                	ld	a4,88(a0)
    80002658:	6134                	ld	a3,64(a0)
    8000265a:	6585                	lui	a1,0x1
    8000265c:	96ae                	add	a3,a3,a1
    8000265e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002660:	6d38                	ld	a4,88(a0)
    80002662:	00000697          	auipc	a3,0x0
    80002666:	13868693          	addi	a3,a3,312 # 8000279a <usertrap>
    8000266a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000266c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000266e:	8692                	mv	a3,tp
    80002670:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002672:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002676:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000267a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000267e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002682:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002684:	6f18                	ld	a4,24(a4)
    80002686:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000268a:	692c                	ld	a1,80(a0)
    8000268c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000268e:	00005717          	auipc	a4,0x5
    80002692:	a0270713          	addi	a4,a4,-1534 # 80007090 <userret>
    80002696:	8f11                	sub	a4,a4,a2
    80002698:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000269a:	577d                	li	a4,-1
    8000269c:	177e                	slli	a4,a4,0x3f
    8000269e:	8dd9                	or	a1,a1,a4
    800026a0:	02000537          	lui	a0,0x2000
    800026a4:	157d                	addi	a0,a0,-1
    800026a6:	0536                	slli	a0,a0,0xd
    800026a8:	9782                	jalr	a5
}
    800026aa:	60a2                	ld	ra,8(sp)
    800026ac:	6402                	ld	s0,0(sp)
    800026ae:	0141                	addi	sp,sp,16
    800026b0:	8082                	ret

00000000800026b2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026b2:	1101                	addi	sp,sp,-32
    800026b4:	ec06                	sd	ra,24(sp)
    800026b6:	e822                	sd	s0,16(sp)
    800026b8:	e426                	sd	s1,8(sp)
    800026ba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026bc:	00015497          	auipc	s1,0x15
    800026c0:	a1448493          	addi	s1,s1,-1516 # 800170d0 <tickslock>
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	51e080e7          	jalr	1310(ra) # 80000be4 <acquire>
  ticks++;
    800026ce:	00007517          	auipc	a0,0x7
    800026d2:	96250513          	addi	a0,a0,-1694 # 80009030 <ticks>
    800026d6:	411c                	lw	a5,0(a0)
    800026d8:	2785                	addiw	a5,a5,1
    800026da:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026dc:	00000097          	auipc	ra,0x0
    800026e0:	b1c080e7          	jalr	-1252(ra) # 800021f8 <wakeup>
  release(&tickslock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
}
    800026ee:	60e2                	ld	ra,24(sp)
    800026f0:	6442                	ld	s0,16(sp)
    800026f2:	64a2                	ld	s1,8(sp)
    800026f4:	6105                	addi	sp,sp,32
    800026f6:	8082                	ret

00000000800026f8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026f8:	1101                	addi	sp,sp,-32
    800026fa:	ec06                	sd	ra,24(sp)
    800026fc:	e822                	sd	s0,16(sp)
    800026fe:	e426                	sd	s1,8(sp)
    80002700:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002702:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002706:	00074d63          	bltz	a4,80002720 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000270a:	57fd                	li	a5,-1
    8000270c:	17fe                	slli	a5,a5,0x3f
    8000270e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002710:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002712:	06f70363          	beq	a4,a5,80002778 <devintr+0x80>
  }
}
    80002716:	60e2                	ld	ra,24(sp)
    80002718:	6442                	ld	s0,16(sp)
    8000271a:	64a2                	ld	s1,8(sp)
    8000271c:	6105                	addi	sp,sp,32
    8000271e:	8082                	ret
     (scause & 0xff) == 9){
    80002720:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002724:	46a5                	li	a3,9
    80002726:	fed792e3          	bne	a5,a3,8000270a <devintr+0x12>
    int irq = plic_claim();
    8000272a:	00003097          	auipc	ra,0x3
    8000272e:	47e080e7          	jalr	1150(ra) # 80005ba8 <plic_claim>
    80002732:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002734:	47a9                	li	a5,10
    80002736:	02f50763          	beq	a0,a5,80002764 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000273a:	4785                	li	a5,1
    8000273c:	02f50963          	beq	a0,a5,8000276e <devintr+0x76>
    return 1;
    80002740:	4505                	li	a0,1
    } else if(irq){
    80002742:	d8f1                	beqz	s1,80002716 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002744:	85a6                	mv	a1,s1
    80002746:	00006517          	auipc	a0,0x6
    8000274a:	bb250513          	addi	a0,a0,-1102 # 800082f8 <states.1709+0x38>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	e3a080e7          	jalr	-454(ra) # 80000588 <printf>
      plic_complete(irq);
    80002756:	8526                	mv	a0,s1
    80002758:	00003097          	auipc	ra,0x3
    8000275c:	474080e7          	jalr	1140(ra) # 80005bcc <plic_complete>
    return 1;
    80002760:	4505                	li	a0,1
    80002762:	bf55                	j	80002716 <devintr+0x1e>
      uartintr();
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	244080e7          	jalr	580(ra) # 800009a8 <uartintr>
    8000276c:	b7ed                	j	80002756 <devintr+0x5e>
      virtio_disk_intr();
    8000276e:	00004097          	auipc	ra,0x4
    80002772:	93e080e7          	jalr	-1730(ra) # 800060ac <virtio_disk_intr>
    80002776:	b7c5                	j	80002756 <devintr+0x5e>
    if(cpuid() == 0){
    80002778:	fffff097          	auipc	ra,0xfffff
    8000277c:	20c080e7          	jalr	524(ra) # 80001984 <cpuid>
    80002780:	c901                	beqz	a0,80002790 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002782:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002786:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002788:	14479073          	csrw	sip,a5
    return 2;
    8000278c:	4509                	li	a0,2
    8000278e:	b761                	j	80002716 <devintr+0x1e>
      clockintr();
    80002790:	00000097          	auipc	ra,0x0
    80002794:	f22080e7          	jalr	-222(ra) # 800026b2 <clockintr>
    80002798:	b7ed                	j	80002782 <devintr+0x8a>

000000008000279a <usertrap>:
{
    8000279a:	1101                	addi	sp,sp,-32
    8000279c:	ec06                	sd	ra,24(sp)
    8000279e:	e822                	sd	s0,16(sp)
    800027a0:	e426                	sd	s1,8(sp)
    800027a2:	e04a                	sd	s2,0(sp)
    800027a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027aa:	1007f793          	andi	a5,a5,256
    800027ae:	e3ad                	bnez	a5,80002810 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b0:	00003797          	auipc	a5,0x3
    800027b4:	2f078793          	addi	a5,a5,752 # 80005aa0 <kernelvec>
    800027b8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	1f4080e7          	jalr	500(ra) # 800019b0 <myproc>
    800027c4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027c6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027c8:	14102773          	csrr	a4,sepc
    800027cc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027d2:	47a1                	li	a5,8
    800027d4:	04f71c63          	bne	a4,a5,8000282c <usertrap+0x92>
    if(p->killed)
    800027d8:	551c                	lw	a5,40(a0)
    800027da:	e3b9                	bnez	a5,80002820 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027dc:	6cb8                	ld	a4,88(s1)
    800027de:	6f1c                	ld	a5,24(a4)
    800027e0:	0791                	addi	a5,a5,4
    800027e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ec:	10079073          	csrw	sstatus,a5
    syscall();
    800027f0:	00000097          	auipc	ra,0x0
    800027f4:	2e0080e7          	jalr	736(ra) # 80002ad0 <syscall>
  if(p->killed)
    800027f8:	549c                	lw	a5,40(s1)
    800027fa:	ebc1                	bnez	a5,8000288a <usertrap+0xf0>
  usertrapret();
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	e18080e7          	jalr	-488(ra) # 80002614 <usertrapret>
}
    80002804:	60e2                	ld	ra,24(sp)
    80002806:	6442                	ld	s0,16(sp)
    80002808:	64a2                	ld	s1,8(sp)
    8000280a:	6902                	ld	s2,0(sp)
    8000280c:	6105                	addi	sp,sp,32
    8000280e:	8082                	ret
    panic("usertrap: not from user mode");
    80002810:	00006517          	auipc	a0,0x6
    80002814:	b0850513          	addi	a0,a0,-1272 # 80008318 <states.1709+0x58>
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	d26080e7          	jalr	-730(ra) # 8000053e <panic>
      exit(-1);
    80002820:	557d                	li	a0,-1
    80002822:	00000097          	auipc	ra,0x0
    80002826:	aa6080e7          	jalr	-1370(ra) # 800022c8 <exit>
    8000282a:	bf4d                	j	800027dc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000282c:	00000097          	auipc	ra,0x0
    80002830:	ecc080e7          	jalr	-308(ra) # 800026f8 <devintr>
    80002834:	892a                	mv	s2,a0
    80002836:	c501                	beqz	a0,8000283e <usertrap+0xa4>
  if(p->killed)
    80002838:	549c                	lw	a5,40(s1)
    8000283a:	c3a1                	beqz	a5,8000287a <usertrap+0xe0>
    8000283c:	a815                	j	80002870 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000283e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002842:	5890                	lw	a2,48(s1)
    80002844:	00006517          	auipc	a0,0x6
    80002848:	af450513          	addi	a0,a0,-1292 # 80008338 <states.1709+0x78>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d3c080e7          	jalr	-708(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002854:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002858:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000285c:	00006517          	auipc	a0,0x6
    80002860:	b0c50513          	addi	a0,a0,-1268 # 80008368 <states.1709+0xa8>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	d24080e7          	jalr	-732(ra) # 80000588 <printf>
    p->killed = 1;
    8000286c:	4785                	li	a5,1
    8000286e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002870:	557d                	li	a0,-1
    80002872:	00000097          	auipc	ra,0x0
    80002876:	a56080e7          	jalr	-1450(ra) # 800022c8 <exit>
  if(which_dev == 2)
    8000287a:	4789                	li	a5,2
    8000287c:	f8f910e3          	bne	s2,a5,800027fc <usertrap+0x62>
    yield();
    80002880:	fffff097          	auipc	ra,0xfffff
    80002884:	7b0080e7          	jalr	1968(ra) # 80002030 <yield>
    80002888:	bf95                	j	800027fc <usertrap+0x62>
  int which_dev = 0;
    8000288a:	4901                	li	s2,0
    8000288c:	b7d5                	j	80002870 <usertrap+0xd6>

000000008000288e <kerneltrap>:
{
    8000288e:	7179                	addi	sp,sp,-48
    80002890:	f406                	sd	ra,40(sp)
    80002892:	f022                	sd	s0,32(sp)
    80002894:	ec26                	sd	s1,24(sp)
    80002896:	e84a                	sd	s2,16(sp)
    80002898:	e44e                	sd	s3,8(sp)
    8000289a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000289c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028a8:	1004f793          	andi	a5,s1,256
    800028ac:	cb85                	beqz	a5,800028dc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028b2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028b4:	ef85                	bnez	a5,800028ec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	e42080e7          	jalr	-446(ra) # 800026f8 <devintr>
    800028be:	cd1d                	beqz	a0,800028fc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028c0:	4789                	li	a5,2
    800028c2:	06f50a63          	beq	a0,a5,80002936 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ca:	10049073          	csrw	sstatus,s1
}
    800028ce:	70a2                	ld	ra,40(sp)
    800028d0:	7402                	ld	s0,32(sp)
    800028d2:	64e2                	ld	s1,24(sp)
    800028d4:	6942                	ld	s2,16(sp)
    800028d6:	69a2                	ld	s3,8(sp)
    800028d8:	6145                	addi	sp,sp,48
    800028da:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	aac50513          	addi	a0,a0,-1364 # 80008388 <states.1709+0xc8>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c5a080e7          	jalr	-934(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	ac450513          	addi	a0,a0,-1340 # 800083b0 <states.1709+0xf0>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c4a080e7          	jalr	-950(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800028fc:	85ce                	mv	a1,s3
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	ad250513          	addi	a0,a0,-1326 # 800083d0 <states.1709+0x110>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c82080e7          	jalr	-894(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002912:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	aca50513          	addi	a0,a0,-1334 # 800083e0 <states.1709+0x120>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c6a080e7          	jalr	-918(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002926:	00006517          	auipc	a0,0x6
    8000292a:	ad250513          	addi	a0,a0,-1326 # 800083f8 <states.1709+0x138>
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	07a080e7          	jalr	122(ra) # 800019b0 <myproc>
    8000293e:	d541                	beqz	a0,800028c6 <kerneltrap+0x38>
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	070080e7          	jalr	112(ra) # 800019b0 <myproc>
    80002948:	4d18                	lw	a4,24(a0)
    8000294a:	4791                	li	a5,4
    8000294c:	f6f71de3          	bne	a4,a5,800028c6 <kerneltrap+0x38>
    yield();
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	6e0080e7          	jalr	1760(ra) # 80002030 <yield>
    80002958:	b7bd                	j	800028c6 <kerneltrap+0x38>

000000008000295a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000295a:	1101                	addi	sp,sp,-32
    8000295c:	ec06                	sd	ra,24(sp)
    8000295e:	e822                	sd	s0,16(sp)
    80002960:	e426                	sd	s1,8(sp)
    80002962:	1000                	addi	s0,sp,32
    80002964:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	04a080e7          	jalr	74(ra) # 800019b0 <myproc>
  switch (n) {
    8000296e:	4795                	li	a5,5
    80002970:	0497e163          	bltu	a5,s1,800029b2 <argraw+0x58>
    80002974:	048a                	slli	s1,s1,0x2
    80002976:	00006717          	auipc	a4,0x6
    8000297a:	aba70713          	addi	a4,a4,-1350 # 80008430 <states.1709+0x170>
    8000297e:	94ba                	add	s1,s1,a4
    80002980:	409c                	lw	a5,0(s1)
    80002982:	97ba                	add	a5,a5,a4
    80002984:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002986:	6d3c                	ld	a5,88(a0)
    80002988:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000298a:	60e2                	ld	ra,24(sp)
    8000298c:	6442                	ld	s0,16(sp)
    8000298e:	64a2                	ld	s1,8(sp)
    80002990:	6105                	addi	sp,sp,32
    80002992:	8082                	ret
    return p->trapframe->a1;
    80002994:	6d3c                	ld	a5,88(a0)
    80002996:	7fa8                	ld	a0,120(a5)
    80002998:	bfcd                	j	8000298a <argraw+0x30>
    return p->trapframe->a2;
    8000299a:	6d3c                	ld	a5,88(a0)
    8000299c:	63c8                	ld	a0,128(a5)
    8000299e:	b7f5                	j	8000298a <argraw+0x30>
    return p->trapframe->a3;
    800029a0:	6d3c                	ld	a5,88(a0)
    800029a2:	67c8                	ld	a0,136(a5)
    800029a4:	b7dd                	j	8000298a <argraw+0x30>
    return p->trapframe->a4;
    800029a6:	6d3c                	ld	a5,88(a0)
    800029a8:	6bc8                	ld	a0,144(a5)
    800029aa:	b7c5                	j	8000298a <argraw+0x30>
    return p->trapframe->a5;
    800029ac:	6d3c                	ld	a5,88(a0)
    800029ae:	6fc8                	ld	a0,152(a5)
    800029b0:	bfe9                	j	8000298a <argraw+0x30>
  panic("argraw");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a5650513          	addi	a0,a0,-1450 # 80008408 <states.1709+0x148>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>

00000000800029c2 <fetchaddr>:
{
    800029c2:	1101                	addi	sp,sp,-32
    800029c4:	ec06                	sd	ra,24(sp)
    800029c6:	e822                	sd	s0,16(sp)
    800029c8:	e426                	sd	s1,8(sp)
    800029ca:	e04a                	sd	s2,0(sp)
    800029cc:	1000                	addi	s0,sp,32
    800029ce:	84aa                	mv	s1,a0
    800029d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	fde080e7          	jalr	-34(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029da:	653c                	ld	a5,72(a0)
    800029dc:	02f4f863          	bgeu	s1,a5,80002a0c <fetchaddr+0x4a>
    800029e0:	00848713          	addi	a4,s1,8
    800029e4:	02e7e663          	bltu	a5,a4,80002a10 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029e8:	46a1                	li	a3,8
    800029ea:	8626                	mv	a2,s1
    800029ec:	85ca                	mv	a1,s2
    800029ee:	6928                	ld	a0,80(a0)
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	d0e080e7          	jalr	-754(ra) # 800016fe <copyin>
    800029f8:	00a03533          	snez	a0,a0
    800029fc:	40a00533          	neg	a0,a0
}
    80002a00:	60e2                	ld	ra,24(sp)
    80002a02:	6442                	ld	s0,16(sp)
    80002a04:	64a2                	ld	s1,8(sp)
    80002a06:	6902                	ld	s2,0(sp)
    80002a08:	6105                	addi	sp,sp,32
    80002a0a:	8082                	ret
    return -1;
    80002a0c:	557d                	li	a0,-1
    80002a0e:	bfcd                	j	80002a00 <fetchaddr+0x3e>
    80002a10:	557d                	li	a0,-1
    80002a12:	b7fd                	j	80002a00 <fetchaddr+0x3e>

0000000080002a14 <fetchstr>:
{
    80002a14:	7179                	addi	sp,sp,-48
    80002a16:	f406                	sd	ra,40(sp)
    80002a18:	f022                	sd	s0,32(sp)
    80002a1a:	ec26                	sd	s1,24(sp)
    80002a1c:	e84a                	sd	s2,16(sp)
    80002a1e:	e44e                	sd	s3,8(sp)
    80002a20:	1800                	addi	s0,sp,48
    80002a22:	892a                	mv	s2,a0
    80002a24:	84ae                	mv	s1,a1
    80002a26:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	f88080e7          	jalr	-120(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a30:	86ce                	mv	a3,s3
    80002a32:	864a                	mv	a2,s2
    80002a34:	85a6                	mv	a1,s1
    80002a36:	6928                	ld	a0,80(a0)
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	d52080e7          	jalr	-686(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a40:	00054763          	bltz	a0,80002a4e <fetchstr+0x3a>
  return strlen(buf);
    80002a44:	8526                	mv	a0,s1
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	41e080e7          	jalr	1054(ra) # 80000e64 <strlen>
}
    80002a4e:	70a2                	ld	ra,40(sp)
    80002a50:	7402                	ld	s0,32(sp)
    80002a52:	64e2                	ld	s1,24(sp)
    80002a54:	6942                	ld	s2,16(sp)
    80002a56:	69a2                	ld	s3,8(sp)
    80002a58:	6145                	addi	sp,sp,48
    80002a5a:	8082                	ret

0000000080002a5c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	1000                	addi	s0,sp,32
    80002a66:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	ef2080e7          	jalr	-270(ra) # 8000295a <argraw>
    80002a70:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a72:	4501                	li	a0,0
    80002a74:	60e2                	ld	ra,24(sp)
    80002a76:	6442                	ld	s0,16(sp)
    80002a78:	64a2                	ld	s1,8(sp)
    80002a7a:	6105                	addi	sp,sp,32
    80002a7c:	8082                	ret

0000000080002a7e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a7e:	1101                	addi	sp,sp,-32
    80002a80:	ec06                	sd	ra,24(sp)
    80002a82:	e822                	sd	s0,16(sp)
    80002a84:	e426                	sd	s1,8(sp)
    80002a86:	1000                	addi	s0,sp,32
    80002a88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	ed0080e7          	jalr	-304(ra) # 8000295a <argraw>
    80002a92:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a94:	4501                	li	a0,0
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret

0000000080002aa0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	e04a                	sd	s2,0(sp)
    80002aaa:	1000                	addi	s0,sp,32
    80002aac:	84ae                	mv	s1,a1
    80002aae:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	eaa080e7          	jalr	-342(ra) # 8000295a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ab8:	864a                	mv	a2,s2
    80002aba:	85a6                	mv	a1,s1
    80002abc:	00000097          	auipc	ra,0x0
    80002ac0:	f58080e7          	jalr	-168(ra) # 80002a14 <fetchstr>
}
    80002ac4:	60e2                	ld	ra,24(sp)
    80002ac6:	6442                	ld	s0,16(sp)
    80002ac8:	64a2                	ld	s1,8(sp)
    80002aca:	6902                	ld	s2,0(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret

0000000080002ad0 <syscall>:
[SYS_kill_system]   sys_kill_system,
};

void
syscall(void)
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	e04a                	sd	s2,0(sp)
    80002ada:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	ed4080e7          	jalr	-300(ra) # 800019b0 <myproc>
    80002ae4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ae6:	05853903          	ld	s2,88(a0)
    80002aea:	0a893783          	ld	a5,168(s2)
    80002aee:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002af2:	37fd                	addiw	a5,a5,-1
    80002af4:	4759                	li	a4,22
    80002af6:	00f76f63          	bltu	a4,a5,80002b14 <syscall+0x44>
    80002afa:	00369713          	slli	a4,a3,0x3
    80002afe:	00006797          	auipc	a5,0x6
    80002b02:	94a78793          	addi	a5,a5,-1718 # 80008448 <syscalls>
    80002b06:	97ba                	add	a5,a5,a4
    80002b08:	639c                	ld	a5,0(a5)
    80002b0a:	c789                	beqz	a5,80002b14 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b0c:	9782                	jalr	a5
    80002b0e:	06a93823          	sd	a0,112(s2)
    80002b12:	a839                	j	80002b30 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b14:	15848613          	addi	a2,s1,344
    80002b18:	588c                	lw	a1,48(s1)
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	8f650513          	addi	a0,a0,-1802 # 80008410 <states.1709+0x150>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a66080e7          	jalr	-1434(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b2a:	6cbc                	ld	a5,88(s1)
    80002b2c:	577d                	li	a4,-1
    80002b2e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b30:	60e2                	ld	ra,24(sp)
    80002b32:	6442                	ld	s0,16(sp)
    80002b34:	64a2                	ld	s1,8(sp)
    80002b36:	6902                	ld	s2,0(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret

0000000080002b3c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b3c:	1101                	addi	sp,sp,-32
    80002b3e:	ec06                	sd	ra,24(sp)
    80002b40:	e822                	sd	s0,16(sp)
    80002b42:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b44:	fec40593          	addi	a1,s0,-20
    80002b48:	4501                	li	a0,0
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	f12080e7          	jalr	-238(ra) # 80002a5c <argint>
    return -1;
    80002b52:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b54:	00054963          	bltz	a0,80002b66 <sys_exit+0x2a>
  exit(n);
    80002b58:	fec42503          	lw	a0,-20(s0)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	76c080e7          	jalr	1900(ra) # 800022c8 <exit>
  return 0;  // not reached
    80002b64:	4781                	li	a5,0
}
    80002b66:	853e                	mv	a0,a5
    80002b68:	60e2                	ld	ra,24(sp)
    80002b6a:	6442                	ld	s0,16(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b70:	1141                	addi	sp,sp,-16
    80002b72:	e406                	sd	ra,8(sp)
    80002b74:	e022                	sd	s0,0(sp)
    80002b76:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e38080e7          	jalr	-456(ra) # 800019b0 <myproc>
}
    80002b80:	5908                	lw	a0,48(a0)
    80002b82:	60a2                	ld	ra,8(sp)
    80002b84:	6402                	ld	s0,0(sp)
    80002b86:	0141                	addi	sp,sp,16
    80002b88:	8082                	ret

0000000080002b8a <sys_fork>:

uint64
sys_fork(void)
{
    80002b8a:	1141                	addi	sp,sp,-16
    80002b8c:	e406                	sd	ra,8(sp)
    80002b8e:	e022                	sd	s0,0(sp)
    80002b90:	0800                	addi	s0,sp,16
  return fork();
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	1ec080e7          	jalr	492(ra) # 80001d7e <fork>
}
    80002b9a:	60a2                	ld	ra,8(sp)
    80002b9c:	6402                	ld	s0,0(sp)
    80002b9e:	0141                	addi	sp,sp,16
    80002ba0:	8082                	ret

0000000080002ba2 <sys_wait>:

uint64
sys_wait(void)
{
    80002ba2:	1101                	addi	sp,sp,-32
    80002ba4:	ec06                	sd	ra,24(sp)
    80002ba6:	e822                	sd	s0,16(sp)
    80002ba8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002baa:	fe840593          	addi	a1,s0,-24
    80002bae:	4501                	li	a0,0
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	ece080e7          	jalr	-306(ra) # 80002a7e <argaddr>
    80002bb8:	87aa                	mv	a5,a0
    return -1;
    80002bba:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bbc:	0007c863          	bltz	a5,80002bcc <sys_wait+0x2a>
  return wait(p);
    80002bc0:	fe843503          	ld	a0,-24(s0)
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	50c080e7          	jalr	1292(ra) # 800020d0 <wait>
}
    80002bcc:	60e2                	ld	ra,24(sp)
    80002bce:	6442                	ld	s0,16(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret

0000000080002bd4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bd4:	7179                	addi	sp,sp,-48
    80002bd6:	f406                	sd	ra,40(sp)
    80002bd8:	f022                	sd	s0,32(sp)
    80002bda:	ec26                	sd	s1,24(sp)
    80002bdc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bde:	fdc40593          	addi	a1,s0,-36
    80002be2:	4501                	li	a0,0
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	e78080e7          	jalr	-392(ra) # 80002a5c <argint>
    80002bec:	87aa                	mv	a5,a0
    return -1;
    80002bee:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002bf0:	0207c063          	bltz	a5,80002c10 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	dbc080e7          	jalr	-580(ra) # 800019b0 <myproc>
    80002bfc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002bfe:	fdc42503          	lw	a0,-36(s0)
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	108080e7          	jalr	264(ra) # 80001d0a <growproc>
    80002c0a:	00054863          	bltz	a0,80002c1a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c0e:	8526                	mv	a0,s1
}
    80002c10:	70a2                	ld	ra,40(sp)
    80002c12:	7402                	ld	s0,32(sp)
    80002c14:	64e2                	ld	s1,24(sp)
    80002c16:	6145                	addi	sp,sp,48
    80002c18:	8082                	ret
    return -1;
    80002c1a:	557d                	li	a0,-1
    80002c1c:	bfd5                	j	80002c10 <sys_sbrk+0x3c>

0000000080002c1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c1e:	7139                	addi	sp,sp,-64
    80002c20:	fc06                	sd	ra,56(sp)
    80002c22:	f822                	sd	s0,48(sp)
    80002c24:	f426                	sd	s1,40(sp)
    80002c26:	f04a                	sd	s2,32(sp)
    80002c28:	ec4e                	sd	s3,24(sp)
    80002c2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c2c:	fcc40593          	addi	a1,s0,-52
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	e2a080e7          	jalr	-470(ra) # 80002a5c <argint>
    return -1;
    80002c3a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c3c:	06054563          	bltz	a0,80002ca6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c40:	00014517          	auipc	a0,0x14
    80002c44:	49050513          	addi	a0,a0,1168 # 800170d0 <tickslock>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002c50:	00006917          	auipc	s2,0x6
    80002c54:	3e092903          	lw	s2,992(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c58:	fcc42783          	lw	a5,-52(s0)
    80002c5c:	cf85                	beqz	a5,80002c94 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c5e:	00014997          	auipc	s3,0x14
    80002c62:	47298993          	addi	s3,s3,1138 # 800170d0 <tickslock>
    80002c66:	00006497          	auipc	s1,0x6
    80002c6a:	3ca48493          	addi	s1,s1,970 # 80009030 <ticks>
    if(myproc()->killed){
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	d42080e7          	jalr	-702(ra) # 800019b0 <myproc>
    80002c76:	551c                	lw	a5,40(a0)
    80002c78:	ef9d                	bnez	a5,80002cb6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c7a:	85ce                	mv	a1,s3
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	3ee080e7          	jalr	1006(ra) # 8000206c <sleep>
  while(ticks - ticks0 < n){
    80002c86:	409c                	lw	a5,0(s1)
    80002c88:	412787bb          	subw	a5,a5,s2
    80002c8c:	fcc42703          	lw	a4,-52(s0)
    80002c90:	fce7efe3          	bltu	a5,a4,80002c6e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c94:	00014517          	auipc	a0,0x14
    80002c98:	43c50513          	addi	a0,a0,1084 # 800170d0 <tickslock>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	ffc080e7          	jalr	-4(ra) # 80000c98 <release>
  return 0;
    80002ca4:	4781                	li	a5,0
}
    80002ca6:	853e                	mv	a0,a5
    80002ca8:	70e2                	ld	ra,56(sp)
    80002caa:	7442                	ld	s0,48(sp)
    80002cac:	74a2                	ld	s1,40(sp)
    80002cae:	7902                	ld	s2,32(sp)
    80002cb0:	69e2                	ld	s3,24(sp)
    80002cb2:	6121                	addi	sp,sp,64
    80002cb4:	8082                	ret
      release(&tickslock);
    80002cb6:	00014517          	auipc	a0,0x14
    80002cba:	41a50513          	addi	a0,a0,1050 # 800170d0 <tickslock>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
      return -1;
    80002cc6:	57fd                	li	a5,-1
    80002cc8:	bff9                	j	80002ca6 <sys_sleep+0x88>

0000000080002cca <sys_kill>:

uint64
sys_kill(void)
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cd2:	fec40593          	addi	a1,s0,-20
    80002cd6:	4501                	li	a0,0
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	d84080e7          	jalr	-636(ra) # 80002a5c <argint>
    80002ce0:	87aa                	mv	a5,a0
    return -1;
    80002ce2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ce4:	0007c863          	bltz	a5,80002cf4 <sys_kill+0x2a>
  return kill(pid);
    80002ce8:	fec42503          	lw	a0,-20(s0)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	6b2080e7          	jalr	1714(ra) # 8000239e <kill>
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d06:	00014517          	auipc	a0,0x14
    80002d0a:	3ca50513          	addi	a0,a0,970 # 800170d0 <tickslock>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	ed6080e7          	jalr	-298(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002d16:	00006497          	auipc	s1,0x6
    80002d1a:	31a4a483          	lw	s1,794(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d1e:	00014517          	auipc	a0,0x14
    80002d22:	3b250513          	addi	a0,a0,946 # 800170d0 <tickslock>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	f72080e7          	jalr	-142(ra) # 80000c98 <release>
  return xticks;
}
    80002d2e:	02049513          	slli	a0,s1,0x20
    80002d32:	9101                	srli	a0,a0,0x20
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <sys_pause_system>:


uint64
sys_pause_system(void)
{
    80002d3e:	1141                	addi	sp,sp,-16
    80002d40:	e422                	sd	s0,8(sp)
    80002d42:	0800                	addi	s0,sp,16
    return 0;
}
    80002d44:	4501                	li	a0,0
    80002d46:	6422                	ld	s0,8(sp)
    80002d48:	0141                	addi	sp,sp,16
    80002d4a:	8082                	ret

0000000080002d4c <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80002d4c:	1141                	addi	sp,sp,-16
    80002d4e:	e422                	sd	s0,8(sp)
    80002d50:	0800                	addi	s0,sp,16
    return 0;
}
    80002d52:	4501                	li	a0,0
    80002d54:	6422                	ld	s0,8(sp)
    80002d56:	0141                	addi	sp,sp,16
    80002d58:	8082                	ret

0000000080002d5a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d5a:	7179                	addi	sp,sp,-48
    80002d5c:	f406                	sd	ra,40(sp)
    80002d5e:	f022                	sd	s0,32(sp)
    80002d60:	ec26                	sd	s1,24(sp)
    80002d62:	e84a                	sd	s2,16(sp)
    80002d64:	e44e                	sd	s3,8(sp)
    80002d66:	e052                	sd	s4,0(sp)
    80002d68:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d6a:	00005597          	auipc	a1,0x5
    80002d6e:	79e58593          	addi	a1,a1,1950 # 80008508 <syscalls+0xc0>
    80002d72:	00014517          	auipc	a0,0x14
    80002d76:	37650513          	addi	a0,a0,886 # 800170e8 <bcache>
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	dda080e7          	jalr	-550(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d82:	0001c797          	auipc	a5,0x1c
    80002d86:	36678793          	addi	a5,a5,870 # 8001f0e8 <bcache+0x8000>
    80002d8a:	0001c717          	auipc	a4,0x1c
    80002d8e:	5c670713          	addi	a4,a4,1478 # 8001f350 <bcache+0x8268>
    80002d92:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d96:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d9a:	00014497          	auipc	s1,0x14
    80002d9e:	36648493          	addi	s1,s1,870 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002da2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002da4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002da6:	00005a17          	auipc	s4,0x5
    80002daa:	76aa0a13          	addi	s4,s4,1898 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002dae:	2b893783          	ld	a5,696(s2)
    80002db2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002db4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002db8:	85d2                	mv	a1,s4
    80002dba:	01048513          	addi	a0,s1,16
    80002dbe:	00001097          	auipc	ra,0x1
    80002dc2:	4bc080e7          	jalr	1212(ra) # 8000427a <initsleeplock>
    bcache.head.next->prev = b;
    80002dc6:	2b893783          	ld	a5,696(s2)
    80002dca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dcc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dd0:	45848493          	addi	s1,s1,1112
    80002dd4:	fd349de3          	bne	s1,s3,80002dae <binit+0x54>
  }
}
    80002dd8:	70a2                	ld	ra,40(sp)
    80002dda:	7402                	ld	s0,32(sp)
    80002ddc:	64e2                	ld	s1,24(sp)
    80002dde:	6942                	ld	s2,16(sp)
    80002de0:	69a2                	ld	s3,8(sp)
    80002de2:	6a02                	ld	s4,0(sp)
    80002de4:	6145                	addi	sp,sp,48
    80002de6:	8082                	ret

0000000080002de8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002de8:	7179                	addi	sp,sp,-48
    80002dea:	f406                	sd	ra,40(sp)
    80002dec:	f022                	sd	s0,32(sp)
    80002dee:	ec26                	sd	s1,24(sp)
    80002df0:	e84a                	sd	s2,16(sp)
    80002df2:	e44e                	sd	s3,8(sp)
    80002df4:	1800                	addi	s0,sp,48
    80002df6:	89aa                	mv	s3,a0
    80002df8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002dfa:	00014517          	auipc	a0,0x14
    80002dfe:	2ee50513          	addi	a0,a0,750 # 800170e8 <bcache>
    80002e02:	ffffe097          	auipc	ra,0xffffe
    80002e06:	de2080e7          	jalr	-542(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e0a:	0001c497          	auipc	s1,0x1c
    80002e0e:	5964b483          	ld	s1,1430(s1) # 8001f3a0 <bcache+0x82b8>
    80002e12:	0001c797          	auipc	a5,0x1c
    80002e16:	53e78793          	addi	a5,a5,1342 # 8001f350 <bcache+0x8268>
    80002e1a:	02f48f63          	beq	s1,a5,80002e58 <bread+0x70>
    80002e1e:	873e                	mv	a4,a5
    80002e20:	a021                	j	80002e28 <bread+0x40>
    80002e22:	68a4                	ld	s1,80(s1)
    80002e24:	02e48a63          	beq	s1,a4,80002e58 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e28:	449c                	lw	a5,8(s1)
    80002e2a:	ff379ce3          	bne	a5,s3,80002e22 <bread+0x3a>
    80002e2e:	44dc                	lw	a5,12(s1)
    80002e30:	ff2799e3          	bne	a5,s2,80002e22 <bread+0x3a>
      b->refcnt++;
    80002e34:	40bc                	lw	a5,64(s1)
    80002e36:	2785                	addiw	a5,a5,1
    80002e38:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e3a:	00014517          	auipc	a0,0x14
    80002e3e:	2ae50513          	addi	a0,a0,686 # 800170e8 <bcache>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e4a:	01048513          	addi	a0,s1,16
    80002e4e:	00001097          	auipc	ra,0x1
    80002e52:	466080e7          	jalr	1126(ra) # 800042b4 <acquiresleep>
      return b;
    80002e56:	a8b9                	j	80002eb4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e58:	0001c497          	auipc	s1,0x1c
    80002e5c:	5404b483          	ld	s1,1344(s1) # 8001f398 <bcache+0x82b0>
    80002e60:	0001c797          	auipc	a5,0x1c
    80002e64:	4f078793          	addi	a5,a5,1264 # 8001f350 <bcache+0x8268>
    80002e68:	00f48863          	beq	s1,a5,80002e78 <bread+0x90>
    80002e6c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e6e:	40bc                	lw	a5,64(s1)
    80002e70:	cf81                	beqz	a5,80002e88 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e72:	64a4                	ld	s1,72(s1)
    80002e74:	fee49de3          	bne	s1,a4,80002e6e <bread+0x86>
  panic("bget: no buffers");
    80002e78:	00005517          	auipc	a0,0x5
    80002e7c:	6a050513          	addi	a0,a0,1696 # 80008518 <syscalls+0xd0>
    80002e80:	ffffd097          	auipc	ra,0xffffd
    80002e84:	6be080e7          	jalr	1726(ra) # 8000053e <panic>
      b->dev = dev;
    80002e88:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e8c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e90:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e94:	4785                	li	a5,1
    80002e96:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e98:	00014517          	auipc	a0,0x14
    80002e9c:	25050513          	addi	a0,a0,592 # 800170e8 <bcache>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	df8080e7          	jalr	-520(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ea8:	01048513          	addi	a0,s1,16
    80002eac:	00001097          	auipc	ra,0x1
    80002eb0:	408080e7          	jalr	1032(ra) # 800042b4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eb4:	409c                	lw	a5,0(s1)
    80002eb6:	cb89                	beqz	a5,80002ec8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002eb8:	8526                	mv	a0,s1
    80002eba:	70a2                	ld	ra,40(sp)
    80002ebc:	7402                	ld	s0,32(sp)
    80002ebe:	64e2                	ld	s1,24(sp)
    80002ec0:	6942                	ld	s2,16(sp)
    80002ec2:	69a2                	ld	s3,8(sp)
    80002ec4:	6145                	addi	sp,sp,48
    80002ec6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ec8:	4581                	li	a1,0
    80002eca:	8526                	mv	a0,s1
    80002ecc:	00003097          	auipc	ra,0x3
    80002ed0:	f0a080e7          	jalr	-246(ra) # 80005dd6 <virtio_disk_rw>
    b->valid = 1;
    80002ed4:	4785                	li	a5,1
    80002ed6:	c09c                	sw	a5,0(s1)
  return b;
    80002ed8:	b7c5                	j	80002eb8 <bread+0xd0>

0000000080002eda <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	e426                	sd	s1,8(sp)
    80002ee2:	1000                	addi	s0,sp,32
    80002ee4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ee6:	0541                	addi	a0,a0,16
    80002ee8:	00001097          	auipc	ra,0x1
    80002eec:	466080e7          	jalr	1126(ra) # 8000434e <holdingsleep>
    80002ef0:	cd01                	beqz	a0,80002f08 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ef2:	4585                	li	a1,1
    80002ef4:	8526                	mv	a0,s1
    80002ef6:	00003097          	auipc	ra,0x3
    80002efa:	ee0080e7          	jalr	-288(ra) # 80005dd6 <virtio_disk_rw>
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret
    panic("bwrite");
    80002f08:	00005517          	auipc	a0,0x5
    80002f0c:	62850513          	addi	a0,a0,1576 # 80008530 <syscalls+0xe8>
    80002f10:	ffffd097          	auipc	ra,0xffffd
    80002f14:	62e080e7          	jalr	1582(ra) # 8000053e <panic>

0000000080002f18 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f18:	1101                	addi	sp,sp,-32
    80002f1a:	ec06                	sd	ra,24(sp)
    80002f1c:	e822                	sd	s0,16(sp)
    80002f1e:	e426                	sd	s1,8(sp)
    80002f20:	e04a                	sd	s2,0(sp)
    80002f22:	1000                	addi	s0,sp,32
    80002f24:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f26:	01050913          	addi	s2,a0,16
    80002f2a:	854a                	mv	a0,s2
    80002f2c:	00001097          	auipc	ra,0x1
    80002f30:	422080e7          	jalr	1058(ra) # 8000434e <holdingsleep>
    80002f34:	c92d                	beqz	a0,80002fa6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f36:	854a                	mv	a0,s2
    80002f38:	00001097          	auipc	ra,0x1
    80002f3c:	3d2080e7          	jalr	978(ra) # 8000430a <releasesleep>

  acquire(&bcache.lock);
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	1a850513          	addi	a0,a0,424 # 800170e8 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	c9c080e7          	jalr	-868(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002f50:	40bc                	lw	a5,64(s1)
    80002f52:	37fd                	addiw	a5,a5,-1
    80002f54:	0007871b          	sext.w	a4,a5
    80002f58:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f5a:	eb05                	bnez	a4,80002f8a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f5c:	68bc                	ld	a5,80(s1)
    80002f5e:	64b8                	ld	a4,72(s1)
    80002f60:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f62:	64bc                	ld	a5,72(s1)
    80002f64:	68b8                	ld	a4,80(s1)
    80002f66:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f68:	0001c797          	auipc	a5,0x1c
    80002f6c:	18078793          	addi	a5,a5,384 # 8001f0e8 <bcache+0x8000>
    80002f70:	2b87b703          	ld	a4,696(a5)
    80002f74:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f76:	0001c717          	auipc	a4,0x1c
    80002f7a:	3da70713          	addi	a4,a4,986 # 8001f350 <bcache+0x8268>
    80002f7e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f80:	2b87b703          	ld	a4,696(a5)
    80002f84:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f86:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f8a:	00014517          	auipc	a0,0x14
    80002f8e:	15e50513          	addi	a0,a0,350 # 800170e8 <bcache>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	d06080e7          	jalr	-762(ra) # 80000c98 <release>
}
    80002f9a:	60e2                	ld	ra,24(sp)
    80002f9c:	6442                	ld	s0,16(sp)
    80002f9e:	64a2                	ld	s1,8(sp)
    80002fa0:	6902                	ld	s2,0(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret
    panic("brelse");
    80002fa6:	00005517          	auipc	a0,0x5
    80002faa:	59250513          	addi	a0,a0,1426 # 80008538 <syscalls+0xf0>
    80002fae:	ffffd097          	auipc	ra,0xffffd
    80002fb2:	590080e7          	jalr	1424(ra) # 8000053e <panic>

0000000080002fb6 <bpin>:

void
bpin(struct buf *b) {
    80002fb6:	1101                	addi	sp,sp,-32
    80002fb8:	ec06                	sd	ra,24(sp)
    80002fba:	e822                	sd	s0,16(sp)
    80002fbc:	e426                	sd	s1,8(sp)
    80002fbe:	1000                	addi	s0,sp,32
    80002fc0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fc2:	00014517          	auipc	a0,0x14
    80002fc6:	12650513          	addi	a0,a0,294 # 800170e8 <bcache>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	c1a080e7          	jalr	-998(ra) # 80000be4 <acquire>
  b->refcnt++;
    80002fd2:	40bc                	lw	a5,64(s1)
    80002fd4:	2785                	addiw	a5,a5,1
    80002fd6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fd8:	00014517          	auipc	a0,0x14
    80002fdc:	11050513          	addi	a0,a0,272 # 800170e8 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	cb8080e7          	jalr	-840(ra) # 80000c98 <release>
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <bunpin>:

void
bunpin(struct buf *b) {
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	e426                	sd	s1,8(sp)
    80002ffa:	1000                	addi	s0,sp,32
    80002ffc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ffe:	00014517          	auipc	a0,0x14
    80003002:	0ea50513          	addi	a0,a0,234 # 800170e8 <bcache>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	bde080e7          	jalr	-1058(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000300e:	40bc                	lw	a5,64(s1)
    80003010:	37fd                	addiw	a5,a5,-1
    80003012:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003014:	00014517          	auipc	a0,0x14
    80003018:	0d450513          	addi	a0,a0,212 # 800170e8 <bcache>
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	c7c080e7          	jalr	-900(ra) # 80000c98 <release>
}
    80003024:	60e2                	ld	ra,24(sp)
    80003026:	6442                	ld	s0,16(sp)
    80003028:	64a2                	ld	s1,8(sp)
    8000302a:	6105                	addi	sp,sp,32
    8000302c:	8082                	ret

000000008000302e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	e04a                	sd	s2,0(sp)
    80003038:	1000                	addi	s0,sp,32
    8000303a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000303c:	00d5d59b          	srliw	a1,a1,0xd
    80003040:	0001c797          	auipc	a5,0x1c
    80003044:	7847a783          	lw	a5,1924(a5) # 8001f7c4 <sb+0x1c>
    80003048:	9dbd                	addw	a1,a1,a5
    8000304a:	00000097          	auipc	ra,0x0
    8000304e:	d9e080e7          	jalr	-610(ra) # 80002de8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003052:	0074f713          	andi	a4,s1,7
    80003056:	4785                	li	a5,1
    80003058:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000305c:	14ce                	slli	s1,s1,0x33
    8000305e:	90d9                	srli	s1,s1,0x36
    80003060:	00950733          	add	a4,a0,s1
    80003064:	05874703          	lbu	a4,88(a4)
    80003068:	00e7f6b3          	and	a3,a5,a4
    8000306c:	c69d                	beqz	a3,8000309a <bfree+0x6c>
    8000306e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003070:	94aa                	add	s1,s1,a0
    80003072:	fff7c793          	not	a5,a5
    80003076:	8ff9                	and	a5,a5,a4
    80003078:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000307c:	00001097          	auipc	ra,0x1
    80003080:	118080e7          	jalr	280(ra) # 80004194 <log_write>
  brelse(bp);
    80003084:	854a                	mv	a0,s2
    80003086:	00000097          	auipc	ra,0x0
    8000308a:	e92080e7          	jalr	-366(ra) # 80002f18 <brelse>
}
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	64a2                	ld	s1,8(sp)
    80003094:	6902                	ld	s2,0(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
    panic("freeing free block");
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	4a650513          	addi	a0,a0,1190 # 80008540 <syscalls+0xf8>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>

00000000800030aa <balloc>:
{
    800030aa:	711d                	addi	sp,sp,-96
    800030ac:	ec86                	sd	ra,88(sp)
    800030ae:	e8a2                	sd	s0,80(sp)
    800030b0:	e4a6                	sd	s1,72(sp)
    800030b2:	e0ca                	sd	s2,64(sp)
    800030b4:	fc4e                	sd	s3,56(sp)
    800030b6:	f852                	sd	s4,48(sp)
    800030b8:	f456                	sd	s5,40(sp)
    800030ba:	f05a                	sd	s6,32(sp)
    800030bc:	ec5e                	sd	s7,24(sp)
    800030be:	e862                	sd	s8,16(sp)
    800030c0:	e466                	sd	s9,8(sp)
    800030c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030c4:	0001c797          	auipc	a5,0x1c
    800030c8:	6e87a783          	lw	a5,1768(a5) # 8001f7ac <sb+0x4>
    800030cc:	cbd1                	beqz	a5,80003160 <balloc+0xb6>
    800030ce:	8baa                	mv	s7,a0
    800030d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030d2:	0001cb17          	auipc	s6,0x1c
    800030d6:	6d6b0b13          	addi	s6,s6,1750 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030e0:	6c89                	lui	s9,0x2
    800030e2:	a831                	j	800030fe <balloc+0x54>
    brelse(bp);
    800030e4:	854a                	mv	a0,s2
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	e32080e7          	jalr	-462(ra) # 80002f18 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030ee:	015c87bb          	addw	a5,s9,s5
    800030f2:	00078a9b          	sext.w	s5,a5
    800030f6:	004b2703          	lw	a4,4(s6)
    800030fa:	06eaf363          	bgeu	s5,a4,80003160 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030fe:	41fad79b          	sraiw	a5,s5,0x1f
    80003102:	0137d79b          	srliw	a5,a5,0x13
    80003106:	015787bb          	addw	a5,a5,s5
    8000310a:	40d7d79b          	sraiw	a5,a5,0xd
    8000310e:	01cb2583          	lw	a1,28(s6)
    80003112:	9dbd                	addw	a1,a1,a5
    80003114:	855e                	mv	a0,s7
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	cd2080e7          	jalr	-814(ra) # 80002de8 <bread>
    8000311e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003120:	004b2503          	lw	a0,4(s6)
    80003124:	000a849b          	sext.w	s1,s5
    80003128:	8662                	mv	a2,s8
    8000312a:	faa4fde3          	bgeu	s1,a0,800030e4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000312e:	41f6579b          	sraiw	a5,a2,0x1f
    80003132:	01d7d69b          	srliw	a3,a5,0x1d
    80003136:	00c6873b          	addw	a4,a3,a2
    8000313a:	00777793          	andi	a5,a4,7
    8000313e:	9f95                	subw	a5,a5,a3
    80003140:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003144:	4037571b          	sraiw	a4,a4,0x3
    80003148:	00e906b3          	add	a3,s2,a4
    8000314c:	0586c683          	lbu	a3,88(a3)
    80003150:	00d7f5b3          	and	a1,a5,a3
    80003154:	cd91                	beqz	a1,80003170 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003156:	2605                	addiw	a2,a2,1
    80003158:	2485                	addiw	s1,s1,1
    8000315a:	fd4618e3          	bne	a2,s4,8000312a <balloc+0x80>
    8000315e:	b759                	j	800030e4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	3f850513          	addi	a0,a0,1016 # 80008558 <syscalls+0x110>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	3d6080e7          	jalr	982(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003170:	974a                	add	a4,a4,s2
    80003172:	8fd5                	or	a5,a5,a3
    80003174:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003178:	854a                	mv	a0,s2
    8000317a:	00001097          	auipc	ra,0x1
    8000317e:	01a080e7          	jalr	26(ra) # 80004194 <log_write>
        brelse(bp);
    80003182:	854a                	mv	a0,s2
    80003184:	00000097          	auipc	ra,0x0
    80003188:	d94080e7          	jalr	-620(ra) # 80002f18 <brelse>
  bp = bread(dev, bno);
    8000318c:	85a6                	mv	a1,s1
    8000318e:	855e                	mv	a0,s7
    80003190:	00000097          	auipc	ra,0x0
    80003194:	c58080e7          	jalr	-936(ra) # 80002de8 <bread>
    80003198:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000319a:	40000613          	li	a2,1024
    8000319e:	4581                	li	a1,0
    800031a0:	05850513          	addi	a0,a0,88
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	b3c080e7          	jalr	-1220(ra) # 80000ce0 <memset>
  log_write(bp);
    800031ac:	854a                	mv	a0,s2
    800031ae:	00001097          	auipc	ra,0x1
    800031b2:	fe6080e7          	jalr	-26(ra) # 80004194 <log_write>
  brelse(bp);
    800031b6:	854a                	mv	a0,s2
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	d60080e7          	jalr	-672(ra) # 80002f18 <brelse>
}
    800031c0:	8526                	mv	a0,s1
    800031c2:	60e6                	ld	ra,88(sp)
    800031c4:	6446                	ld	s0,80(sp)
    800031c6:	64a6                	ld	s1,72(sp)
    800031c8:	6906                	ld	s2,64(sp)
    800031ca:	79e2                	ld	s3,56(sp)
    800031cc:	7a42                	ld	s4,48(sp)
    800031ce:	7aa2                	ld	s5,40(sp)
    800031d0:	7b02                	ld	s6,32(sp)
    800031d2:	6be2                	ld	s7,24(sp)
    800031d4:	6c42                	ld	s8,16(sp)
    800031d6:	6ca2                	ld	s9,8(sp)
    800031d8:	6125                	addi	sp,sp,96
    800031da:	8082                	ret

00000000800031dc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031dc:	7179                	addi	sp,sp,-48
    800031de:	f406                	sd	ra,40(sp)
    800031e0:	f022                	sd	s0,32(sp)
    800031e2:	ec26                	sd	s1,24(sp)
    800031e4:	e84a                	sd	s2,16(sp)
    800031e6:	e44e                	sd	s3,8(sp)
    800031e8:	e052                	sd	s4,0(sp)
    800031ea:	1800                	addi	s0,sp,48
    800031ec:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031ee:	47ad                	li	a5,11
    800031f0:	04b7fe63          	bgeu	a5,a1,8000324c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031f4:	ff45849b          	addiw	s1,a1,-12
    800031f8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031fc:	0ff00793          	li	a5,255
    80003200:	0ae7e363          	bltu	a5,a4,800032a6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003204:	08052583          	lw	a1,128(a0)
    80003208:	c5ad                	beqz	a1,80003272 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000320a:	00092503          	lw	a0,0(s2)
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	bda080e7          	jalr	-1062(ra) # 80002de8 <bread>
    80003216:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003218:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000321c:	02049593          	slli	a1,s1,0x20
    80003220:	9181                	srli	a1,a1,0x20
    80003222:	058a                	slli	a1,a1,0x2
    80003224:	00b784b3          	add	s1,a5,a1
    80003228:	0004a983          	lw	s3,0(s1)
    8000322c:	04098d63          	beqz	s3,80003286 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003230:	8552                	mv	a0,s4
    80003232:	00000097          	auipc	ra,0x0
    80003236:	ce6080e7          	jalr	-794(ra) # 80002f18 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000323a:	854e                	mv	a0,s3
    8000323c:	70a2                	ld	ra,40(sp)
    8000323e:	7402                	ld	s0,32(sp)
    80003240:	64e2                	ld	s1,24(sp)
    80003242:	6942                	ld	s2,16(sp)
    80003244:	69a2                	ld	s3,8(sp)
    80003246:	6a02                	ld	s4,0(sp)
    80003248:	6145                	addi	sp,sp,48
    8000324a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000324c:	02059493          	slli	s1,a1,0x20
    80003250:	9081                	srli	s1,s1,0x20
    80003252:	048a                	slli	s1,s1,0x2
    80003254:	94aa                	add	s1,s1,a0
    80003256:	0504a983          	lw	s3,80(s1)
    8000325a:	fe0990e3          	bnez	s3,8000323a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000325e:	4108                	lw	a0,0(a0)
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e4a080e7          	jalr	-438(ra) # 800030aa <balloc>
    80003268:	0005099b          	sext.w	s3,a0
    8000326c:	0534a823          	sw	s3,80(s1)
    80003270:	b7e9                	j	8000323a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003272:	4108                	lw	a0,0(a0)
    80003274:	00000097          	auipc	ra,0x0
    80003278:	e36080e7          	jalr	-458(ra) # 800030aa <balloc>
    8000327c:	0005059b          	sext.w	a1,a0
    80003280:	08b92023          	sw	a1,128(s2)
    80003284:	b759                	j	8000320a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003286:	00092503          	lw	a0,0(s2)
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	e20080e7          	jalr	-480(ra) # 800030aa <balloc>
    80003292:	0005099b          	sext.w	s3,a0
    80003296:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000329a:	8552                	mv	a0,s4
    8000329c:	00001097          	auipc	ra,0x1
    800032a0:	ef8080e7          	jalr	-264(ra) # 80004194 <log_write>
    800032a4:	b771                	j	80003230 <bmap+0x54>
  panic("bmap: out of range");
    800032a6:	00005517          	auipc	a0,0x5
    800032aa:	2ca50513          	addi	a0,a0,714 # 80008570 <syscalls+0x128>
    800032ae:	ffffd097          	auipc	ra,0xffffd
    800032b2:	290080e7          	jalr	656(ra) # 8000053e <panic>

00000000800032b6 <iget>:
{
    800032b6:	7179                	addi	sp,sp,-48
    800032b8:	f406                	sd	ra,40(sp)
    800032ba:	f022                	sd	s0,32(sp)
    800032bc:	ec26                	sd	s1,24(sp)
    800032be:	e84a                	sd	s2,16(sp)
    800032c0:	e44e                	sd	s3,8(sp)
    800032c2:	e052                	sd	s4,0(sp)
    800032c4:	1800                	addi	s0,sp,48
    800032c6:	89aa                	mv	s3,a0
    800032c8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032ca:	0001c517          	auipc	a0,0x1c
    800032ce:	4fe50513          	addi	a0,a0,1278 # 8001f7c8 <itable>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	912080e7          	jalr	-1774(ra) # 80000be4 <acquire>
  empty = 0;
    800032da:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032dc:	0001c497          	auipc	s1,0x1c
    800032e0:	50448493          	addi	s1,s1,1284 # 8001f7e0 <itable+0x18>
    800032e4:	0001e697          	auipc	a3,0x1e
    800032e8:	f8c68693          	addi	a3,a3,-116 # 80021270 <log>
    800032ec:	a039                	j	800032fa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032ee:	02090b63          	beqz	s2,80003324 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032f2:	08848493          	addi	s1,s1,136
    800032f6:	02d48a63          	beq	s1,a3,8000332a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032fa:	449c                	lw	a5,8(s1)
    800032fc:	fef059e3          	blez	a5,800032ee <iget+0x38>
    80003300:	4098                	lw	a4,0(s1)
    80003302:	ff3716e3          	bne	a4,s3,800032ee <iget+0x38>
    80003306:	40d8                	lw	a4,4(s1)
    80003308:	ff4713e3          	bne	a4,s4,800032ee <iget+0x38>
      ip->ref++;
    8000330c:	2785                	addiw	a5,a5,1
    8000330e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003310:	0001c517          	auipc	a0,0x1c
    80003314:	4b850513          	addi	a0,a0,1208 # 8001f7c8 <itable>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	980080e7          	jalr	-1664(ra) # 80000c98 <release>
      return ip;
    80003320:	8926                	mv	s2,s1
    80003322:	a03d                	j	80003350 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003324:	f7f9                	bnez	a5,800032f2 <iget+0x3c>
    80003326:	8926                	mv	s2,s1
    80003328:	b7e9                	j	800032f2 <iget+0x3c>
  if(empty == 0)
    8000332a:	02090c63          	beqz	s2,80003362 <iget+0xac>
  ip->dev = dev;
    8000332e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003332:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003336:	4785                	li	a5,1
    80003338:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000333c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003340:	0001c517          	auipc	a0,0x1c
    80003344:	48850513          	addi	a0,a0,1160 # 8001f7c8 <itable>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	950080e7          	jalr	-1712(ra) # 80000c98 <release>
}
    80003350:	854a                	mv	a0,s2
    80003352:	70a2                	ld	ra,40(sp)
    80003354:	7402                	ld	s0,32(sp)
    80003356:	64e2                	ld	s1,24(sp)
    80003358:	6942                	ld	s2,16(sp)
    8000335a:	69a2                	ld	s3,8(sp)
    8000335c:	6a02                	ld	s4,0(sp)
    8000335e:	6145                	addi	sp,sp,48
    80003360:	8082                	ret
    panic("iget: no inodes");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	22650513          	addi	a0,a0,550 # 80008588 <syscalls+0x140>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>

0000000080003372 <fsinit>:
fsinit(int dev) {
    80003372:	7179                	addi	sp,sp,-48
    80003374:	f406                	sd	ra,40(sp)
    80003376:	f022                	sd	s0,32(sp)
    80003378:	ec26                	sd	s1,24(sp)
    8000337a:	e84a                	sd	s2,16(sp)
    8000337c:	e44e                	sd	s3,8(sp)
    8000337e:	1800                	addi	s0,sp,48
    80003380:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003382:	4585                	li	a1,1
    80003384:	00000097          	auipc	ra,0x0
    80003388:	a64080e7          	jalr	-1436(ra) # 80002de8 <bread>
    8000338c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000338e:	0001c997          	auipc	s3,0x1c
    80003392:	41a98993          	addi	s3,s3,1050 # 8001f7a8 <sb>
    80003396:	02000613          	li	a2,32
    8000339a:	05850593          	addi	a1,a0,88
    8000339e:	854e                	mv	a0,s3
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	9a0080e7          	jalr	-1632(ra) # 80000d40 <memmove>
  brelse(bp);
    800033a8:	8526                	mv	a0,s1
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	b6e080e7          	jalr	-1170(ra) # 80002f18 <brelse>
  if(sb.magic != FSMAGIC)
    800033b2:	0009a703          	lw	a4,0(s3)
    800033b6:	102037b7          	lui	a5,0x10203
    800033ba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033be:	02f71263          	bne	a4,a5,800033e2 <fsinit+0x70>
  initlog(dev, &sb);
    800033c2:	0001c597          	auipc	a1,0x1c
    800033c6:	3e658593          	addi	a1,a1,998 # 8001f7a8 <sb>
    800033ca:	854a                	mv	a0,s2
    800033cc:	00001097          	auipc	ra,0x1
    800033d0:	b4c080e7          	jalr	-1204(ra) # 80003f18 <initlog>
}
    800033d4:	70a2                	ld	ra,40(sp)
    800033d6:	7402                	ld	s0,32(sp)
    800033d8:	64e2                	ld	s1,24(sp)
    800033da:	6942                	ld	s2,16(sp)
    800033dc:	69a2                	ld	s3,8(sp)
    800033de:	6145                	addi	sp,sp,48
    800033e0:	8082                	ret
    panic("invalid file system");
    800033e2:	00005517          	auipc	a0,0x5
    800033e6:	1b650513          	addi	a0,a0,438 # 80008598 <syscalls+0x150>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	154080e7          	jalr	340(ra) # 8000053e <panic>

00000000800033f2 <iinit>:
{
    800033f2:	7179                	addi	sp,sp,-48
    800033f4:	f406                	sd	ra,40(sp)
    800033f6:	f022                	sd	s0,32(sp)
    800033f8:	ec26                	sd	s1,24(sp)
    800033fa:	e84a                	sd	s2,16(sp)
    800033fc:	e44e                	sd	s3,8(sp)
    800033fe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003400:	00005597          	auipc	a1,0x5
    80003404:	1b058593          	addi	a1,a1,432 # 800085b0 <syscalls+0x168>
    80003408:	0001c517          	auipc	a0,0x1c
    8000340c:	3c050513          	addi	a0,a0,960 # 8001f7c8 <itable>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	744080e7          	jalr	1860(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003418:	0001c497          	auipc	s1,0x1c
    8000341c:	3d848493          	addi	s1,s1,984 # 8001f7f0 <itable+0x28>
    80003420:	0001e997          	auipc	s3,0x1e
    80003424:	e6098993          	addi	s3,s3,-416 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003428:	00005917          	auipc	s2,0x5
    8000342c:	19090913          	addi	s2,s2,400 # 800085b8 <syscalls+0x170>
    80003430:	85ca                	mv	a1,s2
    80003432:	8526                	mv	a0,s1
    80003434:	00001097          	auipc	ra,0x1
    80003438:	e46080e7          	jalr	-442(ra) # 8000427a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000343c:	08848493          	addi	s1,s1,136
    80003440:	ff3498e3          	bne	s1,s3,80003430 <iinit+0x3e>
}
    80003444:	70a2                	ld	ra,40(sp)
    80003446:	7402                	ld	s0,32(sp)
    80003448:	64e2                	ld	s1,24(sp)
    8000344a:	6942                	ld	s2,16(sp)
    8000344c:	69a2                	ld	s3,8(sp)
    8000344e:	6145                	addi	sp,sp,48
    80003450:	8082                	ret

0000000080003452 <ialloc>:
{
    80003452:	715d                	addi	sp,sp,-80
    80003454:	e486                	sd	ra,72(sp)
    80003456:	e0a2                	sd	s0,64(sp)
    80003458:	fc26                	sd	s1,56(sp)
    8000345a:	f84a                	sd	s2,48(sp)
    8000345c:	f44e                	sd	s3,40(sp)
    8000345e:	f052                	sd	s4,32(sp)
    80003460:	ec56                	sd	s5,24(sp)
    80003462:	e85a                	sd	s6,16(sp)
    80003464:	e45e                	sd	s7,8(sp)
    80003466:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003468:	0001c717          	auipc	a4,0x1c
    8000346c:	34c72703          	lw	a4,844(a4) # 8001f7b4 <sb+0xc>
    80003470:	4785                	li	a5,1
    80003472:	04e7fa63          	bgeu	a5,a4,800034c6 <ialloc+0x74>
    80003476:	8aaa                	mv	s5,a0
    80003478:	8bae                	mv	s7,a1
    8000347a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000347c:	0001ca17          	auipc	s4,0x1c
    80003480:	32ca0a13          	addi	s4,s4,812 # 8001f7a8 <sb>
    80003484:	00048b1b          	sext.w	s6,s1
    80003488:	0044d593          	srli	a1,s1,0x4
    8000348c:	018a2783          	lw	a5,24(s4)
    80003490:	9dbd                	addw	a1,a1,a5
    80003492:	8556                	mv	a0,s5
    80003494:	00000097          	auipc	ra,0x0
    80003498:	954080e7          	jalr	-1708(ra) # 80002de8 <bread>
    8000349c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000349e:	05850993          	addi	s3,a0,88
    800034a2:	00f4f793          	andi	a5,s1,15
    800034a6:	079a                	slli	a5,a5,0x6
    800034a8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034aa:	00099783          	lh	a5,0(s3)
    800034ae:	c785                	beqz	a5,800034d6 <ialloc+0x84>
    brelse(bp);
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	a68080e7          	jalr	-1432(ra) # 80002f18 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034b8:	0485                	addi	s1,s1,1
    800034ba:	00ca2703          	lw	a4,12(s4)
    800034be:	0004879b          	sext.w	a5,s1
    800034c2:	fce7e1e3          	bltu	a5,a4,80003484 <ialloc+0x32>
  panic("ialloc: no inodes");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	0fa50513          	addi	a0,a0,250 # 800085c0 <syscalls+0x178>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800034d6:	04000613          	li	a2,64
    800034da:	4581                	li	a1,0
    800034dc:	854e                	mv	a0,s3
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	802080e7          	jalr	-2046(ra) # 80000ce0 <memset>
      dip->type = type;
    800034e6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034ea:	854a                	mv	a0,s2
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	ca8080e7          	jalr	-856(ra) # 80004194 <log_write>
      brelse(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	a22080e7          	jalr	-1502(ra) # 80002f18 <brelse>
      return iget(dev, inum);
    800034fe:	85da                	mv	a1,s6
    80003500:	8556                	mv	a0,s5
    80003502:	00000097          	auipc	ra,0x0
    80003506:	db4080e7          	jalr	-588(ra) # 800032b6 <iget>
}
    8000350a:	60a6                	ld	ra,72(sp)
    8000350c:	6406                	ld	s0,64(sp)
    8000350e:	74e2                	ld	s1,56(sp)
    80003510:	7942                	ld	s2,48(sp)
    80003512:	79a2                	ld	s3,40(sp)
    80003514:	7a02                	ld	s4,32(sp)
    80003516:	6ae2                	ld	s5,24(sp)
    80003518:	6b42                	ld	s6,16(sp)
    8000351a:	6ba2                	ld	s7,8(sp)
    8000351c:	6161                	addi	sp,sp,80
    8000351e:	8082                	ret

0000000080003520 <iupdate>:
{
    80003520:	1101                	addi	sp,sp,-32
    80003522:	ec06                	sd	ra,24(sp)
    80003524:	e822                	sd	s0,16(sp)
    80003526:	e426                	sd	s1,8(sp)
    80003528:	e04a                	sd	s2,0(sp)
    8000352a:	1000                	addi	s0,sp,32
    8000352c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000352e:	415c                	lw	a5,4(a0)
    80003530:	0047d79b          	srliw	a5,a5,0x4
    80003534:	0001c597          	auipc	a1,0x1c
    80003538:	28c5a583          	lw	a1,652(a1) # 8001f7c0 <sb+0x18>
    8000353c:	9dbd                	addw	a1,a1,a5
    8000353e:	4108                	lw	a0,0(a0)
    80003540:	00000097          	auipc	ra,0x0
    80003544:	8a8080e7          	jalr	-1880(ra) # 80002de8 <bread>
    80003548:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000354a:	05850793          	addi	a5,a0,88
    8000354e:	40c8                	lw	a0,4(s1)
    80003550:	893d                	andi	a0,a0,15
    80003552:	051a                	slli	a0,a0,0x6
    80003554:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003556:	04449703          	lh	a4,68(s1)
    8000355a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000355e:	04649703          	lh	a4,70(s1)
    80003562:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003566:	04849703          	lh	a4,72(s1)
    8000356a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000356e:	04a49703          	lh	a4,74(s1)
    80003572:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003576:	44f8                	lw	a4,76(s1)
    80003578:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000357a:	03400613          	li	a2,52
    8000357e:	05048593          	addi	a1,s1,80
    80003582:	0531                	addi	a0,a0,12
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	7bc080e7          	jalr	1980(ra) # 80000d40 <memmove>
  log_write(bp);
    8000358c:	854a                	mv	a0,s2
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	c06080e7          	jalr	-1018(ra) # 80004194 <log_write>
  brelse(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	980080e7          	jalr	-1664(ra) # 80002f18 <brelse>
}
    800035a0:	60e2                	ld	ra,24(sp)
    800035a2:	6442                	ld	s0,16(sp)
    800035a4:	64a2                	ld	s1,8(sp)
    800035a6:	6902                	ld	s2,0(sp)
    800035a8:	6105                	addi	sp,sp,32
    800035aa:	8082                	ret

00000000800035ac <idup>:
{
    800035ac:	1101                	addi	sp,sp,-32
    800035ae:	ec06                	sd	ra,24(sp)
    800035b0:	e822                	sd	s0,16(sp)
    800035b2:	e426                	sd	s1,8(sp)
    800035b4:	1000                	addi	s0,sp,32
    800035b6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035b8:	0001c517          	auipc	a0,0x1c
    800035bc:	21050513          	addi	a0,a0,528 # 8001f7c8 <itable>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	624080e7          	jalr	1572(ra) # 80000be4 <acquire>
  ip->ref++;
    800035c8:	449c                	lw	a5,8(s1)
    800035ca:	2785                	addiw	a5,a5,1
    800035cc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035ce:	0001c517          	auipc	a0,0x1c
    800035d2:	1fa50513          	addi	a0,a0,506 # 8001f7c8 <itable>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
}
    800035de:	8526                	mv	a0,s1
    800035e0:	60e2                	ld	ra,24(sp)
    800035e2:	6442                	ld	s0,16(sp)
    800035e4:	64a2                	ld	s1,8(sp)
    800035e6:	6105                	addi	sp,sp,32
    800035e8:	8082                	ret

00000000800035ea <ilock>:
{
    800035ea:	1101                	addi	sp,sp,-32
    800035ec:	ec06                	sd	ra,24(sp)
    800035ee:	e822                	sd	s0,16(sp)
    800035f0:	e426                	sd	s1,8(sp)
    800035f2:	e04a                	sd	s2,0(sp)
    800035f4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035f6:	c115                	beqz	a0,8000361a <ilock+0x30>
    800035f8:	84aa                	mv	s1,a0
    800035fa:	451c                	lw	a5,8(a0)
    800035fc:	00f05f63          	blez	a5,8000361a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003600:	0541                	addi	a0,a0,16
    80003602:	00001097          	auipc	ra,0x1
    80003606:	cb2080e7          	jalr	-846(ra) # 800042b4 <acquiresleep>
  if(ip->valid == 0){
    8000360a:	40bc                	lw	a5,64(s1)
    8000360c:	cf99                	beqz	a5,8000362a <ilock+0x40>
}
    8000360e:	60e2                	ld	ra,24(sp)
    80003610:	6442                	ld	s0,16(sp)
    80003612:	64a2                	ld	s1,8(sp)
    80003614:	6902                	ld	s2,0(sp)
    80003616:	6105                	addi	sp,sp,32
    80003618:	8082                	ret
    panic("ilock");
    8000361a:	00005517          	auipc	a0,0x5
    8000361e:	fbe50513          	addi	a0,a0,-66 # 800085d8 <syscalls+0x190>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f1c080e7          	jalr	-228(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000362a:	40dc                	lw	a5,4(s1)
    8000362c:	0047d79b          	srliw	a5,a5,0x4
    80003630:	0001c597          	auipc	a1,0x1c
    80003634:	1905a583          	lw	a1,400(a1) # 8001f7c0 <sb+0x18>
    80003638:	9dbd                	addw	a1,a1,a5
    8000363a:	4088                	lw	a0,0(s1)
    8000363c:	fffff097          	auipc	ra,0xfffff
    80003640:	7ac080e7          	jalr	1964(ra) # 80002de8 <bread>
    80003644:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003646:	05850593          	addi	a1,a0,88
    8000364a:	40dc                	lw	a5,4(s1)
    8000364c:	8bbd                	andi	a5,a5,15
    8000364e:	079a                	slli	a5,a5,0x6
    80003650:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003652:	00059783          	lh	a5,0(a1)
    80003656:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000365a:	00259783          	lh	a5,2(a1)
    8000365e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003662:	00459783          	lh	a5,4(a1)
    80003666:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000366a:	00659783          	lh	a5,6(a1)
    8000366e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003672:	459c                	lw	a5,8(a1)
    80003674:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003676:	03400613          	li	a2,52
    8000367a:	05b1                	addi	a1,a1,12
    8000367c:	05048513          	addi	a0,s1,80
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	6c0080e7          	jalr	1728(ra) # 80000d40 <memmove>
    brelse(bp);
    80003688:	854a                	mv	a0,s2
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	88e080e7          	jalr	-1906(ra) # 80002f18 <brelse>
    ip->valid = 1;
    80003692:	4785                	li	a5,1
    80003694:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003696:	04449783          	lh	a5,68(s1)
    8000369a:	fbb5                	bnez	a5,8000360e <ilock+0x24>
      panic("ilock: no type");
    8000369c:	00005517          	auipc	a0,0x5
    800036a0:	f4450513          	addi	a0,a0,-188 # 800085e0 <syscalls+0x198>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	e9a080e7          	jalr	-358(ra) # 8000053e <panic>

00000000800036ac <iunlock>:
{
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	e04a                	sd	s2,0(sp)
    800036b6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036b8:	c905                	beqz	a0,800036e8 <iunlock+0x3c>
    800036ba:	84aa                	mv	s1,a0
    800036bc:	01050913          	addi	s2,a0,16
    800036c0:	854a                	mv	a0,s2
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	c8c080e7          	jalr	-884(ra) # 8000434e <holdingsleep>
    800036ca:	cd19                	beqz	a0,800036e8 <iunlock+0x3c>
    800036cc:	449c                	lw	a5,8(s1)
    800036ce:	00f05d63          	blez	a5,800036e8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036d2:	854a                	mv	a0,s2
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	c36080e7          	jalr	-970(ra) # 8000430a <releasesleep>
}
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6902                	ld	s2,0(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret
    panic("iunlock");
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	f0850513          	addi	a0,a0,-248 # 800085f0 <syscalls+0x1a8>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	e4e080e7          	jalr	-434(ra) # 8000053e <panic>

00000000800036f8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036f8:	7179                	addi	sp,sp,-48
    800036fa:	f406                	sd	ra,40(sp)
    800036fc:	f022                	sd	s0,32(sp)
    800036fe:	ec26                	sd	s1,24(sp)
    80003700:	e84a                	sd	s2,16(sp)
    80003702:	e44e                	sd	s3,8(sp)
    80003704:	e052                	sd	s4,0(sp)
    80003706:	1800                	addi	s0,sp,48
    80003708:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000370a:	05050493          	addi	s1,a0,80
    8000370e:	08050913          	addi	s2,a0,128
    80003712:	a021                	j	8000371a <itrunc+0x22>
    80003714:	0491                	addi	s1,s1,4
    80003716:	01248d63          	beq	s1,s2,80003730 <itrunc+0x38>
    if(ip->addrs[i]){
    8000371a:	408c                	lw	a1,0(s1)
    8000371c:	dde5                	beqz	a1,80003714 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000371e:	0009a503          	lw	a0,0(s3)
    80003722:	00000097          	auipc	ra,0x0
    80003726:	90c080e7          	jalr	-1780(ra) # 8000302e <bfree>
      ip->addrs[i] = 0;
    8000372a:	0004a023          	sw	zero,0(s1)
    8000372e:	b7dd                	j	80003714 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003730:	0809a583          	lw	a1,128(s3)
    80003734:	e185                	bnez	a1,80003754 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003736:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000373a:	854e                	mv	a0,s3
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	de4080e7          	jalr	-540(ra) # 80003520 <iupdate>
}
    80003744:	70a2                	ld	ra,40(sp)
    80003746:	7402                	ld	s0,32(sp)
    80003748:	64e2                	ld	s1,24(sp)
    8000374a:	6942                	ld	s2,16(sp)
    8000374c:	69a2                	ld	s3,8(sp)
    8000374e:	6a02                	ld	s4,0(sp)
    80003750:	6145                	addi	sp,sp,48
    80003752:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003754:	0009a503          	lw	a0,0(s3)
    80003758:	fffff097          	auipc	ra,0xfffff
    8000375c:	690080e7          	jalr	1680(ra) # 80002de8 <bread>
    80003760:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003762:	05850493          	addi	s1,a0,88
    80003766:	45850913          	addi	s2,a0,1112
    8000376a:	a811                	j	8000377e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000376c:	0009a503          	lw	a0,0(s3)
    80003770:	00000097          	auipc	ra,0x0
    80003774:	8be080e7          	jalr	-1858(ra) # 8000302e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003778:	0491                	addi	s1,s1,4
    8000377a:	01248563          	beq	s1,s2,80003784 <itrunc+0x8c>
      if(a[j])
    8000377e:	408c                	lw	a1,0(s1)
    80003780:	dde5                	beqz	a1,80003778 <itrunc+0x80>
    80003782:	b7ed                	j	8000376c <itrunc+0x74>
    brelse(bp);
    80003784:	8552                	mv	a0,s4
    80003786:	fffff097          	auipc	ra,0xfffff
    8000378a:	792080e7          	jalr	1938(ra) # 80002f18 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000378e:	0809a583          	lw	a1,128(s3)
    80003792:	0009a503          	lw	a0,0(s3)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	898080e7          	jalr	-1896(ra) # 8000302e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000379e:	0809a023          	sw	zero,128(s3)
    800037a2:	bf51                	j	80003736 <itrunc+0x3e>

00000000800037a4 <iput>:
{
    800037a4:	1101                	addi	sp,sp,-32
    800037a6:	ec06                	sd	ra,24(sp)
    800037a8:	e822                	sd	s0,16(sp)
    800037aa:	e426                	sd	s1,8(sp)
    800037ac:	e04a                	sd	s2,0(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037b2:	0001c517          	auipc	a0,0x1c
    800037b6:	01650513          	addi	a0,a0,22 # 8001f7c8 <itable>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	42a080e7          	jalr	1066(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037c2:	4498                	lw	a4,8(s1)
    800037c4:	4785                	li	a5,1
    800037c6:	02f70363          	beq	a4,a5,800037ec <iput+0x48>
  ip->ref--;
    800037ca:	449c                	lw	a5,8(s1)
    800037cc:	37fd                	addiw	a5,a5,-1
    800037ce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037d0:	0001c517          	auipc	a0,0x1c
    800037d4:	ff850513          	addi	a0,a0,-8 # 8001f7c8 <itable>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	4c0080e7          	jalr	1216(ra) # 80000c98 <release>
}
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	64a2                	ld	s1,8(sp)
    800037e6:	6902                	ld	s2,0(sp)
    800037e8:	6105                	addi	sp,sp,32
    800037ea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037ec:	40bc                	lw	a5,64(s1)
    800037ee:	dff1                	beqz	a5,800037ca <iput+0x26>
    800037f0:	04a49783          	lh	a5,74(s1)
    800037f4:	fbf9                	bnez	a5,800037ca <iput+0x26>
    acquiresleep(&ip->lock);
    800037f6:	01048913          	addi	s2,s1,16
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	ab8080e7          	jalr	-1352(ra) # 800042b4 <acquiresleep>
    release(&itable.lock);
    80003804:	0001c517          	auipc	a0,0x1c
    80003808:	fc450513          	addi	a0,a0,-60 # 8001f7c8 <itable>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	48c080e7          	jalr	1164(ra) # 80000c98 <release>
    itrunc(ip);
    80003814:	8526                	mv	a0,s1
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	ee2080e7          	jalr	-286(ra) # 800036f8 <itrunc>
    ip->type = 0;
    8000381e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003822:	8526                	mv	a0,s1
    80003824:	00000097          	auipc	ra,0x0
    80003828:	cfc080e7          	jalr	-772(ra) # 80003520 <iupdate>
    ip->valid = 0;
    8000382c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003830:	854a                	mv	a0,s2
    80003832:	00001097          	auipc	ra,0x1
    80003836:	ad8080e7          	jalr	-1320(ra) # 8000430a <releasesleep>
    acquire(&itable.lock);
    8000383a:	0001c517          	auipc	a0,0x1c
    8000383e:	f8e50513          	addi	a0,a0,-114 # 8001f7c8 <itable>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	3a2080e7          	jalr	930(ra) # 80000be4 <acquire>
    8000384a:	b741                	j	800037ca <iput+0x26>

000000008000384c <iunlockput>:
{
    8000384c:	1101                	addi	sp,sp,-32
    8000384e:	ec06                	sd	ra,24(sp)
    80003850:	e822                	sd	s0,16(sp)
    80003852:	e426                	sd	s1,8(sp)
    80003854:	1000                	addi	s0,sp,32
    80003856:	84aa                	mv	s1,a0
  iunlock(ip);
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	e54080e7          	jalr	-428(ra) # 800036ac <iunlock>
  iput(ip);
    80003860:	8526                	mv	a0,s1
    80003862:	00000097          	auipc	ra,0x0
    80003866:	f42080e7          	jalr	-190(ra) # 800037a4 <iput>
}
    8000386a:	60e2                	ld	ra,24(sp)
    8000386c:	6442                	ld	s0,16(sp)
    8000386e:	64a2                	ld	s1,8(sp)
    80003870:	6105                	addi	sp,sp,32
    80003872:	8082                	ret

0000000080003874 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003874:	1141                	addi	sp,sp,-16
    80003876:	e422                	sd	s0,8(sp)
    80003878:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000387a:	411c                	lw	a5,0(a0)
    8000387c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000387e:	415c                	lw	a5,4(a0)
    80003880:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003882:	04451783          	lh	a5,68(a0)
    80003886:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000388a:	04a51783          	lh	a5,74(a0)
    8000388e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003892:	04c56783          	lwu	a5,76(a0)
    80003896:	e99c                	sd	a5,16(a1)
}
    80003898:	6422                	ld	s0,8(sp)
    8000389a:	0141                	addi	sp,sp,16
    8000389c:	8082                	ret

000000008000389e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000389e:	457c                	lw	a5,76(a0)
    800038a0:	0ed7e963          	bltu	a5,a3,80003992 <readi+0xf4>
{
    800038a4:	7159                	addi	sp,sp,-112
    800038a6:	f486                	sd	ra,104(sp)
    800038a8:	f0a2                	sd	s0,96(sp)
    800038aa:	eca6                	sd	s1,88(sp)
    800038ac:	e8ca                	sd	s2,80(sp)
    800038ae:	e4ce                	sd	s3,72(sp)
    800038b0:	e0d2                	sd	s4,64(sp)
    800038b2:	fc56                	sd	s5,56(sp)
    800038b4:	f85a                	sd	s6,48(sp)
    800038b6:	f45e                	sd	s7,40(sp)
    800038b8:	f062                	sd	s8,32(sp)
    800038ba:	ec66                	sd	s9,24(sp)
    800038bc:	e86a                	sd	s10,16(sp)
    800038be:	e46e                	sd	s11,8(sp)
    800038c0:	1880                	addi	s0,sp,112
    800038c2:	8baa                	mv	s7,a0
    800038c4:	8c2e                	mv	s8,a1
    800038c6:	8ab2                	mv	s5,a2
    800038c8:	84b6                	mv	s1,a3
    800038ca:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038cc:	9f35                	addw	a4,a4,a3
    return 0;
    800038ce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038d0:	0ad76063          	bltu	a4,a3,80003970 <readi+0xd2>
  if(off + n > ip->size)
    800038d4:	00e7f463          	bgeu	a5,a4,800038dc <readi+0x3e>
    n = ip->size - off;
    800038d8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038dc:	0a0b0963          	beqz	s6,8000398e <readi+0xf0>
    800038e0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038e2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038e6:	5cfd                	li	s9,-1
    800038e8:	a82d                	j	80003922 <readi+0x84>
    800038ea:	020a1d93          	slli	s11,s4,0x20
    800038ee:	020ddd93          	srli	s11,s11,0x20
    800038f2:	05890613          	addi	a2,s2,88
    800038f6:	86ee                	mv	a3,s11
    800038f8:	963a                	add	a2,a2,a4
    800038fa:	85d6                	mv	a1,s5
    800038fc:	8562                	mv	a0,s8
    800038fe:	fffff097          	auipc	ra,0xfffff
    80003902:	b12080e7          	jalr	-1262(ra) # 80002410 <either_copyout>
    80003906:	05950d63          	beq	a0,s9,80003960 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000390a:	854a                	mv	a0,s2
    8000390c:	fffff097          	auipc	ra,0xfffff
    80003910:	60c080e7          	jalr	1548(ra) # 80002f18 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003914:	013a09bb          	addw	s3,s4,s3
    80003918:	009a04bb          	addw	s1,s4,s1
    8000391c:	9aee                	add	s5,s5,s11
    8000391e:	0569f763          	bgeu	s3,s6,8000396c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003922:	000ba903          	lw	s2,0(s7)
    80003926:	00a4d59b          	srliw	a1,s1,0xa
    8000392a:	855e                	mv	a0,s7
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	8b0080e7          	jalr	-1872(ra) # 800031dc <bmap>
    80003934:	0005059b          	sext.w	a1,a0
    80003938:	854a                	mv	a0,s2
    8000393a:	fffff097          	auipc	ra,0xfffff
    8000393e:	4ae080e7          	jalr	1198(ra) # 80002de8 <bread>
    80003942:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003944:	3ff4f713          	andi	a4,s1,1023
    80003948:	40ed07bb          	subw	a5,s10,a4
    8000394c:	413b06bb          	subw	a3,s6,s3
    80003950:	8a3e                	mv	s4,a5
    80003952:	2781                	sext.w	a5,a5
    80003954:	0006861b          	sext.w	a2,a3
    80003958:	f8f679e3          	bgeu	a2,a5,800038ea <readi+0x4c>
    8000395c:	8a36                	mv	s4,a3
    8000395e:	b771                	j	800038ea <readi+0x4c>
      brelse(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	fffff097          	auipc	ra,0xfffff
    80003966:	5b6080e7          	jalr	1462(ra) # 80002f18 <brelse>
      tot = -1;
    8000396a:	59fd                	li	s3,-1
  }
  return tot;
    8000396c:	0009851b          	sext.w	a0,s3
}
    80003970:	70a6                	ld	ra,104(sp)
    80003972:	7406                	ld	s0,96(sp)
    80003974:	64e6                	ld	s1,88(sp)
    80003976:	6946                	ld	s2,80(sp)
    80003978:	69a6                	ld	s3,72(sp)
    8000397a:	6a06                	ld	s4,64(sp)
    8000397c:	7ae2                	ld	s5,56(sp)
    8000397e:	7b42                	ld	s6,48(sp)
    80003980:	7ba2                	ld	s7,40(sp)
    80003982:	7c02                	ld	s8,32(sp)
    80003984:	6ce2                	ld	s9,24(sp)
    80003986:	6d42                	ld	s10,16(sp)
    80003988:	6da2                	ld	s11,8(sp)
    8000398a:	6165                	addi	sp,sp,112
    8000398c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000398e:	89da                	mv	s3,s6
    80003990:	bff1                	j	8000396c <readi+0xce>
    return 0;
    80003992:	4501                	li	a0,0
}
    80003994:	8082                	ret

0000000080003996 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003996:	457c                	lw	a5,76(a0)
    80003998:	10d7e863          	bltu	a5,a3,80003aa8 <writei+0x112>
{
    8000399c:	7159                	addi	sp,sp,-112
    8000399e:	f486                	sd	ra,104(sp)
    800039a0:	f0a2                	sd	s0,96(sp)
    800039a2:	eca6                	sd	s1,88(sp)
    800039a4:	e8ca                	sd	s2,80(sp)
    800039a6:	e4ce                	sd	s3,72(sp)
    800039a8:	e0d2                	sd	s4,64(sp)
    800039aa:	fc56                	sd	s5,56(sp)
    800039ac:	f85a                	sd	s6,48(sp)
    800039ae:	f45e                	sd	s7,40(sp)
    800039b0:	f062                	sd	s8,32(sp)
    800039b2:	ec66                	sd	s9,24(sp)
    800039b4:	e86a                	sd	s10,16(sp)
    800039b6:	e46e                	sd	s11,8(sp)
    800039b8:	1880                	addi	s0,sp,112
    800039ba:	8b2a                	mv	s6,a0
    800039bc:	8c2e                	mv	s8,a1
    800039be:	8ab2                	mv	s5,a2
    800039c0:	8936                	mv	s2,a3
    800039c2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039c4:	00e687bb          	addw	a5,a3,a4
    800039c8:	0ed7e263          	bltu	a5,a3,80003aac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039cc:	00043737          	lui	a4,0x43
    800039d0:	0ef76063          	bltu	a4,a5,80003ab0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039d4:	0c0b8863          	beqz	s7,80003aa4 <writei+0x10e>
    800039d8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039da:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039de:	5cfd                	li	s9,-1
    800039e0:	a091                	j	80003a24 <writei+0x8e>
    800039e2:	02099d93          	slli	s11,s3,0x20
    800039e6:	020ddd93          	srli	s11,s11,0x20
    800039ea:	05848513          	addi	a0,s1,88
    800039ee:	86ee                	mv	a3,s11
    800039f0:	8656                	mv	a2,s5
    800039f2:	85e2                	mv	a1,s8
    800039f4:	953a                	add	a0,a0,a4
    800039f6:	fffff097          	auipc	ra,0xfffff
    800039fa:	a70080e7          	jalr	-1424(ra) # 80002466 <either_copyin>
    800039fe:	07950263          	beq	a0,s9,80003a62 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a02:	8526                	mv	a0,s1
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	790080e7          	jalr	1936(ra) # 80004194 <log_write>
    brelse(bp);
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	fffff097          	auipc	ra,0xfffff
    80003a12:	50a080e7          	jalr	1290(ra) # 80002f18 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a16:	01498a3b          	addw	s4,s3,s4
    80003a1a:	0129893b          	addw	s2,s3,s2
    80003a1e:	9aee                	add	s5,s5,s11
    80003a20:	057a7663          	bgeu	s4,s7,80003a6c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a24:	000b2483          	lw	s1,0(s6)
    80003a28:	00a9559b          	srliw	a1,s2,0xa
    80003a2c:	855a                	mv	a0,s6
    80003a2e:	fffff097          	auipc	ra,0xfffff
    80003a32:	7ae080e7          	jalr	1966(ra) # 800031dc <bmap>
    80003a36:	0005059b          	sext.w	a1,a0
    80003a3a:	8526                	mv	a0,s1
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	3ac080e7          	jalr	940(ra) # 80002de8 <bread>
    80003a44:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a46:	3ff97713          	andi	a4,s2,1023
    80003a4a:	40ed07bb          	subw	a5,s10,a4
    80003a4e:	414b86bb          	subw	a3,s7,s4
    80003a52:	89be                	mv	s3,a5
    80003a54:	2781                	sext.w	a5,a5
    80003a56:	0006861b          	sext.w	a2,a3
    80003a5a:	f8f674e3          	bgeu	a2,a5,800039e2 <writei+0x4c>
    80003a5e:	89b6                	mv	s3,a3
    80003a60:	b749                	j	800039e2 <writei+0x4c>
      brelse(bp);
    80003a62:	8526                	mv	a0,s1
    80003a64:	fffff097          	auipc	ra,0xfffff
    80003a68:	4b4080e7          	jalr	1204(ra) # 80002f18 <brelse>
  }

  if(off > ip->size)
    80003a6c:	04cb2783          	lw	a5,76(s6)
    80003a70:	0127f463          	bgeu	a5,s2,80003a78 <writei+0xe2>
    ip->size = off;
    80003a74:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a78:	855a                	mv	a0,s6
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	aa6080e7          	jalr	-1370(ra) # 80003520 <iupdate>

  return tot;
    80003a82:	000a051b          	sext.w	a0,s4
}
    80003a86:	70a6                	ld	ra,104(sp)
    80003a88:	7406                	ld	s0,96(sp)
    80003a8a:	64e6                	ld	s1,88(sp)
    80003a8c:	6946                	ld	s2,80(sp)
    80003a8e:	69a6                	ld	s3,72(sp)
    80003a90:	6a06                	ld	s4,64(sp)
    80003a92:	7ae2                	ld	s5,56(sp)
    80003a94:	7b42                	ld	s6,48(sp)
    80003a96:	7ba2                	ld	s7,40(sp)
    80003a98:	7c02                	ld	s8,32(sp)
    80003a9a:	6ce2                	ld	s9,24(sp)
    80003a9c:	6d42                	ld	s10,16(sp)
    80003a9e:	6da2                	ld	s11,8(sp)
    80003aa0:	6165                	addi	sp,sp,112
    80003aa2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa4:	8a5e                	mv	s4,s7
    80003aa6:	bfc9                	j	80003a78 <writei+0xe2>
    return -1;
    80003aa8:	557d                	li	a0,-1
}
    80003aaa:	8082                	ret
    return -1;
    80003aac:	557d                	li	a0,-1
    80003aae:	bfe1                	j	80003a86 <writei+0xf0>
    return -1;
    80003ab0:	557d                	li	a0,-1
    80003ab2:	bfd1                	j	80003a86 <writei+0xf0>

0000000080003ab4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ab4:	1141                	addi	sp,sp,-16
    80003ab6:	e406                	sd	ra,8(sp)
    80003ab8:	e022                	sd	s0,0(sp)
    80003aba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003abc:	4639                	li	a2,14
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	2fa080e7          	jalr	762(ra) # 80000db8 <strncmp>
}
    80003ac6:	60a2                	ld	ra,8(sp)
    80003ac8:	6402                	ld	s0,0(sp)
    80003aca:	0141                	addi	sp,sp,16
    80003acc:	8082                	ret

0000000080003ace <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ace:	7139                	addi	sp,sp,-64
    80003ad0:	fc06                	sd	ra,56(sp)
    80003ad2:	f822                	sd	s0,48(sp)
    80003ad4:	f426                	sd	s1,40(sp)
    80003ad6:	f04a                	sd	s2,32(sp)
    80003ad8:	ec4e                	sd	s3,24(sp)
    80003ada:	e852                	sd	s4,16(sp)
    80003adc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ade:	04451703          	lh	a4,68(a0)
    80003ae2:	4785                	li	a5,1
    80003ae4:	00f71a63          	bne	a4,a5,80003af8 <dirlookup+0x2a>
    80003ae8:	892a                	mv	s2,a0
    80003aea:	89ae                	mv	s3,a1
    80003aec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003aee:	457c                	lw	a5,76(a0)
    80003af0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003af2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003af4:	e79d                	bnez	a5,80003b22 <dirlookup+0x54>
    80003af6:	a8a5                	j	80003b6e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003af8:	00005517          	auipc	a0,0x5
    80003afc:	b0050513          	addi	a0,a0,-1280 # 800085f8 <syscalls+0x1b0>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	a3e080e7          	jalr	-1474(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b08:	00005517          	auipc	a0,0x5
    80003b0c:	b0850513          	addi	a0,a0,-1272 # 80008610 <syscalls+0x1c8>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	a2e080e7          	jalr	-1490(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b18:	24c1                	addiw	s1,s1,16
    80003b1a:	04c92783          	lw	a5,76(s2)
    80003b1e:	04f4f763          	bgeu	s1,a5,80003b6c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b22:	4741                	li	a4,16
    80003b24:	86a6                	mv	a3,s1
    80003b26:	fc040613          	addi	a2,s0,-64
    80003b2a:	4581                	li	a1,0
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	d70080e7          	jalr	-656(ra) # 8000389e <readi>
    80003b36:	47c1                	li	a5,16
    80003b38:	fcf518e3          	bne	a0,a5,80003b08 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b3c:	fc045783          	lhu	a5,-64(s0)
    80003b40:	dfe1                	beqz	a5,80003b18 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b42:	fc240593          	addi	a1,s0,-62
    80003b46:	854e                	mv	a0,s3
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	f6c080e7          	jalr	-148(ra) # 80003ab4 <namecmp>
    80003b50:	f561                	bnez	a0,80003b18 <dirlookup+0x4a>
      if(poff)
    80003b52:	000a0463          	beqz	s4,80003b5a <dirlookup+0x8c>
        *poff = off;
    80003b56:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b5a:	fc045583          	lhu	a1,-64(s0)
    80003b5e:	00092503          	lw	a0,0(s2)
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	754080e7          	jalr	1876(ra) # 800032b6 <iget>
    80003b6a:	a011                	j	80003b6e <dirlookup+0xa0>
  return 0;
    80003b6c:	4501                	li	a0,0
}
    80003b6e:	70e2                	ld	ra,56(sp)
    80003b70:	7442                	ld	s0,48(sp)
    80003b72:	74a2                	ld	s1,40(sp)
    80003b74:	7902                	ld	s2,32(sp)
    80003b76:	69e2                	ld	s3,24(sp)
    80003b78:	6a42                	ld	s4,16(sp)
    80003b7a:	6121                	addi	sp,sp,64
    80003b7c:	8082                	ret

0000000080003b7e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b7e:	711d                	addi	sp,sp,-96
    80003b80:	ec86                	sd	ra,88(sp)
    80003b82:	e8a2                	sd	s0,80(sp)
    80003b84:	e4a6                	sd	s1,72(sp)
    80003b86:	e0ca                	sd	s2,64(sp)
    80003b88:	fc4e                	sd	s3,56(sp)
    80003b8a:	f852                	sd	s4,48(sp)
    80003b8c:	f456                	sd	s5,40(sp)
    80003b8e:	f05a                	sd	s6,32(sp)
    80003b90:	ec5e                	sd	s7,24(sp)
    80003b92:	e862                	sd	s8,16(sp)
    80003b94:	e466                	sd	s9,8(sp)
    80003b96:	1080                	addi	s0,sp,96
    80003b98:	84aa                	mv	s1,a0
    80003b9a:	8b2e                	mv	s6,a1
    80003b9c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b9e:	00054703          	lbu	a4,0(a0)
    80003ba2:	02f00793          	li	a5,47
    80003ba6:	02f70363          	beq	a4,a5,80003bcc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003baa:	ffffe097          	auipc	ra,0xffffe
    80003bae:	e06080e7          	jalr	-506(ra) # 800019b0 <myproc>
    80003bb2:	15053503          	ld	a0,336(a0)
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	9f6080e7          	jalr	-1546(ra) # 800035ac <idup>
    80003bbe:	89aa                	mv	s3,a0
  while(*path == '/')
    80003bc0:	02f00913          	li	s2,47
  len = path - s;
    80003bc4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003bc6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bc8:	4c05                	li	s8,1
    80003bca:	a865                	j	80003c82 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bcc:	4585                	li	a1,1
    80003bce:	4505                	li	a0,1
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	6e6080e7          	jalr	1766(ra) # 800032b6 <iget>
    80003bd8:	89aa                	mv	s3,a0
    80003bda:	b7dd                	j	80003bc0 <namex+0x42>
      iunlockput(ip);
    80003bdc:	854e                	mv	a0,s3
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	c6e080e7          	jalr	-914(ra) # 8000384c <iunlockput>
      return 0;
    80003be6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003be8:	854e                	mv	a0,s3
    80003bea:	60e6                	ld	ra,88(sp)
    80003bec:	6446                	ld	s0,80(sp)
    80003bee:	64a6                	ld	s1,72(sp)
    80003bf0:	6906                	ld	s2,64(sp)
    80003bf2:	79e2                	ld	s3,56(sp)
    80003bf4:	7a42                	ld	s4,48(sp)
    80003bf6:	7aa2                	ld	s5,40(sp)
    80003bf8:	7b02                	ld	s6,32(sp)
    80003bfa:	6be2                	ld	s7,24(sp)
    80003bfc:	6c42                	ld	s8,16(sp)
    80003bfe:	6ca2                	ld	s9,8(sp)
    80003c00:	6125                	addi	sp,sp,96
    80003c02:	8082                	ret
      iunlock(ip);
    80003c04:	854e                	mv	a0,s3
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	aa6080e7          	jalr	-1370(ra) # 800036ac <iunlock>
      return ip;
    80003c0e:	bfe9                	j	80003be8 <namex+0x6a>
      iunlockput(ip);
    80003c10:	854e                	mv	a0,s3
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	c3a080e7          	jalr	-966(ra) # 8000384c <iunlockput>
      return 0;
    80003c1a:	89d2                	mv	s3,s4
    80003c1c:	b7f1                	j	80003be8 <namex+0x6a>
  len = path - s;
    80003c1e:	40b48633          	sub	a2,s1,a1
    80003c22:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c26:	094cd463          	bge	s9,s4,80003cae <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c2a:	4639                	li	a2,14
    80003c2c:	8556                	mv	a0,s5
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	112080e7          	jalr	274(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c36:	0004c783          	lbu	a5,0(s1)
    80003c3a:	01279763          	bne	a5,s2,80003c48 <namex+0xca>
    path++;
    80003c3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c40:	0004c783          	lbu	a5,0(s1)
    80003c44:	ff278de3          	beq	a5,s2,80003c3e <namex+0xc0>
    ilock(ip);
    80003c48:	854e                	mv	a0,s3
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	9a0080e7          	jalr	-1632(ra) # 800035ea <ilock>
    if(ip->type != T_DIR){
    80003c52:	04499783          	lh	a5,68(s3)
    80003c56:	f98793e3          	bne	a5,s8,80003bdc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c5a:	000b0563          	beqz	s6,80003c64 <namex+0xe6>
    80003c5e:	0004c783          	lbu	a5,0(s1)
    80003c62:	d3cd                	beqz	a5,80003c04 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c64:	865e                	mv	a2,s7
    80003c66:	85d6                	mv	a1,s5
    80003c68:	854e                	mv	a0,s3
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	e64080e7          	jalr	-412(ra) # 80003ace <dirlookup>
    80003c72:	8a2a                	mv	s4,a0
    80003c74:	dd51                	beqz	a0,80003c10 <namex+0x92>
    iunlockput(ip);
    80003c76:	854e                	mv	a0,s3
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	bd4080e7          	jalr	-1068(ra) # 8000384c <iunlockput>
    ip = next;
    80003c80:	89d2                	mv	s3,s4
  while(*path == '/')
    80003c82:	0004c783          	lbu	a5,0(s1)
    80003c86:	05279763          	bne	a5,s2,80003cd4 <namex+0x156>
    path++;
    80003c8a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c8c:	0004c783          	lbu	a5,0(s1)
    80003c90:	ff278de3          	beq	a5,s2,80003c8a <namex+0x10c>
  if(*path == 0)
    80003c94:	c79d                	beqz	a5,80003cc2 <namex+0x144>
    path++;
    80003c96:	85a6                	mv	a1,s1
  len = path - s;
    80003c98:	8a5e                	mv	s4,s7
    80003c9a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003c9c:	01278963          	beq	a5,s2,80003cae <namex+0x130>
    80003ca0:	dfbd                	beqz	a5,80003c1e <namex+0xa0>
    path++;
    80003ca2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ca4:	0004c783          	lbu	a5,0(s1)
    80003ca8:	ff279ce3          	bne	a5,s2,80003ca0 <namex+0x122>
    80003cac:	bf8d                	j	80003c1e <namex+0xa0>
    memmove(name, s, len);
    80003cae:	2601                	sext.w	a2,a2
    80003cb0:	8556                	mv	a0,s5
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	08e080e7          	jalr	142(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003cba:	9a56                	add	s4,s4,s5
    80003cbc:	000a0023          	sb	zero,0(s4)
    80003cc0:	bf9d                	j	80003c36 <namex+0xb8>
  if(nameiparent){
    80003cc2:	f20b03e3          	beqz	s6,80003be8 <namex+0x6a>
    iput(ip);
    80003cc6:	854e                	mv	a0,s3
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	adc080e7          	jalr	-1316(ra) # 800037a4 <iput>
    return 0;
    80003cd0:	4981                	li	s3,0
    80003cd2:	bf19                	j	80003be8 <namex+0x6a>
  if(*path == 0)
    80003cd4:	d7fd                	beqz	a5,80003cc2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cd6:	0004c783          	lbu	a5,0(s1)
    80003cda:	85a6                	mv	a1,s1
    80003cdc:	b7d1                	j	80003ca0 <namex+0x122>

0000000080003cde <dirlink>:
{
    80003cde:	7139                	addi	sp,sp,-64
    80003ce0:	fc06                	sd	ra,56(sp)
    80003ce2:	f822                	sd	s0,48(sp)
    80003ce4:	f426                	sd	s1,40(sp)
    80003ce6:	f04a                	sd	s2,32(sp)
    80003ce8:	ec4e                	sd	s3,24(sp)
    80003cea:	e852                	sd	s4,16(sp)
    80003cec:	0080                	addi	s0,sp,64
    80003cee:	892a                	mv	s2,a0
    80003cf0:	8a2e                	mv	s4,a1
    80003cf2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cf4:	4601                	li	a2,0
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	dd8080e7          	jalr	-552(ra) # 80003ace <dirlookup>
    80003cfe:	e93d                	bnez	a0,80003d74 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d00:	04c92483          	lw	s1,76(s2)
    80003d04:	c49d                	beqz	s1,80003d32 <dirlink+0x54>
    80003d06:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d08:	4741                	li	a4,16
    80003d0a:	86a6                	mv	a3,s1
    80003d0c:	fc040613          	addi	a2,s0,-64
    80003d10:	4581                	li	a1,0
    80003d12:	854a                	mv	a0,s2
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	b8a080e7          	jalr	-1142(ra) # 8000389e <readi>
    80003d1c:	47c1                	li	a5,16
    80003d1e:	06f51163          	bne	a0,a5,80003d80 <dirlink+0xa2>
    if(de.inum == 0)
    80003d22:	fc045783          	lhu	a5,-64(s0)
    80003d26:	c791                	beqz	a5,80003d32 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d28:	24c1                	addiw	s1,s1,16
    80003d2a:	04c92783          	lw	a5,76(s2)
    80003d2e:	fcf4ede3          	bltu	s1,a5,80003d08 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d32:	4639                	li	a2,14
    80003d34:	85d2                	mv	a1,s4
    80003d36:	fc240513          	addi	a0,s0,-62
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	0ba080e7          	jalr	186(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003d42:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d46:	4741                	li	a4,16
    80003d48:	86a6                	mv	a3,s1
    80003d4a:	fc040613          	addi	a2,s0,-64
    80003d4e:	4581                	li	a1,0
    80003d50:	854a                	mv	a0,s2
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	c44080e7          	jalr	-956(ra) # 80003996 <writei>
    80003d5a:	872a                	mv	a4,a0
    80003d5c:	47c1                	li	a5,16
  return 0;
    80003d5e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d60:	02f71863          	bne	a4,a5,80003d90 <dirlink+0xb2>
}
    80003d64:	70e2                	ld	ra,56(sp)
    80003d66:	7442                	ld	s0,48(sp)
    80003d68:	74a2                	ld	s1,40(sp)
    80003d6a:	7902                	ld	s2,32(sp)
    80003d6c:	69e2                	ld	s3,24(sp)
    80003d6e:	6a42                	ld	s4,16(sp)
    80003d70:	6121                	addi	sp,sp,64
    80003d72:	8082                	ret
    iput(ip);
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	a30080e7          	jalr	-1488(ra) # 800037a4 <iput>
    return -1;
    80003d7c:	557d                	li	a0,-1
    80003d7e:	b7dd                	j	80003d64 <dirlink+0x86>
      panic("dirlink read");
    80003d80:	00005517          	auipc	a0,0x5
    80003d84:	8a050513          	addi	a0,a0,-1888 # 80008620 <syscalls+0x1d8>
    80003d88:	ffffc097          	auipc	ra,0xffffc
    80003d8c:	7b6080e7          	jalr	1974(ra) # 8000053e <panic>
    panic("dirlink");
    80003d90:	00005517          	auipc	a0,0x5
    80003d94:	9a050513          	addi	a0,a0,-1632 # 80008730 <syscalls+0x2e8>
    80003d98:	ffffc097          	auipc	ra,0xffffc
    80003d9c:	7a6080e7          	jalr	1958(ra) # 8000053e <panic>

0000000080003da0 <namei>:

struct inode*
namei(char *path)
{
    80003da0:	1101                	addi	sp,sp,-32
    80003da2:	ec06                	sd	ra,24(sp)
    80003da4:	e822                	sd	s0,16(sp)
    80003da6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003da8:	fe040613          	addi	a2,s0,-32
    80003dac:	4581                	li	a1,0
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	dd0080e7          	jalr	-560(ra) # 80003b7e <namex>
}
    80003db6:	60e2                	ld	ra,24(sp)
    80003db8:	6442                	ld	s0,16(sp)
    80003dba:	6105                	addi	sp,sp,32
    80003dbc:	8082                	ret

0000000080003dbe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dbe:	1141                	addi	sp,sp,-16
    80003dc0:	e406                	sd	ra,8(sp)
    80003dc2:	e022                	sd	s0,0(sp)
    80003dc4:	0800                	addi	s0,sp,16
    80003dc6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dc8:	4585                	li	a1,1
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	db4080e7          	jalr	-588(ra) # 80003b7e <namex>
}
    80003dd2:	60a2                	ld	ra,8(sp)
    80003dd4:	6402                	ld	s0,0(sp)
    80003dd6:	0141                	addi	sp,sp,16
    80003dd8:	8082                	ret

0000000080003dda <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dda:	1101                	addi	sp,sp,-32
    80003ddc:	ec06                	sd	ra,24(sp)
    80003dde:	e822                	sd	s0,16(sp)
    80003de0:	e426                	sd	s1,8(sp)
    80003de2:	e04a                	sd	s2,0(sp)
    80003de4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003de6:	0001d917          	auipc	s2,0x1d
    80003dea:	48a90913          	addi	s2,s2,1162 # 80021270 <log>
    80003dee:	01892583          	lw	a1,24(s2)
    80003df2:	02892503          	lw	a0,40(s2)
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	ff2080e7          	jalr	-14(ra) # 80002de8 <bread>
    80003dfe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e00:	02c92683          	lw	a3,44(s2)
    80003e04:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e06:	02d05763          	blez	a3,80003e34 <write_head+0x5a>
    80003e0a:	0001d797          	auipc	a5,0x1d
    80003e0e:	49678793          	addi	a5,a5,1174 # 800212a0 <log+0x30>
    80003e12:	05c50713          	addi	a4,a0,92
    80003e16:	36fd                	addiw	a3,a3,-1
    80003e18:	1682                	slli	a3,a3,0x20
    80003e1a:	9281                	srli	a3,a3,0x20
    80003e1c:	068a                	slli	a3,a3,0x2
    80003e1e:	0001d617          	auipc	a2,0x1d
    80003e22:	48660613          	addi	a2,a2,1158 # 800212a4 <log+0x34>
    80003e26:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e28:	4390                	lw	a2,0(a5)
    80003e2a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e2c:	0791                	addi	a5,a5,4
    80003e2e:	0711                	addi	a4,a4,4
    80003e30:	fed79ce3          	bne	a5,a3,80003e28 <write_head+0x4e>
  }
  bwrite(buf);
    80003e34:	8526                	mv	a0,s1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	0a4080e7          	jalr	164(ra) # 80002eda <bwrite>
  brelse(buf);
    80003e3e:	8526                	mv	a0,s1
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	0d8080e7          	jalr	216(ra) # 80002f18 <brelse>
}
    80003e48:	60e2                	ld	ra,24(sp)
    80003e4a:	6442                	ld	s0,16(sp)
    80003e4c:	64a2                	ld	s1,8(sp)
    80003e4e:	6902                	ld	s2,0(sp)
    80003e50:	6105                	addi	sp,sp,32
    80003e52:	8082                	ret

0000000080003e54 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e54:	0001d797          	auipc	a5,0x1d
    80003e58:	4487a783          	lw	a5,1096(a5) # 8002129c <log+0x2c>
    80003e5c:	0af05d63          	blez	a5,80003f16 <install_trans+0xc2>
{
    80003e60:	7139                	addi	sp,sp,-64
    80003e62:	fc06                	sd	ra,56(sp)
    80003e64:	f822                	sd	s0,48(sp)
    80003e66:	f426                	sd	s1,40(sp)
    80003e68:	f04a                	sd	s2,32(sp)
    80003e6a:	ec4e                	sd	s3,24(sp)
    80003e6c:	e852                	sd	s4,16(sp)
    80003e6e:	e456                	sd	s5,8(sp)
    80003e70:	e05a                	sd	s6,0(sp)
    80003e72:	0080                	addi	s0,sp,64
    80003e74:	8b2a                	mv	s6,a0
    80003e76:	0001da97          	auipc	s5,0x1d
    80003e7a:	42aa8a93          	addi	s5,s5,1066 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e7e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e80:	0001d997          	auipc	s3,0x1d
    80003e84:	3f098993          	addi	s3,s3,1008 # 80021270 <log>
    80003e88:	a035                	j	80003eb4 <install_trans+0x60>
      bunpin(dbuf);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	166080e7          	jalr	358(ra) # 80002ff2 <bunpin>
    brelse(lbuf);
    80003e94:	854a                	mv	a0,s2
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	082080e7          	jalr	130(ra) # 80002f18 <brelse>
    brelse(dbuf);
    80003e9e:	8526                	mv	a0,s1
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	078080e7          	jalr	120(ra) # 80002f18 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea8:	2a05                	addiw	s4,s4,1
    80003eaa:	0a91                	addi	s5,s5,4
    80003eac:	02c9a783          	lw	a5,44(s3)
    80003eb0:	04fa5963          	bge	s4,a5,80003f02 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eb4:	0189a583          	lw	a1,24(s3)
    80003eb8:	014585bb          	addw	a1,a1,s4
    80003ebc:	2585                	addiw	a1,a1,1
    80003ebe:	0289a503          	lw	a0,40(s3)
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	f26080e7          	jalr	-218(ra) # 80002de8 <bread>
    80003eca:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ecc:	000aa583          	lw	a1,0(s5)
    80003ed0:	0289a503          	lw	a0,40(s3)
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	f14080e7          	jalr	-236(ra) # 80002de8 <bread>
    80003edc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ede:	40000613          	li	a2,1024
    80003ee2:	05890593          	addi	a1,s2,88
    80003ee6:	05850513          	addi	a0,a0,88
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	e56080e7          	jalr	-426(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ef2:	8526                	mv	a0,s1
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	fe6080e7          	jalr	-26(ra) # 80002eda <bwrite>
    if(recovering == 0)
    80003efc:	f80b1ce3          	bnez	s6,80003e94 <install_trans+0x40>
    80003f00:	b769                	j	80003e8a <install_trans+0x36>
}
    80003f02:	70e2                	ld	ra,56(sp)
    80003f04:	7442                	ld	s0,48(sp)
    80003f06:	74a2                	ld	s1,40(sp)
    80003f08:	7902                	ld	s2,32(sp)
    80003f0a:	69e2                	ld	s3,24(sp)
    80003f0c:	6a42                	ld	s4,16(sp)
    80003f0e:	6aa2                	ld	s5,8(sp)
    80003f10:	6b02                	ld	s6,0(sp)
    80003f12:	6121                	addi	sp,sp,64
    80003f14:	8082                	ret
    80003f16:	8082                	ret

0000000080003f18 <initlog>:
{
    80003f18:	7179                	addi	sp,sp,-48
    80003f1a:	f406                	sd	ra,40(sp)
    80003f1c:	f022                	sd	s0,32(sp)
    80003f1e:	ec26                	sd	s1,24(sp)
    80003f20:	e84a                	sd	s2,16(sp)
    80003f22:	e44e                	sd	s3,8(sp)
    80003f24:	1800                	addi	s0,sp,48
    80003f26:	892a                	mv	s2,a0
    80003f28:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f2a:	0001d497          	auipc	s1,0x1d
    80003f2e:	34648493          	addi	s1,s1,838 # 80021270 <log>
    80003f32:	00004597          	auipc	a1,0x4
    80003f36:	6fe58593          	addi	a1,a1,1790 # 80008630 <syscalls+0x1e8>
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	c18080e7          	jalr	-1000(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003f44:	0149a583          	lw	a1,20(s3)
    80003f48:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f4a:	0109a783          	lw	a5,16(s3)
    80003f4e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f50:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f54:	854a                	mv	a0,s2
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	e92080e7          	jalr	-366(ra) # 80002de8 <bread>
  log.lh.n = lh->n;
    80003f5e:	4d3c                	lw	a5,88(a0)
    80003f60:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f62:	02f05563          	blez	a5,80003f8c <initlog+0x74>
    80003f66:	05c50713          	addi	a4,a0,92
    80003f6a:	0001d697          	auipc	a3,0x1d
    80003f6e:	33668693          	addi	a3,a3,822 # 800212a0 <log+0x30>
    80003f72:	37fd                	addiw	a5,a5,-1
    80003f74:	1782                	slli	a5,a5,0x20
    80003f76:	9381                	srli	a5,a5,0x20
    80003f78:	078a                	slli	a5,a5,0x2
    80003f7a:	06050613          	addi	a2,a0,96
    80003f7e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003f80:	4310                	lw	a2,0(a4)
    80003f82:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003f84:	0711                	addi	a4,a4,4
    80003f86:	0691                	addi	a3,a3,4
    80003f88:	fef71ce3          	bne	a4,a5,80003f80 <initlog+0x68>
  brelse(buf);
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	f8c080e7          	jalr	-116(ra) # 80002f18 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f94:	4505                	li	a0,1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	ebe080e7          	jalr	-322(ra) # 80003e54 <install_trans>
  log.lh.n = 0;
    80003f9e:	0001d797          	auipc	a5,0x1d
    80003fa2:	2e07af23          	sw	zero,766(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	e34080e7          	jalr	-460(ra) # 80003dda <write_head>
}
    80003fae:	70a2                	ld	ra,40(sp)
    80003fb0:	7402                	ld	s0,32(sp)
    80003fb2:	64e2                	ld	s1,24(sp)
    80003fb4:	6942                	ld	s2,16(sp)
    80003fb6:	69a2                	ld	s3,8(sp)
    80003fb8:	6145                	addi	sp,sp,48
    80003fba:	8082                	ret

0000000080003fbc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fbc:	1101                	addi	sp,sp,-32
    80003fbe:	ec06                	sd	ra,24(sp)
    80003fc0:	e822                	sd	s0,16(sp)
    80003fc2:	e426                	sd	s1,8(sp)
    80003fc4:	e04a                	sd	s2,0(sp)
    80003fc6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fc8:	0001d517          	auipc	a0,0x1d
    80003fcc:	2a850513          	addi	a0,a0,680 # 80021270 <log>
    80003fd0:	ffffd097          	auipc	ra,0xffffd
    80003fd4:	c14080e7          	jalr	-1004(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80003fd8:	0001d497          	auipc	s1,0x1d
    80003fdc:	29848493          	addi	s1,s1,664 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fe0:	4979                	li	s2,30
    80003fe2:	a039                	j	80003ff0 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fe4:	85a6                	mv	a1,s1
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	ffffe097          	auipc	ra,0xffffe
    80003fec:	084080e7          	jalr	132(ra) # 8000206c <sleep>
    if(log.committing){
    80003ff0:	50dc                	lw	a5,36(s1)
    80003ff2:	fbed                	bnez	a5,80003fe4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ff4:	509c                	lw	a5,32(s1)
    80003ff6:	0017871b          	addiw	a4,a5,1
    80003ffa:	0007069b          	sext.w	a3,a4
    80003ffe:	0027179b          	slliw	a5,a4,0x2
    80004002:	9fb9                	addw	a5,a5,a4
    80004004:	0017979b          	slliw	a5,a5,0x1
    80004008:	54d8                	lw	a4,44(s1)
    8000400a:	9fb9                	addw	a5,a5,a4
    8000400c:	00f95963          	bge	s2,a5,8000401e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004010:	85a6                	mv	a1,s1
    80004012:	8526                	mv	a0,s1
    80004014:	ffffe097          	auipc	ra,0xffffe
    80004018:	058080e7          	jalr	88(ra) # 8000206c <sleep>
    8000401c:	bfd1                	j	80003ff0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000401e:	0001d517          	auipc	a0,0x1d
    80004022:	25250513          	addi	a0,a0,594 # 80021270 <log>
    80004026:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004028:	ffffd097          	auipc	ra,0xffffd
    8000402c:	c70080e7          	jalr	-912(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004030:	60e2                	ld	ra,24(sp)
    80004032:	6442                	ld	s0,16(sp)
    80004034:	64a2                	ld	s1,8(sp)
    80004036:	6902                	ld	s2,0(sp)
    80004038:	6105                	addi	sp,sp,32
    8000403a:	8082                	ret

000000008000403c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000403c:	7139                	addi	sp,sp,-64
    8000403e:	fc06                	sd	ra,56(sp)
    80004040:	f822                	sd	s0,48(sp)
    80004042:	f426                	sd	s1,40(sp)
    80004044:	f04a                	sd	s2,32(sp)
    80004046:	ec4e                	sd	s3,24(sp)
    80004048:	e852                	sd	s4,16(sp)
    8000404a:	e456                	sd	s5,8(sp)
    8000404c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000404e:	0001d497          	auipc	s1,0x1d
    80004052:	22248493          	addi	s1,s1,546 # 80021270 <log>
    80004056:	8526                	mv	a0,s1
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	b8c080e7          	jalr	-1140(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004060:	509c                	lw	a5,32(s1)
    80004062:	37fd                	addiw	a5,a5,-1
    80004064:	0007891b          	sext.w	s2,a5
    80004068:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000406a:	50dc                	lw	a5,36(s1)
    8000406c:	efb9                	bnez	a5,800040ca <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000406e:	06091663          	bnez	s2,800040da <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004072:	0001d497          	auipc	s1,0x1d
    80004076:	1fe48493          	addi	s1,s1,510 # 80021270 <log>
    8000407a:	4785                	li	a5,1
    8000407c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000407e:	8526                	mv	a0,s1
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	c18080e7          	jalr	-1000(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004088:	54dc                	lw	a5,44(s1)
    8000408a:	06f04763          	bgtz	a5,800040f8 <end_op+0xbc>
    acquire(&log.lock);
    8000408e:	0001d497          	auipc	s1,0x1d
    80004092:	1e248493          	addi	s1,s1,482 # 80021270 <log>
    80004096:	8526                	mv	a0,s1
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	b4c080e7          	jalr	-1204(ra) # 80000be4 <acquire>
    log.committing = 0;
    800040a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040a4:	8526                	mv	a0,s1
    800040a6:	ffffe097          	auipc	ra,0xffffe
    800040aa:	152080e7          	jalr	338(ra) # 800021f8 <wakeup>
    release(&log.lock);
    800040ae:	8526                	mv	a0,s1
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	be8080e7          	jalr	-1048(ra) # 80000c98 <release>
}
    800040b8:	70e2                	ld	ra,56(sp)
    800040ba:	7442                	ld	s0,48(sp)
    800040bc:	74a2                	ld	s1,40(sp)
    800040be:	7902                	ld	s2,32(sp)
    800040c0:	69e2                	ld	s3,24(sp)
    800040c2:	6a42                	ld	s4,16(sp)
    800040c4:	6aa2                	ld	s5,8(sp)
    800040c6:	6121                	addi	sp,sp,64
    800040c8:	8082                	ret
    panic("log.committing");
    800040ca:	00004517          	auipc	a0,0x4
    800040ce:	56e50513          	addi	a0,a0,1390 # 80008638 <syscalls+0x1f0>
    800040d2:	ffffc097          	auipc	ra,0xffffc
    800040d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>
    wakeup(&log);
    800040da:	0001d497          	auipc	s1,0x1d
    800040de:	19648493          	addi	s1,s1,406 # 80021270 <log>
    800040e2:	8526                	mv	a0,s1
    800040e4:	ffffe097          	auipc	ra,0xffffe
    800040e8:	114080e7          	jalr	276(ra) # 800021f8 <wakeup>
  release(&log.lock);
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	baa080e7          	jalr	-1110(ra) # 80000c98 <release>
  if(do_commit){
    800040f6:	b7c9                	j	800040b8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f8:	0001da97          	auipc	s5,0x1d
    800040fc:	1a8a8a93          	addi	s5,s5,424 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004100:	0001da17          	auipc	s4,0x1d
    80004104:	170a0a13          	addi	s4,s4,368 # 80021270 <log>
    80004108:	018a2583          	lw	a1,24(s4)
    8000410c:	012585bb          	addw	a1,a1,s2
    80004110:	2585                	addiw	a1,a1,1
    80004112:	028a2503          	lw	a0,40(s4)
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	cd2080e7          	jalr	-814(ra) # 80002de8 <bread>
    8000411e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004120:	000aa583          	lw	a1,0(s5)
    80004124:	028a2503          	lw	a0,40(s4)
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	cc0080e7          	jalr	-832(ra) # 80002de8 <bread>
    80004130:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004132:	40000613          	li	a2,1024
    80004136:	05850593          	addi	a1,a0,88
    8000413a:	05848513          	addi	a0,s1,88
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	c02080e7          	jalr	-1022(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	d92080e7          	jalr	-622(ra) # 80002eda <bwrite>
    brelse(from);
    80004150:	854e                	mv	a0,s3
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	dc6080e7          	jalr	-570(ra) # 80002f18 <brelse>
    brelse(to);
    8000415a:	8526                	mv	a0,s1
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	dbc080e7          	jalr	-580(ra) # 80002f18 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004164:	2905                	addiw	s2,s2,1
    80004166:	0a91                	addi	s5,s5,4
    80004168:	02ca2783          	lw	a5,44(s4)
    8000416c:	f8f94ee3          	blt	s2,a5,80004108 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004170:	00000097          	auipc	ra,0x0
    80004174:	c6a080e7          	jalr	-918(ra) # 80003dda <write_head>
    install_trans(0); // Now install writes to home locations
    80004178:	4501                	li	a0,0
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	cda080e7          	jalr	-806(ra) # 80003e54 <install_trans>
    log.lh.n = 0;
    80004182:	0001d797          	auipc	a5,0x1d
    80004186:	1007ad23          	sw	zero,282(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000418a:	00000097          	auipc	ra,0x0
    8000418e:	c50080e7          	jalr	-944(ra) # 80003dda <write_head>
    80004192:	bdf5                	j	8000408e <end_op+0x52>

0000000080004194 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004194:	1101                	addi	sp,sp,-32
    80004196:	ec06                	sd	ra,24(sp)
    80004198:	e822                	sd	s0,16(sp)
    8000419a:	e426                	sd	s1,8(sp)
    8000419c:	e04a                	sd	s2,0(sp)
    8000419e:	1000                	addi	s0,sp,32
    800041a0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041a2:	0001d917          	auipc	s2,0x1d
    800041a6:	0ce90913          	addi	s2,s2,206 # 80021270 <log>
    800041aa:	854a                	mv	a0,s2
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041b4:	02c92603          	lw	a2,44(s2)
    800041b8:	47f5                	li	a5,29
    800041ba:	06c7c563          	blt	a5,a2,80004224 <log_write+0x90>
    800041be:	0001d797          	auipc	a5,0x1d
    800041c2:	0ce7a783          	lw	a5,206(a5) # 8002128c <log+0x1c>
    800041c6:	37fd                	addiw	a5,a5,-1
    800041c8:	04f65e63          	bge	a2,a5,80004224 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041cc:	0001d797          	auipc	a5,0x1d
    800041d0:	0c47a783          	lw	a5,196(a5) # 80021290 <log+0x20>
    800041d4:	06f05063          	blez	a5,80004234 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041d8:	4781                	li	a5,0
    800041da:	06c05563          	blez	a2,80004244 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041de:	44cc                	lw	a1,12(s1)
    800041e0:	0001d717          	auipc	a4,0x1d
    800041e4:	0c070713          	addi	a4,a4,192 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041e8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041ea:	4314                	lw	a3,0(a4)
    800041ec:	04b68c63          	beq	a3,a1,80004244 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041f0:	2785                	addiw	a5,a5,1
    800041f2:	0711                	addi	a4,a4,4
    800041f4:	fef61be3          	bne	a2,a5,800041ea <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041f8:	0621                	addi	a2,a2,8
    800041fa:	060a                	slli	a2,a2,0x2
    800041fc:	0001d797          	auipc	a5,0x1d
    80004200:	07478793          	addi	a5,a5,116 # 80021270 <log>
    80004204:	963e                	add	a2,a2,a5
    80004206:	44dc                	lw	a5,12(s1)
    80004208:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	daa080e7          	jalr	-598(ra) # 80002fb6 <bpin>
    log.lh.n++;
    80004214:	0001d717          	auipc	a4,0x1d
    80004218:	05c70713          	addi	a4,a4,92 # 80021270 <log>
    8000421c:	575c                	lw	a5,44(a4)
    8000421e:	2785                	addiw	a5,a5,1
    80004220:	d75c                	sw	a5,44(a4)
    80004222:	a835                	j	8000425e <log_write+0xca>
    panic("too big a transaction");
    80004224:	00004517          	auipc	a0,0x4
    80004228:	42450513          	addi	a0,a0,1060 # 80008648 <syscalls+0x200>
    8000422c:	ffffc097          	auipc	ra,0xffffc
    80004230:	312080e7          	jalr	786(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004234:	00004517          	auipc	a0,0x4
    80004238:	42c50513          	addi	a0,a0,1068 # 80008660 <syscalls+0x218>
    8000423c:	ffffc097          	auipc	ra,0xffffc
    80004240:	302080e7          	jalr	770(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004244:	00878713          	addi	a4,a5,8
    80004248:	00271693          	slli	a3,a4,0x2
    8000424c:	0001d717          	auipc	a4,0x1d
    80004250:	02470713          	addi	a4,a4,36 # 80021270 <log>
    80004254:	9736                	add	a4,a4,a3
    80004256:	44d4                	lw	a3,12(s1)
    80004258:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000425a:	faf608e3          	beq	a2,a5,8000420a <log_write+0x76>
  }
  release(&log.lock);
    8000425e:	0001d517          	auipc	a0,0x1d
    80004262:	01250513          	addi	a0,a0,18 # 80021270 <log>
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
}
    8000426e:	60e2                	ld	ra,24(sp)
    80004270:	6442                	ld	s0,16(sp)
    80004272:	64a2                	ld	s1,8(sp)
    80004274:	6902                	ld	s2,0(sp)
    80004276:	6105                	addi	sp,sp,32
    80004278:	8082                	ret

000000008000427a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000427a:	1101                	addi	sp,sp,-32
    8000427c:	ec06                	sd	ra,24(sp)
    8000427e:	e822                	sd	s0,16(sp)
    80004280:	e426                	sd	s1,8(sp)
    80004282:	e04a                	sd	s2,0(sp)
    80004284:	1000                	addi	s0,sp,32
    80004286:	84aa                	mv	s1,a0
    80004288:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000428a:	00004597          	auipc	a1,0x4
    8000428e:	3f658593          	addi	a1,a1,1014 # 80008680 <syscalls+0x238>
    80004292:	0521                	addi	a0,a0,8
    80004294:	ffffd097          	auipc	ra,0xffffd
    80004298:	8c0080e7          	jalr	-1856(ra) # 80000b54 <initlock>
  lk->name = name;
    8000429c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042a4:	0204a423          	sw	zero,40(s1)
}
    800042a8:	60e2                	ld	ra,24(sp)
    800042aa:	6442                	ld	s0,16(sp)
    800042ac:	64a2                	ld	s1,8(sp)
    800042ae:	6902                	ld	s2,0(sp)
    800042b0:	6105                	addi	sp,sp,32
    800042b2:	8082                	ret

00000000800042b4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042b4:	1101                	addi	sp,sp,-32
    800042b6:	ec06                	sd	ra,24(sp)
    800042b8:	e822                	sd	s0,16(sp)
    800042ba:	e426                	sd	s1,8(sp)
    800042bc:	e04a                	sd	s2,0(sp)
    800042be:	1000                	addi	s0,sp,32
    800042c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042c2:	00850913          	addi	s2,a0,8
    800042c6:	854a                	mv	a0,s2
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	91c080e7          	jalr	-1764(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800042d0:	409c                	lw	a5,0(s1)
    800042d2:	cb89                	beqz	a5,800042e4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042d4:	85ca                	mv	a1,s2
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffe097          	auipc	ra,0xffffe
    800042dc:	d94080e7          	jalr	-620(ra) # 8000206c <sleep>
  while (lk->locked) {
    800042e0:	409c                	lw	a5,0(s1)
    800042e2:	fbed                	bnez	a5,800042d4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042e4:	4785                	li	a5,1
    800042e6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	6c8080e7          	jalr	1736(ra) # 800019b0 <myproc>
    800042f0:	591c                	lw	a5,48(a0)
    800042f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042f4:	854a                	mv	a0,s2
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	9a2080e7          	jalr	-1630(ra) # 80000c98 <release>
}
    800042fe:	60e2                	ld	ra,24(sp)
    80004300:	6442                	ld	s0,16(sp)
    80004302:	64a2                	ld	s1,8(sp)
    80004304:	6902                	ld	s2,0(sp)
    80004306:	6105                	addi	sp,sp,32
    80004308:	8082                	ret

000000008000430a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	e04a                	sd	s2,0(sp)
    80004314:	1000                	addi	s0,sp,32
    80004316:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004318:	00850913          	addi	s2,a0,8
    8000431c:	854a                	mv	a0,s2
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	8c6080e7          	jalr	-1850(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004326:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000432a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000432e:	8526                	mv	a0,s1
    80004330:	ffffe097          	auipc	ra,0xffffe
    80004334:	ec8080e7          	jalr	-312(ra) # 800021f8 <wakeup>
  release(&lk->lk);
    80004338:	854a                	mv	a0,s2
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	95e080e7          	jalr	-1698(ra) # 80000c98 <release>
}
    80004342:	60e2                	ld	ra,24(sp)
    80004344:	6442                	ld	s0,16(sp)
    80004346:	64a2                	ld	s1,8(sp)
    80004348:	6902                	ld	s2,0(sp)
    8000434a:	6105                	addi	sp,sp,32
    8000434c:	8082                	ret

000000008000434e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000434e:	7179                	addi	sp,sp,-48
    80004350:	f406                	sd	ra,40(sp)
    80004352:	f022                	sd	s0,32(sp)
    80004354:	ec26                	sd	s1,24(sp)
    80004356:	e84a                	sd	s2,16(sp)
    80004358:	e44e                	sd	s3,8(sp)
    8000435a:	1800                	addi	s0,sp,48
    8000435c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000435e:	00850913          	addi	s2,a0,8
    80004362:	854a                	mv	a0,s2
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	880080e7          	jalr	-1920(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000436c:	409c                	lw	a5,0(s1)
    8000436e:	ef99                	bnez	a5,8000438c <holdingsleep+0x3e>
    80004370:	4481                	li	s1,0
  release(&lk->lk);
    80004372:	854a                	mv	a0,s2
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
  return r;
}
    8000437c:	8526                	mv	a0,s1
    8000437e:	70a2                	ld	ra,40(sp)
    80004380:	7402                	ld	s0,32(sp)
    80004382:	64e2                	ld	s1,24(sp)
    80004384:	6942                	ld	s2,16(sp)
    80004386:	69a2                	ld	s3,8(sp)
    80004388:	6145                	addi	sp,sp,48
    8000438a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000438c:	0284a983          	lw	s3,40(s1)
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	620080e7          	jalr	1568(ra) # 800019b0 <myproc>
    80004398:	5904                	lw	s1,48(a0)
    8000439a:	413484b3          	sub	s1,s1,s3
    8000439e:	0014b493          	seqz	s1,s1
    800043a2:	bfc1                	j	80004372 <holdingsleep+0x24>

00000000800043a4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043a4:	1141                	addi	sp,sp,-16
    800043a6:	e406                	sd	ra,8(sp)
    800043a8:	e022                	sd	s0,0(sp)
    800043aa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043ac:	00004597          	auipc	a1,0x4
    800043b0:	2e458593          	addi	a1,a1,740 # 80008690 <syscalls+0x248>
    800043b4:	0001d517          	auipc	a0,0x1d
    800043b8:	00450513          	addi	a0,a0,4 # 800213b8 <ftable>
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	798080e7          	jalr	1944(ra) # 80000b54 <initlock>
}
    800043c4:	60a2                	ld	ra,8(sp)
    800043c6:	6402                	ld	s0,0(sp)
    800043c8:	0141                	addi	sp,sp,16
    800043ca:	8082                	ret

00000000800043cc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043d6:	0001d517          	auipc	a0,0x1d
    800043da:	fe250513          	addi	a0,a0,-30 # 800213b8 <ftable>
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043e6:	0001d497          	auipc	s1,0x1d
    800043ea:	fea48493          	addi	s1,s1,-22 # 800213d0 <ftable+0x18>
    800043ee:	0001e717          	auipc	a4,0x1e
    800043f2:	f8270713          	addi	a4,a4,-126 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800043f6:	40dc                	lw	a5,4(s1)
    800043f8:	cf99                	beqz	a5,80004416 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043fa:	02848493          	addi	s1,s1,40
    800043fe:	fee49ce3          	bne	s1,a4,800043f6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004402:	0001d517          	auipc	a0,0x1d
    80004406:	fb650513          	addi	a0,a0,-74 # 800213b8 <ftable>
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	88e080e7          	jalr	-1906(ra) # 80000c98 <release>
  return 0;
    80004412:	4481                	li	s1,0
    80004414:	a819                	j	8000442a <filealloc+0x5e>
      f->ref = 1;
    80004416:	4785                	li	a5,1
    80004418:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000441a:	0001d517          	auipc	a0,0x1d
    8000441e:	f9e50513          	addi	a0,a0,-98 # 800213b8 <ftable>
    80004422:	ffffd097          	auipc	ra,0xffffd
    80004426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
}
    8000442a:	8526                	mv	a0,s1
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6105                	addi	sp,sp,32
    80004434:	8082                	ret

0000000080004436 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004436:	1101                	addi	sp,sp,-32
    80004438:	ec06                	sd	ra,24(sp)
    8000443a:	e822                	sd	s0,16(sp)
    8000443c:	e426                	sd	s1,8(sp)
    8000443e:	1000                	addi	s0,sp,32
    80004440:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004442:	0001d517          	auipc	a0,0x1d
    80004446:	f7650513          	addi	a0,a0,-138 # 800213b8 <ftable>
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	79a080e7          	jalr	1946(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004452:	40dc                	lw	a5,4(s1)
    80004454:	02f05263          	blez	a5,80004478 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004458:	2785                	addiw	a5,a5,1
    8000445a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000445c:	0001d517          	auipc	a0,0x1d
    80004460:	f5c50513          	addi	a0,a0,-164 # 800213b8 <ftable>
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	834080e7          	jalr	-1996(ra) # 80000c98 <release>
  return f;
}
    8000446c:	8526                	mv	a0,s1
    8000446e:	60e2                	ld	ra,24(sp)
    80004470:	6442                	ld	s0,16(sp)
    80004472:	64a2                	ld	s1,8(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret
    panic("filedup");
    80004478:	00004517          	auipc	a0,0x4
    8000447c:	22050513          	addi	a0,a0,544 # 80008698 <syscalls+0x250>
    80004480:	ffffc097          	auipc	ra,0xffffc
    80004484:	0be080e7          	jalr	190(ra) # 8000053e <panic>

0000000080004488 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004488:	7139                	addi	sp,sp,-64
    8000448a:	fc06                	sd	ra,56(sp)
    8000448c:	f822                	sd	s0,48(sp)
    8000448e:	f426                	sd	s1,40(sp)
    80004490:	f04a                	sd	s2,32(sp)
    80004492:	ec4e                	sd	s3,24(sp)
    80004494:	e852                	sd	s4,16(sp)
    80004496:	e456                	sd	s5,8(sp)
    80004498:	0080                	addi	s0,sp,64
    8000449a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000449c:	0001d517          	auipc	a0,0x1d
    800044a0:	f1c50513          	addi	a0,a0,-228 # 800213b8 <ftable>
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	740080e7          	jalr	1856(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800044ac:	40dc                	lw	a5,4(s1)
    800044ae:	06f05163          	blez	a5,80004510 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044b2:	37fd                	addiw	a5,a5,-1
    800044b4:	0007871b          	sext.w	a4,a5
    800044b8:	c0dc                	sw	a5,4(s1)
    800044ba:	06e04363          	bgtz	a4,80004520 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044be:	0004a903          	lw	s2,0(s1)
    800044c2:	0094ca83          	lbu	s5,9(s1)
    800044c6:	0104ba03          	ld	s4,16(s1)
    800044ca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044ce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044d2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044d6:	0001d517          	auipc	a0,0x1d
    800044da:	ee250513          	addi	a0,a0,-286 # 800213b8 <ftable>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800044e6:	4785                	li	a5,1
    800044e8:	04f90d63          	beq	s2,a5,80004542 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044ec:	3979                	addiw	s2,s2,-2
    800044ee:	4785                	li	a5,1
    800044f0:	0527e063          	bltu	a5,s2,80004530 <fileclose+0xa8>
    begin_op();
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	ac8080e7          	jalr	-1336(ra) # 80003fbc <begin_op>
    iput(ff.ip);
    800044fc:	854e                	mv	a0,s3
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	2a6080e7          	jalr	678(ra) # 800037a4 <iput>
    end_op();
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	b36080e7          	jalr	-1226(ra) # 8000403c <end_op>
    8000450e:	a00d                	j	80004530 <fileclose+0xa8>
    panic("fileclose");
    80004510:	00004517          	auipc	a0,0x4
    80004514:	19050513          	addi	a0,a0,400 # 800086a0 <syscalls+0x258>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	026080e7          	jalr	38(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004520:	0001d517          	auipc	a0,0x1d
    80004524:	e9850513          	addi	a0,a0,-360 # 800213b8 <ftable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	770080e7          	jalr	1904(ra) # 80000c98 <release>
  }
}
    80004530:	70e2                	ld	ra,56(sp)
    80004532:	7442                	ld	s0,48(sp)
    80004534:	74a2                	ld	s1,40(sp)
    80004536:	7902                	ld	s2,32(sp)
    80004538:	69e2                	ld	s3,24(sp)
    8000453a:	6a42                	ld	s4,16(sp)
    8000453c:	6aa2                	ld	s5,8(sp)
    8000453e:	6121                	addi	sp,sp,64
    80004540:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004542:	85d6                	mv	a1,s5
    80004544:	8552                	mv	a0,s4
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	34c080e7          	jalr	844(ra) # 80004892 <pipeclose>
    8000454e:	b7cd                	j	80004530 <fileclose+0xa8>

0000000080004550 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004550:	715d                	addi	sp,sp,-80
    80004552:	e486                	sd	ra,72(sp)
    80004554:	e0a2                	sd	s0,64(sp)
    80004556:	fc26                	sd	s1,56(sp)
    80004558:	f84a                	sd	s2,48(sp)
    8000455a:	f44e                	sd	s3,40(sp)
    8000455c:	0880                	addi	s0,sp,80
    8000455e:	84aa                	mv	s1,a0
    80004560:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004562:	ffffd097          	auipc	ra,0xffffd
    80004566:	44e080e7          	jalr	1102(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000456a:	409c                	lw	a5,0(s1)
    8000456c:	37f9                	addiw	a5,a5,-2
    8000456e:	4705                	li	a4,1
    80004570:	04f76763          	bltu	a4,a5,800045be <filestat+0x6e>
    80004574:	892a                	mv	s2,a0
    ilock(f->ip);
    80004576:	6c88                	ld	a0,24(s1)
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	072080e7          	jalr	114(ra) # 800035ea <ilock>
    stati(f->ip, &st);
    80004580:	fb840593          	addi	a1,s0,-72
    80004584:	6c88                	ld	a0,24(s1)
    80004586:	fffff097          	auipc	ra,0xfffff
    8000458a:	2ee080e7          	jalr	750(ra) # 80003874 <stati>
    iunlock(f->ip);
    8000458e:	6c88                	ld	a0,24(s1)
    80004590:	fffff097          	auipc	ra,0xfffff
    80004594:	11c080e7          	jalr	284(ra) # 800036ac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004598:	46e1                	li	a3,24
    8000459a:	fb840613          	addi	a2,s0,-72
    8000459e:	85ce                	mv	a1,s3
    800045a0:	05093503          	ld	a0,80(s2)
    800045a4:	ffffd097          	auipc	ra,0xffffd
    800045a8:	0ce080e7          	jalr	206(ra) # 80001672 <copyout>
    800045ac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045b0:	60a6                	ld	ra,72(sp)
    800045b2:	6406                	ld	s0,64(sp)
    800045b4:	74e2                	ld	s1,56(sp)
    800045b6:	7942                	ld	s2,48(sp)
    800045b8:	79a2                	ld	s3,40(sp)
    800045ba:	6161                	addi	sp,sp,80
    800045bc:	8082                	ret
  return -1;
    800045be:	557d                	li	a0,-1
    800045c0:	bfc5                	j	800045b0 <filestat+0x60>

00000000800045c2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045c2:	7179                	addi	sp,sp,-48
    800045c4:	f406                	sd	ra,40(sp)
    800045c6:	f022                	sd	s0,32(sp)
    800045c8:	ec26                	sd	s1,24(sp)
    800045ca:	e84a                	sd	s2,16(sp)
    800045cc:	e44e                	sd	s3,8(sp)
    800045ce:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045d0:	00854783          	lbu	a5,8(a0)
    800045d4:	c3d5                	beqz	a5,80004678 <fileread+0xb6>
    800045d6:	84aa                	mv	s1,a0
    800045d8:	89ae                	mv	s3,a1
    800045da:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045dc:	411c                	lw	a5,0(a0)
    800045de:	4705                	li	a4,1
    800045e0:	04e78963          	beq	a5,a4,80004632 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045e4:	470d                	li	a4,3
    800045e6:	04e78d63          	beq	a5,a4,80004640 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045ea:	4709                	li	a4,2
    800045ec:	06e79e63          	bne	a5,a4,80004668 <fileread+0xa6>
    ilock(f->ip);
    800045f0:	6d08                	ld	a0,24(a0)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	ff8080e7          	jalr	-8(ra) # 800035ea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045fa:	874a                	mv	a4,s2
    800045fc:	5094                	lw	a3,32(s1)
    800045fe:	864e                	mv	a2,s3
    80004600:	4585                	li	a1,1
    80004602:	6c88                	ld	a0,24(s1)
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	29a080e7          	jalr	666(ra) # 8000389e <readi>
    8000460c:	892a                	mv	s2,a0
    8000460e:	00a05563          	blez	a0,80004618 <fileread+0x56>
      f->off += r;
    80004612:	509c                	lw	a5,32(s1)
    80004614:	9fa9                	addw	a5,a5,a0
    80004616:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004618:	6c88                	ld	a0,24(s1)
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	092080e7          	jalr	146(ra) # 800036ac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004622:	854a                	mv	a0,s2
    80004624:	70a2                	ld	ra,40(sp)
    80004626:	7402                	ld	s0,32(sp)
    80004628:	64e2                	ld	s1,24(sp)
    8000462a:	6942                	ld	s2,16(sp)
    8000462c:	69a2                	ld	s3,8(sp)
    8000462e:	6145                	addi	sp,sp,48
    80004630:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004632:	6908                	ld	a0,16(a0)
    80004634:	00000097          	auipc	ra,0x0
    80004638:	3c8080e7          	jalr	968(ra) # 800049fc <piperead>
    8000463c:	892a                	mv	s2,a0
    8000463e:	b7d5                	j	80004622 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004640:	02451783          	lh	a5,36(a0)
    80004644:	03079693          	slli	a3,a5,0x30
    80004648:	92c1                	srli	a3,a3,0x30
    8000464a:	4725                	li	a4,9
    8000464c:	02d76863          	bltu	a4,a3,8000467c <fileread+0xba>
    80004650:	0792                	slli	a5,a5,0x4
    80004652:	0001d717          	auipc	a4,0x1d
    80004656:	cc670713          	addi	a4,a4,-826 # 80021318 <devsw>
    8000465a:	97ba                	add	a5,a5,a4
    8000465c:	639c                	ld	a5,0(a5)
    8000465e:	c38d                	beqz	a5,80004680 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004660:	4505                	li	a0,1
    80004662:	9782                	jalr	a5
    80004664:	892a                	mv	s2,a0
    80004666:	bf75                	j	80004622 <fileread+0x60>
    panic("fileread");
    80004668:	00004517          	auipc	a0,0x4
    8000466c:	04850513          	addi	a0,a0,72 # 800086b0 <syscalls+0x268>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>
    return -1;
    80004678:	597d                	li	s2,-1
    8000467a:	b765                	j	80004622 <fileread+0x60>
      return -1;
    8000467c:	597d                	li	s2,-1
    8000467e:	b755                	j	80004622 <fileread+0x60>
    80004680:	597d                	li	s2,-1
    80004682:	b745                	j	80004622 <fileread+0x60>

0000000080004684 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004684:	715d                	addi	sp,sp,-80
    80004686:	e486                	sd	ra,72(sp)
    80004688:	e0a2                	sd	s0,64(sp)
    8000468a:	fc26                	sd	s1,56(sp)
    8000468c:	f84a                	sd	s2,48(sp)
    8000468e:	f44e                	sd	s3,40(sp)
    80004690:	f052                	sd	s4,32(sp)
    80004692:	ec56                	sd	s5,24(sp)
    80004694:	e85a                	sd	s6,16(sp)
    80004696:	e45e                	sd	s7,8(sp)
    80004698:	e062                	sd	s8,0(sp)
    8000469a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000469c:	00954783          	lbu	a5,9(a0)
    800046a0:	10078663          	beqz	a5,800047ac <filewrite+0x128>
    800046a4:	892a                	mv	s2,a0
    800046a6:	8aae                	mv	s5,a1
    800046a8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046aa:	411c                	lw	a5,0(a0)
    800046ac:	4705                	li	a4,1
    800046ae:	02e78263          	beq	a5,a4,800046d2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b2:	470d                	li	a4,3
    800046b4:	02e78663          	beq	a5,a4,800046e0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046b8:	4709                	li	a4,2
    800046ba:	0ee79163          	bne	a5,a4,8000479c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046be:	0ac05d63          	blez	a2,80004778 <filewrite+0xf4>
    int i = 0;
    800046c2:	4981                	li	s3,0
    800046c4:	6b05                	lui	s6,0x1
    800046c6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046ca:	6b85                	lui	s7,0x1
    800046cc:	c00b8b9b          	addiw	s7,s7,-1024
    800046d0:	a861                	j	80004768 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046d2:	6908                	ld	a0,16(a0)
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	22e080e7          	jalr	558(ra) # 80004902 <pipewrite>
    800046dc:	8a2a                	mv	s4,a0
    800046de:	a045                	j	8000477e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046e0:	02451783          	lh	a5,36(a0)
    800046e4:	03079693          	slli	a3,a5,0x30
    800046e8:	92c1                	srli	a3,a3,0x30
    800046ea:	4725                	li	a4,9
    800046ec:	0cd76263          	bltu	a4,a3,800047b0 <filewrite+0x12c>
    800046f0:	0792                	slli	a5,a5,0x4
    800046f2:	0001d717          	auipc	a4,0x1d
    800046f6:	c2670713          	addi	a4,a4,-986 # 80021318 <devsw>
    800046fa:	97ba                	add	a5,a5,a4
    800046fc:	679c                	ld	a5,8(a5)
    800046fe:	cbdd                	beqz	a5,800047b4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004700:	4505                	li	a0,1
    80004702:	9782                	jalr	a5
    80004704:	8a2a                	mv	s4,a0
    80004706:	a8a5                	j	8000477e <filewrite+0xfa>
    80004708:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	8b0080e7          	jalr	-1872(ra) # 80003fbc <begin_op>
      ilock(f->ip);
    80004714:	01893503          	ld	a0,24(s2)
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	ed2080e7          	jalr	-302(ra) # 800035ea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004720:	8762                	mv	a4,s8
    80004722:	02092683          	lw	a3,32(s2)
    80004726:	01598633          	add	a2,s3,s5
    8000472a:	4585                	li	a1,1
    8000472c:	01893503          	ld	a0,24(s2)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	266080e7          	jalr	614(ra) # 80003996 <writei>
    80004738:	84aa                	mv	s1,a0
    8000473a:	00a05763          	blez	a0,80004748 <filewrite+0xc4>
        f->off += r;
    8000473e:	02092783          	lw	a5,32(s2)
    80004742:	9fa9                	addw	a5,a5,a0
    80004744:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004748:	01893503          	ld	a0,24(s2)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	f60080e7          	jalr	-160(ra) # 800036ac <iunlock>
      end_op();
    80004754:	00000097          	auipc	ra,0x0
    80004758:	8e8080e7          	jalr	-1816(ra) # 8000403c <end_op>

      if(r != n1){
    8000475c:	009c1f63          	bne	s8,s1,8000477a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004760:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004764:	0149db63          	bge	s3,s4,8000477a <filewrite+0xf6>
      int n1 = n - i;
    80004768:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000476c:	84be                	mv	s1,a5
    8000476e:	2781                	sext.w	a5,a5
    80004770:	f8fb5ce3          	bge	s6,a5,80004708 <filewrite+0x84>
    80004774:	84de                	mv	s1,s7
    80004776:	bf49                	j	80004708 <filewrite+0x84>
    int i = 0;
    80004778:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000477a:	013a1f63          	bne	s4,s3,80004798 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000477e:	8552                	mv	a0,s4
    80004780:	60a6                	ld	ra,72(sp)
    80004782:	6406                	ld	s0,64(sp)
    80004784:	74e2                	ld	s1,56(sp)
    80004786:	7942                	ld	s2,48(sp)
    80004788:	79a2                	ld	s3,40(sp)
    8000478a:	7a02                	ld	s4,32(sp)
    8000478c:	6ae2                	ld	s5,24(sp)
    8000478e:	6b42                	ld	s6,16(sp)
    80004790:	6ba2                	ld	s7,8(sp)
    80004792:	6c02                	ld	s8,0(sp)
    80004794:	6161                	addi	sp,sp,80
    80004796:	8082                	ret
    ret = (i == n ? n : -1);
    80004798:	5a7d                	li	s4,-1
    8000479a:	b7d5                	j	8000477e <filewrite+0xfa>
    panic("filewrite");
    8000479c:	00004517          	auipc	a0,0x4
    800047a0:	f2450513          	addi	a0,a0,-220 # 800086c0 <syscalls+0x278>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	d9a080e7          	jalr	-614(ra) # 8000053e <panic>
    return -1;
    800047ac:	5a7d                	li	s4,-1
    800047ae:	bfc1                	j	8000477e <filewrite+0xfa>
      return -1;
    800047b0:	5a7d                	li	s4,-1
    800047b2:	b7f1                	j	8000477e <filewrite+0xfa>
    800047b4:	5a7d                	li	s4,-1
    800047b6:	b7e1                	j	8000477e <filewrite+0xfa>

00000000800047b8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047b8:	7179                	addi	sp,sp,-48
    800047ba:	f406                	sd	ra,40(sp)
    800047bc:	f022                	sd	s0,32(sp)
    800047be:	ec26                	sd	s1,24(sp)
    800047c0:	e84a                	sd	s2,16(sp)
    800047c2:	e44e                	sd	s3,8(sp)
    800047c4:	e052                	sd	s4,0(sp)
    800047c6:	1800                	addi	s0,sp,48
    800047c8:	84aa                	mv	s1,a0
    800047ca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047cc:	0005b023          	sd	zero,0(a1)
    800047d0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	bf8080e7          	jalr	-1032(ra) # 800043cc <filealloc>
    800047dc:	e088                	sd	a0,0(s1)
    800047de:	c551                	beqz	a0,8000486a <pipealloc+0xb2>
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	bec080e7          	jalr	-1044(ra) # 800043cc <filealloc>
    800047e8:	00aa3023          	sd	a0,0(s4)
    800047ec:	c92d                	beqz	a0,8000485e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	306080e7          	jalr	774(ra) # 80000af4 <kalloc>
    800047f6:	892a                	mv	s2,a0
    800047f8:	c125                	beqz	a0,80004858 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047fa:	4985                	li	s3,1
    800047fc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004800:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004804:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004808:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000480c:	00004597          	auipc	a1,0x4
    80004810:	ec458593          	addi	a1,a1,-316 # 800086d0 <syscalls+0x288>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	340080e7          	jalr	832(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000481c:	609c                	ld	a5,0(s1)
    8000481e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004822:	609c                	ld	a5,0(s1)
    80004824:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004828:	609c                	ld	a5,0(s1)
    8000482a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000482e:	609c                	ld	a5,0(s1)
    80004830:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004834:	000a3783          	ld	a5,0(s4)
    80004838:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000483c:	000a3783          	ld	a5,0(s4)
    80004840:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004844:	000a3783          	ld	a5,0(s4)
    80004848:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000484c:	000a3783          	ld	a5,0(s4)
    80004850:	0127b823          	sd	s2,16(a5)
  return 0;
    80004854:	4501                	li	a0,0
    80004856:	a025                	j	8000487e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004858:	6088                	ld	a0,0(s1)
    8000485a:	e501                	bnez	a0,80004862 <pipealloc+0xaa>
    8000485c:	a039                	j	8000486a <pipealloc+0xb2>
    8000485e:	6088                	ld	a0,0(s1)
    80004860:	c51d                	beqz	a0,8000488e <pipealloc+0xd6>
    fileclose(*f0);
    80004862:	00000097          	auipc	ra,0x0
    80004866:	c26080e7          	jalr	-986(ra) # 80004488 <fileclose>
  if(*f1)
    8000486a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000486e:	557d                	li	a0,-1
  if(*f1)
    80004870:	c799                	beqz	a5,8000487e <pipealloc+0xc6>
    fileclose(*f1);
    80004872:	853e                	mv	a0,a5
    80004874:	00000097          	auipc	ra,0x0
    80004878:	c14080e7          	jalr	-1004(ra) # 80004488 <fileclose>
  return -1;
    8000487c:	557d                	li	a0,-1
}
    8000487e:	70a2                	ld	ra,40(sp)
    80004880:	7402                	ld	s0,32(sp)
    80004882:	64e2                	ld	s1,24(sp)
    80004884:	6942                	ld	s2,16(sp)
    80004886:	69a2                	ld	s3,8(sp)
    80004888:	6a02                	ld	s4,0(sp)
    8000488a:	6145                	addi	sp,sp,48
    8000488c:	8082                	ret
  return -1;
    8000488e:	557d                	li	a0,-1
    80004890:	b7fd                	j	8000487e <pipealloc+0xc6>

0000000080004892 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004892:	1101                	addi	sp,sp,-32
    80004894:	ec06                	sd	ra,24(sp)
    80004896:	e822                	sd	s0,16(sp)
    80004898:	e426                	sd	s1,8(sp)
    8000489a:	e04a                	sd	s2,0(sp)
    8000489c:	1000                	addi	s0,sp,32
    8000489e:	84aa                	mv	s1,a0
    800048a0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	342080e7          	jalr	834(ra) # 80000be4 <acquire>
  if(writable){
    800048aa:	02090d63          	beqz	s2,800048e4 <pipeclose+0x52>
    pi->writeopen = 0;
    800048ae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048b2:	21848513          	addi	a0,s1,536
    800048b6:	ffffe097          	auipc	ra,0xffffe
    800048ba:	942080e7          	jalr	-1726(ra) # 800021f8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048be:	2204b783          	ld	a5,544(s1)
    800048c2:	eb95                	bnez	a5,800048f6 <pipeclose+0x64>
    release(&pi->lock);
    800048c4:	8526                	mv	a0,s1
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	3d2080e7          	jalr	978(ra) # 80000c98 <release>
    kfree((char*)pi);
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	128080e7          	jalr	296(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800048d8:	60e2                	ld	ra,24(sp)
    800048da:	6442                	ld	s0,16(sp)
    800048dc:	64a2                	ld	s1,8(sp)
    800048de:	6902                	ld	s2,0(sp)
    800048e0:	6105                	addi	sp,sp,32
    800048e2:	8082                	ret
    pi->readopen = 0;
    800048e4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048e8:	21c48513          	addi	a0,s1,540
    800048ec:	ffffe097          	auipc	ra,0xffffe
    800048f0:	90c080e7          	jalr	-1780(ra) # 800021f8 <wakeup>
    800048f4:	b7e9                	j	800048be <pipeclose+0x2c>
    release(&pi->lock);
    800048f6:	8526                	mv	a0,s1
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	3a0080e7          	jalr	928(ra) # 80000c98 <release>
}
    80004900:	bfe1                	j	800048d8 <pipeclose+0x46>

0000000080004902 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004902:	7159                	addi	sp,sp,-112
    80004904:	f486                	sd	ra,104(sp)
    80004906:	f0a2                	sd	s0,96(sp)
    80004908:	eca6                	sd	s1,88(sp)
    8000490a:	e8ca                	sd	s2,80(sp)
    8000490c:	e4ce                	sd	s3,72(sp)
    8000490e:	e0d2                	sd	s4,64(sp)
    80004910:	fc56                	sd	s5,56(sp)
    80004912:	f85a                	sd	s6,48(sp)
    80004914:	f45e                	sd	s7,40(sp)
    80004916:	f062                	sd	s8,32(sp)
    80004918:	ec66                	sd	s9,24(sp)
    8000491a:	1880                	addi	s0,sp,112
    8000491c:	84aa                	mv	s1,a0
    8000491e:	8aae                	mv	s5,a1
    80004920:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004922:	ffffd097          	auipc	ra,0xffffd
    80004926:	08e080e7          	jalr	142(ra) # 800019b0 <myproc>
    8000492a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	2b6080e7          	jalr	694(ra) # 80000be4 <acquire>
  while(i < n){
    80004936:	0d405163          	blez	s4,800049f8 <pipewrite+0xf6>
    8000493a:	8ba6                	mv	s7,s1
  int i = 0;
    8000493c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000493e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004940:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004944:	21c48c13          	addi	s8,s1,540
    80004948:	a08d                	j	800049aa <pipewrite+0xa8>
      release(&pi->lock);
    8000494a:	8526                	mv	a0,s1
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	34c080e7          	jalr	844(ra) # 80000c98 <release>
      return -1;
    80004954:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004956:	854a                	mv	a0,s2
    80004958:	70a6                	ld	ra,104(sp)
    8000495a:	7406                	ld	s0,96(sp)
    8000495c:	64e6                	ld	s1,88(sp)
    8000495e:	6946                	ld	s2,80(sp)
    80004960:	69a6                	ld	s3,72(sp)
    80004962:	6a06                	ld	s4,64(sp)
    80004964:	7ae2                	ld	s5,56(sp)
    80004966:	7b42                	ld	s6,48(sp)
    80004968:	7ba2                	ld	s7,40(sp)
    8000496a:	7c02                	ld	s8,32(sp)
    8000496c:	6ce2                	ld	s9,24(sp)
    8000496e:	6165                	addi	sp,sp,112
    80004970:	8082                	ret
      wakeup(&pi->nread);
    80004972:	8566                	mv	a0,s9
    80004974:	ffffe097          	auipc	ra,0xffffe
    80004978:	884080e7          	jalr	-1916(ra) # 800021f8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000497c:	85de                	mv	a1,s7
    8000497e:	8562                	mv	a0,s8
    80004980:	ffffd097          	auipc	ra,0xffffd
    80004984:	6ec080e7          	jalr	1772(ra) # 8000206c <sleep>
    80004988:	a839                	j	800049a6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000498a:	21c4a783          	lw	a5,540(s1)
    8000498e:	0017871b          	addiw	a4,a5,1
    80004992:	20e4ae23          	sw	a4,540(s1)
    80004996:	1ff7f793          	andi	a5,a5,511
    8000499a:	97a6                	add	a5,a5,s1
    8000499c:	f9f44703          	lbu	a4,-97(s0)
    800049a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800049a4:	2905                	addiw	s2,s2,1
  while(i < n){
    800049a6:	03495d63          	bge	s2,s4,800049e0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800049aa:	2204a783          	lw	a5,544(s1)
    800049ae:	dfd1                	beqz	a5,8000494a <pipewrite+0x48>
    800049b0:	0289a783          	lw	a5,40(s3)
    800049b4:	fbd9                	bnez	a5,8000494a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049b6:	2184a783          	lw	a5,536(s1)
    800049ba:	21c4a703          	lw	a4,540(s1)
    800049be:	2007879b          	addiw	a5,a5,512
    800049c2:	faf708e3          	beq	a4,a5,80004972 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049c6:	4685                	li	a3,1
    800049c8:	01590633          	add	a2,s2,s5
    800049cc:	f9f40593          	addi	a1,s0,-97
    800049d0:	0509b503          	ld	a0,80(s3)
    800049d4:	ffffd097          	auipc	ra,0xffffd
    800049d8:	d2a080e7          	jalr	-726(ra) # 800016fe <copyin>
    800049dc:	fb6517e3          	bne	a0,s6,8000498a <pipewrite+0x88>
  wakeup(&pi->nread);
    800049e0:	21848513          	addi	a0,s1,536
    800049e4:	ffffe097          	auipc	ra,0xffffe
    800049e8:	814080e7          	jalr	-2028(ra) # 800021f8 <wakeup>
  release(&pi->lock);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
  return i;
    800049f6:	b785                	j	80004956 <pipewrite+0x54>
  int i = 0;
    800049f8:	4901                	li	s2,0
    800049fa:	b7dd                	j	800049e0 <pipewrite+0xde>

00000000800049fc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049fc:	715d                	addi	sp,sp,-80
    800049fe:	e486                	sd	ra,72(sp)
    80004a00:	e0a2                	sd	s0,64(sp)
    80004a02:	fc26                	sd	s1,56(sp)
    80004a04:	f84a                	sd	s2,48(sp)
    80004a06:	f44e                	sd	s3,40(sp)
    80004a08:	f052                	sd	s4,32(sp)
    80004a0a:	ec56                	sd	s5,24(sp)
    80004a0c:	e85a                	sd	s6,16(sp)
    80004a0e:	0880                	addi	s0,sp,80
    80004a10:	84aa                	mv	s1,a0
    80004a12:	892e                	mv	s2,a1
    80004a14:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a16:	ffffd097          	auipc	ra,0xffffd
    80004a1a:	f9a080e7          	jalr	-102(ra) # 800019b0 <myproc>
    80004a1e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a20:	8b26                	mv	s6,s1
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	1c0080e7          	jalr	448(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a2c:	2184a703          	lw	a4,536(s1)
    80004a30:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a34:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a38:	02f71463          	bne	a4,a5,80004a60 <piperead+0x64>
    80004a3c:	2244a783          	lw	a5,548(s1)
    80004a40:	c385                	beqz	a5,80004a60 <piperead+0x64>
    if(pr->killed){
    80004a42:	028a2783          	lw	a5,40(s4)
    80004a46:	ebc1                	bnez	a5,80004ad6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a48:	85da                	mv	a1,s6
    80004a4a:	854e                	mv	a0,s3
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	620080e7          	jalr	1568(ra) # 8000206c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a54:	2184a703          	lw	a4,536(s1)
    80004a58:	21c4a783          	lw	a5,540(s1)
    80004a5c:	fef700e3          	beq	a4,a5,80004a3c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a60:	09505263          	blez	s5,80004ae4 <piperead+0xe8>
    80004a64:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a66:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004a68:	2184a783          	lw	a5,536(s1)
    80004a6c:	21c4a703          	lw	a4,540(s1)
    80004a70:	02f70d63          	beq	a4,a5,80004aaa <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a74:	0017871b          	addiw	a4,a5,1
    80004a78:	20e4ac23          	sw	a4,536(s1)
    80004a7c:	1ff7f793          	andi	a5,a5,511
    80004a80:	97a6                	add	a5,a5,s1
    80004a82:	0187c783          	lbu	a5,24(a5)
    80004a86:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a8a:	4685                	li	a3,1
    80004a8c:	fbf40613          	addi	a2,s0,-65
    80004a90:	85ca                	mv	a1,s2
    80004a92:	050a3503          	ld	a0,80(s4)
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	bdc080e7          	jalr	-1060(ra) # 80001672 <copyout>
    80004a9e:	01650663          	beq	a0,s6,80004aaa <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aa2:	2985                	addiw	s3,s3,1
    80004aa4:	0905                	addi	s2,s2,1
    80004aa6:	fd3a91e3          	bne	s5,s3,80004a68 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004aaa:	21c48513          	addi	a0,s1,540
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	74a080e7          	jalr	1866(ra) # 800021f8 <wakeup>
  release(&pi->lock);
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1e0080e7          	jalr	480(ra) # 80000c98 <release>
  return i;
}
    80004ac0:	854e                	mv	a0,s3
    80004ac2:	60a6                	ld	ra,72(sp)
    80004ac4:	6406                	ld	s0,64(sp)
    80004ac6:	74e2                	ld	s1,56(sp)
    80004ac8:	7942                	ld	s2,48(sp)
    80004aca:	79a2                	ld	s3,40(sp)
    80004acc:	7a02                	ld	s4,32(sp)
    80004ace:	6ae2                	ld	s5,24(sp)
    80004ad0:	6b42                	ld	s6,16(sp)
    80004ad2:	6161                	addi	sp,sp,80
    80004ad4:	8082                	ret
      release(&pi->lock);
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	1c0080e7          	jalr	448(ra) # 80000c98 <release>
      return -1;
    80004ae0:	59fd                	li	s3,-1
    80004ae2:	bff9                	j	80004ac0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ae4:	4981                	li	s3,0
    80004ae6:	b7d1                	j	80004aaa <piperead+0xae>

0000000080004ae8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ae8:	df010113          	addi	sp,sp,-528
    80004aec:	20113423          	sd	ra,520(sp)
    80004af0:	20813023          	sd	s0,512(sp)
    80004af4:	ffa6                	sd	s1,504(sp)
    80004af6:	fbca                	sd	s2,496(sp)
    80004af8:	f7ce                	sd	s3,488(sp)
    80004afa:	f3d2                	sd	s4,480(sp)
    80004afc:	efd6                	sd	s5,472(sp)
    80004afe:	ebda                	sd	s6,464(sp)
    80004b00:	e7de                	sd	s7,456(sp)
    80004b02:	e3e2                	sd	s8,448(sp)
    80004b04:	ff66                	sd	s9,440(sp)
    80004b06:	fb6a                	sd	s10,432(sp)
    80004b08:	f76e                	sd	s11,424(sp)
    80004b0a:	0c00                	addi	s0,sp,528
    80004b0c:	84aa                	mv	s1,a0
    80004b0e:	dea43c23          	sd	a0,-520(s0)
    80004b12:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b16:	ffffd097          	auipc	ra,0xffffd
    80004b1a:	e9a080e7          	jalr	-358(ra) # 800019b0 <myproc>
    80004b1e:	892a                	mv	s2,a0

  begin_op();
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	49c080e7          	jalr	1180(ra) # 80003fbc <begin_op>

  if((ip = namei(path)) == 0){
    80004b28:	8526                	mv	a0,s1
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	276080e7          	jalr	630(ra) # 80003da0 <namei>
    80004b32:	c92d                	beqz	a0,80004ba4 <exec+0xbc>
    80004b34:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	ab4080e7          	jalr	-1356(ra) # 800035ea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b3e:	04000713          	li	a4,64
    80004b42:	4681                	li	a3,0
    80004b44:	e5040613          	addi	a2,s0,-432
    80004b48:	4581                	li	a1,0
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	d52080e7          	jalr	-686(ra) # 8000389e <readi>
    80004b54:	04000793          	li	a5,64
    80004b58:	00f51a63          	bne	a0,a5,80004b6c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b5c:	e5042703          	lw	a4,-432(s0)
    80004b60:	464c47b7          	lui	a5,0x464c4
    80004b64:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b68:	04f70463          	beq	a4,a5,80004bb0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	cde080e7          	jalr	-802(ra) # 8000384c <iunlockput>
    end_op();
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	4c6080e7          	jalr	1222(ra) # 8000403c <end_op>
  }
  return -1;
    80004b7e:	557d                	li	a0,-1
}
    80004b80:	20813083          	ld	ra,520(sp)
    80004b84:	20013403          	ld	s0,512(sp)
    80004b88:	74fe                	ld	s1,504(sp)
    80004b8a:	795e                	ld	s2,496(sp)
    80004b8c:	79be                	ld	s3,488(sp)
    80004b8e:	7a1e                	ld	s4,480(sp)
    80004b90:	6afe                	ld	s5,472(sp)
    80004b92:	6b5e                	ld	s6,464(sp)
    80004b94:	6bbe                	ld	s7,456(sp)
    80004b96:	6c1e                	ld	s8,448(sp)
    80004b98:	7cfa                	ld	s9,440(sp)
    80004b9a:	7d5a                	ld	s10,432(sp)
    80004b9c:	7dba                	ld	s11,424(sp)
    80004b9e:	21010113          	addi	sp,sp,528
    80004ba2:	8082                	ret
    end_op();
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	498080e7          	jalr	1176(ra) # 8000403c <end_op>
    return -1;
    80004bac:	557d                	li	a0,-1
    80004bae:	bfc9                	j	80004b80 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bb0:	854a                	mv	a0,s2
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	ec2080e7          	jalr	-318(ra) # 80001a74 <proc_pagetable>
    80004bba:	8baa                	mv	s7,a0
    80004bbc:	d945                	beqz	a0,80004b6c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bbe:	e7042983          	lw	s3,-400(s0)
    80004bc2:	e8845783          	lhu	a5,-376(s0)
    80004bc6:	c7ad                	beqz	a5,80004c30 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004bc8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bca:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004bcc:	6c85                	lui	s9,0x1
    80004bce:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004bd2:	def43823          	sd	a5,-528(s0)
    80004bd6:	a42d                	j	80004e00 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bd8:	00004517          	auipc	a0,0x4
    80004bdc:	b0050513          	addi	a0,a0,-1280 # 800086d8 <syscalls+0x290>
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	95e080e7          	jalr	-1698(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004be8:	8756                	mv	a4,s5
    80004bea:	012d86bb          	addw	a3,s11,s2
    80004bee:	4581                	li	a1,0
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	cac080e7          	jalr	-852(ra) # 8000389e <readi>
    80004bfa:	2501                	sext.w	a0,a0
    80004bfc:	1aaa9963          	bne	s5,a0,80004dae <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c00:	6785                	lui	a5,0x1
    80004c02:	0127893b          	addw	s2,a5,s2
    80004c06:	77fd                	lui	a5,0xfffff
    80004c08:	01478a3b          	addw	s4,a5,s4
    80004c0c:	1f897163          	bgeu	s2,s8,80004dee <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c10:	02091593          	slli	a1,s2,0x20
    80004c14:	9181                	srli	a1,a1,0x20
    80004c16:	95ea                	add	a1,a1,s10
    80004c18:	855e                	mv	a0,s7
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	454080e7          	jalr	1108(ra) # 8000106e <walkaddr>
    80004c22:	862a                	mv	a2,a0
    if(pa == 0)
    80004c24:	d955                	beqz	a0,80004bd8 <exec+0xf0>
      n = PGSIZE;
    80004c26:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c28:	fd9a70e3          	bgeu	s4,s9,80004be8 <exec+0x100>
      n = sz - i;
    80004c2c:	8ad2                	mv	s5,s4
    80004c2e:	bf6d                	j	80004be8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c30:	4901                	li	s2,0
  iunlockput(ip);
    80004c32:	8526                	mv	a0,s1
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	c18080e7          	jalr	-1000(ra) # 8000384c <iunlockput>
  end_op();
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	400080e7          	jalr	1024(ra) # 8000403c <end_op>
  p = myproc();
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	d6c080e7          	jalr	-660(ra) # 800019b0 <myproc>
    80004c4c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004c4e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c52:	6785                	lui	a5,0x1
    80004c54:	17fd                	addi	a5,a5,-1
    80004c56:	993e                	add	s2,s2,a5
    80004c58:	757d                	lui	a0,0xfffff
    80004c5a:	00a977b3          	and	a5,s2,a0
    80004c5e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c62:	6609                	lui	a2,0x2
    80004c64:	963e                	add	a2,a2,a5
    80004c66:	85be                	mv	a1,a5
    80004c68:	855e                	mv	a0,s7
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	7b8080e7          	jalr	1976(ra) # 80001422 <uvmalloc>
    80004c72:	8b2a                	mv	s6,a0
  ip = 0;
    80004c74:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c76:	12050c63          	beqz	a0,80004dae <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c7a:	75f9                	lui	a1,0xffffe
    80004c7c:	95aa                	add	a1,a1,a0
    80004c7e:	855e                	mv	a0,s7
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	9c0080e7          	jalr	-1600(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004c88:	7c7d                	lui	s8,0xfffff
    80004c8a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004c8c:	e0043783          	ld	a5,-512(s0)
    80004c90:	6388                	ld	a0,0(a5)
    80004c92:	c535                	beqz	a0,80004cfe <exec+0x216>
    80004c94:	e9040993          	addi	s3,s0,-368
    80004c98:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004c9c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	1c6080e7          	jalr	454(ra) # 80000e64 <strlen>
    80004ca6:	2505                	addiw	a0,a0,1
    80004ca8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cac:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cb0:	13896363          	bltu	s2,s8,80004dd6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cb4:	e0043d83          	ld	s11,-512(s0)
    80004cb8:	000dba03          	ld	s4,0(s11)
    80004cbc:	8552                	mv	a0,s4
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	1a6080e7          	jalr	422(ra) # 80000e64 <strlen>
    80004cc6:	0015069b          	addiw	a3,a0,1
    80004cca:	8652                	mv	a2,s4
    80004ccc:	85ca                	mv	a1,s2
    80004cce:	855e                	mv	a0,s7
    80004cd0:	ffffd097          	auipc	ra,0xffffd
    80004cd4:	9a2080e7          	jalr	-1630(ra) # 80001672 <copyout>
    80004cd8:	10054363          	bltz	a0,80004dde <exec+0x2f6>
    ustack[argc] = sp;
    80004cdc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ce0:	0485                	addi	s1,s1,1
    80004ce2:	008d8793          	addi	a5,s11,8
    80004ce6:	e0f43023          	sd	a5,-512(s0)
    80004cea:	008db503          	ld	a0,8(s11)
    80004cee:	c911                	beqz	a0,80004d02 <exec+0x21a>
    if(argc >= MAXARG)
    80004cf0:	09a1                	addi	s3,s3,8
    80004cf2:	fb3c96e3          	bne	s9,s3,80004c9e <exec+0x1b6>
  sz = sz1;
    80004cf6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004cfa:	4481                	li	s1,0
    80004cfc:	a84d                	j	80004dae <exec+0x2c6>
  sp = sz;
    80004cfe:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d00:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d02:	00349793          	slli	a5,s1,0x3
    80004d06:	f9040713          	addi	a4,s0,-112
    80004d0a:	97ba                	add	a5,a5,a4
    80004d0c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004d10:	00148693          	addi	a3,s1,1
    80004d14:	068e                	slli	a3,a3,0x3
    80004d16:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d1a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d1e:	01897663          	bgeu	s2,s8,80004d2a <exec+0x242>
  sz = sz1;
    80004d22:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d26:	4481                	li	s1,0
    80004d28:	a059                	j	80004dae <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d2a:	e9040613          	addi	a2,s0,-368
    80004d2e:	85ca                	mv	a1,s2
    80004d30:	855e                	mv	a0,s7
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	940080e7          	jalr	-1728(ra) # 80001672 <copyout>
    80004d3a:	0a054663          	bltz	a0,80004de6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004d3e:	058ab783          	ld	a5,88(s5)
    80004d42:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d46:	df843783          	ld	a5,-520(s0)
    80004d4a:	0007c703          	lbu	a4,0(a5)
    80004d4e:	cf11                	beqz	a4,80004d6a <exec+0x282>
    80004d50:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d52:	02f00693          	li	a3,47
    80004d56:	a039                	j	80004d64 <exec+0x27c>
      last = s+1;
    80004d58:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004d5c:	0785                	addi	a5,a5,1
    80004d5e:	fff7c703          	lbu	a4,-1(a5)
    80004d62:	c701                	beqz	a4,80004d6a <exec+0x282>
    if(*s == '/')
    80004d64:	fed71ce3          	bne	a4,a3,80004d5c <exec+0x274>
    80004d68:	bfc5                	j	80004d58 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d6a:	4641                	li	a2,16
    80004d6c:	df843583          	ld	a1,-520(s0)
    80004d70:	158a8513          	addi	a0,s5,344
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	0be080e7          	jalr	190(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d7c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004d80:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004d84:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d88:	058ab783          	ld	a5,88(s5)
    80004d8c:	e6843703          	ld	a4,-408(s0)
    80004d90:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d92:	058ab783          	ld	a5,88(s5)
    80004d96:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004d9a:	85ea                	mv	a1,s10
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	d74080e7          	jalr	-652(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004da4:	0004851b          	sext.w	a0,s1
    80004da8:	bbe1                	j	80004b80 <exec+0x98>
    80004daa:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004dae:	e0843583          	ld	a1,-504(s0)
    80004db2:	855e                	mv	a0,s7
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	d5c080e7          	jalr	-676(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004dbc:	da0498e3          	bnez	s1,80004b6c <exec+0x84>
  return -1;
    80004dc0:	557d                	li	a0,-1
    80004dc2:	bb7d                	j	80004b80 <exec+0x98>
    80004dc4:	e1243423          	sd	s2,-504(s0)
    80004dc8:	b7dd                	j	80004dae <exec+0x2c6>
    80004dca:	e1243423          	sd	s2,-504(s0)
    80004dce:	b7c5                	j	80004dae <exec+0x2c6>
    80004dd0:	e1243423          	sd	s2,-504(s0)
    80004dd4:	bfe9                	j	80004dae <exec+0x2c6>
  sz = sz1;
    80004dd6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dda:	4481                	li	s1,0
    80004ddc:	bfc9                	j	80004dae <exec+0x2c6>
  sz = sz1;
    80004dde:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004de2:	4481                	li	s1,0
    80004de4:	b7e9                	j	80004dae <exec+0x2c6>
  sz = sz1;
    80004de6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dea:	4481                	li	s1,0
    80004dec:	b7c9                	j	80004dae <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004dee:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df2:	2b05                	addiw	s6,s6,1
    80004df4:	0389899b          	addiw	s3,s3,56
    80004df8:	e8845783          	lhu	a5,-376(s0)
    80004dfc:	e2fb5be3          	bge	s6,a5,80004c32 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e00:	2981                	sext.w	s3,s3
    80004e02:	03800713          	li	a4,56
    80004e06:	86ce                	mv	a3,s3
    80004e08:	e1840613          	addi	a2,s0,-488
    80004e0c:	4581                	li	a1,0
    80004e0e:	8526                	mv	a0,s1
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	a8e080e7          	jalr	-1394(ra) # 8000389e <readi>
    80004e18:	03800793          	li	a5,56
    80004e1c:	f8f517e3          	bne	a0,a5,80004daa <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e20:	e1842783          	lw	a5,-488(s0)
    80004e24:	4705                	li	a4,1
    80004e26:	fce796e3          	bne	a5,a4,80004df2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e2a:	e4043603          	ld	a2,-448(s0)
    80004e2e:	e3843783          	ld	a5,-456(s0)
    80004e32:	f8f669e3          	bltu	a2,a5,80004dc4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e36:	e2843783          	ld	a5,-472(s0)
    80004e3a:	963e                	add	a2,a2,a5
    80004e3c:	f8f667e3          	bltu	a2,a5,80004dca <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e40:	85ca                	mv	a1,s2
    80004e42:	855e                	mv	a0,s7
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	5de080e7          	jalr	1502(ra) # 80001422 <uvmalloc>
    80004e4c:	e0a43423          	sd	a0,-504(s0)
    80004e50:	d141                	beqz	a0,80004dd0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004e52:	e2843d03          	ld	s10,-472(s0)
    80004e56:	df043783          	ld	a5,-528(s0)
    80004e5a:	00fd77b3          	and	a5,s10,a5
    80004e5e:	fba1                	bnez	a5,80004dae <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e60:	e2042d83          	lw	s11,-480(s0)
    80004e64:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e68:	f80c03e3          	beqz	s8,80004dee <exec+0x306>
    80004e6c:	8a62                	mv	s4,s8
    80004e6e:	4901                	li	s2,0
    80004e70:	b345                	j	80004c10 <exec+0x128>

0000000080004e72 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e72:	7179                	addi	sp,sp,-48
    80004e74:	f406                	sd	ra,40(sp)
    80004e76:	f022                	sd	s0,32(sp)
    80004e78:	ec26                	sd	s1,24(sp)
    80004e7a:	e84a                	sd	s2,16(sp)
    80004e7c:	1800                	addi	s0,sp,48
    80004e7e:	892e                	mv	s2,a1
    80004e80:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e82:	fdc40593          	addi	a1,s0,-36
    80004e86:	ffffe097          	auipc	ra,0xffffe
    80004e8a:	bd6080e7          	jalr	-1066(ra) # 80002a5c <argint>
    80004e8e:	04054063          	bltz	a0,80004ece <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e92:	fdc42703          	lw	a4,-36(s0)
    80004e96:	47bd                	li	a5,15
    80004e98:	02e7ed63          	bltu	a5,a4,80004ed2 <argfd+0x60>
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	b14080e7          	jalr	-1260(ra) # 800019b0 <myproc>
    80004ea4:	fdc42703          	lw	a4,-36(s0)
    80004ea8:	01a70793          	addi	a5,a4,26
    80004eac:	078e                	slli	a5,a5,0x3
    80004eae:	953e                	add	a0,a0,a5
    80004eb0:	611c                	ld	a5,0(a0)
    80004eb2:	c395                	beqz	a5,80004ed6 <argfd+0x64>
    return -1;
  if(pfd)
    80004eb4:	00090463          	beqz	s2,80004ebc <argfd+0x4a>
    *pfd = fd;
    80004eb8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ebc:	4501                	li	a0,0
  if(pf)
    80004ebe:	c091                	beqz	s1,80004ec2 <argfd+0x50>
    *pf = f;
    80004ec0:	e09c                	sd	a5,0(s1)
}
    80004ec2:	70a2                	ld	ra,40(sp)
    80004ec4:	7402                	ld	s0,32(sp)
    80004ec6:	64e2                	ld	s1,24(sp)
    80004ec8:	6942                	ld	s2,16(sp)
    80004eca:	6145                	addi	sp,sp,48
    80004ecc:	8082                	ret
    return -1;
    80004ece:	557d                	li	a0,-1
    80004ed0:	bfcd                	j	80004ec2 <argfd+0x50>
    return -1;
    80004ed2:	557d                	li	a0,-1
    80004ed4:	b7fd                	j	80004ec2 <argfd+0x50>
    80004ed6:	557d                	li	a0,-1
    80004ed8:	b7ed                	j	80004ec2 <argfd+0x50>

0000000080004eda <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004eda:	1101                	addi	sp,sp,-32
    80004edc:	ec06                	sd	ra,24(sp)
    80004ede:	e822                	sd	s0,16(sp)
    80004ee0:	e426                	sd	s1,8(sp)
    80004ee2:	1000                	addi	s0,sp,32
    80004ee4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	aca080e7          	jalr	-1334(ra) # 800019b0 <myproc>
    80004eee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ef0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004ef4:	4501                	li	a0,0
    80004ef6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ef8:	6398                	ld	a4,0(a5)
    80004efa:	cb19                	beqz	a4,80004f10 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004efc:	2505                	addiw	a0,a0,1
    80004efe:	07a1                	addi	a5,a5,8
    80004f00:	fed51ce3          	bne	a0,a3,80004ef8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f04:	557d                	li	a0,-1
}
    80004f06:	60e2                	ld	ra,24(sp)
    80004f08:	6442                	ld	s0,16(sp)
    80004f0a:	64a2                	ld	s1,8(sp)
    80004f0c:	6105                	addi	sp,sp,32
    80004f0e:	8082                	ret
      p->ofile[fd] = f;
    80004f10:	01a50793          	addi	a5,a0,26
    80004f14:	078e                	slli	a5,a5,0x3
    80004f16:	963e                	add	a2,a2,a5
    80004f18:	e204                	sd	s1,0(a2)
      return fd;
    80004f1a:	b7f5                	j	80004f06 <fdalloc+0x2c>

0000000080004f1c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f1c:	715d                	addi	sp,sp,-80
    80004f1e:	e486                	sd	ra,72(sp)
    80004f20:	e0a2                	sd	s0,64(sp)
    80004f22:	fc26                	sd	s1,56(sp)
    80004f24:	f84a                	sd	s2,48(sp)
    80004f26:	f44e                	sd	s3,40(sp)
    80004f28:	f052                	sd	s4,32(sp)
    80004f2a:	ec56                	sd	s5,24(sp)
    80004f2c:	0880                	addi	s0,sp,80
    80004f2e:	89ae                	mv	s3,a1
    80004f30:	8ab2                	mv	s5,a2
    80004f32:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f34:	fb040593          	addi	a1,s0,-80
    80004f38:	fffff097          	auipc	ra,0xfffff
    80004f3c:	e86080e7          	jalr	-378(ra) # 80003dbe <nameiparent>
    80004f40:	892a                	mv	s2,a0
    80004f42:	12050f63          	beqz	a0,80005080 <create+0x164>
    return 0;

  ilock(dp);
    80004f46:	ffffe097          	auipc	ra,0xffffe
    80004f4a:	6a4080e7          	jalr	1700(ra) # 800035ea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f4e:	4601                	li	a2,0
    80004f50:	fb040593          	addi	a1,s0,-80
    80004f54:	854a                	mv	a0,s2
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	b78080e7          	jalr	-1160(ra) # 80003ace <dirlookup>
    80004f5e:	84aa                	mv	s1,a0
    80004f60:	c921                	beqz	a0,80004fb0 <create+0x94>
    iunlockput(dp);
    80004f62:	854a                	mv	a0,s2
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	8e8080e7          	jalr	-1816(ra) # 8000384c <iunlockput>
    ilock(ip);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffe097          	auipc	ra,0xffffe
    80004f72:	67c080e7          	jalr	1660(ra) # 800035ea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f76:	2981                	sext.w	s3,s3
    80004f78:	4789                	li	a5,2
    80004f7a:	02f99463          	bne	s3,a5,80004fa2 <create+0x86>
    80004f7e:	0444d783          	lhu	a5,68(s1)
    80004f82:	37f9                	addiw	a5,a5,-2
    80004f84:	17c2                	slli	a5,a5,0x30
    80004f86:	93c1                	srli	a5,a5,0x30
    80004f88:	4705                	li	a4,1
    80004f8a:	00f76c63          	bltu	a4,a5,80004fa2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f8e:	8526                	mv	a0,s1
    80004f90:	60a6                	ld	ra,72(sp)
    80004f92:	6406                	ld	s0,64(sp)
    80004f94:	74e2                	ld	s1,56(sp)
    80004f96:	7942                	ld	s2,48(sp)
    80004f98:	79a2                	ld	s3,40(sp)
    80004f9a:	7a02                	ld	s4,32(sp)
    80004f9c:	6ae2                	ld	s5,24(sp)
    80004f9e:	6161                	addi	sp,sp,80
    80004fa0:	8082                	ret
    iunlockput(ip);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	8a8080e7          	jalr	-1880(ra) # 8000384c <iunlockput>
    return 0;
    80004fac:	4481                	li	s1,0
    80004fae:	b7c5                	j	80004f8e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fb0:	85ce                	mv	a1,s3
    80004fb2:	00092503          	lw	a0,0(s2)
    80004fb6:	ffffe097          	auipc	ra,0xffffe
    80004fba:	49c080e7          	jalr	1180(ra) # 80003452 <ialloc>
    80004fbe:	84aa                	mv	s1,a0
    80004fc0:	c529                	beqz	a0,8000500a <create+0xee>
  ilock(ip);
    80004fc2:	ffffe097          	auipc	ra,0xffffe
    80004fc6:	628080e7          	jalr	1576(ra) # 800035ea <ilock>
  ip->major = major;
    80004fca:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fce:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fd2:	4785                	li	a5,1
    80004fd4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004fd8:	8526                	mv	a0,s1
    80004fda:	ffffe097          	auipc	ra,0xffffe
    80004fde:	546080e7          	jalr	1350(ra) # 80003520 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fe2:	2981                	sext.w	s3,s3
    80004fe4:	4785                	li	a5,1
    80004fe6:	02f98a63          	beq	s3,a5,8000501a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80004fea:	40d0                	lw	a2,4(s1)
    80004fec:	fb040593          	addi	a1,s0,-80
    80004ff0:	854a                	mv	a0,s2
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	cec080e7          	jalr	-788(ra) # 80003cde <dirlink>
    80004ffa:	06054b63          	bltz	a0,80005070 <create+0x154>
  iunlockput(dp);
    80004ffe:	854a                	mv	a0,s2
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	84c080e7          	jalr	-1972(ra) # 8000384c <iunlockput>
  return ip;
    80005008:	b759                	j	80004f8e <create+0x72>
    panic("create: ialloc");
    8000500a:	00003517          	auipc	a0,0x3
    8000500e:	6ee50513          	addi	a0,a0,1774 # 800086f8 <syscalls+0x2b0>
    80005012:	ffffb097          	auipc	ra,0xffffb
    80005016:	52c080e7          	jalr	1324(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000501a:	04a95783          	lhu	a5,74(s2)
    8000501e:	2785                	addiw	a5,a5,1
    80005020:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005024:	854a                	mv	a0,s2
    80005026:	ffffe097          	auipc	ra,0xffffe
    8000502a:	4fa080e7          	jalr	1274(ra) # 80003520 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000502e:	40d0                	lw	a2,4(s1)
    80005030:	00003597          	auipc	a1,0x3
    80005034:	6d858593          	addi	a1,a1,1752 # 80008708 <syscalls+0x2c0>
    80005038:	8526                	mv	a0,s1
    8000503a:	fffff097          	auipc	ra,0xfffff
    8000503e:	ca4080e7          	jalr	-860(ra) # 80003cde <dirlink>
    80005042:	00054f63          	bltz	a0,80005060 <create+0x144>
    80005046:	00492603          	lw	a2,4(s2)
    8000504a:	00003597          	auipc	a1,0x3
    8000504e:	6c658593          	addi	a1,a1,1734 # 80008710 <syscalls+0x2c8>
    80005052:	8526                	mv	a0,s1
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	c8a080e7          	jalr	-886(ra) # 80003cde <dirlink>
    8000505c:	f80557e3          	bgez	a0,80004fea <create+0xce>
      panic("create dots");
    80005060:	00003517          	auipc	a0,0x3
    80005064:	6b850513          	addi	a0,a0,1720 # 80008718 <syscalls+0x2d0>
    80005068:	ffffb097          	auipc	ra,0xffffb
    8000506c:	4d6080e7          	jalr	1238(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005070:	00003517          	auipc	a0,0x3
    80005074:	6b850513          	addi	a0,a0,1720 # 80008728 <syscalls+0x2e0>
    80005078:	ffffb097          	auipc	ra,0xffffb
    8000507c:	4c6080e7          	jalr	1222(ra) # 8000053e <panic>
    return 0;
    80005080:	84aa                	mv	s1,a0
    80005082:	b731                	j	80004f8e <create+0x72>

0000000080005084 <sys_dup>:
{
    80005084:	7179                	addi	sp,sp,-48
    80005086:	f406                	sd	ra,40(sp)
    80005088:	f022                	sd	s0,32(sp)
    8000508a:	ec26                	sd	s1,24(sp)
    8000508c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000508e:	fd840613          	addi	a2,s0,-40
    80005092:	4581                	li	a1,0
    80005094:	4501                	li	a0,0
    80005096:	00000097          	auipc	ra,0x0
    8000509a:	ddc080e7          	jalr	-548(ra) # 80004e72 <argfd>
    return -1;
    8000509e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050a0:	02054363          	bltz	a0,800050c6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050a4:	fd843503          	ld	a0,-40(s0)
    800050a8:	00000097          	auipc	ra,0x0
    800050ac:	e32080e7          	jalr	-462(ra) # 80004eda <fdalloc>
    800050b0:	84aa                	mv	s1,a0
    return -1;
    800050b2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050b4:	00054963          	bltz	a0,800050c6 <sys_dup+0x42>
  filedup(f);
    800050b8:	fd843503          	ld	a0,-40(s0)
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	37a080e7          	jalr	890(ra) # 80004436 <filedup>
  return fd;
    800050c4:	87a6                	mv	a5,s1
}
    800050c6:	853e                	mv	a0,a5
    800050c8:	70a2                	ld	ra,40(sp)
    800050ca:	7402                	ld	s0,32(sp)
    800050cc:	64e2                	ld	s1,24(sp)
    800050ce:	6145                	addi	sp,sp,48
    800050d0:	8082                	ret

00000000800050d2 <sys_read>:
{
    800050d2:	7179                	addi	sp,sp,-48
    800050d4:	f406                	sd	ra,40(sp)
    800050d6:	f022                	sd	s0,32(sp)
    800050d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050da:	fe840613          	addi	a2,s0,-24
    800050de:	4581                	li	a1,0
    800050e0:	4501                	li	a0,0
    800050e2:	00000097          	auipc	ra,0x0
    800050e6:	d90080e7          	jalr	-624(ra) # 80004e72 <argfd>
    return -1;
    800050ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050ec:	04054163          	bltz	a0,8000512e <sys_read+0x5c>
    800050f0:	fe440593          	addi	a1,s0,-28
    800050f4:	4509                	li	a0,2
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	966080e7          	jalr	-1690(ra) # 80002a5c <argint>
    return -1;
    800050fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005100:	02054763          	bltz	a0,8000512e <sys_read+0x5c>
    80005104:	fd840593          	addi	a1,s0,-40
    80005108:	4505                	li	a0,1
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	974080e7          	jalr	-1676(ra) # 80002a7e <argaddr>
    return -1;
    80005112:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005114:	00054d63          	bltz	a0,8000512e <sys_read+0x5c>
  return fileread(f, p, n);
    80005118:	fe442603          	lw	a2,-28(s0)
    8000511c:	fd843583          	ld	a1,-40(s0)
    80005120:	fe843503          	ld	a0,-24(s0)
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	49e080e7          	jalr	1182(ra) # 800045c2 <fileread>
    8000512c:	87aa                	mv	a5,a0
}
    8000512e:	853e                	mv	a0,a5
    80005130:	70a2                	ld	ra,40(sp)
    80005132:	7402                	ld	s0,32(sp)
    80005134:	6145                	addi	sp,sp,48
    80005136:	8082                	ret

0000000080005138 <sys_write>:
{
    80005138:	7179                	addi	sp,sp,-48
    8000513a:	f406                	sd	ra,40(sp)
    8000513c:	f022                	sd	s0,32(sp)
    8000513e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005140:	fe840613          	addi	a2,s0,-24
    80005144:	4581                	li	a1,0
    80005146:	4501                	li	a0,0
    80005148:	00000097          	auipc	ra,0x0
    8000514c:	d2a080e7          	jalr	-726(ra) # 80004e72 <argfd>
    return -1;
    80005150:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005152:	04054163          	bltz	a0,80005194 <sys_write+0x5c>
    80005156:	fe440593          	addi	a1,s0,-28
    8000515a:	4509                	li	a0,2
    8000515c:	ffffe097          	auipc	ra,0xffffe
    80005160:	900080e7          	jalr	-1792(ra) # 80002a5c <argint>
    return -1;
    80005164:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005166:	02054763          	bltz	a0,80005194 <sys_write+0x5c>
    8000516a:	fd840593          	addi	a1,s0,-40
    8000516e:	4505                	li	a0,1
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	90e080e7          	jalr	-1778(ra) # 80002a7e <argaddr>
    return -1;
    80005178:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000517a:	00054d63          	bltz	a0,80005194 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000517e:	fe442603          	lw	a2,-28(s0)
    80005182:	fd843583          	ld	a1,-40(s0)
    80005186:	fe843503          	ld	a0,-24(s0)
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	4fa080e7          	jalr	1274(ra) # 80004684 <filewrite>
    80005192:	87aa                	mv	a5,a0
}
    80005194:	853e                	mv	a0,a5
    80005196:	70a2                	ld	ra,40(sp)
    80005198:	7402                	ld	s0,32(sp)
    8000519a:	6145                	addi	sp,sp,48
    8000519c:	8082                	ret

000000008000519e <sys_close>:
{
    8000519e:	1101                	addi	sp,sp,-32
    800051a0:	ec06                	sd	ra,24(sp)
    800051a2:	e822                	sd	s0,16(sp)
    800051a4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051a6:	fe040613          	addi	a2,s0,-32
    800051aa:	fec40593          	addi	a1,s0,-20
    800051ae:	4501                	li	a0,0
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	cc2080e7          	jalr	-830(ra) # 80004e72 <argfd>
    return -1;
    800051b8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051ba:	02054463          	bltz	a0,800051e2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	7f2080e7          	jalr	2034(ra) # 800019b0 <myproc>
    800051c6:	fec42783          	lw	a5,-20(s0)
    800051ca:	07e9                	addi	a5,a5,26
    800051cc:	078e                	slli	a5,a5,0x3
    800051ce:	97aa                	add	a5,a5,a0
    800051d0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051d4:	fe043503          	ld	a0,-32(s0)
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	2b0080e7          	jalr	688(ra) # 80004488 <fileclose>
  return 0;
    800051e0:	4781                	li	a5,0
}
    800051e2:	853e                	mv	a0,a5
    800051e4:	60e2                	ld	ra,24(sp)
    800051e6:	6442                	ld	s0,16(sp)
    800051e8:	6105                	addi	sp,sp,32
    800051ea:	8082                	ret

00000000800051ec <sys_fstat>:
{
    800051ec:	1101                	addi	sp,sp,-32
    800051ee:	ec06                	sd	ra,24(sp)
    800051f0:	e822                	sd	s0,16(sp)
    800051f2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051f4:	fe840613          	addi	a2,s0,-24
    800051f8:	4581                	li	a1,0
    800051fa:	4501                	li	a0,0
    800051fc:	00000097          	auipc	ra,0x0
    80005200:	c76080e7          	jalr	-906(ra) # 80004e72 <argfd>
    return -1;
    80005204:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005206:	02054563          	bltz	a0,80005230 <sys_fstat+0x44>
    8000520a:	fe040593          	addi	a1,s0,-32
    8000520e:	4505                	li	a0,1
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	86e080e7          	jalr	-1938(ra) # 80002a7e <argaddr>
    return -1;
    80005218:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000521a:	00054b63          	bltz	a0,80005230 <sys_fstat+0x44>
  return filestat(f, st);
    8000521e:	fe043583          	ld	a1,-32(s0)
    80005222:	fe843503          	ld	a0,-24(s0)
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	32a080e7          	jalr	810(ra) # 80004550 <filestat>
    8000522e:	87aa                	mv	a5,a0
}
    80005230:	853e                	mv	a0,a5
    80005232:	60e2                	ld	ra,24(sp)
    80005234:	6442                	ld	s0,16(sp)
    80005236:	6105                	addi	sp,sp,32
    80005238:	8082                	ret

000000008000523a <sys_link>:
{
    8000523a:	7169                	addi	sp,sp,-304
    8000523c:	f606                	sd	ra,296(sp)
    8000523e:	f222                	sd	s0,288(sp)
    80005240:	ee26                	sd	s1,280(sp)
    80005242:	ea4a                	sd	s2,272(sp)
    80005244:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005246:	08000613          	li	a2,128
    8000524a:	ed040593          	addi	a1,s0,-304
    8000524e:	4501                	li	a0,0
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	850080e7          	jalr	-1968(ra) # 80002aa0 <argstr>
    return -1;
    80005258:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000525a:	10054e63          	bltz	a0,80005376 <sys_link+0x13c>
    8000525e:	08000613          	li	a2,128
    80005262:	f5040593          	addi	a1,s0,-176
    80005266:	4505                	li	a0,1
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	838080e7          	jalr	-1992(ra) # 80002aa0 <argstr>
    return -1;
    80005270:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005272:	10054263          	bltz	a0,80005376 <sys_link+0x13c>
  begin_op();
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	d46080e7          	jalr	-698(ra) # 80003fbc <begin_op>
  if((ip = namei(old)) == 0){
    8000527e:	ed040513          	addi	a0,s0,-304
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	b1e080e7          	jalr	-1250(ra) # 80003da0 <namei>
    8000528a:	84aa                	mv	s1,a0
    8000528c:	c551                	beqz	a0,80005318 <sys_link+0xde>
  ilock(ip);
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	35c080e7          	jalr	860(ra) # 800035ea <ilock>
  if(ip->type == T_DIR){
    80005296:	04449703          	lh	a4,68(s1)
    8000529a:	4785                	li	a5,1
    8000529c:	08f70463          	beq	a4,a5,80005324 <sys_link+0xea>
  ip->nlink++;
    800052a0:	04a4d783          	lhu	a5,74(s1)
    800052a4:	2785                	addiw	a5,a5,1
    800052a6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052aa:	8526                	mv	a0,s1
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	274080e7          	jalr	628(ra) # 80003520 <iupdate>
  iunlock(ip);
    800052b4:	8526                	mv	a0,s1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	3f6080e7          	jalr	1014(ra) # 800036ac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052be:	fd040593          	addi	a1,s0,-48
    800052c2:	f5040513          	addi	a0,s0,-176
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	af8080e7          	jalr	-1288(ra) # 80003dbe <nameiparent>
    800052ce:	892a                	mv	s2,a0
    800052d0:	c935                	beqz	a0,80005344 <sys_link+0x10a>
  ilock(dp);
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	318080e7          	jalr	792(ra) # 800035ea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052da:	00092703          	lw	a4,0(s2)
    800052de:	409c                	lw	a5,0(s1)
    800052e0:	04f71d63          	bne	a4,a5,8000533a <sys_link+0x100>
    800052e4:	40d0                	lw	a2,4(s1)
    800052e6:	fd040593          	addi	a1,s0,-48
    800052ea:	854a                	mv	a0,s2
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	9f2080e7          	jalr	-1550(ra) # 80003cde <dirlink>
    800052f4:	04054363          	bltz	a0,8000533a <sys_link+0x100>
  iunlockput(dp);
    800052f8:	854a                	mv	a0,s2
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	552080e7          	jalr	1362(ra) # 8000384c <iunlockput>
  iput(ip);
    80005302:	8526                	mv	a0,s1
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	4a0080e7          	jalr	1184(ra) # 800037a4 <iput>
  end_op();
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	d30080e7          	jalr	-720(ra) # 8000403c <end_op>
  return 0;
    80005314:	4781                	li	a5,0
    80005316:	a085                	j	80005376 <sys_link+0x13c>
    end_op();
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	d24080e7          	jalr	-732(ra) # 8000403c <end_op>
    return -1;
    80005320:	57fd                	li	a5,-1
    80005322:	a891                	j	80005376 <sys_link+0x13c>
    iunlockput(ip);
    80005324:	8526                	mv	a0,s1
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	526080e7          	jalr	1318(ra) # 8000384c <iunlockput>
    end_op();
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	d0e080e7          	jalr	-754(ra) # 8000403c <end_op>
    return -1;
    80005336:	57fd                	li	a5,-1
    80005338:	a83d                	j	80005376 <sys_link+0x13c>
    iunlockput(dp);
    8000533a:	854a                	mv	a0,s2
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	510080e7          	jalr	1296(ra) # 8000384c <iunlockput>
  ilock(ip);
    80005344:	8526                	mv	a0,s1
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	2a4080e7          	jalr	676(ra) # 800035ea <ilock>
  ip->nlink--;
    8000534e:	04a4d783          	lhu	a5,74(s1)
    80005352:	37fd                	addiw	a5,a5,-1
    80005354:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	1c6080e7          	jalr	454(ra) # 80003520 <iupdate>
  iunlockput(ip);
    80005362:	8526                	mv	a0,s1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	4e8080e7          	jalr	1256(ra) # 8000384c <iunlockput>
  end_op();
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	cd0080e7          	jalr	-816(ra) # 8000403c <end_op>
  return -1;
    80005374:	57fd                	li	a5,-1
}
    80005376:	853e                	mv	a0,a5
    80005378:	70b2                	ld	ra,296(sp)
    8000537a:	7412                	ld	s0,288(sp)
    8000537c:	64f2                	ld	s1,280(sp)
    8000537e:	6952                	ld	s2,272(sp)
    80005380:	6155                	addi	sp,sp,304
    80005382:	8082                	ret

0000000080005384 <sys_unlink>:
{
    80005384:	7151                	addi	sp,sp,-240
    80005386:	f586                	sd	ra,232(sp)
    80005388:	f1a2                	sd	s0,224(sp)
    8000538a:	eda6                	sd	s1,216(sp)
    8000538c:	e9ca                	sd	s2,208(sp)
    8000538e:	e5ce                	sd	s3,200(sp)
    80005390:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005392:	08000613          	li	a2,128
    80005396:	f3040593          	addi	a1,s0,-208
    8000539a:	4501                	li	a0,0
    8000539c:	ffffd097          	auipc	ra,0xffffd
    800053a0:	704080e7          	jalr	1796(ra) # 80002aa0 <argstr>
    800053a4:	18054163          	bltz	a0,80005526 <sys_unlink+0x1a2>
  begin_op();
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	c14080e7          	jalr	-1004(ra) # 80003fbc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053b0:	fb040593          	addi	a1,s0,-80
    800053b4:	f3040513          	addi	a0,s0,-208
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	a06080e7          	jalr	-1530(ra) # 80003dbe <nameiparent>
    800053c0:	84aa                	mv	s1,a0
    800053c2:	c979                	beqz	a0,80005498 <sys_unlink+0x114>
  ilock(dp);
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	226080e7          	jalr	550(ra) # 800035ea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053cc:	00003597          	auipc	a1,0x3
    800053d0:	33c58593          	addi	a1,a1,828 # 80008708 <syscalls+0x2c0>
    800053d4:	fb040513          	addi	a0,s0,-80
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	6dc080e7          	jalr	1756(ra) # 80003ab4 <namecmp>
    800053e0:	14050a63          	beqz	a0,80005534 <sys_unlink+0x1b0>
    800053e4:	00003597          	auipc	a1,0x3
    800053e8:	32c58593          	addi	a1,a1,812 # 80008710 <syscalls+0x2c8>
    800053ec:	fb040513          	addi	a0,s0,-80
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	6c4080e7          	jalr	1732(ra) # 80003ab4 <namecmp>
    800053f8:	12050e63          	beqz	a0,80005534 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800053fc:	f2c40613          	addi	a2,s0,-212
    80005400:	fb040593          	addi	a1,s0,-80
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	6c8080e7          	jalr	1736(ra) # 80003ace <dirlookup>
    8000540e:	892a                	mv	s2,a0
    80005410:	12050263          	beqz	a0,80005534 <sys_unlink+0x1b0>
  ilock(ip);
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	1d6080e7          	jalr	470(ra) # 800035ea <ilock>
  if(ip->nlink < 1)
    8000541c:	04a91783          	lh	a5,74(s2)
    80005420:	08f05263          	blez	a5,800054a4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005424:	04491703          	lh	a4,68(s2)
    80005428:	4785                	li	a5,1
    8000542a:	08f70563          	beq	a4,a5,800054b4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000542e:	4641                	li	a2,16
    80005430:	4581                	li	a1,0
    80005432:	fc040513          	addi	a0,s0,-64
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	8aa080e7          	jalr	-1878(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000543e:	4741                	li	a4,16
    80005440:	f2c42683          	lw	a3,-212(s0)
    80005444:	fc040613          	addi	a2,s0,-64
    80005448:	4581                	li	a1,0
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	54a080e7          	jalr	1354(ra) # 80003996 <writei>
    80005454:	47c1                	li	a5,16
    80005456:	0af51563          	bne	a0,a5,80005500 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000545a:	04491703          	lh	a4,68(s2)
    8000545e:	4785                	li	a5,1
    80005460:	0af70863          	beq	a4,a5,80005510 <sys_unlink+0x18c>
  iunlockput(dp);
    80005464:	8526                	mv	a0,s1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	3e6080e7          	jalr	998(ra) # 8000384c <iunlockput>
  ip->nlink--;
    8000546e:	04a95783          	lhu	a5,74(s2)
    80005472:	37fd                	addiw	a5,a5,-1
    80005474:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005478:	854a                	mv	a0,s2
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	0a6080e7          	jalr	166(ra) # 80003520 <iupdate>
  iunlockput(ip);
    80005482:	854a                	mv	a0,s2
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	3c8080e7          	jalr	968(ra) # 8000384c <iunlockput>
  end_op();
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	bb0080e7          	jalr	-1104(ra) # 8000403c <end_op>
  return 0;
    80005494:	4501                	li	a0,0
    80005496:	a84d                	j	80005548 <sys_unlink+0x1c4>
    end_op();
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	ba4080e7          	jalr	-1116(ra) # 8000403c <end_op>
    return -1;
    800054a0:	557d                	li	a0,-1
    800054a2:	a05d                	j	80005548 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054a4:	00003517          	auipc	a0,0x3
    800054a8:	29450513          	addi	a0,a0,660 # 80008738 <syscalls+0x2f0>
    800054ac:	ffffb097          	auipc	ra,0xffffb
    800054b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054b4:	04c92703          	lw	a4,76(s2)
    800054b8:	02000793          	li	a5,32
    800054bc:	f6e7f9e3          	bgeu	a5,a4,8000542e <sys_unlink+0xaa>
    800054c0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054c4:	4741                	li	a4,16
    800054c6:	86ce                	mv	a3,s3
    800054c8:	f1840613          	addi	a2,s0,-232
    800054cc:	4581                	li	a1,0
    800054ce:	854a                	mv	a0,s2
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	3ce080e7          	jalr	974(ra) # 8000389e <readi>
    800054d8:	47c1                	li	a5,16
    800054da:	00f51b63          	bne	a0,a5,800054f0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054de:	f1845783          	lhu	a5,-232(s0)
    800054e2:	e7a1                	bnez	a5,8000552a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054e4:	29c1                	addiw	s3,s3,16
    800054e6:	04c92783          	lw	a5,76(s2)
    800054ea:	fcf9ede3          	bltu	s3,a5,800054c4 <sys_unlink+0x140>
    800054ee:	b781                	j	8000542e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800054f0:	00003517          	auipc	a0,0x3
    800054f4:	26050513          	addi	a0,a0,608 # 80008750 <syscalls+0x308>
    800054f8:	ffffb097          	auipc	ra,0xffffb
    800054fc:	046080e7          	jalr	70(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005500:	00003517          	auipc	a0,0x3
    80005504:	26850513          	addi	a0,a0,616 # 80008768 <syscalls+0x320>
    80005508:	ffffb097          	auipc	ra,0xffffb
    8000550c:	036080e7          	jalr	54(ra) # 8000053e <panic>
    dp->nlink--;
    80005510:	04a4d783          	lhu	a5,74(s1)
    80005514:	37fd                	addiw	a5,a5,-1
    80005516:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	004080e7          	jalr	4(ra) # 80003520 <iupdate>
    80005524:	b781                	j	80005464 <sys_unlink+0xe0>
    return -1;
    80005526:	557d                	li	a0,-1
    80005528:	a005                	j	80005548 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000552a:	854a                	mv	a0,s2
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	320080e7          	jalr	800(ra) # 8000384c <iunlockput>
  iunlockput(dp);
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	316080e7          	jalr	790(ra) # 8000384c <iunlockput>
  end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	afe080e7          	jalr	-1282(ra) # 8000403c <end_op>
  return -1;
    80005546:	557d                	li	a0,-1
}
    80005548:	70ae                	ld	ra,232(sp)
    8000554a:	740e                	ld	s0,224(sp)
    8000554c:	64ee                	ld	s1,216(sp)
    8000554e:	694e                	ld	s2,208(sp)
    80005550:	69ae                	ld	s3,200(sp)
    80005552:	616d                	addi	sp,sp,240
    80005554:	8082                	ret

0000000080005556 <sys_open>:

uint64
sys_open(void)
{
    80005556:	7131                	addi	sp,sp,-192
    80005558:	fd06                	sd	ra,184(sp)
    8000555a:	f922                	sd	s0,176(sp)
    8000555c:	f526                	sd	s1,168(sp)
    8000555e:	f14a                	sd	s2,160(sp)
    80005560:	ed4e                	sd	s3,152(sp)
    80005562:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005564:	08000613          	li	a2,128
    80005568:	f5040593          	addi	a1,s0,-176
    8000556c:	4501                	li	a0,0
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	532080e7          	jalr	1330(ra) # 80002aa0 <argstr>
    return -1;
    80005576:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005578:	0c054163          	bltz	a0,8000563a <sys_open+0xe4>
    8000557c:	f4c40593          	addi	a1,s0,-180
    80005580:	4505                	li	a0,1
    80005582:	ffffd097          	auipc	ra,0xffffd
    80005586:	4da080e7          	jalr	1242(ra) # 80002a5c <argint>
    8000558a:	0a054863          	bltz	a0,8000563a <sys_open+0xe4>

  begin_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	a2e080e7          	jalr	-1490(ra) # 80003fbc <begin_op>

  if(omode & O_CREATE){
    80005596:	f4c42783          	lw	a5,-180(s0)
    8000559a:	2007f793          	andi	a5,a5,512
    8000559e:	cbdd                	beqz	a5,80005654 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055a0:	4681                	li	a3,0
    800055a2:	4601                	li	a2,0
    800055a4:	4589                	li	a1,2
    800055a6:	f5040513          	addi	a0,s0,-176
    800055aa:	00000097          	auipc	ra,0x0
    800055ae:	972080e7          	jalr	-1678(ra) # 80004f1c <create>
    800055b2:	892a                	mv	s2,a0
    if(ip == 0){
    800055b4:	c959                	beqz	a0,8000564a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055b6:	04491703          	lh	a4,68(s2)
    800055ba:	478d                	li	a5,3
    800055bc:	00f71763          	bne	a4,a5,800055ca <sys_open+0x74>
    800055c0:	04695703          	lhu	a4,70(s2)
    800055c4:	47a5                	li	a5,9
    800055c6:	0ce7ec63          	bltu	a5,a4,8000569e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	e02080e7          	jalr	-510(ra) # 800043cc <filealloc>
    800055d2:	89aa                	mv	s3,a0
    800055d4:	10050263          	beqz	a0,800056d8 <sys_open+0x182>
    800055d8:	00000097          	auipc	ra,0x0
    800055dc:	902080e7          	jalr	-1790(ra) # 80004eda <fdalloc>
    800055e0:	84aa                	mv	s1,a0
    800055e2:	0e054663          	bltz	a0,800056ce <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055e6:	04491703          	lh	a4,68(s2)
    800055ea:	478d                	li	a5,3
    800055ec:	0cf70463          	beq	a4,a5,800056b4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055f0:	4789                	li	a5,2
    800055f2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800055f6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800055fa:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800055fe:	f4c42783          	lw	a5,-180(s0)
    80005602:	0017c713          	xori	a4,a5,1
    80005606:	8b05                	andi	a4,a4,1
    80005608:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000560c:	0037f713          	andi	a4,a5,3
    80005610:	00e03733          	snez	a4,a4
    80005614:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005618:	4007f793          	andi	a5,a5,1024
    8000561c:	c791                	beqz	a5,80005628 <sys_open+0xd2>
    8000561e:	04491703          	lh	a4,68(s2)
    80005622:	4789                	li	a5,2
    80005624:	08f70f63          	beq	a4,a5,800056c2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005628:	854a                	mv	a0,s2
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	082080e7          	jalr	130(ra) # 800036ac <iunlock>
  end_op();
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	a0a080e7          	jalr	-1526(ra) # 8000403c <end_op>

  return fd;
}
    8000563a:	8526                	mv	a0,s1
    8000563c:	70ea                	ld	ra,184(sp)
    8000563e:	744a                	ld	s0,176(sp)
    80005640:	74aa                	ld	s1,168(sp)
    80005642:	790a                	ld	s2,160(sp)
    80005644:	69ea                	ld	s3,152(sp)
    80005646:	6129                	addi	sp,sp,192
    80005648:	8082                	ret
      end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	9f2080e7          	jalr	-1550(ra) # 8000403c <end_op>
      return -1;
    80005652:	b7e5                	j	8000563a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005654:	f5040513          	addi	a0,s0,-176
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	748080e7          	jalr	1864(ra) # 80003da0 <namei>
    80005660:	892a                	mv	s2,a0
    80005662:	c905                	beqz	a0,80005692 <sys_open+0x13c>
    ilock(ip);
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	f86080e7          	jalr	-122(ra) # 800035ea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000566c:	04491703          	lh	a4,68(s2)
    80005670:	4785                	li	a5,1
    80005672:	f4f712e3          	bne	a4,a5,800055b6 <sys_open+0x60>
    80005676:	f4c42783          	lw	a5,-180(s0)
    8000567a:	dba1                	beqz	a5,800055ca <sys_open+0x74>
      iunlockput(ip);
    8000567c:	854a                	mv	a0,s2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	1ce080e7          	jalr	462(ra) # 8000384c <iunlockput>
      end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	9b6080e7          	jalr	-1610(ra) # 8000403c <end_op>
      return -1;
    8000568e:	54fd                	li	s1,-1
    80005690:	b76d                	j	8000563a <sys_open+0xe4>
      end_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	9aa080e7          	jalr	-1622(ra) # 8000403c <end_op>
      return -1;
    8000569a:	54fd                	li	s1,-1
    8000569c:	bf79                	j	8000563a <sys_open+0xe4>
    iunlockput(ip);
    8000569e:	854a                	mv	a0,s2
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	1ac080e7          	jalr	428(ra) # 8000384c <iunlockput>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	994080e7          	jalr	-1644(ra) # 8000403c <end_op>
    return -1;
    800056b0:	54fd                	li	s1,-1
    800056b2:	b761                	j	8000563a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056b4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056b8:	04691783          	lh	a5,70(s2)
    800056bc:	02f99223          	sh	a5,36(s3)
    800056c0:	bf2d                	j	800055fa <sys_open+0xa4>
    itrunc(ip);
    800056c2:	854a                	mv	a0,s2
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	034080e7          	jalr	52(ra) # 800036f8 <itrunc>
    800056cc:	bfb1                	j	80005628 <sys_open+0xd2>
      fileclose(f);
    800056ce:	854e                	mv	a0,s3
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	db8080e7          	jalr	-584(ra) # 80004488 <fileclose>
    iunlockput(ip);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	172080e7          	jalr	370(ra) # 8000384c <iunlockput>
    end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	95a080e7          	jalr	-1702(ra) # 8000403c <end_op>
    return -1;
    800056ea:	54fd                	li	s1,-1
    800056ec:	b7b9                	j	8000563a <sys_open+0xe4>

00000000800056ee <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056ee:	7175                	addi	sp,sp,-144
    800056f0:	e506                	sd	ra,136(sp)
    800056f2:	e122                	sd	s0,128(sp)
    800056f4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	8c6080e7          	jalr	-1850(ra) # 80003fbc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800056fe:	08000613          	li	a2,128
    80005702:	f7040593          	addi	a1,s0,-144
    80005706:	4501                	li	a0,0
    80005708:	ffffd097          	auipc	ra,0xffffd
    8000570c:	398080e7          	jalr	920(ra) # 80002aa0 <argstr>
    80005710:	02054963          	bltz	a0,80005742 <sys_mkdir+0x54>
    80005714:	4681                	li	a3,0
    80005716:	4601                	li	a2,0
    80005718:	4585                	li	a1,1
    8000571a:	f7040513          	addi	a0,s0,-144
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	7fe080e7          	jalr	2046(ra) # 80004f1c <create>
    80005726:	cd11                	beqz	a0,80005742 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	124080e7          	jalr	292(ra) # 8000384c <iunlockput>
  end_op();
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	90c080e7          	jalr	-1780(ra) # 8000403c <end_op>
  return 0;
    80005738:	4501                	li	a0,0
}
    8000573a:	60aa                	ld	ra,136(sp)
    8000573c:	640a                	ld	s0,128(sp)
    8000573e:	6149                	addi	sp,sp,144
    80005740:	8082                	ret
    end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	8fa080e7          	jalr	-1798(ra) # 8000403c <end_op>
    return -1;
    8000574a:	557d                	li	a0,-1
    8000574c:	b7fd                	j	8000573a <sys_mkdir+0x4c>

000000008000574e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000574e:	7135                	addi	sp,sp,-160
    80005750:	ed06                	sd	ra,152(sp)
    80005752:	e922                	sd	s0,144(sp)
    80005754:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	866080e7          	jalr	-1946(ra) # 80003fbc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000575e:	08000613          	li	a2,128
    80005762:	f7040593          	addi	a1,s0,-144
    80005766:	4501                	li	a0,0
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	338080e7          	jalr	824(ra) # 80002aa0 <argstr>
    80005770:	04054a63          	bltz	a0,800057c4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005774:	f6c40593          	addi	a1,s0,-148
    80005778:	4505                	li	a0,1
    8000577a:	ffffd097          	auipc	ra,0xffffd
    8000577e:	2e2080e7          	jalr	738(ra) # 80002a5c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005782:	04054163          	bltz	a0,800057c4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005786:	f6840593          	addi	a1,s0,-152
    8000578a:	4509                	li	a0,2
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	2d0080e7          	jalr	720(ra) # 80002a5c <argint>
     argint(1, &major) < 0 ||
    80005794:	02054863          	bltz	a0,800057c4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005798:	f6841683          	lh	a3,-152(s0)
    8000579c:	f6c41603          	lh	a2,-148(s0)
    800057a0:	458d                	li	a1,3
    800057a2:	f7040513          	addi	a0,s0,-144
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	776080e7          	jalr	1910(ra) # 80004f1c <create>
     argint(2, &minor) < 0 ||
    800057ae:	c919                	beqz	a0,800057c4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	09c080e7          	jalr	156(ra) # 8000384c <iunlockput>
  end_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	884080e7          	jalr	-1916(ra) # 8000403c <end_op>
  return 0;
    800057c0:	4501                	li	a0,0
    800057c2:	a031                	j	800057ce <sys_mknod+0x80>
    end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	878080e7          	jalr	-1928(ra) # 8000403c <end_op>
    return -1;
    800057cc:	557d                	li	a0,-1
}
    800057ce:	60ea                	ld	ra,152(sp)
    800057d0:	644a                	ld	s0,144(sp)
    800057d2:	610d                	addi	sp,sp,160
    800057d4:	8082                	ret

00000000800057d6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057d6:	7135                	addi	sp,sp,-160
    800057d8:	ed06                	sd	ra,152(sp)
    800057da:	e922                	sd	s0,144(sp)
    800057dc:	e526                	sd	s1,136(sp)
    800057de:	e14a                	sd	s2,128(sp)
    800057e0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057e2:	ffffc097          	auipc	ra,0xffffc
    800057e6:	1ce080e7          	jalr	462(ra) # 800019b0 <myproc>
    800057ea:	892a                	mv	s2,a0
  
  begin_op();
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	7d0080e7          	jalr	2000(ra) # 80003fbc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057f4:	08000613          	li	a2,128
    800057f8:	f6040593          	addi	a1,s0,-160
    800057fc:	4501                	li	a0,0
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	2a2080e7          	jalr	674(ra) # 80002aa0 <argstr>
    80005806:	04054b63          	bltz	a0,8000585c <sys_chdir+0x86>
    8000580a:	f6040513          	addi	a0,s0,-160
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	592080e7          	jalr	1426(ra) # 80003da0 <namei>
    80005816:	84aa                	mv	s1,a0
    80005818:	c131                	beqz	a0,8000585c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	dd0080e7          	jalr	-560(ra) # 800035ea <ilock>
  if(ip->type != T_DIR){
    80005822:	04449703          	lh	a4,68(s1)
    80005826:	4785                	li	a5,1
    80005828:	04f71063          	bne	a4,a5,80005868 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	e7e080e7          	jalr	-386(ra) # 800036ac <iunlock>
  iput(p->cwd);
    80005836:	15093503          	ld	a0,336(s2)
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	f6a080e7          	jalr	-150(ra) # 800037a4 <iput>
  end_op();
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	7fa080e7          	jalr	2042(ra) # 8000403c <end_op>
  p->cwd = ip;
    8000584a:	14993823          	sd	s1,336(s2)
  return 0;
    8000584e:	4501                	li	a0,0
}
    80005850:	60ea                	ld	ra,152(sp)
    80005852:	644a                	ld	s0,144(sp)
    80005854:	64aa                	ld	s1,136(sp)
    80005856:	690a                	ld	s2,128(sp)
    80005858:	610d                	addi	sp,sp,160
    8000585a:	8082                	ret
    end_op();
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	7e0080e7          	jalr	2016(ra) # 8000403c <end_op>
    return -1;
    80005864:	557d                	li	a0,-1
    80005866:	b7ed                	j	80005850 <sys_chdir+0x7a>
    iunlockput(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	fe2080e7          	jalr	-30(ra) # 8000384c <iunlockput>
    end_op();
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	7ca080e7          	jalr	1994(ra) # 8000403c <end_op>
    return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	bfd1                	j	80005850 <sys_chdir+0x7a>

000000008000587e <sys_exec>:

uint64
sys_exec(void)
{
    8000587e:	7145                	addi	sp,sp,-464
    80005880:	e786                	sd	ra,456(sp)
    80005882:	e3a2                	sd	s0,448(sp)
    80005884:	ff26                	sd	s1,440(sp)
    80005886:	fb4a                	sd	s2,432(sp)
    80005888:	f74e                	sd	s3,424(sp)
    8000588a:	f352                	sd	s4,416(sp)
    8000588c:	ef56                	sd	s5,408(sp)
    8000588e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005890:	08000613          	li	a2,128
    80005894:	f4040593          	addi	a1,s0,-192
    80005898:	4501                	li	a0,0
    8000589a:	ffffd097          	auipc	ra,0xffffd
    8000589e:	206080e7          	jalr	518(ra) # 80002aa0 <argstr>
    return -1;
    800058a2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058a4:	0c054a63          	bltz	a0,80005978 <sys_exec+0xfa>
    800058a8:	e3840593          	addi	a1,s0,-456
    800058ac:	4505                	li	a0,1
    800058ae:	ffffd097          	auipc	ra,0xffffd
    800058b2:	1d0080e7          	jalr	464(ra) # 80002a7e <argaddr>
    800058b6:	0c054163          	bltz	a0,80005978 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058ba:	10000613          	li	a2,256
    800058be:	4581                	li	a1,0
    800058c0:	e4040513          	addi	a0,s0,-448
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	41c080e7          	jalr	1052(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058cc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058d0:	89a6                	mv	s3,s1
    800058d2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058d4:	02000a13          	li	s4,32
    800058d8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058dc:	00391513          	slli	a0,s2,0x3
    800058e0:	e3040593          	addi	a1,s0,-464
    800058e4:	e3843783          	ld	a5,-456(s0)
    800058e8:	953e                	add	a0,a0,a5
    800058ea:	ffffd097          	auipc	ra,0xffffd
    800058ee:	0d8080e7          	jalr	216(ra) # 800029c2 <fetchaddr>
    800058f2:	02054a63          	bltz	a0,80005926 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800058f6:	e3043783          	ld	a5,-464(s0)
    800058fa:	c3b9                	beqz	a5,80005940 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800058fc:	ffffb097          	auipc	ra,0xffffb
    80005900:	1f8080e7          	jalr	504(ra) # 80000af4 <kalloc>
    80005904:	85aa                	mv	a1,a0
    80005906:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000590a:	cd11                	beqz	a0,80005926 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000590c:	6605                	lui	a2,0x1
    8000590e:	e3043503          	ld	a0,-464(s0)
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	102080e7          	jalr	258(ra) # 80002a14 <fetchstr>
    8000591a:	00054663          	bltz	a0,80005926 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000591e:	0905                	addi	s2,s2,1
    80005920:	09a1                	addi	s3,s3,8
    80005922:	fb491be3          	bne	s2,s4,800058d8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005926:	10048913          	addi	s2,s1,256
    8000592a:	6088                	ld	a0,0(s1)
    8000592c:	c529                	beqz	a0,80005976 <sys_exec+0xf8>
    kfree(argv[i]);
    8000592e:	ffffb097          	auipc	ra,0xffffb
    80005932:	0ca080e7          	jalr	202(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005936:	04a1                	addi	s1,s1,8
    80005938:	ff2499e3          	bne	s1,s2,8000592a <sys_exec+0xac>
  return -1;
    8000593c:	597d                	li	s2,-1
    8000593e:	a82d                	j	80005978 <sys_exec+0xfa>
      argv[i] = 0;
    80005940:	0a8e                	slli	s5,s5,0x3
    80005942:	fc040793          	addi	a5,s0,-64
    80005946:	9abe                	add	s5,s5,a5
    80005948:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000594c:	e4040593          	addi	a1,s0,-448
    80005950:	f4040513          	addi	a0,s0,-192
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	194080e7          	jalr	404(ra) # 80004ae8 <exec>
    8000595c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000595e:	10048993          	addi	s3,s1,256
    80005962:	6088                	ld	a0,0(s1)
    80005964:	c911                	beqz	a0,80005978 <sys_exec+0xfa>
    kfree(argv[i]);
    80005966:	ffffb097          	auipc	ra,0xffffb
    8000596a:	092080e7          	jalr	146(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000596e:	04a1                	addi	s1,s1,8
    80005970:	ff3499e3          	bne	s1,s3,80005962 <sys_exec+0xe4>
    80005974:	a011                	j	80005978 <sys_exec+0xfa>
  return -1;
    80005976:	597d                	li	s2,-1
}
    80005978:	854a                	mv	a0,s2
    8000597a:	60be                	ld	ra,456(sp)
    8000597c:	641e                	ld	s0,448(sp)
    8000597e:	74fa                	ld	s1,440(sp)
    80005980:	795a                	ld	s2,432(sp)
    80005982:	79ba                	ld	s3,424(sp)
    80005984:	7a1a                	ld	s4,416(sp)
    80005986:	6afa                	ld	s5,408(sp)
    80005988:	6179                	addi	sp,sp,464
    8000598a:	8082                	ret

000000008000598c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000598c:	7139                	addi	sp,sp,-64
    8000598e:	fc06                	sd	ra,56(sp)
    80005990:	f822                	sd	s0,48(sp)
    80005992:	f426                	sd	s1,40(sp)
    80005994:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005996:	ffffc097          	auipc	ra,0xffffc
    8000599a:	01a080e7          	jalr	26(ra) # 800019b0 <myproc>
    8000599e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059a0:	fd840593          	addi	a1,s0,-40
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	0d8080e7          	jalr	216(ra) # 80002a7e <argaddr>
    return -1;
    800059ae:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059b0:	0e054063          	bltz	a0,80005a90 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059b4:	fc840593          	addi	a1,s0,-56
    800059b8:	fd040513          	addi	a0,s0,-48
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	dfc080e7          	jalr	-516(ra) # 800047b8 <pipealloc>
    return -1;
    800059c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059c6:	0c054563          	bltz	a0,80005a90 <sys_pipe+0x104>
  fd0 = -1;
    800059ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059ce:	fd043503          	ld	a0,-48(s0)
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	508080e7          	jalr	1288(ra) # 80004eda <fdalloc>
    800059da:	fca42223          	sw	a0,-60(s0)
    800059de:	08054c63          	bltz	a0,80005a76 <sys_pipe+0xea>
    800059e2:	fc843503          	ld	a0,-56(s0)
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	4f4080e7          	jalr	1268(ra) # 80004eda <fdalloc>
    800059ee:	fca42023          	sw	a0,-64(s0)
    800059f2:	06054863          	bltz	a0,80005a62 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059f6:	4691                	li	a3,4
    800059f8:	fc440613          	addi	a2,s0,-60
    800059fc:	fd843583          	ld	a1,-40(s0)
    80005a00:	68a8                	ld	a0,80(s1)
    80005a02:	ffffc097          	auipc	ra,0xffffc
    80005a06:	c70080e7          	jalr	-912(ra) # 80001672 <copyout>
    80005a0a:	02054063          	bltz	a0,80005a2a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a0e:	4691                	li	a3,4
    80005a10:	fc040613          	addi	a2,s0,-64
    80005a14:	fd843583          	ld	a1,-40(s0)
    80005a18:	0591                	addi	a1,a1,4
    80005a1a:	68a8                	ld	a0,80(s1)
    80005a1c:	ffffc097          	auipc	ra,0xffffc
    80005a20:	c56080e7          	jalr	-938(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a24:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a26:	06055563          	bgez	a0,80005a90 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a2a:	fc442783          	lw	a5,-60(s0)
    80005a2e:	07e9                	addi	a5,a5,26
    80005a30:	078e                	slli	a5,a5,0x3
    80005a32:	97a6                	add	a5,a5,s1
    80005a34:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a38:	fc042503          	lw	a0,-64(s0)
    80005a3c:	0569                	addi	a0,a0,26
    80005a3e:	050e                	slli	a0,a0,0x3
    80005a40:	9526                	add	a0,a0,s1
    80005a42:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a46:	fd043503          	ld	a0,-48(s0)
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	a3e080e7          	jalr	-1474(ra) # 80004488 <fileclose>
    fileclose(wf);
    80005a52:	fc843503          	ld	a0,-56(s0)
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	a32080e7          	jalr	-1486(ra) # 80004488 <fileclose>
    return -1;
    80005a5e:	57fd                	li	a5,-1
    80005a60:	a805                	j	80005a90 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a62:	fc442783          	lw	a5,-60(s0)
    80005a66:	0007c863          	bltz	a5,80005a76 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a6a:	01a78513          	addi	a0,a5,26
    80005a6e:	050e                	slli	a0,a0,0x3
    80005a70:	9526                	add	a0,a0,s1
    80005a72:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a76:	fd043503          	ld	a0,-48(s0)
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	a0e080e7          	jalr	-1522(ra) # 80004488 <fileclose>
    fileclose(wf);
    80005a82:	fc843503          	ld	a0,-56(s0)
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	a02080e7          	jalr	-1534(ra) # 80004488 <fileclose>
    return -1;
    80005a8e:	57fd                	li	a5,-1
}
    80005a90:	853e                	mv	a0,a5
    80005a92:	70e2                	ld	ra,56(sp)
    80005a94:	7442                	ld	s0,48(sp)
    80005a96:	74a2                	ld	s1,40(sp)
    80005a98:	6121                	addi	sp,sp,64
    80005a9a:	8082                	ret
    80005a9c:	0000                	unimp
	...

0000000080005aa0 <kernelvec>:
    80005aa0:	7111                	addi	sp,sp,-256
    80005aa2:	e006                	sd	ra,0(sp)
    80005aa4:	e40a                	sd	sp,8(sp)
    80005aa6:	e80e                	sd	gp,16(sp)
    80005aa8:	ec12                	sd	tp,24(sp)
    80005aaa:	f016                	sd	t0,32(sp)
    80005aac:	f41a                	sd	t1,40(sp)
    80005aae:	f81e                	sd	t2,48(sp)
    80005ab0:	fc22                	sd	s0,56(sp)
    80005ab2:	e0a6                	sd	s1,64(sp)
    80005ab4:	e4aa                	sd	a0,72(sp)
    80005ab6:	e8ae                	sd	a1,80(sp)
    80005ab8:	ecb2                	sd	a2,88(sp)
    80005aba:	f0b6                	sd	a3,96(sp)
    80005abc:	f4ba                	sd	a4,104(sp)
    80005abe:	f8be                	sd	a5,112(sp)
    80005ac0:	fcc2                	sd	a6,120(sp)
    80005ac2:	e146                	sd	a7,128(sp)
    80005ac4:	e54a                	sd	s2,136(sp)
    80005ac6:	e94e                	sd	s3,144(sp)
    80005ac8:	ed52                	sd	s4,152(sp)
    80005aca:	f156                	sd	s5,160(sp)
    80005acc:	f55a                	sd	s6,168(sp)
    80005ace:	f95e                	sd	s7,176(sp)
    80005ad0:	fd62                	sd	s8,184(sp)
    80005ad2:	e1e6                	sd	s9,192(sp)
    80005ad4:	e5ea                	sd	s10,200(sp)
    80005ad6:	e9ee                	sd	s11,208(sp)
    80005ad8:	edf2                	sd	t3,216(sp)
    80005ada:	f1f6                	sd	t4,224(sp)
    80005adc:	f5fa                	sd	t5,232(sp)
    80005ade:	f9fe                	sd	t6,240(sp)
    80005ae0:	daffc0ef          	jal	ra,8000288e <kerneltrap>
    80005ae4:	6082                	ld	ra,0(sp)
    80005ae6:	6122                	ld	sp,8(sp)
    80005ae8:	61c2                	ld	gp,16(sp)
    80005aea:	7282                	ld	t0,32(sp)
    80005aec:	7322                	ld	t1,40(sp)
    80005aee:	73c2                	ld	t2,48(sp)
    80005af0:	7462                	ld	s0,56(sp)
    80005af2:	6486                	ld	s1,64(sp)
    80005af4:	6526                	ld	a0,72(sp)
    80005af6:	65c6                	ld	a1,80(sp)
    80005af8:	6666                	ld	a2,88(sp)
    80005afa:	7686                	ld	a3,96(sp)
    80005afc:	7726                	ld	a4,104(sp)
    80005afe:	77c6                	ld	a5,112(sp)
    80005b00:	7866                	ld	a6,120(sp)
    80005b02:	688a                	ld	a7,128(sp)
    80005b04:	692a                	ld	s2,136(sp)
    80005b06:	69ca                	ld	s3,144(sp)
    80005b08:	6a6a                	ld	s4,152(sp)
    80005b0a:	7a8a                	ld	s5,160(sp)
    80005b0c:	7b2a                	ld	s6,168(sp)
    80005b0e:	7bca                	ld	s7,176(sp)
    80005b10:	7c6a                	ld	s8,184(sp)
    80005b12:	6c8e                	ld	s9,192(sp)
    80005b14:	6d2e                	ld	s10,200(sp)
    80005b16:	6dce                	ld	s11,208(sp)
    80005b18:	6e6e                	ld	t3,216(sp)
    80005b1a:	7e8e                	ld	t4,224(sp)
    80005b1c:	7f2e                	ld	t5,232(sp)
    80005b1e:	7fce                	ld	t6,240(sp)
    80005b20:	6111                	addi	sp,sp,256
    80005b22:	10200073          	sret
    80005b26:	00000013          	nop
    80005b2a:	00000013          	nop
    80005b2e:	0001                	nop

0000000080005b30 <timervec>:
    80005b30:	34051573          	csrrw	a0,mscratch,a0
    80005b34:	e10c                	sd	a1,0(a0)
    80005b36:	e510                	sd	a2,8(a0)
    80005b38:	e914                	sd	a3,16(a0)
    80005b3a:	6d0c                	ld	a1,24(a0)
    80005b3c:	7110                	ld	a2,32(a0)
    80005b3e:	6194                	ld	a3,0(a1)
    80005b40:	96b2                	add	a3,a3,a2
    80005b42:	e194                	sd	a3,0(a1)
    80005b44:	4589                	li	a1,2
    80005b46:	14459073          	csrw	sip,a1
    80005b4a:	6914                	ld	a3,16(a0)
    80005b4c:	6510                	ld	a2,8(a0)
    80005b4e:	610c                	ld	a1,0(a0)
    80005b50:	34051573          	csrrw	a0,mscratch,a0
    80005b54:	30200073          	mret
	...

0000000080005b5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b5a:	1141                	addi	sp,sp,-16
    80005b5c:	e422                	sd	s0,8(sp)
    80005b5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b60:	0c0007b7          	lui	a5,0xc000
    80005b64:	4705                	li	a4,1
    80005b66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b68:	c3d8                	sw	a4,4(a5)
}
    80005b6a:	6422                	ld	s0,8(sp)
    80005b6c:	0141                	addi	sp,sp,16
    80005b6e:	8082                	ret

0000000080005b70 <plicinithart>:

void
plicinithart(void)
{
    80005b70:	1141                	addi	sp,sp,-16
    80005b72:	e406                	sd	ra,8(sp)
    80005b74:	e022                	sd	s0,0(sp)
    80005b76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	e0c080e7          	jalr	-500(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b80:	0085171b          	slliw	a4,a0,0x8
    80005b84:	0c0027b7          	lui	a5,0xc002
    80005b88:	97ba                	add	a5,a5,a4
    80005b8a:	40200713          	li	a4,1026
    80005b8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005b92:	00d5151b          	slliw	a0,a0,0xd
    80005b96:	0c2017b7          	lui	a5,0xc201
    80005b9a:	953e                	add	a0,a0,a5
    80005b9c:	00052023          	sw	zero,0(a0)
}
    80005ba0:	60a2                	ld	ra,8(sp)
    80005ba2:	6402                	ld	s0,0(sp)
    80005ba4:	0141                	addi	sp,sp,16
    80005ba6:	8082                	ret

0000000080005ba8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ba8:	1141                	addi	sp,sp,-16
    80005baa:	e406                	sd	ra,8(sp)
    80005bac:	e022                	sd	s0,0(sp)
    80005bae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	dd4080e7          	jalr	-556(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bb8:	00d5179b          	slliw	a5,a0,0xd
    80005bbc:	0c201537          	lui	a0,0xc201
    80005bc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005bc2:	4148                	lw	a0,4(a0)
    80005bc4:	60a2                	ld	ra,8(sp)
    80005bc6:	6402                	ld	s0,0(sp)
    80005bc8:	0141                	addi	sp,sp,16
    80005bca:	8082                	ret

0000000080005bcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bcc:	1101                	addi	sp,sp,-32
    80005bce:	ec06                	sd	ra,24(sp)
    80005bd0:	e822                	sd	s0,16(sp)
    80005bd2:	e426                	sd	s1,8(sp)
    80005bd4:	1000                	addi	s0,sp,32
    80005bd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	dac080e7          	jalr	-596(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005be0:	00d5151b          	slliw	a0,a0,0xd
    80005be4:	0c2017b7          	lui	a5,0xc201
    80005be8:	97aa                	add	a5,a5,a0
    80005bea:	c3c4                	sw	s1,4(a5)
}
    80005bec:	60e2                	ld	ra,24(sp)
    80005bee:	6442                	ld	s0,16(sp)
    80005bf0:	64a2                	ld	s1,8(sp)
    80005bf2:	6105                	addi	sp,sp,32
    80005bf4:	8082                	ret

0000000080005bf6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005bf6:	1141                	addi	sp,sp,-16
    80005bf8:	e406                	sd	ra,8(sp)
    80005bfa:	e022                	sd	s0,0(sp)
    80005bfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005bfe:	479d                	li	a5,7
    80005c00:	06a7c963          	blt	a5,a0,80005c72 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c04:	0001d797          	auipc	a5,0x1d
    80005c08:	3fc78793          	addi	a5,a5,1020 # 80023000 <disk>
    80005c0c:	00a78733          	add	a4,a5,a0
    80005c10:	6789                	lui	a5,0x2
    80005c12:	97ba                	add	a5,a5,a4
    80005c14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c18:	e7ad                	bnez	a5,80005c82 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c1a:	00451793          	slli	a5,a0,0x4
    80005c1e:	0001f717          	auipc	a4,0x1f
    80005c22:	3e270713          	addi	a4,a4,994 # 80025000 <disk+0x2000>
    80005c26:	6314                	ld	a3,0(a4)
    80005c28:	96be                	add	a3,a3,a5
    80005c2a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c2e:	6314                	ld	a3,0(a4)
    80005c30:	96be                	add	a3,a3,a5
    80005c32:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c36:	6314                	ld	a3,0(a4)
    80005c38:	96be                	add	a3,a3,a5
    80005c3a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c3e:	6318                	ld	a4,0(a4)
    80005c40:	97ba                	add	a5,a5,a4
    80005c42:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c46:	0001d797          	auipc	a5,0x1d
    80005c4a:	3ba78793          	addi	a5,a5,954 # 80023000 <disk>
    80005c4e:	97aa                	add	a5,a5,a0
    80005c50:	6509                	lui	a0,0x2
    80005c52:	953e                	add	a0,a0,a5
    80005c54:	4785                	li	a5,1
    80005c56:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c5a:	0001f517          	auipc	a0,0x1f
    80005c5e:	3be50513          	addi	a0,a0,958 # 80025018 <disk+0x2018>
    80005c62:	ffffc097          	auipc	ra,0xffffc
    80005c66:	596080e7          	jalr	1430(ra) # 800021f8 <wakeup>
}
    80005c6a:	60a2                	ld	ra,8(sp)
    80005c6c:	6402                	ld	s0,0(sp)
    80005c6e:	0141                	addi	sp,sp,16
    80005c70:	8082                	ret
    panic("free_desc 1");
    80005c72:	00003517          	auipc	a0,0x3
    80005c76:	b0650513          	addi	a0,a0,-1274 # 80008778 <syscalls+0x330>
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	8c4080e7          	jalr	-1852(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005c82:	00003517          	auipc	a0,0x3
    80005c86:	b0650513          	addi	a0,a0,-1274 # 80008788 <syscalls+0x340>
    80005c8a:	ffffb097          	auipc	ra,0xffffb
    80005c8e:	8b4080e7          	jalr	-1868(ra) # 8000053e <panic>

0000000080005c92 <virtio_disk_init>:
{
    80005c92:	1101                	addi	sp,sp,-32
    80005c94:	ec06                	sd	ra,24(sp)
    80005c96:	e822                	sd	s0,16(sp)
    80005c98:	e426                	sd	s1,8(sp)
    80005c9a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005c9c:	00003597          	auipc	a1,0x3
    80005ca0:	afc58593          	addi	a1,a1,-1284 # 80008798 <syscalls+0x350>
    80005ca4:	0001f517          	auipc	a0,0x1f
    80005ca8:	48450513          	addi	a0,a0,1156 # 80025128 <disk+0x2128>
    80005cac:	ffffb097          	auipc	ra,0xffffb
    80005cb0:	ea8080e7          	jalr	-344(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cb4:	100017b7          	lui	a5,0x10001
    80005cb8:	4398                	lw	a4,0(a5)
    80005cba:	2701                	sext.w	a4,a4
    80005cbc:	747277b7          	lui	a5,0x74727
    80005cc0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cc4:	0ef71163          	bne	a4,a5,80005da6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cc8:	100017b7          	lui	a5,0x10001
    80005ccc:	43dc                	lw	a5,4(a5)
    80005cce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cd0:	4705                	li	a4,1
    80005cd2:	0ce79a63          	bne	a5,a4,80005da6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cd6:	100017b7          	lui	a5,0x10001
    80005cda:	479c                	lw	a5,8(a5)
    80005cdc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cde:	4709                	li	a4,2
    80005ce0:	0ce79363          	bne	a5,a4,80005da6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ce4:	100017b7          	lui	a5,0x10001
    80005ce8:	47d8                	lw	a4,12(a5)
    80005cea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cec:	554d47b7          	lui	a5,0x554d4
    80005cf0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cf4:	0af71963          	bne	a4,a5,80005da6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cf8:	100017b7          	lui	a5,0x10001
    80005cfc:	4705                	li	a4,1
    80005cfe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d00:	470d                	li	a4,3
    80005d02:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d04:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d06:	c7ffe737          	lui	a4,0xc7ffe
    80005d0a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d0e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d10:	2701                	sext.w	a4,a4
    80005d12:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d14:	472d                	li	a4,11
    80005d16:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d18:	473d                	li	a4,15
    80005d1a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d1c:	6705                	lui	a4,0x1
    80005d1e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d24:	5bdc                	lw	a5,52(a5)
    80005d26:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d28:	c7d9                	beqz	a5,80005db6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d2a:	471d                	li	a4,7
    80005d2c:	08f77d63          	bgeu	a4,a5,80005dc6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d30:	100014b7          	lui	s1,0x10001
    80005d34:	47a1                	li	a5,8
    80005d36:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d38:	6609                	lui	a2,0x2
    80005d3a:	4581                	li	a1,0
    80005d3c:	0001d517          	auipc	a0,0x1d
    80005d40:	2c450513          	addi	a0,a0,708 # 80023000 <disk>
    80005d44:	ffffb097          	auipc	ra,0xffffb
    80005d48:	f9c080e7          	jalr	-100(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d4c:	0001d717          	auipc	a4,0x1d
    80005d50:	2b470713          	addi	a4,a4,692 # 80023000 <disk>
    80005d54:	00c75793          	srli	a5,a4,0xc
    80005d58:	2781                	sext.w	a5,a5
    80005d5a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d5c:	0001f797          	auipc	a5,0x1f
    80005d60:	2a478793          	addi	a5,a5,676 # 80025000 <disk+0x2000>
    80005d64:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d66:	0001d717          	auipc	a4,0x1d
    80005d6a:	31a70713          	addi	a4,a4,794 # 80023080 <disk+0x80>
    80005d6e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d70:	0001e717          	auipc	a4,0x1e
    80005d74:	29070713          	addi	a4,a4,656 # 80024000 <disk+0x1000>
    80005d78:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d7a:	4705                	li	a4,1
    80005d7c:	00e78c23          	sb	a4,24(a5)
    80005d80:	00e78ca3          	sb	a4,25(a5)
    80005d84:	00e78d23          	sb	a4,26(a5)
    80005d88:	00e78da3          	sb	a4,27(a5)
    80005d8c:	00e78e23          	sb	a4,28(a5)
    80005d90:	00e78ea3          	sb	a4,29(a5)
    80005d94:	00e78f23          	sb	a4,30(a5)
    80005d98:	00e78fa3          	sb	a4,31(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret
    panic("could not find virtio disk");
    80005da6:	00003517          	auipc	a0,0x3
    80005daa:	a0250513          	addi	a0,a0,-1534 # 800087a8 <syscalls+0x360>
    80005dae:	ffffa097          	auipc	ra,0xffffa
    80005db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005db6:	00003517          	auipc	a0,0x3
    80005dba:	a1250513          	addi	a0,a0,-1518 # 800087c8 <syscalls+0x380>
    80005dbe:	ffffa097          	auipc	ra,0xffffa
    80005dc2:	780080e7          	jalr	1920(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005dc6:	00003517          	auipc	a0,0x3
    80005dca:	a2250513          	addi	a0,a0,-1502 # 800087e8 <syscalls+0x3a0>
    80005dce:	ffffa097          	auipc	ra,0xffffa
    80005dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>

0000000080005dd6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005dd6:	7159                	addi	sp,sp,-112
    80005dd8:	f486                	sd	ra,104(sp)
    80005dda:	f0a2                	sd	s0,96(sp)
    80005ddc:	eca6                	sd	s1,88(sp)
    80005dde:	e8ca                	sd	s2,80(sp)
    80005de0:	e4ce                	sd	s3,72(sp)
    80005de2:	e0d2                	sd	s4,64(sp)
    80005de4:	fc56                	sd	s5,56(sp)
    80005de6:	f85a                	sd	s6,48(sp)
    80005de8:	f45e                	sd	s7,40(sp)
    80005dea:	f062                	sd	s8,32(sp)
    80005dec:	ec66                	sd	s9,24(sp)
    80005dee:	e86a                	sd	s10,16(sp)
    80005df0:	1880                	addi	s0,sp,112
    80005df2:	892a                	mv	s2,a0
    80005df4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005df6:	00c52c83          	lw	s9,12(a0)
    80005dfa:	001c9c9b          	slliw	s9,s9,0x1
    80005dfe:	1c82                	slli	s9,s9,0x20
    80005e00:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e04:	0001f517          	auipc	a0,0x1f
    80005e08:	32450513          	addi	a0,a0,804 # 80025128 <disk+0x2128>
    80005e0c:	ffffb097          	auipc	ra,0xffffb
    80005e10:	dd8080e7          	jalr	-552(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e14:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e16:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e18:	0001db97          	auipc	s7,0x1d
    80005e1c:	1e8b8b93          	addi	s7,s7,488 # 80023000 <disk>
    80005e20:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e22:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e24:	8a4e                	mv	s4,s3
    80005e26:	a051                	j	80005eaa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e28:	00fb86b3          	add	a3,s7,a5
    80005e2c:	96da                	add	a3,a3,s6
    80005e2e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e32:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e34:	0207c563          	bltz	a5,80005e5e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e38:	2485                	addiw	s1,s1,1
    80005e3a:	0711                	addi	a4,a4,4
    80005e3c:	25548063          	beq	s1,s5,8000607c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005e40:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005e42:	0001f697          	auipc	a3,0x1f
    80005e46:	1d668693          	addi	a3,a3,470 # 80025018 <disk+0x2018>
    80005e4a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005e4c:	0006c583          	lbu	a1,0(a3)
    80005e50:	fde1                	bnez	a1,80005e28 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e52:	2785                	addiw	a5,a5,1
    80005e54:	0685                	addi	a3,a3,1
    80005e56:	ff879be3          	bne	a5,s8,80005e4c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e5a:	57fd                	li	a5,-1
    80005e5c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005e5e:	02905a63          	blez	s1,80005e92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e62:	f9042503          	lw	a0,-112(s0)
    80005e66:	00000097          	auipc	ra,0x0
    80005e6a:	d90080e7          	jalr	-624(ra) # 80005bf6 <free_desc>
      for(int j = 0; j < i; j++)
    80005e6e:	4785                	li	a5,1
    80005e70:	0297d163          	bge	a5,s1,80005e92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e74:	f9442503          	lw	a0,-108(s0)
    80005e78:	00000097          	auipc	ra,0x0
    80005e7c:	d7e080e7          	jalr	-642(ra) # 80005bf6 <free_desc>
      for(int j = 0; j < i; j++)
    80005e80:	4789                	li	a5,2
    80005e82:	0097d863          	bge	a5,s1,80005e92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e86:	f9842503          	lw	a0,-104(s0)
    80005e8a:	00000097          	auipc	ra,0x0
    80005e8e:	d6c080e7          	jalr	-660(ra) # 80005bf6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e92:	0001f597          	auipc	a1,0x1f
    80005e96:	29658593          	addi	a1,a1,662 # 80025128 <disk+0x2128>
    80005e9a:	0001f517          	auipc	a0,0x1f
    80005e9e:	17e50513          	addi	a0,a0,382 # 80025018 <disk+0x2018>
    80005ea2:	ffffc097          	auipc	ra,0xffffc
    80005ea6:	1ca080e7          	jalr	458(ra) # 8000206c <sleep>
  for(int i = 0; i < 3; i++){
    80005eaa:	f9040713          	addi	a4,s0,-112
    80005eae:	84ce                	mv	s1,s3
    80005eb0:	bf41                	j	80005e40 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005eb2:	20058713          	addi	a4,a1,512
    80005eb6:	00471693          	slli	a3,a4,0x4
    80005eba:	0001d717          	auipc	a4,0x1d
    80005ebe:	14670713          	addi	a4,a4,326 # 80023000 <disk>
    80005ec2:	9736                	add	a4,a4,a3
    80005ec4:	4685                	li	a3,1
    80005ec6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005eca:	20058713          	addi	a4,a1,512
    80005ece:	00471693          	slli	a3,a4,0x4
    80005ed2:	0001d717          	auipc	a4,0x1d
    80005ed6:	12e70713          	addi	a4,a4,302 # 80023000 <disk>
    80005eda:	9736                	add	a4,a4,a3
    80005edc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005ee0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005ee4:	7679                	lui	a2,0xffffe
    80005ee6:	963e                	add	a2,a2,a5
    80005ee8:	0001f697          	auipc	a3,0x1f
    80005eec:	11868693          	addi	a3,a3,280 # 80025000 <disk+0x2000>
    80005ef0:	6298                	ld	a4,0(a3)
    80005ef2:	9732                	add	a4,a4,a2
    80005ef4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005ef6:	6298                	ld	a4,0(a3)
    80005ef8:	9732                	add	a4,a4,a2
    80005efa:	4541                	li	a0,16
    80005efc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005efe:	6298                	ld	a4,0(a3)
    80005f00:	9732                	add	a4,a4,a2
    80005f02:	4505                	li	a0,1
    80005f04:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f08:	f9442703          	lw	a4,-108(s0)
    80005f0c:	6288                	ld	a0,0(a3)
    80005f0e:	962a                	add	a2,a2,a0
    80005f10:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f14:	0712                	slli	a4,a4,0x4
    80005f16:	6290                	ld	a2,0(a3)
    80005f18:	963a                	add	a2,a2,a4
    80005f1a:	05890513          	addi	a0,s2,88
    80005f1e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f20:	6294                	ld	a3,0(a3)
    80005f22:	96ba                	add	a3,a3,a4
    80005f24:	40000613          	li	a2,1024
    80005f28:	c690                	sw	a2,8(a3)
  if(write)
    80005f2a:	140d0063          	beqz	s10,8000606a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f2e:	0001f697          	auipc	a3,0x1f
    80005f32:	0d26b683          	ld	a3,210(a3) # 80025000 <disk+0x2000>
    80005f36:	96ba                	add	a3,a3,a4
    80005f38:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f3c:	0001d817          	auipc	a6,0x1d
    80005f40:	0c480813          	addi	a6,a6,196 # 80023000 <disk>
    80005f44:	0001f517          	auipc	a0,0x1f
    80005f48:	0bc50513          	addi	a0,a0,188 # 80025000 <disk+0x2000>
    80005f4c:	6114                	ld	a3,0(a0)
    80005f4e:	96ba                	add	a3,a3,a4
    80005f50:	00c6d603          	lhu	a2,12(a3)
    80005f54:	00166613          	ori	a2,a2,1
    80005f58:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005f5c:	f9842683          	lw	a3,-104(s0)
    80005f60:	6110                	ld	a2,0(a0)
    80005f62:	9732                	add	a4,a4,a2
    80005f64:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f68:	20058613          	addi	a2,a1,512
    80005f6c:	0612                	slli	a2,a2,0x4
    80005f6e:	9642                	add	a2,a2,a6
    80005f70:	577d                	li	a4,-1
    80005f72:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f76:	00469713          	slli	a4,a3,0x4
    80005f7a:	6114                	ld	a3,0(a0)
    80005f7c:	96ba                	add	a3,a3,a4
    80005f7e:	03078793          	addi	a5,a5,48
    80005f82:	97c2                	add	a5,a5,a6
    80005f84:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005f86:	611c                	ld	a5,0(a0)
    80005f88:	97ba                	add	a5,a5,a4
    80005f8a:	4685                	li	a3,1
    80005f8c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f8e:	611c                	ld	a5,0(a0)
    80005f90:	97ba                	add	a5,a5,a4
    80005f92:	4809                	li	a6,2
    80005f94:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f98:	611c                	ld	a5,0(a0)
    80005f9a:	973e                	add	a4,a4,a5
    80005f9c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fa0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80005fa4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fa8:	6518                	ld	a4,8(a0)
    80005faa:	00275783          	lhu	a5,2(a4)
    80005fae:	8b9d                	andi	a5,a5,7
    80005fb0:	0786                	slli	a5,a5,0x1
    80005fb2:	97ba                	add	a5,a5,a4
    80005fb4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005fb8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005fbc:	6518                	ld	a4,8(a0)
    80005fbe:	00275783          	lhu	a5,2(a4)
    80005fc2:	2785                	addiw	a5,a5,1
    80005fc4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005fc8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005fcc:	100017b7          	lui	a5,0x10001
    80005fd0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005fd4:	00492703          	lw	a4,4(s2)
    80005fd8:	4785                	li	a5,1
    80005fda:	02f71163          	bne	a4,a5,80005ffc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80005fde:	0001f997          	auipc	s3,0x1f
    80005fe2:	14a98993          	addi	s3,s3,330 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005fe6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005fe8:	85ce                	mv	a1,s3
    80005fea:	854a                	mv	a0,s2
    80005fec:	ffffc097          	auipc	ra,0xffffc
    80005ff0:	080080e7          	jalr	128(ra) # 8000206c <sleep>
  while(b->disk == 1) {
    80005ff4:	00492783          	lw	a5,4(s2)
    80005ff8:	fe9788e3          	beq	a5,s1,80005fe8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80005ffc:	f9042903          	lw	s2,-112(s0)
    80006000:	20090793          	addi	a5,s2,512
    80006004:	00479713          	slli	a4,a5,0x4
    80006008:	0001d797          	auipc	a5,0x1d
    8000600c:	ff878793          	addi	a5,a5,-8 # 80023000 <disk>
    80006010:	97ba                	add	a5,a5,a4
    80006012:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006016:	0001f997          	auipc	s3,0x1f
    8000601a:	fea98993          	addi	s3,s3,-22 # 80025000 <disk+0x2000>
    8000601e:	00491713          	slli	a4,s2,0x4
    80006022:	0009b783          	ld	a5,0(s3)
    80006026:	97ba                	add	a5,a5,a4
    80006028:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000602c:	854a                	mv	a0,s2
    8000602e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006032:	00000097          	auipc	ra,0x0
    80006036:	bc4080e7          	jalr	-1084(ra) # 80005bf6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000603a:	8885                	andi	s1,s1,1
    8000603c:	f0ed                	bnez	s1,8000601e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000603e:	0001f517          	auipc	a0,0x1f
    80006042:	0ea50513          	addi	a0,a0,234 # 80025128 <disk+0x2128>
    80006046:	ffffb097          	auipc	ra,0xffffb
    8000604a:	c52080e7          	jalr	-942(ra) # 80000c98 <release>
}
    8000604e:	70a6                	ld	ra,104(sp)
    80006050:	7406                	ld	s0,96(sp)
    80006052:	64e6                	ld	s1,88(sp)
    80006054:	6946                	ld	s2,80(sp)
    80006056:	69a6                	ld	s3,72(sp)
    80006058:	6a06                	ld	s4,64(sp)
    8000605a:	7ae2                	ld	s5,56(sp)
    8000605c:	7b42                	ld	s6,48(sp)
    8000605e:	7ba2                	ld	s7,40(sp)
    80006060:	7c02                	ld	s8,32(sp)
    80006062:	6ce2                	ld	s9,24(sp)
    80006064:	6d42                	ld	s10,16(sp)
    80006066:	6165                	addi	sp,sp,112
    80006068:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000606a:	0001f697          	auipc	a3,0x1f
    8000606e:	f966b683          	ld	a3,-106(a3) # 80025000 <disk+0x2000>
    80006072:	96ba                	add	a3,a3,a4
    80006074:	4609                	li	a2,2
    80006076:	00c69623          	sh	a2,12(a3)
    8000607a:	b5c9                	j	80005f3c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000607c:	f9042583          	lw	a1,-112(s0)
    80006080:	20058793          	addi	a5,a1,512
    80006084:	0792                	slli	a5,a5,0x4
    80006086:	0001d517          	auipc	a0,0x1d
    8000608a:	02250513          	addi	a0,a0,34 # 800230a8 <disk+0xa8>
    8000608e:	953e                	add	a0,a0,a5
  if(write)
    80006090:	e20d11e3          	bnez	s10,80005eb2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006094:	20058713          	addi	a4,a1,512
    80006098:	00471693          	slli	a3,a4,0x4
    8000609c:	0001d717          	auipc	a4,0x1d
    800060a0:	f6470713          	addi	a4,a4,-156 # 80023000 <disk>
    800060a4:	9736                	add	a4,a4,a3
    800060a6:	0a072423          	sw	zero,168(a4)
    800060aa:	b505                	j	80005eca <virtio_disk_rw+0xf4>

00000000800060ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060ac:	1101                	addi	sp,sp,-32
    800060ae:	ec06                	sd	ra,24(sp)
    800060b0:	e822                	sd	s0,16(sp)
    800060b2:	e426                	sd	s1,8(sp)
    800060b4:	e04a                	sd	s2,0(sp)
    800060b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060b8:	0001f517          	auipc	a0,0x1f
    800060bc:	07050513          	addi	a0,a0,112 # 80025128 <disk+0x2128>
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	b24080e7          	jalr	-1244(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060c8:	10001737          	lui	a4,0x10001
    800060cc:	533c                	lw	a5,96(a4)
    800060ce:	8b8d                	andi	a5,a5,3
    800060d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060d6:	0001f797          	auipc	a5,0x1f
    800060da:	f2a78793          	addi	a5,a5,-214 # 80025000 <disk+0x2000>
    800060de:	6b94                	ld	a3,16(a5)
    800060e0:	0207d703          	lhu	a4,32(a5)
    800060e4:	0026d783          	lhu	a5,2(a3)
    800060e8:	06f70163          	beq	a4,a5,8000614a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060ec:	0001d917          	auipc	s2,0x1d
    800060f0:	f1490913          	addi	s2,s2,-236 # 80023000 <disk>
    800060f4:	0001f497          	auipc	s1,0x1f
    800060f8:	f0c48493          	addi	s1,s1,-244 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800060fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006100:	6898                	ld	a4,16(s1)
    80006102:	0204d783          	lhu	a5,32(s1)
    80006106:	8b9d                	andi	a5,a5,7
    80006108:	078e                	slli	a5,a5,0x3
    8000610a:	97ba                	add	a5,a5,a4
    8000610c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000610e:	20078713          	addi	a4,a5,512
    80006112:	0712                	slli	a4,a4,0x4
    80006114:	974a                	add	a4,a4,s2
    80006116:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000611a:	e731                	bnez	a4,80006166 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000611c:	20078793          	addi	a5,a5,512
    80006120:	0792                	slli	a5,a5,0x4
    80006122:	97ca                	add	a5,a5,s2
    80006124:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006126:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000612a:	ffffc097          	auipc	ra,0xffffc
    8000612e:	0ce080e7          	jalr	206(ra) # 800021f8 <wakeup>

    disk.used_idx += 1;
    80006132:	0204d783          	lhu	a5,32(s1)
    80006136:	2785                	addiw	a5,a5,1
    80006138:	17c2                	slli	a5,a5,0x30
    8000613a:	93c1                	srli	a5,a5,0x30
    8000613c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006140:	6898                	ld	a4,16(s1)
    80006142:	00275703          	lhu	a4,2(a4)
    80006146:	faf71be3          	bne	a4,a5,800060fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000614a:	0001f517          	auipc	a0,0x1f
    8000614e:	fde50513          	addi	a0,a0,-34 # 80025128 <disk+0x2128>
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
}
    8000615a:	60e2                	ld	ra,24(sp)
    8000615c:	6442                	ld	s0,16(sp)
    8000615e:	64a2                	ld	s1,8(sp)
    80006160:	6902                	ld	s2,0(sp)
    80006162:	6105                	addi	sp,sp,32
    80006164:	8082                	ret
      panic("virtio_disk_intr status");
    80006166:	00002517          	auipc	a0,0x2
    8000616a:	6a250513          	addi	a0,a0,1698 # 80008808 <syscalls+0x3c0>
    8000616e:	ffffa097          	auipc	ra,0xffffa
    80006172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
