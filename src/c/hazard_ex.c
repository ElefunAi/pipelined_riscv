// data hazardがexe stage以前で生じた際にstallできるかのテスト
int main(){
    asm volatile("addi a0, x0, 1");
    asm volatile("add a1, a0, a0");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    return 0;
}