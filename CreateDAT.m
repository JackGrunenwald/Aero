function [] = CreateDAT(InputFileName, OutputFileName, AngleOfAttack)
% 
% Converts igs coordinate data to scaled coordinate data for the hotwire
% machine and saves as a .dat file
%
%
%
%
%
%
%
%
%

OutputAngle = -0.9943*(AngleOfAttack*(pi/180)) + 0.0149;

filename = InputFileName;
delimiter = ',';
startRow = 5;

% Read columns of data as text:
formatSpec = '%s%s%s%[^\n\r]';

% Open the text file.
fileID = fopen(filename,'r');

% Read columns of data according to the format.
%  This call is based on the structure of the file used to generate this
%  code. If an error occurs for a different file, try regenerating the code
%  from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

% Close the text file.
fclose(fileID);

% Convert the contents of columns containing numeric text to numbers.
%  Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end

% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

% Create output variable
AirfoilData = cell2mat(raw);
% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp R;

ValidIndex = find(abs(AirfoilData(:,2)>=0));

NewAirfoilData = AirfoilData(ValidIndex,:);

CoordData = find(AirfoilData(ValidIndex,1)==116);

OGAirfoilCoords = NewAirfoilData(CoordData, 2:3);

% Start modifying data

TrailingEdgePoint = OGAirfoilCoords(find(OGAirfoilCoords==max(OGAirfoilCoords(:,1))), :);

LeftPushCoords = OGAirfoilCoords - TrailingEdgePoint;

InvertCoords = [-1*LeftPushCoords(:,1), LeftPushCoords(:,2)];

TiltedCoords = [((cos(OutputAngle)*InvertCoords(:,1))+(sin(OutputAngle)*InvertCoords(:,2))), ((-1*sin(OutputAngle)*InvertCoords(:,1))+(cos(OutputAngle)*InvertCoords(:,2)))];

InvertCoords2 = [-1*TiltedCoords(:,1), TiltedCoords(:,2)];

LeadingEdgePoint = InvertCoords2(find(InvertCoords2==min(InvertCoords2(:,1))), :);

RightPushCoords = [InvertCoords2(:,1) - LeadingEdgePoint(:,1), InvertCoords2(:,2)];

UpPushPoint = RightPushCoords((find(RightPushCoords(:,1)==0)),2);

UpPushCoords = [RightPushCoords(:,1), (RightPushCoords(:,2) - UpPushPoint)];

ScaledCoords = [(UpPushCoords(:,1)/max(UpPushCoords(:,1))), (UpPushCoords(:,2)/max(UpPushCoords(:,1)))];


%% Export to text

% OutputFileName = 'Airfoil 1 Data 2'; % Filename test (Use as input
% variable) [DELETE SOON]

FileName = sprintf('%s.dat',OutputFileName);

fid = fopen(FileName, 'wt');

for n = 1:size(ScaledCoords,1)
    fprintf(fid, '  %0.5f', ScaledCoords(n,1));
    fprintf(fid, '  %0.5f', ScaledCoords(n,2));
    fprintf(fid, '\n');
end 
fclose(fid);


