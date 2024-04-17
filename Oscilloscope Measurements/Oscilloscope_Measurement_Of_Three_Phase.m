%% Variables
% Define constants and parameters
INPUT_BUFFER_SIZE = 2^9;   % Input buffer size in bytes (512 bytes)
TIMEOUT = 5;               % Timeout for communication in seconds
DATA_HEADER_LENGTH = 16;   % Length of data header in bytes
DATA_END_LENGTH = 2;       % Length of data end in bytes
connStr = 'USB0::0xF4EC::0xEE38::SDSMMFCQ5R7215::INSTR'; % Connection string
warning('off', 'instrument:visa:ClassToBeRemoved')

%% Determine Settings
% Set up VISA object for instrument communication
visaObj = visa('ni', connStr);
visaObj.InputBufferSize = INPUT_BUFFER_SIZE;
visaObj.Timeout = TIMEOUT;
fopen(visaObj);
fwrite(visaObj, 'CHDR OFF'); % Turn off headers to receive raw data
flushoutput(visaObj);

% Query instrument settings
vDiv = str2double(query(visaObj, 'C1:VDIV?'));  % Voltage division
sCount = str2double(query(visaObj, 'SANU? C1')); % Sample count
tDiv = str2double(query(visaObj, 'TDIV?'));      % Time division
sRate = str2double(query(visaObj, 'SARA?'));     % Sample rate
flushinput(visaObj);
fclose(visaObj);
delete(visaObj);
clear visaObj;

%% Connect
% Re-create VISA object with adjusted input buffer size
visaObj = visa('ni', connStr);
visaObj.InputBufferSize = sCount + DATA_HEADER_LENGTH + DATA_END_LENGTH;
visaObj.Timeout = TIMEOUT;
fopen(visaObj);
fwrite(visaObj, 'CHDR OFF'); % Turn off headers to receive raw data
flushoutput(visaObj);

tic
%% Pull Data
% Query waveform data for each channel
fwrite(visaObj, 'C1:WF? DAT2');
flushoutput(visaObj);
r1 = fread(visaObj);
flushinput(visaObj);

fwrite(visaObj, 'C2:WF? DAT2');
flushoutput(visaObj);
r2 = fread(visaObj);
flushinput(visaObj);

fwrite(visaObj, 'C3:WF? DAT2');
flushoutput(visaObj);
r3 = fread(visaObj);
flushinput(visaObj);

%% Decode Time
% Extract time data from the received raw data
d1 = r1((DATA_HEADER_LENGTH + 1):(end - DATA_END_LENGTH));
d2 = r2((DATA_HEADER_LENGTH + 1):(end - DATA_END_LENGTH));
d3 = r3((DATA_HEADER_LENGTH + 1):(end - DATA_END_LENGTH));

outputSize = size(d1);

% Calculate time vector based on time division and sample rate
timeOut = zeros(outputSize);
for i = 1:1:outputSize
    timeOut(i) = -(tDiv * 14 / 2) + ((i - 1) * (1 / sRate));
end

%% Decode raw data
% Convert raw data to voltage for each channel
C1 = zeros(outputSize);
C2 = zeros(outputSize);
C3 = zeros(outputSize);

for i = 1:1:outputSize
    % Adjust signedness of raw data
    if d1(i) > 127
        d1(i) = d1(i) - 255;
    end
    if d2(i) > 127
        d2(i) = d2(i) - 255;
    end
    if d3(i) > 127
        d3(i) = d3(i) - 255;
    end
    
    % Convert to voltage using voltage division
    C1(i) = d1(i) * (vDiv / 25);
    C2(i) = d2(i) * (vDiv / 25);
    C3(i) = d3(i) * (vDiv / 25);
end
toc

% Calculate voltage differences
Diff1 = C1 - C2;
Diff2 = C2 - C3;
Diff3 = C3 - C1;

%% Finding Phase
[xData, yData] = prepareCurveData( timeOut, Diff1 );
ft = fittype( 'a*sin(120*pi*x+b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [200 -3.2];
opts.StartPoint = [300 0];
opts.Upper = [400 3.2];
[fitresult, ~] = fit( xData, yData, ft, opts );
D1 = fitresult.b;

[xData, yData] = prepareCurveData( timeOut, Diff2 );
ft = fittype( 'a*sin(120*pi*x+b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [200 -3.2];
opts.StartPoint = [300 0];
opts.Upper = [400 3.2];
[fitresult, ~] = fit( xData, yData, ft, opts );
D2 = fitresult.b;

[xData, yData] = prepareCurveData( timeOut, Diff3 );
ft = fittype( 'a*sin(120*pi*x+b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [200 -3.2];
opts.StartPoint = [300 0];
opts.Upper = [400 3.2];
[fitresult, ~] = fit( xData, yData, ft, opts );
D3 = fitresult.b;


[xData, yData] = prepareCurveData( timeOut, C1 );
ft = fittype( 'a*sin(120*pi*x+b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [200 -3.2];
opts.StartPoint = [300 0];
opts.Upper = [400 3.2];
[fitresult, ~] = fit( xData, yData, ft, opts );
c1 = fitresult.b;

[xData, yData] = prepareCurveData( timeOut, C2);
ft = fittype( 'a*sin(120*pi*x+b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [200 -3.2];
opts.StartPoint = [300 0];
opts.Upper = [400 3.2];
[fitresult, ~] = fit( xData, yData, ft, opts );
c2 = fitresult.b;

[xData, yData] = prepareCurveData( timeOut, C3 );
ft = fittype( 'a*sin(120*pi*x+b)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [200 -3.2];
opts.StartPoint = [300 0];
opts.Upper = [400 3.2];
[fitresult, ~] = fit( xData, yData, ft, opts );
c3 = fitresult.b;


p1 = -rad2deg(c1-c3);
p2 = rad2deg(c2-c1);
p3 = rad2deg(c3-c2) + 360;

phaseDiff1_2_deg = rad2deg(D2-D1);
phaseDiff2_3_deg = rad2deg(D3-D2)+360;
phaseDiff3_1_deg = rad2deg(D1-D3);

%% Plotting
% Original plots
figure('Position', [350, 150, 800, 700]); % Adjust the size as needed
subplot(211)
hold on;
plot(timeOut, C1, 'LineWidth', 2, 'Color', 'b')
plot(timeOut, C2, 'LineWidth', 2, 'Color', 'g')
plot(timeOut, C3, 'LineWidth', 2, 'Color', 'r')
xlabel('Time')
ylabel('Voltage')
title('Voltage with Respect to Neutral')
legend('C1', 'C2', 'C3')
grid on;
hold off;
maxVoltage_C1 = max(C1);
maxVoltage_C2 = max(C2);
maxVoltage_C3 = max(C3);
text(1.04, .6, sprintf('RMS Voltage:\n C1: %.2fV \n C2: %.2fV \n C3: %.2fV', ...
    maxVoltage_C1/sqrt(2), maxVoltage_C2/sqrt(2), maxVoltage_C3/sqrt(2)), 'Units', 'normalized', 'HorizontalAlignment', 'center','FontWeight', 'bold');
text(1.04, .2, sprintf('Phases:\n C1-C2: %.2f °\n C2-C3: %.2f °\n C3-C1: %.2f °', ...
    p2, p1, p3), 'Units', 'normalized', 'HorizontalAlignment', 'center','FontWeight', 'bold');

% Difference plots with legends
subplot(212)
hold on;
plot(timeOut, Diff1, 'LineWidth', 2, 'Color', 'b')
plot(timeOut, Diff2, 'LineWidth', 2, 'Color', 'g')
plot(timeOut, Diff3, 'LineWidth', 2, 'Color', 'r')
xlabel('Time')
ylabel('Voltage Difference')
title('Voltage Differences between Phases')
legend('C1 - C2', 'C2 - C3', 'C3 - C1')
grid on;
hold off;

maxVoltage_Diff1 = max(Diff1);
maxVoltage_Diff2 = max(Diff2);
maxVoltage_Diff3 = max(Diff3);
text(1.04, .6, sprintf('RMS Voltage:\n C1-C2: %.2fV \n C2-C3: %.2fV \n C3-C1: %.2fV', ...
    maxVoltage_Diff1/sqrt(2), maxVoltage_Diff2/sqrt(2), maxVoltage_Diff3/sqrt(2)), 'Units', 'normalized', 'HorizontalAlignment', 'center','FontWeight', 'bold');
text(1.04, .2, sprintf('Phases:\n C1-C2: %.2f °\n C2-C3: %.2f °\n C3-C1: %.2f °', ...
    phaseDiff1_2_deg, phaseDiff2_3_deg, phaseDiff3_1_deg), 'Units', 'normalized', 'HorizontalAlignment', 'center','FontWeight', 'bold');

fclose(visaObj);
delete(visaObj);
clear visaObj;
