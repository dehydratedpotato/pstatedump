# pstatedump
A small command line tool to dump P-States on Intel Macs.

## Building
Just run `make`. Boom. You're done.

## Usage
```
usage:
  pstatedump
  pstatedump [-c|-n|-m|-b|-a]

  -c, --count         print pstate count
  -n, --max           print maximum nominal freq only
  -m, --min           print minimum nominal freq only
  -b, --boost         print maximum boost freq only
  -a, --avail-boost   print maximum available boost freq only
  -h, --help          print this help menu

  Default: prints P-State table for the CPU
```

## Example Output
Example dump on a i7-4578U MacBook Pro. 
```
Intel(R) Core(TM) i7-4578U CPU 

***** 28 P-States *****

 0   3500 MHz   (Boost)
 1   3400 MHz   (Boost)
 2   3300 MHz   (Boost)
 3   3200 MHz   (Boost)
 4   3100 MHz   (Boost)
 5   3000 MHz   (Nominal)
 6   2900 MHz
 7   2800 MHz
 8   2700 MHz
 9   2600 MHz
10   2500 MHz
11   2400 MHz
12   2300 MHz
13   2200 MHz
14   2100 MHz
15   2000 MHz
16   1900 MHz
17   1800 MHz
18   1700 MHz
19   1600 MHz
20   1500 MHz
21   1400 MHz
22   1300 MHz
23   1200 MHz
24   1100 MHz
25   1000 MHz
26    900 MHz
27    800 MHz
```
