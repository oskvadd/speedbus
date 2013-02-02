toggle_led.asm: toggle_led.hex
	gpasm toggle_led/toggle_led.asm
	sudo ./pk2cmd -PPIC16F690 -F toggle_led/toggle_led.hex -M
	sudo ./pk2cmd -PPIC16F690 -T
