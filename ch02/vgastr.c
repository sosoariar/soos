
void _strwrite(char* string)
{
    char* p_strdst = (char*)(0xb8000);
    while (*string)
    {

        *p_strdst = *string++;
        p_strdst += 2;
    }
    return;
}
// printf后面的形参，可用于扩展，比如格式化操作。例如 printf("error msg: %s","Out Of Memorry")
void printf(char* fmt, ...)
{
    _strwrite(fmt);
    return;
}