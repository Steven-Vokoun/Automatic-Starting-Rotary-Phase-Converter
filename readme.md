# Automatic Starting Rotary Phase Converter
Automatically starting and stopping rotary phase converter build.

There are three main folders:  
- 'Phase Converter build' holds the powerpoint describing the whole process and build including the schematic.  Additionally it holds the arduino code, schematic, and other information needed to replicate the device.  
- 'Oscilloscope measurements' represents Matlab code to measure the output three phase wave form using a Siglent SDS1104x-E oscilloscope and 10X probes.  This uses NIVISA and SCPI Commands.  May work with other manufactureres with minimal modifications.  
- 'Extra math' holds a spice file and matlab for finding the capacitor values, but should not be used as is an approximation and experimental methods are needed.

Parts list (Besides For Standard Phase Converter Componets):
- 6 Relay Board
- Single Pole Contactor
- Double Pole Contactor
- Tripple Pole Contactor
- Arduino Nano
- ADS1115 I2C dual channel differential ADC
- 2 - SCT013 20A 1V Current Transformer
