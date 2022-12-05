clear all;
close all;
clc;

input = csvread ("./csv/input.csv")
output = csvread ("./csv/output.csv")
xaxis = csvread ("./csv/time.csv")

#figure
plot(xaxis, input, "-r", xaxis, output, "-b")
xlabel('Time in [sec]')
ylabel('Amplitude in [V]')
#grid on