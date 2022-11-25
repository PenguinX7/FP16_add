#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include "FP16_add_algorithim.c"

unsigned short FP16_add(unsigned short data1,unsigned short data2);
float myconv(unsigned short data);
int verify(unsigned short data_in1,unsigned short data_in2,FILE * p);

int main()
{
    unsigned short data_in1,data_in2;
    int count2,error_count;
    FILE *p = fopen("report.txt","w");

    error_count = 0;                        //错误计数初始化
    srand((unsigned)time(NULL));            //以时间为种子

    do
    {
        data_in1 = rand();                  //随机一个操作数
    } while ((data_in1!= 0x0000) && (data_in1 != 0xffff) && (((data_in1 & 0x7fff) < 0x0400) || ((data_in1 & 0x7fff) > 0x7bff)));    //检查合理性，不合理重复生成
    

    data_in2 = 0x0000;
    count2 = 1;
    while(count2 <= 61442)                  //将另一个操作数的所有合理可能(0,min~max,Inf)全部尝试，包括正负
    {
        count2++;
        error_count += verify(data_in1,data_in2,p);

        if(data_in2 == 0x0000)              //另一个操作数递进
            data_in2 = 0x0400;
        else if(data_in2 == 0x7bff)
            data_in2 = 0xffff;
        else if(data_in2 == 0xffff)
            data_in2 = 0x8400;
        else
            data_in2++;
    }
    data_in1 = data_in1 | 0x8000;           //将操作数取反再来一遍
    data_in2 = 0x0000;
    count2 = 1;
    while(count2 <= 30722)
    {
        count2++;
        error_count += verify(data_in1,data_in2,p);

        if(data_in2 == 0x0000)
            data_in2 = 0x0400;
        else if(data_in2 == 0x7bff)
            data_in2 = 0xffff;
        else if(data_in2 == 0xffff)
            data_in2 = 0x8400;
        else
            data_in2++;
    }

    fprintf(p,"\nover,there are %d errors\n",error_count);
    fclose(p);

    return 0;
}



//用于验证两个操作数是否正确并将验证结果写入文件
int verify(unsigned short data_in1,unsigned short data_in2,FILE * p)
{
    float data1 = myconv(data_in1);
    float data2 = myconv(data_in2);
    float data_standard = data1 + data2;
    float mistake;
    unsigned short data_my;
    float data_mycache;

    data_my = FP16_add(data_in1,data_in2);
    data_mycache = myconv(data_my);
    mistake = abs(data_standard - data_mycache);       //计算误差

    if((mistake <= abs(data_standard * 0.005)))     //误差在0.5%以内
    {
        fprintf(p,"inputs are %f(0x%04x),%f(0x%04x),my output is %f(0x%04x),it should be %f,pass\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard);
        return 0;
    }
    else if((data_standard > 65504) && (data_my == 0xffff))     //溢出
    {
        fprintf(p,"inputs are %f(0x%04x),%f(0x%04x),my output is %f(0x%04x),it should be %f,pass\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard);
        return 0;
    }
    else                                            //错误
    {
        fprintf(p,"inputs are %f(0x%04x),%f(0x%04x),my output is %f(0x%04x),it should be %f,fail!!!!!!!!!!\n",data1,data_in1,data2,data_in2,data_mycache,data_my,data_standard);
        return 1;
    }

}



//将16位short存储的FP16转换成结构相同的float(符号、阶数、尾数相同，而不是值相同)
float myconv(unsigned short data)
{
    float result;
    
    short sign = data >> 15;
    short exp = ((data & 0x7c00) >> 10) - 25;
    short rm = (data & 0x03ff | 0x0400);

    result = rm * pow(2,exp);

    if(exp == -25)      //0x0000 is 0
        return 0;
    else if(exp == 6)   //0xffff is overflow、NaN
        return 65505;
    else if(sign == 0)
        return result;
    else if(sign == 1)
        return -1 * result;
}