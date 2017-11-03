% This script takes the '.lsss' file as input, open the LSSS using 
% the api functionality and writes zipped report files to the 'zipfile'.
%
% In/output:
% lsssfile : full path tot he lsss file
% zipfile : full path to the zipped report file

URLprefix = 'http://localhost:8000/';
% lsssfile='\\ces.imr.no\cruise_data\2016\S2016837_PEROS_3317\ACOUSTIC_DATA\LSSS\LSSS_FILES\lsss\S2016837_PEros[3578].lsss';

% When LSSS was run on vessels the data were placed under LSSS/EK60Raw.
% Then, afterwards, the files were moved to the filestructure. 
% That means that the relative paths in the .lsss files are screwed,and all
% the file paths needs to be changed . I have hacked the lsss file, but  
% this could probably be done through the API.

lsssfile='D:\DATA\S2016837_PEROS_3317\ACOUSTIC_DATA\LSSS\LSSS_FILES\lsss\S2016837_PEros[3578].lsss';
% Start LSSS
lsssVersion = '2.2.0';
lsssVersion = 'lsss-2.3.0-alpha-20171102-1008';

lsssCommand = ['cmd.exe /c "C:\Program Files (x86)\Marec\' lsssVersion '\lsss\LSSS.bat"&'];
system(lsssCommand);

%% Open the survey (.lsss file). Uses POST and a JSON body
% The original .lsss file:
webwrite([URLprefix 'lsss/survey/open'], struct('value', lsssfile), weboptions('MediaType','application/json'));

% When I opened LSSS using this call , LSSS throws a dialogue telling me that
% the dB does not exist for the survey and ask if I would like to create
% one. Having a dialouge pop up does not work.

% But the answer is really No. I would like to connect to the db, or load
% the existing db where the data is exported from in the first place.
% According to Rolf, the main product from the survey is the db. 
% wherever that is.   

% The idea is then to read all the .raw files into LSSS:
    
%% Load raw files into LSSS

% first I get a list of all the files that are accessible via that .lsss
% file. Uses GET. This works fine:
r = webread([URLprefix 'lsss/data']);

% I then figure out how many files the .lsss file links to:
%nofile = length(r);
nofiles = 10; % But I use 6 files for testing purposes

% Then I read the files into LSSS
webwrite([URLprefix 'lsss/data/load/file/index/1'], struct('count', nofiles), weboptions('MediaType','application/json'));

% this works!


%% Wait a second
% Wait until the files are read before moving on (I assume this is the
% reason for this call (?), but it throws an error...)
webwrite([URLprefix 'lsss/data/wait'], weboptions('MediaType','application/json'));


%% The nesxt step is to store to the local LSSS db
% This initially failed, but tten I copied the work direcotry to a place where I have write access.

intpr = struct('resolution',0.1,'quality',1,'frequencies',38);% Store resolution, quliaty (usually 1) and the frequencies.
webwrite([URLprefix 'lsss/module/InterpretationModule/database'],intpr , weboptions('MediaType','application/json'));

% This does not work. I was able to store to the db manually. This is
% perhaps beacuse I do not have write access to the server (and I really
% should not have it either...)? But I can do it via the GUI... When moving
% the data to my laptop it still does not work.

%% Export from database
% export using default parameters
websave('LUF20.zip', [URLprefix 'lsss/database/report'])

% Tried a few variants:
%websave('LUF20.zip', [URLprefix 'lsss/database/report'],weboptions('MediaType','application/json'))
%websave('LUF20.zip', [URLprefix 'lsss/database/report'], 'startDate','10000101','startTime',1,'stopDate','99990101','stopTime','0','reports',20, weboptions('MediaType','application/json'));

% This does not work either... I were able to do it manually from LSSS.

%% Close LSSS
webwrite([URLprefix 'lsss/application/exit'], weboptions('MediaType','application/json'));

% does not work either...
