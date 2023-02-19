default: run

SHELL := /bin/bash
BUILDDIR := build
$(shell mkdir -p ${BUILDDIR})

CSRCDIR := ./src/c
CSRCS := ${CSRCDIR}/tmp.c # 状況に応じて要変更 # 現在、CSRCSはCSRCDIRに無いといけない
COBJS := ${CSRCS:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
CLINK := ${CSRCDIR}/link.ld
CEXE := ${BUILDDIR}/target_program
CDUMP := ${CEXE}.dump
CBIN := ${CEXE}.bin
CHEX := ${CEXE}.hex
RESULT := ${BUILDDIR}/result.log

VSRCDIR := ./src/verilog
VTESTBENCH := ${VSRCDIR}/cpu_tb.v # 状況に応じて要変更
TOPMODULE := $(shell sed -ze "s/.*module \([^;]*\).*/\1/" ${VTESTBENCH})
VSRCS := ${wildcard ${VSRCDIR}/*.v}
VMEM := ${VSRCDIR}/mem.v
VEXE := ${BUILDDIR}/riscv_emulation

${VEXE}: ${VSRCS}
	iverilog $^ -I ${VSRCDIR} -s ${TOPMODULE} -o $@
${VMEM}: ${CHEX}
	sed -i -e "s&[^\"]*\.hex&$<&" $@
${CHEX}: ${CBIN}
	od -An -tx1 -w1 -v $< > $@
${CBIN}: ${CEXE}
	riscv32-unknown-linux-gnu-objcopy -O binary $< $@

${CDUMP}: ${CEXE}
	riscv32-unknown-linux-gnu-objdump $< --disassemble-all --disassemble-zeroes > $@
${CEXE}: ${COBJS}
	riscv32-unknown-linux-gnu-gcc $^ -march=rv32i -mabi=ilp32 -o $@ -static -nostdlib -nostartfiles -T ${CLINK}
${COBJS}: ${BUILDDIR}/%.o: ${CSRCDIR}/%.c Makefile
	riscv32-unknown-linux-gnu-gcc $< -c -march=rv32i -mabi=ilp32 -o $@ -nostdlib
.PHONY: run 
run: ${RESULT} ${CDUMP}
	@echo "Return value: $(shell tail -n1 ${RESULT} | rev | cut -d " " -f 1 | rev)"
${RESULT}: ${VEXE}
	./$< > $@
	@# RESULTで実行

test:
	$(MAKE) ${VMEM}
	$(MAKE) -C riscv-tests/isa
	mkdir -p ${BUILDDIR}/isa
	@# ユニットテストを一時ディレクトリbuildにコピー
	find riscv-tests/isa/* -maxdepth 0 -type f -not -name 'Makefile' -exec cp {} ${BUILDDIR}/isa/ \;
	@# ELF(実行ファイル) を .bin に変換
	cd ${BUILDDIR}/isa; for exe in $$(ls | grep -v -e "\."); do riscv32-unknown-linux-gnu-objcopy -O binary $$exe $${exe}.bin; done
	@# .bin を .hex に変換
	cd ${BUILDDIR}/isa; for exe in $$(ls | grep -v -e "\."); do od -An -tx1 -w1 -v $${exe}.bin > $${exe}.hex; done
	@# .hex を読み込んでエミュレート。命令00018513が実行されているかどうかで、テストをpassしているかを判断。
	@# 00018513はaddi a0(10番レジスタ), gp(3番レジスタ), 0 命令。gpに書き込まれたfail情報をa0レジスタへmvしている。ここを判定
	for exe in $$(ls ${BUILDDIR}/isa | grep -v -e "\."); do \
		sed -i -e "s&[^\"]*\.hex&${BUILDDIR}/isa/$${exe}.hex&" ${VMEM};\
		echo -n "$$exe: ";\
		${MAKE} run -s > /dev/null;\
		 cat ${RESULT} | grep -n 00018513 > /dev/null \
		 && echo -e "\e[31m no \e[m" \
		 || echo -e "\e[32m ok \e[m" ;\
	done
	@# ここだめポ
	@# ecall時に、gpを出力し、その値が1であるかを確認する。(2以上でエラー)
	@# [ "$$(tail -n1 ${RESULT} | rev | cut -d " " -f 1 | rev)" -eq "1" ] 
	@# && echo -e "\e[32m ok \e[m" 
	@# || echo -e "\e[31m no \e[m" ;	

.PHONY: clean
clean:
	rm -rf ./build


# default: run

# TOPMODULE := cpu_tb # 状況に応じて要変更

# BUILDDIR := build
# $(shell mkdir -p ${BUILDDIR})

# CSRCDIR := ./src/c
# CSRC := ${CSRCDIR}/hazard_ex.c # 単体ファイルしか対応していない  # 状況に応じて要変更
# COBJ := ${CSRC:${CSRCDIR}/%.c=${BUILDDIR}/%.o}
# CBIN := ${COBJ:%.o=%.bin}
# CHEX := ${COBJ:%.o=%.hex}

# VSRCDIR := ./src/verilog
# VSRCS := ${wildcard ${VSRCDIR}/*.v}
# INSTMEM := ${VSRCDIR}/inst_mem.v
# OUTFILE := ${BUILDDIR}/test.exe

# ${OUTFILE}: ${VSRCS}
# 	iverilog ${VSRCS} -I ${VSRCDIR} -s ${TOPMODULE} -o ${OUTFILE}
# ${INSTMEM}: ${CHEX}
# 	sed -i -e "s&[^\"]*\.hex&${CHEX}&" ${INSTMEM}
# ${CHEX}: ${CBIN}
# 	echo '13\n00\n00\n00' > ${CHEX} # NOP命令から始まるように
# 	od -An -tx1 -w1 -v ${CBIN} >> ${CHEX}
# ${CBIN}: ${COBJ}
# 	riscv32-unknown-linux-gnu-objcopy -O binary ${COBJ} ${CBIN}
# ${COBJ}: ${CSRC}
# 	riscv32-unknown-linux-gnu-gcc ${CSRC} -c -march=rv32i -mabi=ilp32 -o ${COBJ}
# 	riscv32-unknown-linux-gnu-gcc ${CSRC} -S -march=rv32i -mabi=ilp32 -o ${BUILDDIR}/c_debug.asm

# .PHONY: run
# run: ${OUTFILE}
# 	./${OUTFILE}

# .PHONY: clean
# clean:
# 	rm -rf ./build