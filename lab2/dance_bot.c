//
///*
//This code will cause a TekBot connected to a mega128 board to 'dance' in a cool
//pattern. 
//
//Pin 4, 5, 6, 7 of Port B pins are used for output.
//No pins are used as input
//
//PORT MAP
//Port B, Pin 4 -> Output -> Right Motor Enable (Active Low: 0 -> enable, 1 -> disable)
//Port B, Pin 5 -> Output -> Right Motor Direction (0 -> roll backward, 1-> roll forward)
//Port B, Pin 7 -> Output -> Left Motor Enable (Active Low: 0 -> enable, 1 -> disable)
//Port B, Pin 6 -> Output -> Left Motor Direction (0 -> roll backward, 1-> roll forward)
//*/
//#define F_CPU 16000000
//#include <avr/io.h>
//#include <util/delay.h>
//#include <stdio.h>
//
//int main(void)
//{
	//// first 4 pins of port B for output,
	//// the remaining pins is for input
	//DDRB = 0b11110000;      
	//// set initial value for Port B outputs
	//// initially, disable both motors
	//// Active Low
	//// 1 -> enable
	//// 0 -> disable
	//PORTB = 0b11110000;     
	//
	//while (1) { // loop forever
//
		//PORTB = 0b01100000;     // make TekBot move forward
		//_delay_ms(500);         // wait for 500 ms
		//PORTB = 0b00000000;     // move backward
		//_delay_ms(500);         // wait for 500 ms
		//PORTB = 0b00100000;     // turn left
								//// left motor direction = 0 -> rolls backward
								//// right motor direction = 1 -> rolls forward
		//_delay_ms(1000);        // wait for 1 s
		//PORTB = 0b01000000;     // turn right
								//// left motor direction = 1 -> rolls forward
								//// right motor direction = 0 -> rolls backward
		//_delay_ms(2000);        // wait for 2 s
		//PORTB = 0b00100000;     // turn left
		//_delay_ms(1000);        // wait for 1 s
	//}
//}
