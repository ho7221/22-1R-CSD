int get_switch(){
	unsigned char *sw=(unsigned char*) 0x41210000; // switch pointer
	int s=*sw; // get switch data

	if(s&128) return 1; // sw7
	if(s&64) return 2; // sw6
	if(s&32) return 3; // sw5
	if(s&16) return 4; // sw4
	if(s&8) return 5; // sw3
	if(s&4) return 6; // sw2
	if(s&2) return 7; // sw1
	if(s&1) return 8; // sw0
	return 10; // otherwise
}
