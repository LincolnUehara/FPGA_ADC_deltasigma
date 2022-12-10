clear all;
close all;
clc;

# Import signal package
pkg load signal

Fs   = 300e3; # 300 kHz - Freq of sampling
dt   = 1/Fs;
Fsig = 10e3;  # 10 kHz - Freq of the signal
Tdur = 1e-3;  # 1ms - Duration of the signal

tvec = 0:dt:Tdur-dt;         # Time vector (X)
y = 0.5 - (0.5 * square(pi*1750*tvec));

# To see the plot before processing
plot(tvec,y,'-o')

# Create csv folder if it do not exist
if(!isfolder("./csv"))
    mkdir("./csv")
endif

# Write files (the output value should be with dot)
csvwrite ("./csv/input.csv", y, 'precision', '%.4f') 
csvwrite ("./csv/time.csv", tvec)