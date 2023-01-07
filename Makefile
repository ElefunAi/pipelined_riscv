default: run

TOPMODULE := cpu_tb # 状況に応じて要変更

BUILDDIR := build
$(shell mkdir -p ${BUILDDIR})

CSRCDIR := ./src/c
CSRC := ${CSRCDIR}/hazard_ex.c # 単体ファイルしか対応していない  # 状況に応じて要変更
COBJ := ${CSRC:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
CBIN := ${COBJ:%.o=%.bin}
CHEX := ${COBJ:%.o=%.hex}

VSRCDIR := ./src/verilog
VSRCS := ${wildcard ${VSRCDIR}/*.v}
INSTMEM := ${VSRCDIR}/inst_mem.v
OUTFILE := ${BUILDDIR}/test.exe

${OUTFILE}: ${VSRCS}
	iverilog ${VSRCS} -I ${VSRCDIR} -s ${TOPMODULE} -o ${OUTFILE}
${INSTMEM}: ${CHEX}
	sed -i -e "s&[^\"]*\.hex&${CHEX}&" ${INSTMEM}
${CHEX}: ${CBIN}
	echo '13\n00\n00\n00' > ${CHEX} # NOP命令から始まるように
	od -An -tx1 -w1 -v ${CBIN} >> ${CHEX}
${CBIN}: ${COBJ}
	riscv32-unknown-linux-gnu-objcopy -O binary ${COBJ} ${CBIN}
${COBJ}: ${CSRC}
	riscv32-unknown-linux-gnu-gcc ${CSRC} -c -march=rv32i -mabi=ilp32 -o ${COBJ}
	riscv32-unknown-linux-gnu-gcc ${CSRC} -S -march=rv32i -mabi=ilp32 -o ${BUILDDIR}/c_debug.asm

.PHONY: run
run: ${OUTFILE}
	./${OUTFILE}

.PHONY: clean
clean:
	rm -rf ./build