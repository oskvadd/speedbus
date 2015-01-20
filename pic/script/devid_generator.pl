#!/usr/bin/perl -w

if($ARGV[0] > 0xFFFFFFFF){
    print("Devid to high\n"); exit;}

if(@ARGV < 1){
    print("Use: $0 DEV_ID\n"); exit;}
    

$i4 = $ARGV[0] & 0xFF;
$i3 = ($ARGV[0] >> 8) & 0xFF;
$i2 = ($ARGV[0] >> 16) & 0xFF;
$i1 = ($ARGV[0] >> 24) & 0xFF;


print("#define DEV_ID1 $i1\n");
print("#define DEV_ID2 $i2\n");
print("#define DEV_ID3 $i3\n");
print("#define DEV_ID4 $i4\n");
