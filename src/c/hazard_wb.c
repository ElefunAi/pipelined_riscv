// data hazardがexe stage以降で生じた際にforwardingできるかのテスト
int main(){
    asm volatile("addi a0, x0, 1");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("add a1, a0, a0");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    return 0;
}