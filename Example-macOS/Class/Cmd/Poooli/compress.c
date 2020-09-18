//
//  compress.c
//  Bluetooth
//
//  Created by ldc on 2019/11/29.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#include "compress.h"
#include <stdlib.h>
#define byte unsigned char

static unsigned _do_compress(byte *src, unsigned src_len, byte *dst, unsigned long *out_len);

//===================================================================================
/**************************************************
 * inData:     压缩的原数据
 * inData_len: 数据长度
 * outData:    压缩后的数据
 **************************************************/
long lzo_compress(void *inData, unsigned inData_len, void *outData)
{
    byte *op = outData;
    unsigned long t,out_len;
    if (inData_len <= 13)
        t = inData_len;
    else
    {
        t = _do_compress (inData,inData_len,op,&out_len);
        op += out_len;
    }
    if (t > 0)
    {
        byte *ii = (byte*)inData + inData_len - t;
        if (op == (byte*)outData && t <= 238)
            *op++ = (byte) ( 17 + t );
        else
            if (t <= 3)
                op[-2] |= (byte)t ;
            else
                if (t <= 18)
                    *op++ = (byte)(t-3);
                else
                {
                    unsigned long tt = t - 18;
                    *op++ = 0;
                    while (tt > 255)
                    {
                        tt -= 255;
                        *op++ = 0;
                    }
                    *op++ = (byte)tt;
                }
        do *op++ = *ii++; while (--t > 0);
    }
    *op++ = 17;
    *op++ = 0;
    *op++ = 0;
    return (op - (byte*)outData);
}

static unsigned _do_compress(byte *src, unsigned src_len, byte *dst, unsigned long *out_len)
{
    static long wrkmem [16384L];
    register byte *ip;
    byte *op;
    byte *in_end = src + src_len;
    byte *ip_end = src + src_len - 13;
    byte *ii;
    byte **dict = (byte **)wrkmem;
    op = dst;
    ip = src;
    ii = ip;
    ip += 4;
    for(;;)
    {
        register byte *m_pos;
        unsigned long m_off;
        unsigned long m_len;
        unsigned long dindex;
        dindex = ((0x21*(((((((unsigned)(ip[3])<<6)^ip[2])<<5)^ip[1])<<5)^ip[0]))>>5) & 0x3fff;
        m_pos = dict [dindex];
        if(((unsigned)m_pos < (unsigned)src) ||
           (m_off = (unsigned)((unsigned)ip-(unsigned)m_pos) ) <= 0 ||
           m_off > 0xbfff)
            goto literal;
        if(m_off <= 0x0800 || m_pos[3] == ip[3])
            goto try_match;
        dindex = (dindex & 0x7ff ) ^ 0x201f;
        m_pos = dict[dindex];
        if((unsigned)(m_pos) < (unsigned)(src) ||
           (m_off = (unsigned)( (int)((unsigned)ip-(unsigned)m_pos))) <= 0 ||
           m_off > 0xbfff)
            goto literal;
        if (m_off <= 0x0800 || m_pos[3] == ip[3])
            goto try_match;
        goto literal;
    try_match:
        if(*(unsigned short*)m_pos == *(unsigned short*)ip && m_pos[2]==ip[2])
            goto match;
    literal:
        dict[dindex] = ip;
        ++ip;
        if (ip >= ip_end)
            break;
        continue;
    match:
        dict[dindex] = ip;
        if(ip - ii > 0)
        {
            register unsigned long t = ip - ii;
            
            if (t <= 3)
                op[-2] |= (byte)t;
            else if(t <= 18)
                *op++ = (byte)(t - 3);
            else
            {
                register unsigned long tt = t - 18;
                *op++ = 0;
                while(tt > 255)
                {
                    tt -= 255;
                    *op++ = 0;
                }
                *op++ = (byte)tt;
            }
            do *op++ = *ii++; while (--t > 0);
        }
        ip += 3;
        if(m_pos[3] != *ip++ || m_pos[4] != *ip++ || m_pos[5] != *ip++ ||
           m_pos[6] != *ip++ || m_pos[7] != *ip++ || m_pos[8] != *ip++ )
        {
            --ip;
            m_len = ip - ii;
            
            if(m_off <= 0x0800 )
            {
                --m_off;
                *op++ = (byte)(((m_len - 1) << 5) | ((m_off & 7) << 2));
                *op++ = (byte)(m_off >> 3);
            }
            else
                if (m_off <= 0x4000 )
                {
                    -- m_off;
                    *op++ = (byte)(32 | (m_len - 2));
                    goto m3_m4_offset;
                }
                else
                {
                    m_off -= 0x4000;
                    *op++ = (byte)(16 | ((m_off & 0x4000) >> 11) | (m_len - 2));
                    goto m3_m4_offset;
                }
        }
        else
        {
            {
                byte *end = in_end;
                byte *m = m_pos + 9;
                while (ip < end && *m == *ip)
                    m++, ip++;
                m_len = (ip - ii);
            }
            
            if(m_off <= 0x4000)
            {
                --m_off;
                if (m_len <= 33)
                    *op++ = (byte)(32 | (m_len - 2));
                else
                {
                    m_len -= 33;
                    *op++=32;
                    goto m3_m4_len;
                }
            }
            else
            {
                m_off -= 0x4000;
                if(m_len <= 9)
                    *op++ = (byte)(16|((m_off & 0x4000) >> 11) | (m_len - 2));
                else
                {
                    m_len -= 9;
                    *op++ = (byte)(16 | ((m_off & 0x4000) >> 11));
                m3_m4_len:
                    while (m_len > 255)
                    {
                        m_len -= 255;
                        *op++ = 0;
                    }
                    *op++ = (byte)m_len;
                }
            }
        m3_m4_offset:
            *op++ = (byte)((m_off & 63) << 2);
            *op++ = (byte)(m_off >> 6);
        }
        ii = ip;
        if (ip >= ip_end)
            break;
    }
    *out_len = op - dst;
    return (unsigned) (in_end - ii);
}
