int get_time(int s){

	if(s==1) return 0x1;
	else if(s==2) return 0x2;
	else if(s==3) return 0x3;
	else if(s==4) return 0x4;
	else if(s==5) return 0x5;
	else if(s==6) return 0x6;
	else if(s==7) return 0x7;
	else if(s==8) return 0xA;
	else return 0xA; // exception to 1sec
}
