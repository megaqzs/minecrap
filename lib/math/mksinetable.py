#!/bin/env python3
import math

def sin_avg(start, end):
    """ get the avarage of sin(x) where start <= x <= finish (in radians)"""
    return (math.cos(start) - math.cos(end)) / (end - start)

def main():
    max_angle = 1024
    ConvConst = math.tau / max_angle

    # the maximal unsigned in the decimal part plus one
    max_dec = 1 << 16
    line_length

    for i in range(round((max_angle / 4) / line_length - 1)):
        print(round(max_dec * math.sin(i * ConvConst)), end=", ")
    
    # print the closest value to 1
    print(max_dec - 1)

if __name__ == "__main__":
    main()
