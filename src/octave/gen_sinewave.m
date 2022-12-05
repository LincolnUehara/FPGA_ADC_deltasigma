clear all;
close all;
clc;

Fs   = 300e3; # 300 kHz - Freq of sampling
dt   = 1/Fs;
Fsig = 10e3;  # 10 kHz - Freq of the signal
Tdur = 1e-3;  # 1ms - Duration of the signal

tvec = 0:dt:Tdur-dt;         # Time vector (X)
y = 1 + sin(2*pi*Fsig*tvec); # sine wave (Y)

# Create csv folder if it do not exist
if(!isfolder("./csv"))
    mkdir("./csv")
endif

# Write files (the output value should be with dot)
csvwrite ("./csv/input.csv", y, 'precision', '%.4f') 
csvwrite ("./csv/time.csv", tvec)
