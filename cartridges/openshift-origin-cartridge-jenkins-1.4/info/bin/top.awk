{
    if($1 == "Mem:")
        print "Mem: "ENVIRON["TOTAL_MEM"]"k total, "ENVIRON["USED_MEM"]"k used, "ENVIRON["FREE_MEM"]"k free, "$8" buffers";
    else if ($1 == "Swap:")
        print "Swap: "ENVIRON["TOTAL_SWAP"]"k total, "ENVIRON["USED_SWAP"]"k used, "ENVIRON["FREE_SWAP"]"k free, "$8" cached"
    else
        print $0;
}
