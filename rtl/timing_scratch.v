//M1: OP FETCH
posedge(m1)
    addr[15:0] <= pc;
    //Half cycle later
    negedge(t1)
        MREQ <= 1'b0; //MREQ Active
            //Use this signal directly to call chip enable
        RD <= 1'b0; //RD Active to indicate memory read data enabled onto CPU data bus
    //T3
    posedge(t3)
        //sample mem data to CPU
        data_bus <= mem_data;
        RD = 1'b1;
        MREQ = 1'b1;
        //T3 and T4 used to refresh DRAMs
        addr[15:0] <= refresh_addr;
        //RFSH = 1'b0;        
    negedge(t3)
        MREQ = 1'b0;
    negedge(t4)
        MREQ = 1'b1;
    //CPU uses T3 and T4 to decode and execute instruction
