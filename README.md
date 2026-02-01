# MSX JIO CART

This is a simple MSX cartridge that allows software-based serial communications like MSXJIO but without using joystick port 2.

It includes:
* a flash ROM writable by either software (in-system from MSX-DOS) or hardware (using an external programmer)
* an I/O register to interface with embedded serial modules
  * address of I/O register is configurable between a set of predefined options
* one or two of these serial modules (only one active at a time):
  * a RT232RL-based USB Serial Module
  * a Bluetooth HC-05 Module
* a switch to select the active serial module
  * optional if only one module is populated

What can I do with a msx-jio-cart?

* serve a hard or floppy disk-image from a host computer (or smartphone) to your MSX, through high-speed 115200 bauds communication (either USB or Bluetooth)
* more things to come

> [!NOTE]
> Documentation in progress


## Current Status

* First prototype PCB sent for manufacturing as of Dec 2nd 2025 (couldn't wait to confirm some footprints...).
* After a long wait, bare prototype PCBs arrived as of Jan 8th 2026. Now, let's find some time to assemble them and (cross fingers) hope I grabbed all needed components.
* First build1 prototype successfully assembled and tested as of Jan 11th 2026.
* Another build1 cartridge successfully assembled and tested as of Jan 30th 2026.

## [Firmware](https://github.com/b3rendsh/msxdos2s/tree/main/jio/client)

The msx-jio-cart uses @b3rendsh [JIO clients](https://github.com/b3rendsh/msxdos2s/tree/main/jio/client) in ROM format.

You can flash the ROM in-system using [HRA!](https://github.com/hra1129)'s [WRTSST.COM](https://github.com/hra1129/MSX_MegaSCC_for_SST39SF040/tree/main/tools/wrtsst) from your MSX. Or you can flash the ROM using a hardware programmer like TL866II Plus and a tool like [minipro](https://gitlab.com/DavidGriffith/minipro/).

See [ROM Flashing Instructions](#rom-flashing-instructions).

## [Software](https://github.com/louthrax/MSXJIO)

The msx-jio-cart requires one of @louthrax [JIO Servers](https://github.com/louthrax/MSXJIO/releases).

On the JIO server, choose the connection method (Serial or Bluetooth) that matches your current msx-jio-cart serial module selection, according to switch `_SW3_ BLUETOOTH/SERIAL`.

## [Hardware](hardware/kicad/)

The msx-jio-cart is made of a 2-layer PCB with several SMD and through-hole components placed on the front layer only:

* a 6-pin serial RT232RL USB module with DTR, TX, RX, VCC, CTS and GND signals.
* a 6-pin serial HC-05 Bluetooth module with STATE, RXD, TXD, GND, VCC and EN signals.
* a SST39SF010 1Mbit (128Kbyte) flash ROM to store the JIO client ROM
* a switch to disable the ROM at boot time (required to re-program the flash ROM from the MSX itself)
* 74HCT32 and 74HCT138 ICs to implement the I/O address selection logic and control interface
* a DIP switch to configure the I/O address of the msx-jio-cart register
* 74HCT173 and 74HCT245 to implement the I/O register
* extra TX/RX leds to signal transmission events
* a switch to select the active serial module
* several jumpers to control the cartridge behavior and features
* a header to configure the bluetooth module externally if required
* a cartridge-wide fuse to protect the MSX slot 5V power rail in case of a cartridge malfunction
* a Schottky diode to prevent back-powering the MSX from the serial USB module
* other active and passive components, some of them optional

### [msx-jio-cart-v1-build1](hardware/kicad/msx-jio-cart-v1-build1/)

:white_check_mark: This board has been successfully built and tested.

[<img src="images/msx-jiocart-v1-front-render_512x.png" width="512"/>](images/msx-jiocart-v1-front-render.png)

[<img src="images/msx-jiocart-v1-back-render_512x.png" width="512"/>](images/msx-jiocart-v1-back-render.png)

[Bill Of Materials (BoM)](https://html-preview.github.io/?url=https://raw.githubusercontent.com/herraa1/msx-jio-cart-v1/main/hardware/kicad/msx-jio-cart-v1-build1/bom/ibom.html)

[Schematic and PCB](https://kicanvas.org/?github=https%3A%2F%2Fgithub.com%2Fherraa1%2Fmsx-jio-cart-v1%2Ftree%2Fmain%2Fhardware%2Fkicad%2Fmsx-jio-cart-v1-build1)

|[<img src="images/msx-jiocart-v1-front-unpopulated-8742_256x.png" width="256"/>](images/msx-jiocart-v1-front-unpopulated-8742.png)|[<img src="images/msx-jiocart-v1-back-unpopulated-8743_256x.png" width="256"/>](images/msx-jiocart-v1-back-unpopulated-8743.png)|
|-|-|
|msx-jio-cart-v1 build1<br>PCB unpopulated front|msx-jio-cart-v1 build1<br>PCB unpopulated back|

|[<img src="images/msx-jiocart-v1-front-populated-serial-and-bluetooth-8744_512x.png" width="512"/>](images/msx-jiocart-v1-front-populated-serial-and-bluetooth-8744.png)|
|:--|
|msx-jio-cart-v1 build1 PCB populated front|

#### LED indicators

[<img src="images/msx-jiocart-v1-build1-leds_512x.png" width="512"/>](images/msx-jiocart-v1-build1-leds.png)

| **LED**   | **State**      | **Indication** |
|-----------|----------------|----------------|
| _RX_      | On             | data is being received from the MSX |
| _TX_      | On             | data is being sent to the MSX       |

#### Switches and Jumpers

[<img src="images/msx-jiocart-v1-build1-switches-and-jumpers_512x.png" width="512"/>](images/msx-jiocart-v1-build1-switches-and-jumpers.png)

| **Switch/Jumper** | **Label**          | **State**          | **Purpose**    |
|-------------------|--------------------|--------------------|----------------|
| _SW1_             | `ROMDIS`           | **Enable**\*       | Enable Flash ROM for normal operation                                           |
| _SW1_             | `ROMDIS`           | Disable            | Disable Flash ROM (only for in-system programming)                              |
| _SW2_             | `IOSEL`            | 1,2,3 Off          | Disable I/O register (JIO CART unavailable)                                     |
| _SW2_             | `IOSEL`            | **1 On 2,3 Off**\* | Configure I/O register at 00h..07h                                              |
| _SW2_             | `IOSEL`            | 2 On 1,3 Off       | Configure I/O register at 20h..27h                                              |
| _SW2_             | `IOSEL`            | 3 On 1,2 Off       | Configure I/O register at 30h..37h                                              |
| _SW3_             | `BLUETOOTH/SERIAL` | **Left**\*         | Enable Bluetooth, leave EN floating (data mode) when JP4 1-2                    |
| _SW3_             | `BLUETOOTH/SERIAL` | Middle             | Enable Bluetooth, control EN from I/O register when JP4 1-2                     |
| _SW3_             | `BLUETOOTH/SERIAL` | **Right**\*        | Enable USB                                                                      |
| _JP4_             | `BTENCTL`          | **1-2**\*          | Control EN according to SW3 position                                            |
| _JP4_             | `BTENCTL`          | 2-3                | Set EN high unconditionally (AT mode)                                           |

\* Default settings

#### Advanced jumpers

[<img src="images/msx-jiocart-v1-build1-advanced-jumpers_512x.png" width="512"/>](images/msx-jiocart-v1-build1-advanced-jumpers.png)

| **Jumper** | **Label**        | **State**          | **Purpose**    |
|------------|------------------|--------------------|----------------|
| _JP3_      | -                | **Open**\*         | (Advanced) Populate R4 and R5, drive Bluetooth EN signal using 3V3 logic        |
| _JP3_      | -                | Closed             | (Advanced) Do NOT populate R4 and R5, drive Bluetooth EN signal using 5V logic  |
| _JP2_      | -                | **Open**\*         | (Advanced) Populate R2 and R3, drive Bluetooth RXD signal using 3V3 logic       |
| _JP2_      | -                | Closed             | (Advanced) Do NOT populate R2 nor R3, drive Bluetooth RXD signal using 5V logic |
| _JP1_      | -                | **1-2**\*          | (Advanced) Populate C5 and U5, MSX reset causes reset/zeroing of I/O reg        |
| _JP1_      | -                | 2-3                | (Advanced) Do NOT populate C5 nor U5, I/O reg is never reset/zeroed             |

\* Default settings

#### Headers

[<img src="images/msx-jiocart-v1-build1-headers_512x.png" width="512"/>](images/msx-jiocart-v1-build1-headers.png)

| **Header** | **Label**        | **Purpose**    |
|------------|------------------|----------------|
| _J1_       | `EXTPROG`        | Allows to configure the Bluetooth module via AT commands externally |


## Cartridge Setup

### ROM Flashing Instructions

#### Flashing the ROM from MSX-DOS

[<img src="images/msx-jiocart-v1-flashing-with-wrtsst_512x.png" width="512"/>](images/msx-jiocart-v1-flashing-with-wrtsst.png)

1. Prepare your bootable MSX-DOS media (a floppy disk, a mass storage device, etc.)
2. Copy [WRTSST.COM](https://github.com/hra1129/MSX_MegaSCC_for_SST39SF040/blob/main/tools/wrtsst/WRTSST.COM) to your MSX-DOS media
3. Copy the JIO client ROMs [jio_dos1.rom](https://github.com/b3rendsh/msxdos2s/blob/main/jio/client/jio_dos1.rom) for DOS 1.x and [jio_dos2.rom](https://github.com/b3rendsh/msxdos2s/blob/main/jio/client/jio_dos2.rom) for DOS 2.x to your MSX-DOS media
4. Move the _SW1_ `ROMDIS` switch to the _disabled_ position (see [Switches and jumpers](#switches-and-jumpers))
5. With your MSX powered off, insert your bootable MSX-DOS media and insert the msx-jio-cart into an empty slot
6. Power on and boot your MSX with your MSX-DOS media
7. Once on the MSX-DOS prompt, move the _SW1_ `ROMDIS` switch to the _enabled_ position (see [Switches and jumpers](#switches-and-jumpers))

> [!WARNING]
> Make sure you select the right slot before using `WRTSST.COM`.
> If you select the wrong slot, or do not select a slot, and you happen to have other `SST39SF*` compatible Flash ROMs in your MSX system, you may end up erasing and overwriting the wrong IC.

8. To flash the `jio_dos1.rom` into the _msx-jio-cart_ inserted in _slot 1_, execute the following command in the MSX-DOS prompt:

  ~~~Shell
  WRTSST /S1 JIO_DOS1.ROM
  ~~~

   Change the /Sx parameter to the actual slot number where the msx-jio-cart is inserted.

8. To flash the `jio_dos2.rom` into the _msx-jio-cart_ inserted in _slot 1_, execute the following command in the MSX-DOS prompt:

  ~~~Shell
  WRTSST /S1 JIO_DOS2.ROM
  ~~~

   Change the /Sx parameter to the actual slot number where the msx-jio-cart is inserted.

#### Flashing the ROM using a TL866II Plus and minipro

1. Install [minipro](https://gitlab.com/DavidGriffith/minipro/) into your Linux box
2. Insert the `SST39SF010` PLLC32 Flash ROM IC into a PLCC32 to DIP32 adapter, taking into account the orientation markings
3. Insert the PLCC32 to DIP32 adapter into the `TL866II Plus`, again taking into account the orientation markings
4. Connect your `TL866II Plus` to a USB port of your Linux box
5. Check that the Flash ROM IC is correctly identified.
   It should indicate a Chip ID of `0xBFB5`.

  ~~~bash
  ./minipro -p SST39SF010@PLCC32 -D
  ~~~
  ~~~
  Found TL866II+ 04.2.132 (0x284)
  Device code: 02114104
  Serial code: DVJZVC8IFBXAEQ55JFIU
  USB speed: 12Mbps (USB 1.1)
  Chip ID: 0xBFB5  OK
  ~~~

6. Build a 128K file named `128kdos1.bin` with the `jio_dos1.rom` contents at the correct offset executing the following command:

  ~~~bash
  cat <(dd if=/dev/zero ibs=16k count=1 | LC_ALL=C tr "\000" "\377") jio_dos1.rom <(dd if=/dev/zero ibs=96k count=1 | LC_ALL=C tr "\000" "\377") > 128kdos1.bin
  ~~~

7. Build a 128K file named `128kdos2.bin` with the `jio_dos2.rom` contents at the correct offset executing the following command:

  ~~~bash
  cat <(dd if=/dev/zero ibs=16k count=1 | LC_ALL=C tr "\000" "\377") jio_dos2.rom <(dd if=/dev/zero ibs=80k count=1 | LC_ALL=C tr "\000" "\377") > 128kdos2.bin
  ~~~

8. To flash the `128kdos1.bin` for DOS 1.x into the Flash ROM, execute the following command:

  ~~~bash
  ./minipro -p SST39SF010@PLCC32 -w 128kdos1.bin
  ~~~
  ~~~
  Found TL866II+ 04.2.132 (0x284)
  Device code: 02114104
  Serial code: DVJZVC8IFBXAEQ55JFIU
  USB speed: 12Mbps (USB 1.1)
  Chip ID: 0xBFB5  OK
  Erasing... 0.40Sec OK
  Writing Code...  6.40Sec  OK
  Reading Code...  0.98Sec  OK
  Verification OK
  ~~~

9. To flash the `128kdos2.bin` for DOS 2.x into the Flash ROM, execute the following command:

  ~~~bash
  ./minipro -p SST39SF010@PLCC32 -w 128kdos2.bin
  ~~~
  ~~~
  Found TL866II+ 04.2.132 (0x284)
  Device code: 02114104
  Serial code: DVJZVC8IFBXAEQ55JFIU
  USB speed: 12Mbps (USB 1.1)
  Chip ID: 0xBFB5  OK
  Erasing... 0.40Sec OK
  Writing Code...  6.40Sec  OK
  Reading Code...  0.98Sec  OK
  Verification OK
  ~~~

### Bluetooth Configuration Instructions

#### Selecting Bluetooth AT configuration mode at 38400 bauds

To enable Bluetooth AT configuration mode at 38400 bauds, move the _SW1_ `ROMDIS` slider to the `right` (disable) position, move the _SW3_ `BLUETOOTH/SERIAL` slider to the `left` (Bluetooth) position and set the _JP4_ `BTENCTL` jumper to the `2-3` position.

This mode can be used to re-configure the bluetooth module using AT commands with a 38400 fixed baud rate irrespective of the configured baud rate at the module. If not already done, use the `JSM` tool in this mode to assign a name to the Bluetooth module and to set the baud rate to 115200.

| **Switch/Jumper** | **Label**          | **State**          | **Purpose**    |
|-------------------|--------------------|--------------------|----------------|
| _SW1_             | `ROMDIS`           | Disable            | Disable Flash ROM (only for in-system programming or HC-05 re-configuration)    |
| _SW3_             | `BLUETOOTH/SERIAL` | **Left**\*         | Enable Bluetooth, leave EN floating (data mode) when JP4 1-2                    |
| _JP4_             | `BTENCTL`          | 2-3                | Set EN high unconditionally (AT mode)                                           |

[<img src="images/msx-jiocart-ATmode.png" width="512"/>](images/msx-jiocart-ATmode.png)

##### Identifying AT mode 38400 baud state

In Bluetooth AT configuration mode at 38400 bauds, the module LED goes on for 2 seconds approximately and then goes off for 1 second, repeating this pattern continuously.

[<img src="images/msx-jiocart-bluetooth-led-blinking-atmode.gif"/>](images/msx-jiocart-bluetooth-led-blinking-atmode.gif)

#### Using the JSM tool to configure the Bluetooth module

TBD


## Cartridge Operation

### Setting the cartridge I/O address

With the cartridge removed from the MSX and without power applied, slide only one of the three switches in the _SW2_ `IOSEL` DIP switch to the `ON` position to select one of the possible I/O address ranges.

See the [Switches and jumpers](#switches-and-jumpers) section to determine which I/O address range is enabled by each switch.

> [!NOTE]
> Depending on which orientation was used when the DIP switch was soldered, the numbering and the `ON` position side may be different. Always use the numbering of the cartridge silkscreen to identify the `1`, `2` and `3` switches (not the numbering of the DIP switch) and always use the DIP switch `ON` position marking to determine the ON position.

> [!TIP]
> The JIO function of the MSX JIO cartridge can be disabled by setting all of the `1`, `2` and `3` switches to the `OFF` position. 

### Selecting USB Serial Mode

To enable USB Serial mode, move the _SW1_ `ROMDIS` slider to the `left` (enable) position and move the _SW3_ `BLUETOOTH/SERIAL` slider to the `right` (USB Serial) position.

| **Switch/Jumper** | **Label**          | **State**          | **Purpose**    |
|-------------------|--------------------|--------------------|----------------|
| _SW1_             | `ROMDIS`           | **Enable**\*       | Enable Flash ROM for normal operation                                           |
| _SW3_             | `BLUETOOTH/SERIAL` | **Right**\*        | Enable USB                                                                      |

[<img src="images/msx-jiocart-usb-mode.png" width="512"/>](images/msx-jiocart-usb-mode.png)

#### Identifying USB Serial Mode

In USB Serial mode, the USB module RX and TX LEDs blink at the same time as the cartridge RX and TX LEDs.

[<img src="images/msx-jiocart-usb-led-blinking.gif"/>](images/msx-jiocart-usb-led-blinking.gif)


### Selecting Bluetooth normal mode

To enable Bluetooth normal mode, move the _SW1_ `ROMDIS` slider to the `right` (disable) position, move the _SW3_ `BLUETOOTH/SERIAL` slider to the `left` (Bluetooth) position and set the _JP4_ `BTENCTL` jumper to the `1-2` position.

This mode should only be used once the Bluetooth module has been configured at 115200 bauds.

| **Switch/Jumper** | **Label**          | **State**          | **Purpose**    |
|-------------------|--------------------|--------------------|----------------|
| _SW1_             | `ROMDIS`           | **Enable**\*       | Enable Flash ROM for normal operation                                           |
| _SW3_             | `BLUETOOTH/SERIAL` | **Left**\*/Middle  | Enable Bluetooth                                                                |
| _JP4_             | `BTENCTL`          | **1-2**\*          | Control EN according to SW3 position                                            |

[<img src="images/msx-jiocart-bluetooth-mode.png" width="512"/>](images/msx-jiocart-bluetooth-mode.png)

#### Identifying normal mode

##### Non-paired/Unconnected state

In this mode, the bluetooth module is waiting for another unpaired device to pair, or from a previously paired device to connect. The LED blinks 5 times per second approximately.

[<img src="images/msx-jiocart-bluetooth-led-blinking-unpaired.gif"/>](images/msx-jiocart-bluetooth-led-blinking-unpaired.gif)

##### Connected state

In this mode, the bluetooth module is connected to a paired device. The LED blinks twice in a second, then goes off for two seconds, repeating this pattern continuously.

[<img src="images/msx-jiocart-bluetooth-led-blinking-paired.gif"/>](images/msx-jiocart-bluetooth-led-blinking-paired.gif)


## Compatibility Tests

| **Model**                                                                          | **msx-jio-cart v1 build1** |
|------------------------------------------------------------------------------------|----------------------------|
| [Sony MSX HB-101P](https://www.msx.org/wiki/Sony_HB-101P)                          |           OK               |
| [Sony MSX HB-501F](https://www.msx.org/wiki/Sony_HB-501F)                          |           OK               |
| [Toshiba MSX HX-10P](https://www.msx.org/wiki/Toshiba_HX-10P)                      |           OK               |
| [Philips MSX2 VG-8235](https://www.msx.org/wiki/Philips_VG-8235)                   |           OK               |
| [Panasonic MSX2+ FS-A1WSX](https://www.msx.org/wiki/Panasonic_FS-A1WSX)            |           OK               |
| [Omega MSX2+](https://github.com/skiselev/omega)                                   |           OK               |
| [Tides Rider](https://genami.shop/products/tides-rider-hdk)                        |           OK               |
| [JFF-TMSHAT](https://github.com/herraa1/JFF-TMSHAT)                                |           OK               |
| [uMSX](https://theretrohacker.com/2022/07/08/yet-another-fpga-based-msx-the-umsx/) |           OK               |


## Errata / Known Issues

* On some MSX systems, by design or due to the aging of some components, the voltage supplied to the cartridge slots is suboptimal and the bluetooth module of a msx-jio-cart with both USB and bluetooth modules installed may be slower or even randomly disconnect. The cause is likely the additional voltage drop within the cartridge due to the reverse current protection diode that protects the MSX from being back-powered from the USB serial module.

  A workaround for this problem affecting only the bluetooth module is to connect the msx-jio-cart USB port to a 5V USB power supply or data port of a computer, as the USB connector of the USB serial module can back-power the bluetooth module (but never the MSX). By doing this, the bluetooth module and USB serial module are powered directly by 5V from the USB connection.


## msx-jio-cart early prototype

[<img src="images/msx-jiocart-early-prototype-board_512x.png" width="512"/>](images/msx-jiocart-early-prototype-board.png)


## References

NYYRIKKI's 115200 bps routines
* https://www.msx.org/forum/msx-talk/development/software-rs-232-115200bps-on-msx

b3rendsh msxdos2s
* https://github.com/b3rendsh/msxdos2s

Louthrax MSXJIO
* https://github.com/louthrax/MSXJIO

Skoti's Spider Flash Cart
* https://github.com/konkotgit/MSX-Spider-Flash-Cart

Danjovic Soda-IDE
* https://github.com/Danjovic/Soda-IDE
