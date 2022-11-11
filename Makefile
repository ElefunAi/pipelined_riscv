default: run

TOPMODULE := sample_test # 状況に応じて要変更

BUILDDIR := build
$(shell mkdir -p ${BUILDDIR})

CSRCDIR := ./src/c
CSRC := ${CSRCDIR}/c_sample.c # 単体ファイルしか対応していない  # 状況に応じて要変更
COBJ := ${CSRC:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
CBIN := ${COBJ:%.o=%.bin}
CHEX := ${COBJ:%.o=%.hex}

VSRCDIR := ./src/verilog
VSRCS := ${wildcard ${VSRCDIR}/*.v}
VTESTBENCH := $(shell grep -Irw ${TOPMODULE} ${VSRCDIR} | cut -d ":" -f 1)
OUTFILE := ${BUILDDIR}/test.exe

${OUTFILE}: ${VSRCS}
	iverilog ${VSRCS} -I ${VSRCDIR} -s ${TOPMODULE} -o ${OUTFILE}
${VTESTBENCH}: ${CHEX}
	sed -i -e "s&[a-zA-Z0-9_/]*\.hex&${CHEX}&" ${VTESTBENCH}
${CHEX}: ${CBIN}
	od -An -tx1 -w1 -v ${CBIN} > ${CHEX}
${CBIN}: ${COBJ}
	riscv32-unknown-elf-objcopy -O binary ${COBJ} ${CBIN}
${COBJ}: ${CSRC}
	riscv32-unknown-elf-gcc ${CSRC} -c -march=rv32i -mabi=ilp32 -o ${COBJ}

.PHONY: run
run: ${OUTFILE}
	./${OUTFILE}

.PHONY: clean
clean:
	rm -rf ./build