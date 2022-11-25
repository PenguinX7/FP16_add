#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

unsigned short FP16_add(unsigned short data1,unsigned short data2);

unsigned short FP16_add(unsigned short data1,unsigned short data2)
{
    //unsigned short data1 = 0x0000;//0x0000;//0xffff;//0x5bf0 //254 
    //unsigned short data2 = 0x0000;//0x47af;//7.6836
    unsigned short data_o;

    bool overflow;
    unsigned short sign_high;
    unsigned short sign_low;
    unsigned short exp_high;
    unsigned int    rm_high;
    unsigned short exp_low;
    unsigned int    rm_low;
    unsigned int rm_cache;
    unsigned short exp_cache;
    unsigned short sign_new;
    unsigned short rm_new;
    unsigned short exp_new;
    bool ifround;

    //step1:pre_operation
    if((data1 == 0xffff) || (data2 == 0xffff))      //Inf
    {
        overflow = 1;
    }
    else
    {  
        if(((data1 >> 10) & 0x001f) > ((data2 >> 10) & 0x001f))     //data1[14:10] > data2[14:10]
        {
            if(((data2 >> 10) & 0x001f) == 0x00)
                rm_low = 0;
            else
                rm_low = (data2 & 0x03ff | 0x0400) << 11;      //rm_low[21:11] = {1,data2[9:0]}
            exp_high = (data1 >> 10) & 0x001f;      //data1[14:10]
            exp_low = (data2 >> 10) & 0x001f;       //data2[14:10]
            rm_high = (data1 & 0x03ff | 0x0400) << 11;     //rm_high[21:11] = {1,data1[9:0]}
            sign_high = data1 >> 15;
            sign_low = data2 >>15;
        }
        else if(((data1 >> 10) & 0x001f) < ((data2 >> 10) & 0x001f))     //data1[14:10] < data2[14:10]
        {
            if(((data1 >> 10) & 0x001f) == 0x00)
                rm_low = 0;
            else
                rm_low = (data1 & 0x03ff | 0x0400) << 11;      //rm_low[21:11] = {1,data2[9:0]}
            exp_high = (data2 >> 10) & 0x001f;      //data2[14:10]
            exp_low = (data1 >> 10) & 0x001f;       //data1[14:10]
            rm_high = (data2 & 0x03ff | 0x0400) << 11;      //rm_high[21:11] = {1,data2[9:0]}
            sign_high = data2 >> 15;
            sign_low = data1 >>15;
        }
        else if((data1 & 0x03ff) > (data2 & 0x03ff))
        {
            exp_high = (data1 >> 10) & 0x001f;      //data1[14:10]
            exp_low = (data2 >> 10) & 0x001f;       //data2[14:10]
            rm_high = (data1 & 0x03ff | 0x0400) << 11;     //rm_high[21:11] = {1,data1[9:0]}
            rm_low = (data2 & 0x03ff | 0x0400) << 11;      //rm_low[21:11] = {1,data2[9:0]}
            sign_high = data1 >> 15;
            sign_low = data2 >>15;
        }
        else
        {
            if(((data1 >> 10) & 0x001f) == 0x00)
            {
                rm_high = 0;
                rm_low = 0;
            }
            else
            {
                rm_high = (data2 & 0x03ff | 0x0400) << 11;      //rm_high[21:11] = {1,data2[9:0]}
                rm_low = (data1 & 0x03ff | 0x0400) << 11;      //rm_low[21:11] = {1,data2[9:0]}
            }
            exp_high = (data2 >> 10) & 0x001f;      //data2[14:10]
            exp_low = (data1 >> 10) & 0x001f;       //data1[14:10]
            sign_high = data2 >> 15;
            sign_low = data1 >>15;
        }
    }

    //step2:shift to align
    if(overflow)
    {}
    else
    {
        switch(exp_high - exp_low)
        {
            case 0 :rm_low = rm_low;break;
            case 1 : rm_low = rm_low >> 1; break;
            case 2 : rm_low = rm_low >> 2; break;
            case 3 : rm_low = rm_low >> 3; break;
            case 4 : rm_low = rm_low >> 4; break;
            case 5 : rm_low = rm_low >> 5; break;
            case 6 : rm_low = rm_low >> 6; break;
            case 7 : rm_low = rm_low >> 7; break;
            case 8 : rm_low = rm_low >> 8; break;
            case 9 : rm_low = rm_low >> 9; break;
            case 10 : rm_low = rm_low >> 10; break;
            case 11 : rm_low = rm_low >> 11; break;
            case 12 : rm_low = rm_low >> 12; break;
            default : {rm_low = 0;}break;
        }
    }

    //step3:calculate
    if(overflow)
    {}
    else
    {
        sign_new = sign_high;
        exp_cache = exp_high;
        if(sign_high != sign_low)   //一正一负
        {
            rm_cache = rm_high - rm_low;
        }
        else                        //同正或同负
        {
            rm_cache = rm_high + rm_low;
        }
    }
    
    //step4:normalize_pre
    if(overflow)
    {}
    else
    {
        if((rm_cache >= 0x400000) && (rm_cache <= 0x7fffff))            //23'b1xx_xxxx_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache +1;
            rm_new = (rm_cache & 0x7ff000) >> 12;                       //rmcache[22:12]
            ifround = (rm_cache & 0x800) && ((rm_cache & 0x1000) || (rm_cache & 0x7ff));
        }
        else if((rm_cache >= 0x200000) && (rm_cache <= 0x3fffff))            //23'b01x_xxxx_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache;
            rm_new = (rm_cache & 0x3ff800) >> 11;                       //rmcache[21:11]
            ifround = (rm_cache & 0x400) && ((rm_cache & 0x800) || (rm_cache & 0x3ff));
        }
        else if((rm_cache >= 0x100000) && (rm_cache <= 0x1fffff))            //23'b001_xxxx_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 1;
            rm_new = (rm_cache & 0x1ffc00) >> 10;                       //rmcache[20:10]
            ifround = (rm_cache & 0x200) && ((rm_cache & 0x400) || (rm_cache & 0x1ff));
        }
        else if((rm_cache >= 0x80000) && (rm_cache <= 0xfffff))            //23'b000_1xxx_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 2;
            rm_new = (rm_cache & 0x0ffe00) >> 9;                       //rmcache[19:9]
            ifround = (rm_cache & 0x100) && ((rm_cache & 0x200) || (rm_cache & 0x0ff));
        }
        else if((rm_cache >= 0x40000) && (rm_cache <= 0x7ffff))            //23'b000_01xx_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 3;
            rm_new = (rm_cache & 0x07ff00) >> 8;                       //rmcache[18:8]
            ifround = (rm_cache & 0x80) && ((rm_cache & 0x100) || (rm_cache & 0x07f));
        }
        else if((rm_cache >= 0x20000) && (rm_cache <= 0x3ffff))            //23'b000_001x_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 4;
            rm_new = (rm_cache & 0x03ff80) >> 7;                       //rmcache[17:7]
            ifround = (rm_cache & 0x40) && ((rm_cache & 0x80) || (rm_cache & 0x03f));
        }
        else if((rm_cache >= 0x10000) && (rm_cache <= 0x1ffff))            //23'b000_0001_xxxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 5;
            rm_new = (rm_cache & 0x01ffc0) >> 6;                       //rmcache[16:6]
            ifround = (rm_cache & 0x20) && ((rm_cache & 0x40) || (rm_cache & 0x01f));
        }
        else if((rm_cache >= 0x08000) && (rm_cache <= 0xffff))            //23'b000_0000_1xxx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 6;
            rm_new = (rm_cache & 0x00ffe0) >> 5;                       //rmcache[15:5]
            ifround = (rm_cache & 0x10) && ((rm_cache & 0x20) || (rm_cache & 0x00f));
        }
        else if((rm_cache >= 0x04000) && (rm_cache <= 0x07fff))            //23'b000_0000_01xx_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 7;
            rm_new = (rm_cache & 0x007ff0) >> 4;                       //rmcache[14:4]
            ifround = (rm_cache & 0x08) && ((rm_cache & 0x10) || (rm_cache & 0x007));
        }
        else if((rm_cache >= 0x02000) && (rm_cache <= 0x03fff))            //23'b000_0000_001x_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 8;
            rm_new = (rm_cache & 0x003ff8) >> 3;                       //rmcache[13:3]
            ifround = (rm_cache & 0x04) && ((rm_cache & 0x08) || (rm_cache & 0x003));
        }
        else if((rm_cache >= 0x01000) && (rm_cache <= 0x01fff))            //23'b000_0000_0001_xxxx_xxxx_xxxx
        {
            exp_new = exp_cache - 9;
            rm_new = (rm_cache & 0x001ffc) >> 2;                       //rmcache[12:2]
            ifround = (rm_cache & 0x02) && ((rm_cache & 0x04) || (rm_cache & 0x001));
        }
        else if((rm_cache >= 0x00800) && (rm_cache <= 0x00fff))            //23'b000_0000_0000_1xxx_xxxx_xxxx
        {
            exp_new = exp_cache - 10;
            rm_new = (rm_cache & 0x000ffe) >> 1;                       //rmcache[11:1]
            ifround = (rm_cache & 0x01) && (rm_cache & 0x02);
        }
        else
        {
            exp_new = 0;
            rm_new = 0;
            ifround = 0;
        }      
    }

    //step5:normalize_round to nearest even
    if(overflow)
    {}
    else
    {
        rm_new = ifround ? rm_new+1 : rm_new;
    }

    //step6:normalize_carry
    if(overflow)
    {}
    else
    {
        if(rm_new & 0x800)      //rm_new[11]
        {
            rm_new = rm_new >> 1;
            exp_new = exp_new + 1;
        }
    }

    //step7:result
    if(overflow | (exp_new & 0x60 == 0x20))
        data_o = 0xffff;
    else if(((rm_new & 0xfff) == 0x000) | (exp_new & 0x40))
        data_o = 0x0000;
    else
        data_o = (sign_new << 15) | (exp_new << 10) | (rm_new & 0x3ff);

    return data_o;
}



//调试用main函数
/*
int main()
{
    unsigned short data_in1 = 0x07d5;
    unsigned short data_in2 = 0x872f;

    unsigned short data_o;
    data_o = FP16_add(data_in1,data_in2);
    return 0;
}
*/
