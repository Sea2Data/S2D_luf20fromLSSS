% This script takes the '.lsss' file as input, open the LSSS using
% the api functionality and writes zipped report files to the 'zipfile'.

%% Setup
clear all
A{1}=true;  % Cooy existing db
A{2}=false; % Fill empty db

URLprefix = 'http://localhost:8000/';
%lsssVersion = 'lsss-2.3.0-alpha-20171102-1008';
lsssVersion = 'lsss-2.3.0-alpha-20171110-1154';

MainDir = 'D:\DATA\';% The location of the local LSSS dB

reportfile{1}='S2016837_PEROS_3317_local';
reportfile{2}='S2016837_PEROS_3317_server';
reportfile{3}='S2016114_PGOSARS_4174_local';
reportfile{4}='S2016114_PGOSARS_4174_server';

datapath{1} = 'D:\DATA\S2016837_PEROS_3317';
datapath{2} = '\\ces.imr.no\cruise_data\2016\S2016837_PEROS_3317';
datapath{3} = 'D:\DATA\S2016114_PGOSARS_4174';
datapath{4} = '\\ces.imr.no\cruise_data\2016\S2016114_PGOSARS_4174';

lsssfile{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\LSSS\LSSS_FILES\lsss\S2016837_PEros[3578].lsss');
lsssfile{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\LSSS\LSSS_FILES\lsss\S2016837_PEros[3578].lsss');
lsssfile{3} = fullfile(datapath{3},'\ACOUSTIC_DATA\LSSS\LSSS_FILES\S2016114_PG.O.Sars[1016].lsss');
lsssfile{4} = fullfile(datapath{4},'\ACOUSTIC_DATA\LSSS\LSSS_FILES\S2016114_PGOSARS_4174.lsss');

dbdir{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\LSSS\EXPORT\20160513\database\lsssExportDb\');
dbdir{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\LSSS\EXPORT\20160513\database\lsssExportDb\');
dbdir{3} = fullfile(datapath{3},'\ACOUSTIC_DATA\LSSS\EXPORT\database\lsssExportDb');
dbdir{4} = fullfile(datapath{4},'\ACOUSTIC_DATA\LSSS\EXPORT\database\lsssExportDb');

ek60file{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\EK60\EK60_RAWDATA');
ek60file{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\EK60\EK60_RAWDATA');
ek60file{3} = fullfile(datapath{3},'\ACOUSTIC_DATA\EK60\EK60_RAWDATA');
ek60file{4} = fullfile(datapath{4},'\ACOUSTIC_DATA\EK60\EK60_RAWDATA');

workfile{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\LSSS\WORK');
workfile{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\LSSS\WORK');
workfile{3} = fullfile(datapath{3},'\ACOUSTIC_DATA\LSSS\WORK');
workfile{4} = fullfile(datapath{4},'\ACOUSTIC_DATA\LSSS\WORK');

% Test if the files are available
for i=1:4
    if ~exist(lsssfile{i})
        disp([lsssfile{i},' does not exist'])
    end
    if ~exist(dbdir{i})
        disp([dbdir{i},' does not exist'])
    end
    if ~exist(ek60file{i})
        disp([ek60file{i},' does not exist'])
    end
    if ~exist(workfile{i})
        disp([workfile{i},' does not exist'])
    end
end

%% Select survey
%for An=2%1:2 %Both (1) existing and (2) empty db
%    for i=1%1:4
        %% Copy db (or set up empty db)
An=2,i=1        
        % Delete existing local database. This needs to be done prior to opening
        % lsss since lsss connect to the db at startup
        rmdir(fullfile(MainDir,'lsss_DB'), 's')
        % Copy new or existing database
        if A{An}
            copyfile(fullfile(dbdir{i},'*'),fullfile(MainDir,'lsss_DB'))
        else
            copyfile(fullfile(MainDir,'lsss_DB_empty'),fullfile(MainDir,'lsss_DB'))
        end
        
        % Initializing & start LSSS
        lsssCommand = ['cmd.exe /c "C:\Program Files (x86)\Marec\' lsssVersion '\lsss\LSSS.bat"&'];
        system(lsssCommand);
        
        % Wait until the API is live
        exe=true;
        while exe
            try
                webread([URLprefix 'lsss/application/config/xml']);
                exe=false;
            catch
                pause(2)%Wait until the LSSS API is up and running
            end
        end
        
        % Open the survey (.lsss file). Uses POST and a JSON body
        webwrite([URLprefix 'lsss/survey/open'], struct('value', lsssfile{i}), weboptions('MediaType','application/json','Timeout',Inf));
        
        % Fill db from raw and work files
        if ~A{An}
            % Set EK60 file dir
            webwrite([URLprefix 'lsss/survey/config/unit/DataConf/parameter/DataDir'],...
                struct('value',ek60file{i}), weboptions('MediaType','application/json','RequestMethod', 'post','Timeout',Inf));
            
            % Set WORK file dir
            webwrite([URLprefix 'lsss/survey/config/unit/DataConf/parameter/WorkDir'],...
                struct('value',workfile{i}), weboptions('MediaType','application/json','RequestMethod', 'post','Timeout',Inf));
            
            % List of raw files from the .lsss
            r = webread([URLprefix 'lsss/data'],weboptions('Timeout',Inf));
            nofiles = length(r.files);
            
            % Read the files into LSSS
            webwrite([URLprefix 'lsss/data/load/file/index/0?count=',num2str(nofiles)], struct('count', nofiles), weboptions('MediaType','application/json','Timeout',Inf));
            
            % Wait until the files are read before moving on
            webread([URLprefix 'lsss/data/wait'], weboptions('RequestMethod', 'get','Timeout',Inf));
            
            % Store to local LSSS db
            % Note that 38 needs to be an array, use [38 38]. This is not
            % very beatiful, but it works 
            intpr = struct('resolution',.1,'quality',1,'frequencies',[38 38]);% Store resolution, quliaty (usually 1) and the frequencies.
            webwrite([URLprefix 'lsss/module/InterpretationModule/database'],intpr , weboptions('RequestMethod', 'post','MediaType','application/json','Timeout',Inf));
        end
        
        % Export from database (either filled from raw and work or copied from server)
        % export using default parameters
        % websave('LUF20_new.zip', [URLprefix 'lsss/database/report'])
        if A{An}
            file=['./',reportfile{i},'_fromdb.zip'];
        else
            file=['./',reportfile{i},'_fromraw.zip'];
        end
        websave(file, [URLprefix 'lsss/database/report'], 'startDate', 0, 'startTime', 0, ...
            'stopDate', 99991231, 'stopTime', 240000, 'reports',  20,weboptions('Timeout',Inf));
        
        % Close LSSS
        webread([URLprefix 'lsss/application/exit'], weboptions('RequestMethod', 'post','Timeout',Inf))
%    end
%end