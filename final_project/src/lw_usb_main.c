#include <stdio.h>
#include "platform.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/USB.h"
#include "lw_usb/usb_ch9.h"
#include "lw_usb/transfer.h"
#include "lw_usb/HID.h"

#include "xparameters.h"
#include <xgpio.h>

#include "hdmi_text_controller.h"

extern HID_DEVICE hid_device;

static XGpio Gpio_hex;

static BYTE addr = 1; 				//hard-wired USB address
const char* const devclasses[] = { " Uninitialized", " HID Keyboard", " HID Mouse", " Mass storage" };
volatile uint32_t* score_gpio_data = (uint32_t*)0x40030000;
volatile uint32_t highest_score = 0;
volatile uint32_t* game_over_gpio_data = (uint32_t*)0x40040000;
volatile uint32_t* restart_gpio_data = (uint32_t*)0x40050000;

BYTE GetDriverandReport() {
	BYTE i;
	BYTE rcode;
	BYTE device = 0xFF;
	BYTE tmpbyte;

	DEV_RECORD* tpl_ptr;
	xil_printf("Reached USB_STATE_RUNNING (0x40)\n");
	for (i = 1; i < USB_NUMDEVICES; i++) {
		tpl_ptr = GetDevtable(i);
		if (tpl_ptr->epinfo != NULL) {
			xil_printf("Device: %d", i);
			xil_printf("%s \n", devclasses[tpl_ptr->devclass]);
			device = tpl_ptr->devclass;
		}
	}
	//Query rate and protocol
	rcode = XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
	if (rcode) {   //error handling
		xil_printf("GetIdle Error. Error code: ");
		xil_printf("%x \n", rcode);
	} else {
		xil_printf("Update rate: ");
		xil_printf("%x \n", tmpbyte);
	}
	xil_printf("Protocol: ");
	rcode = XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
	if (rcode) {   //error handling
		xil_printf("GetProto Error. Error code ");
		xil_printf("%x \n", rcode);
	} else {
		xil_printf("%d \n", tmpbyte);
	}
	return device;
}

void printHex (u32 data, unsigned channel)
{
	XGpio_DiscreteWrite (&Gpio_hex, channel, data);
}

int main() {
    init_platform();
    XGpio_Initialize(&Gpio_hex, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
   	XGpio_SetDataDirection(&Gpio_hex, 1, 0x00000000); //configure hex display GPIO
   	XGpio_SetDataDirection(&Gpio_hex, 2, 0x00000000); //configure hex display GPIO


   	BYTE rcode;
	BOOT_MOUSE_REPORT buf;		//USB mouse report
	BOOT_KBD_REPORT kbdbuf;

	BYTE runningdebugflag = 0;//flag to dump out a bunch of information when we first get to USB_STATE_RUNNING
	BYTE errorflag = 0; //flag once we get an error device so we don't keep dumping out state info
	BYTE device;

	int enter_pressed = 0;
	int finish_game;
	finish_game = 0;
	int game_restart;
	game_restart = 0;
	int temp;
	int length;
	int number;
	char str[32];
	int temp_high;
	int length_high;
	int number_high;
	char str_high[32];
	int seed;

	xil_printf("initializing MAX3421E...\n");
	MAX3421E_init();
	xil_printf("initializing USB...\n");
	USB_init();
	while (1) {
		xil_printf("."); //A tick here means one loop through the USB main handler
		MAX3421E_Task();
		USB_Task();
		if (GetUsbTaskState() == USB_STATE_RUNNING) {
			if (!runningdebugflag) {
				runningdebugflag = 1;
				device = GetDriverandReport();
			} else if (device == 1) {
				//run keyboard debug polling
				rcode = kbdPoll(&kbdbuf);
				if (rcode == hrNAK) {
					continue; //NAK means no new data
				} else if (rcode) {
					xil_printf("Rcode: ");
					xil_printf("%x \n", rcode);
					continue;
				}
				xil_printf("keycodes: ");
				for (int i = 0; i < 6; i++) {
					xil_printf("%x ", kbdbuf.keycode[i]);
				}
				//Outputs the first 4 keycodes using the USB GPIO channel 1
				printHex (kbdbuf.keycode[0] + (kbdbuf.keycode[1]<<8) + (kbdbuf.keycode[2]<<16) + + (kbdbuf.keycode[3]<<24), 1);
				//Modify to output the last 2 keycodes on channel 2.
				xil_printf("\n");
			}

			else if (device == 2) {
				rcode = mousePoll(&buf);
				if (rcode == hrNAK) {
					//NAK means no new data
					continue;
				} else if (rcode) {
					xil_printf("Rcode: ");
					xil_printf("%x \n", rcode);
					continue;
				}
				xil_printf("X displacement: ");
				xil_printf("%d ", (signed char) buf.Xdispl);
				xil_printf("Y displacement: ");
				xil_printf("%d ", (signed char) buf.Ydispl);
				xil_printf("Buttons: ");
				xil_printf("%x\n", buf.button);
			}
		} else if (GetUsbTaskState() == USB_STATE_ERROR) {
			if (!errorflag) {
				errorflag = 1;
				xil_printf("USB Error State\n");
				//print out string descriptor here
			}
		} else //not in USB running state
		{

			xil_printf("USB task state: ");
			xil_printf("%x\n", GetUsbTaskState());
			if (runningdebugflag) {	//previously running, reset USB hardware just to clear out any funky state, HS/FS etc
				runningdebugflag = 0;
				MAX3421E_init();
				USB_init();
			}
			errorflag = 0;
		}

		if (kbdbuf.keycode[0] == 40) {
			enter_pressed = 1;
		}

		if ((*score_gpio_data) > highest_score) {
			highest_score = (*score_gpio_data);
		}

		seed = 1;

		length = 0;
		length_high = 0;
		temp = (*score_gpio_data);
		temp_high = highest_score;
		number = (*score_gpio_data);
		number_high = highest_score;
		while (temp > 0) {
			temp /= 10;
			length++;
		}
		while (temp_high > 0) {
			temp_high /= 10;
			length_high++;
		}
		str[length] = '\0';
		str_high[length_high] = '\0';
		for (int i = length - 1; i >= 0; i--) {
			str[length-i-1] = (number % 10) + '0';
			number /= 10;
		}
		for (int i = length_high - 1; i >= 0; i--) {
			str_high[length_high-i-1] = (number_high % 10) + '0';
			number_high /= 10;
		}
		if (length == 0) {
			str[0] = '0';
			str[1] = '\0';
		}
		if (length_high == 0) {
			str_high[0] = '0';
			str_high[1] = '\0';
		}

		if (enter_pressed == 1 && (*game_over_gpio_data) == 0) {
			if ((*score_gpio_data) > highest_score) {
				highest_score = (*score_gpio_data);
			}
			for (int j = 0; j < 30; j++) {
				for (int i = 0; i < 40; i++) {
					(*restart_gpio_data) = 0;
					if (i <= 15) {
						if (j + 2*i == 30) {
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x22;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x22;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						} else if (j + 2*i < 30) {
							// 0x20442044
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x44;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x44;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						} else {
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						}
					}
					if (i >= 25) {
						if (j - 2*i == -50) {
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x22;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x22;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						} else if (j - 2*i < -50) {
							// 0x20442044
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x44;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x44;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						} else {
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						}
					}
					if (i > 15 && i < 25) {
						if ((j == 0 && i == 24) || (j == 1 && i == 23)) {
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						} else {
							hdmi_ctrl->VRAM[4*(j*40 + i)] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+1] = 0x20;
							hdmi_ctrl->VRAM[4*(j*40 + i)+2] = 0x55;
							hdmi_ctrl->VRAM[4*(j*40 + i)+3] = 0x20;
						}
					}
				}
			}
			for (int i = 40-(length+1)/2-7; i < 40-(length+1)/2; i++) {
				if (i == 40-(length+1)/2-7) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x43;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x75;
				}
				if (i == 40-(length+1)/2-6) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x72;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x72;
				}
				if (i == 40-(length+1)/2-5) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x65;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x6e;
				}
				if (i == 40-(length+1)/2-4) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x74;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				if (i == 40-(length+1)/2-3) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x53;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x63;
				}
				if (i == 40-(length+1)/2-2) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x6f;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x72;
				}
				if (i == 40-(length+1)/2-1) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x65;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
			}
			for (int i = 40-(length+1)/2; i < 40; i++) {
				if (str[2*(39-i)+1] == '0') {
					hdmi_ctrl->VRAM[4*i+1] = 0x30;
				}
				else if (str[2*(39-i)+1] == '1') {
					hdmi_ctrl->VRAM[4*i+1] = 0x31;
				}
				else if (str[2*(39-i)+1] == '2') {
					hdmi_ctrl->VRAM[4*i+1] = 0x32;
				}
				else if (str[2*(39-i)+1] == '3') {
					hdmi_ctrl->VRAM[4*i+1] = 0x33;
				}
				else if (str[2*(39-i)+1] == '4') {
					hdmi_ctrl->VRAM[4*i+1] = 0x34;
				}
				else if (str[2*(39-i)+1] == '5') {
					hdmi_ctrl->VRAM[4*i+1] = 0x35;
				}
				else if (str[2*(39-i)+1] == '6') {
					hdmi_ctrl->VRAM[4*i+1] = 0x36;
				}
				else if (str[2*(39-i)+1] == '7') {
					hdmi_ctrl->VRAM[4*i+1] = 0x37;
				}
				else if (str[2*(39-i)+1] == '8') {
					hdmi_ctrl->VRAM[4*i+1] = 0x38;
				}
				else if (str[2*(39-i)+1] == '9') {
					hdmi_ctrl->VRAM[4*i+1] = 0x39;
				}
				else {
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
				}

				if (str[2*(39-i)] == '0') {
					hdmi_ctrl->VRAM[4*i+3] = 0x30;
				}
				else if (str[2*(39-i)] == '1') {
					hdmi_ctrl->VRAM[4*i+3] = 0x31;
				}
				else if (str[2*(39-i)] == '2') {
					hdmi_ctrl->VRAM[4*i+3] = 0x32;
				}
				else if (str[2*(39-i)] == '3') {
					hdmi_ctrl->VRAM[4*i+3] = 0x33;
				}
				else if (str[2*(39-i)] == '4') {
					hdmi_ctrl->VRAM[4*i+3] = 0x34;
				}
				else if (str[2*(39-i)] == '5') {
					hdmi_ctrl->VRAM[4*i+3] = 0x35;
				}
				else if (str[2*(39-i)] == '6') {
					hdmi_ctrl->VRAM[4*i+3] = 0x36;
				}
				else if (str[2*(39-i)] == '7') {
					hdmi_ctrl->VRAM[4*i+3] = 0x37;
				}
				else if (str[2*(39-i)] == '8') {
					hdmi_ctrl->VRAM[4*i+3] = 0x38;
				}
				else if (str[2*(39-i)] == '9') {
					hdmi_ctrl->VRAM[4*i+3] = 0x39;
				}
				else {
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				hdmi_ctrl->VRAM[4*i] = 0x12;
				hdmi_ctrl->VRAM[4*i+2] = 0x12;
			}

			for (int i = 40-(length+1)/2-5+40; i < 40-(length+1)/2+40; i++) {
				if (i == 40-(length+1)/2-5+40) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x42;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x65;
				}
				if (i == 40-(length+1)/2-4+40) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x73;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x74;
				}
				if (i == 40-(length+1)/2-3+40) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x53;
				}
				if (i == 40-(length+1)/2-2+40) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x63;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x6f;
				}
				if (i == 40-(length+1)/2-1+40) {
					hdmi_ctrl->VRAM[4*i] = 0x12;
					hdmi_ctrl->VRAM[4*i+1] = 0x72;
					hdmi_ctrl->VRAM[4*i+2] = 0x12;
					hdmi_ctrl->VRAM[4*i+3] = 0x65;
				}
			}
			for (int i = 40-(length+1)/2+40; i < 40+40; i++) {
				if (str_high[2*(79-i)+1] == '0') {
					hdmi_ctrl->VRAM[4*i+1] = 0x30;
				}
				else if (str_high[2*(79-i)+1] == '1') {
					hdmi_ctrl->VRAM[4*i+1] = 0x31;
				}
				else if (str_high[2*(79-i)+1] == '2') {
					hdmi_ctrl->VRAM[4*i+1] = 0x32;
				}
				else if (str_high[2*(79-i)+1] == '3') {
					hdmi_ctrl->VRAM[4*i+1] = 0x33;
				}
				else if (str_high[2*(79-i)+1] == '4') {
					hdmi_ctrl->VRAM[4*i+1] = 0x34;
				}
				else if (str_high[2*(79-i)+1] == '5') {
					hdmi_ctrl->VRAM[4*i+1] = 0x35;
				}
				else if (str_high[2*(79-i)+1] == '6') {
					hdmi_ctrl->VRAM[4*i+1] = 0x36;
				}
				else if (str_high[2*(79-i)+1] == '7') {
					hdmi_ctrl->VRAM[4*i+1] = 0x37;
				}
				else if (str_high[2*(79-i)+1] == '8') {
					hdmi_ctrl->VRAM[4*i+1] = 0x38;
				}
				else if (str_high[2*(79-i)+1] == '9') {
					hdmi_ctrl->VRAM[4*i+1] = 0x39;
				}
				else {
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
				}

				if (str_high[2*(79-i)] == '0') {
					hdmi_ctrl->VRAM[4*i+3] = 0x30;
				}
				else if (str_high[2*(79-i)] == '1') {
					hdmi_ctrl->VRAM[4*i+3] = 0x31;
				}
				else if (str_high[2*(79-i)] == '2') {
					hdmi_ctrl->VRAM[4*i+3] = 0x32;
				}
				else if (str_high[2*(79-i)] == '3') {
					hdmi_ctrl->VRAM[4*i+3] = 0x33;
				}
				else if (str_high[2*(79-i)] == '4') {
					hdmi_ctrl->VRAM[4*i+3] = 0x34;
				}
				else if (str_high[2*(79-i)] == '5') {
					hdmi_ctrl->VRAM[4*i+3] = 0x35;
				}
				else if (str_high[2*(79-i)] == '6') {
					hdmi_ctrl->VRAM[4*i+3] = 0x36;
				}
				else if (str_high[2*(79-i)] == '7') {
					hdmi_ctrl->VRAM[4*i+3] = 0x37;
				}
				else if (str_high[2*(79-i)] == '8') {
					hdmi_ctrl->VRAM[4*i+3] = 0x38;
				}
				else if (str_high[2*(79-i)] == '9') {
					hdmi_ctrl->VRAM[4*i+3] = 0x39;
				}
				else {
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				hdmi_ctrl->VRAM[4*i] = 0x12;
				hdmi_ctrl->VRAM[4*i+2] = 0x12;
			}

			if (seed%2 == 0) {
				for (int i = 6; i < 8; i++) {
					if (i == 6) {
						hdmi_ctrl->VRAM[4*i] = 0x20;
						hdmi_ctrl->VRAM[4*i+1] = 0x10;
						hdmi_ctrl->VRAM[4*i+2] = 0x11;
						hdmi_ctrl->VRAM[4*i+3] = 0x10;

						hdmi_ctrl->VRAM[4*(i+40)] = 0x15;
						hdmi_ctrl->VRAM[4*(i+40)+1] = 0x10;
						hdmi_ctrl->VRAM[4*(i+40)+2] = 0x12;
				 		hdmi_ctrl->VRAM[4*(i+40)+3] = 0x10;

						hdmi_ctrl->VRAM[4*(i+80)] = 0x20;
						hdmi_ctrl->VRAM[4*(i+80)+1] = 0x10;
						hdmi_ctrl->VRAM[4*(i+80)+2] = 0x15;
						hdmi_ctrl->VRAM[4*(i+80)+3] = 0x10;
					}
					if (i == 7) {
						hdmi_ctrl->VRAM[4*i] = 0x10;
						hdmi_ctrl->VRAM[4*i+1] = 0x10;
						hdmi_ctrl->VRAM[4*i+2] = 0x20;
						hdmi_ctrl->VRAM[4*i+3] = 0x10;

						hdmi_ctrl->VRAM[4*(i+40)] = 0x14;
						hdmi_ctrl->VRAM[4*(i+40)+1] = 0x10;
						hdmi_ctrl->VRAM[4*(i+40)+2] = 0x13;
						hdmi_ctrl->VRAM[4*(i+40)+3] = 0x10;

						hdmi_ctrl->VRAM[4*(i+80)] = 0x26;
						hdmi_ctrl->VRAM[4*(i+80)+1] = 0x10;
						hdmi_ctrl->VRAM[4*(i+80)+2] = 0x15;
						hdmi_ctrl->VRAM[4*(i+80)+3] = 0x10;
					}
				}
			}

		} else if ((*game_over_gpio_data) == 0 && enter_pressed == 0) {
			(*restart_gpio_data) = 1;
			for (int i = 0; i < 338; i++) {
				// 0x20222022
				hdmi_ctrl->VRAM[4*i] = 0x55;
				hdmi_ctrl->VRAM[4*i+1] = 0x20;
				hdmi_ctrl->VRAM[4*i+2] = 0x55;
				hdmi_ctrl->VRAM[4*i+3] = 0x20;
			}

			for (int i = 338; i < 342; i++) {
				// 0x49124212
				if (i == 338) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x42; // B
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x49; // I
				}
				// 0x20124712
				if (i == 339) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x47;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				// 0x45124212
				if (i == 340) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x42;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x45;
				}
				// 0x20125412
				if (i == 341) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x54;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
			}
			for (int i = 342; i < 814+40+40; i++) {
				// 0x20222022
				hdmi_ctrl->VRAM[4*i] = 0x55;
				hdmi_ctrl->VRAM[4*i+1] = 0x20;
				hdmi_ctrl->VRAM[4*i+2] = 0x55;
				hdmi_ctrl->VRAM[4*i+3] = 0x20;
			}
			for (int i = 814+40+40; i < 826+40+40; i++) {
				// 0x72205020
				if (i == 814+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x50;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x72;
				}
				// 0x73206520
				if (i == 815+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x65;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x73;
				}
				// 0x20207320
				if (i == 816+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x73;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				// 0x45202220
				if (i == 817+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x22;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x45;
				}
				// 0x74206E20
				if (i == 818+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x6E;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x74;
				}
				// 0x72206520
				if (i == 819+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x65;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x72;
				}
				// 0x20202220
				if (i == 820+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x22;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				// 0x6F207420
				if (i == 821+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x74;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x6F;
				}
				// 0x73202020
				if (i == 822+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x73;
				}
				// 0x61207420
				if (i == 823+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x74;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x61;
				}
				// 0x74207220
				if (i == 824+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x72;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x74;
				}
				// 0x21202020
				if (i == 825+40+40) {
					hdmi_ctrl->VRAM[4*i] = 0x20;
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
					hdmi_ctrl->VRAM[4*i+2] = 0x20;
					hdmi_ctrl->VRAM[4*i+3] = 0x21;
				}
			}
			for (int i = 826+40+40; i < 1200; i++) {
				// 0x20222022
				hdmi_ctrl->VRAM[4*i] = 0x55;
				hdmi_ctrl->VRAM[4*i+1] = 0x20;
				hdmi_ctrl->VRAM[4*i+2] = 0x55;
				hdmi_ctrl->VRAM[4*i+3] = 0x20;
			}
		} else if ((*game_over_gpio_data) == 1) {
			(*restart_gpio_data) = 1;
			enter_pressed = 0;
			if ((*score_gpio_data) > highest_score) {
				highest_score = (*score_gpio_data);
			}
			for (int i = 0; i < 418; i++) {
				// 0x20222022
				hdmi_ctrl->VRAM[4*i] = 0x25;
				hdmi_ctrl->VRAM[4*i+1] = 0x20;
				hdmi_ctrl->VRAM[4*i+2] = 0x25;
				hdmi_ctrl->VRAM[4*i+3] = 0x20;
			}
			for (int i = 418; i < 423; i++) {
				if (i == 418) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x47;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x61;
				}
				if (i == 419) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x6D;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x65;
				}
				if (i == 420) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x4F;
				}
				if (i == 421) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x76;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x65;
				}
				if (i == 422) {
					hdmi_ctrl->VRAM[4*i] = 0x15;
					hdmi_ctrl->VRAM[4*i+1] = 0x72;
					hdmi_ctrl->VRAM[4*i+2] = 0x15;
					hdmi_ctrl->VRAM[4*i+3] = 0x21;
				}
			}
			for (int i = 423; i < 814+40; i++) {
				// 0x20222022
				hdmi_ctrl->VRAM[4*i] = 0x25;
				hdmi_ctrl->VRAM[4*i+1] = 0x20;
				hdmi_ctrl->VRAM[4*i+2] = 0x25;
				hdmi_ctrl->VRAM[4*i+3] = 0x20;
			}
			for (int i = 814; i < 827; i++) {
				// 0x72205020
				if (i == 814) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x50;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x72;
				}
				// 0x73206520
				if (i == 815) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x65;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x73;
				}
				// 0x20207320
				if (i == 816) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x73;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				// 0x45202220
				if (i == 817) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x22;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x53;
				}
				// 0x74206E20
				if (i == 818) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x70;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x61;
				}
				// 0x72206520
				if (i == 819) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x63;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x65;
				}
				// 0x20202220
				if (i == 820) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x22;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
				// 0x6F207420
				if (i == 821) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x74;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x6F;
				}
				// 0x73202020
				if (i == 822) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x20;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x72;
				}
				// 0x61207420
				if (i == 823) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x65;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x73;
				}
				if (i == 824) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x74;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x61;
				}
				if (i == 825) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x72;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x74;
				}
				if (i == 826) {
					hdmi_ctrl->VRAM[4*i] = 0x25;
					hdmi_ctrl->VRAM[4*i+1] = 0x21;
					hdmi_ctrl->VRAM[4*i+2] = 0x25;
					hdmi_ctrl->VRAM[4*i+3] = 0x20;
				}
			}
			for (int i = 827; i < 1200; i++) {
				// 0x20222022
				hdmi_ctrl->VRAM[4*i] = 0x25;
				hdmi_ctrl->VRAM[4*i+1] = 0x20;
				hdmi_ctrl->VRAM[4*i+2] = 0x25;
				hdmi_ctrl->VRAM[4*i+3] = 0x20;
			}
		}

		setColorPalette(0, 0, 0, 15);			// blue
		setColorPalette(1, 15, 9, 0);			// orange
		setColorPalette(2, 15, 15, 15);			// white
		setColorPalette(3, 0, 0, 0);			// black
		setColorPalette(4, 7, 15, 15);			// light blue
		setColorPalette(5, 7, 7, 8);			// grey
	}

    cleanup_platform();
	return 0;
}
