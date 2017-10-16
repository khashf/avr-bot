
/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP

Port B, Pin 4 -> Output -> Right Motor Enable (Active Low: 0 -> enable, 1 -> disable)
Port B, Pin 5 -> Output -> Right Motor Direction (0 -> roll backward, 1-> roll forward)
Port B, Pin 7 -> Output -> Left Motor Enable (Active Low: 0 -> enable, 1 -> disable)
Port B, Pin 6 -> Output -> Left Motor Direction (0 -> roll backward, 1-> roll forward)

Port D, Pin 1 -> Input -> Left Whisker (Active Low: 0 -> has input, 1 -> no input)
Port D, Pin 0 -> Input -> Right Whisker (Active Low: 0 -> has input, 1 -> no input)

TODO

- shift bit
- 0x0 and 0xf ?

*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB = 0b11110000;					// set pins 4, 5, 6, 7 of port B for output
	PORTB = 0b11110000;					// initially disable all motor
	
	DDRD = 0b00000000;					// set all pins of port D for input
	PORTD = 0b11111111;					// set all Port D inputs as Tri-State
	
	const short turnTime = 1000;		// how long the bot turns
	const short reverseTime = 1000;		// how long the bot reverse (go backward)
	const short bumpSensitivity = 500;	// check bump for every 0.5s
	
	while (1)							// loop forever
	{
		if (PIND == 0b11111101)  {		// left whisker triggers
			PORTB = 0b00000000;			// move backward
			_delay_ms(reverseTime);     // keep moving backward for 1s
			PORTB = 0b01000000;			// turn right
			_delay_ms(turnTime);		// keep turning right for turnTime seconds
			
		}
		else if (PIND == 0b11111110) {	// right whisker triggers
			PORTB = 0b00000000;			// move backward
			_delay_ms(reverseTime);		// keep moving backward for 1s
			PORTB = 0b00100000;			// turn left
			_delay_ms(turnTime);		// keep turning left for 1s
		}
		else if (PIND == 0b11111100) {	// both whiskers trigger
			PORTB = 0b00000000;			// move backward
			_delay_ms(reverseTime);		// keep moving backward for 1s
			PORTB = 0b01000000;			// turn right
			_delay_ms(turnTime);		// keep turning right for 1s
		}
		PORTB = 0b01100000;				// make TekBot move forward
		_delay_ms(bumpSensitivity);		// keep moving forward for 500 ms
	}
}
