#define TXFIFO_EMPTY (*(volatile char*)(0x0))&0x1
#define TXFIFO_FULL ((*(volatile char*)(0x0))>>1)&0x1
#define RXFIFO_EMPTY ((*(volatile char*)(0x0))>>2)&0x1
#define RXFIFO_FULL ((*(volatile char*)(0x0))>>3)&0x1
#define RXDATA *(volatile char*)(0x10)
#define TXDATA *(volatile char*)(0x10)

char buffer[256];

void sendbyte(char b)
{
	while (RXFIFO_FULL) {}
	RXDATA = b;
}

void sendmsg(char* msg)
{
	int i = 0;
	while (msg[i])
	{
		while (RXFIFO_FULL) {}
		RXDATA = msg[i];
		i++;
	}
}

char* recvcmd()
{
	int i = 0;
	char recbyte;
	while (1)
	{
		while (TXFIFO_EMPTY) {}
		recbyte = TXDATA;
		sendbyte(recbyte);
		if (recbyte == 0xD) {
			buffer[i] = 0x0;
			sendmsg("\r\n");
			break;
		}
		buffer[i++] = recbyte;
	}
	return buffer;
}

void banner()
{
	sendmsg(" ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄ \r\n");
	sendmsg("▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌\r\n");
	sendmsg("▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀  ▀▀▀▀▀▀▀▀▀█░▌▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀█░▌\r\n");
	sendmsg("▐░▌       ▐░▌▐░▌               ▐░▌               ▐░▌▐░▌▐░▌    ▐░▌▐░▌       ▐░▌▐░▌▐░▌    ▐░▌▐░▌       ▐░▌\r\n");
	sendmsg("▐░█▄▄▄▄▄▄▄█░▌▐░▌               ▐░▌               ▐░▌▐░▌ ▐░▌   ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▐░▌   ▐░▌▐░▌       ▐░▌\r\n");
	sendmsg("▐░░░░░░░░░░░▌▐░▌               ▐░▌      ▄▄▄▄▄▄▄▄▄█░▌▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌▐░▌       ▐░▌\r\n");
	sendmsg("▐░█▀▀▀▀▀▀▀▀▀ ▐░▌               ▐░▌     ▐░░░░░░░░░░░▌▐░▌   ▐░▌ ▐░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌   ▐░▌ ▐░▌▐░▌       ▐░▌\r\n");
	sendmsg("▐░▌          ▐░▌               ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌    ▐░▌▐░▌▐░▌       ▐░▌▐░▌    ▐░▌▐░▌▐░▌       ▐░▌\r\n");
	sendmsg("▐░▌          ▐░█▄▄▄▄▄▄▄▄▄  ▄▄▄▄█░█▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▐░▌▐░▌       ▐░▌▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄█░▌\r\n");
	sendmsg("▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌▐░▌       ▐░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌\r\n");
	sendmsg(" ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀  ▀         ▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀ \r\n");
	sendmsg("       Powered by Nios II!\r\n       PCI core & PCI-UART Core by Evan Custodio\r\n\r\n");
	sendmsg("PCI2Nano is a combination of a reference platform,\r\na PCI core and an 8250-Compatible PCI-UART Function all open source. Neat!\r\n\r\n");
	sendmsg("Enjoy!\r\n\r\n");
}

int main()
{
  memset (buffer,0,sizeof(buffer));
  while (1)
  {
	  sendmsg("NIOS-PCI> ");
	  recvcmd();

	  if (strcmp("info",buffer) == 0)
	  {
		  banner();
		  continue;
	  }
	  if (strcmp("help",buffer) == 0)
	  	  {
		    sendmsg("\r\nPCI2Nano - \"Making PCI cool again!\"\r\n\r\n");
		    sendmsg("PCI2Nano Help Output:\r\n");
		    sendmsg("    Commands:\r\n");
		    sendmsg("        help - displays this help output\r\n");
		    sendmsg("        info - displays information on PCI2Nano\r\n\r\n");
			continue;
	  	  }
	  if (strlen(buffer))
		  sendmsg("Unknown Command!\r\n");
  }
  return 0;
}
