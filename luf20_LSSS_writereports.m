% This script takes the '.lsss' file as input, open the LSSS using
% the api functionality and writes zipped report files to the 'zipfile'.

% IMPORTANT NOTES:
% 1.The LSSS configuration file needs the connected flag set to false:
% <connection name="JavaDB" connected="false">. The flag is found in 
% C:\Users\nilsolav\.ApplicationData\lsss\config\application.xml
% 
% 2.An empty db needs to be generated using LSSS and put under
% D:/DATA/lsss_db_empty 
%
% 3. D:\DATA\lsss_db must exist
%

%% Setup
clear all
A{1}=true;  % Copy existing db
A{2}=false; % Fill empty db

URLprefix = 'http://localhost:8000/';
%lsssVersion = 'lsss-2.3.0-alpha-20171102-1008';
%lsssVersion = 'lsss-2.3.0-alpha-20171110-1154';
lsssVersion = 'lsss-2.3.0-alpha-20171116-1132';

MainDir = 'D:\DATA\';% The location of the local LSSS dB
ScratchDir = 'D:\DATA\';

reportfile{1}='S2016837_PEROS_3317';
reportfile{2}='S2016114_PGOSARS_4174';

datapath{1} = '\\ces.imr.no\cruise_data\2016\S2016837_PEROS_3317';
datapath{2} = '\\ces.imr.no\cruise_data\2016\S2016114_PGOSARS_4174';

lsssfile{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\LSSS\LSSS_FILES\lsss\S2016837_PEros[3578].lsss');
lsssfile{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\LSSS\LSSS_FILES\S2016114_PGOSARS_4174.lsss');

dbdir{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\LSSS\EXPORT\20160513\database\lsssExportDb\');
dbdir{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\LSSS\EXPORT\database\lsssExportDb');

ek60file{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\EK60\EK60_RAWDATA');
ek60file{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\EK60\EK60_RAWDATA');

workfile{1} = fullfile(datapath{1},'\ACOUSTIC_DATA\LSSS\WORK');
workfile{2} = fullfile(datapath{2},'\ACOUSTIC_DATA\LSSS\WORK');

% Test if the files are available
for i=1:length(lsssfile)
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
for An=1:2 %Both (1) existing and (2) empty db
   for i=1:length(lsssfile)
       %% Ensure that LSSS is disconnected from dB (When the API is upgraded I can do this within the API).
       copyfile('application_edited.xml','C:\Users\nilsolav\.ApplicationData\lsss\config\application.xml')
%         % Wait until the API is dead (from last run)
%         exe=true;
%         while exe
%             try
%                 webread([URLprefix 'lsss/application/ready']);
%                 pause(2) % Wait 2 sec and try again
%             catch
%                 exe=false;
%             end
%         end
%         
%         % Set the db flag before start up (this is really ugly coding, but
%         % works). The problem is that we need LSSS to start disconnected
%         % from the dd, but when we store to the db this flag is changed.
%         % This could be changed after storing, but if execution fails the
%         % flag will not be changed. I prefer to start up LSSS on an empty
%         % dB, diconnect the db, save preferences and exit.
%         
%         % Delete dB
%         rmdir(fullfile(MainDir,'lsss_DB'), 's')
%         % Copy a clean db
%         copyfile(fullfile(MainDir,'lsss_DB_empty'),fullfile(MainDir,'lsss_DB'))
%         % Start LSSS
%         lsssCommand = ['cmd.exe /c "C:\Program Files (x86)\Marec\' lsssVersion '\lsss\LSSS.bat"&'];
%         system(lsssCommand);
%         % Get the setup information from LSSS
%         str = webread([URLprefix 'lsss/application/config/xml']);
%         % Change the JavaDB connection flag to false
%         str2 = strrep(str,'<connection name="JavaDB" connected="true">','<connection name="JavaDB" connected="false">') ;
%         % Push it back thourgh the API
%         webwrite([URLprefix 'lsss/application/config/xml'],str2,weboptions('MediaType','application/xml','RequestMethod', 'post','Timeout',Inf));
%         % Save setting
%         webread([URLprefix,'/lsss/survey/save'])
%         %Exit LSSS
%         
        %% Copy db (or set up empty db) and work files 
        % Delete existing local database. This needs to be done prior to opening
        % lsss since lsss connect to the db at startup
        
        % Wait until the API is dead (from last run)
        exe=true;
        while exe
            try
                webread([URLprefix 'lsss/application/ready']);
                pause(2) % Wait 2 sec and try again
            catch
                exe=false;
            end
        end
        try
            rmdir(fullfile(MainDir,'lsss_DB'), 's')
        end
        % Copy new or existing database
        if A{An}
            % Copy the database from ces.imr.no:
            copyfile(fullfile(dbdir{i},'*'),fullfile(MainDir,'lsss_DB'))
        else
            % Copy an empty db:
            copyfile(fullfile(MainDir,'lsss_DB_empty'),fullfile(MainDir,'lsss_DB'))
        end
        
        % Initializing & start LSSS
        lsssCommand = ['cmd.exe /c "C:\Program Files (x86)\Marec\' lsssVersion '\lsss\LSSS.bat"&'];
        system(lsssCommand);
        
        % Wait until the API is live
        exe=true;
        while exe
            try
                webread([URLprefix 'lsss/application/ready']);
                exe=false;
            catch
                pause(2) % Wait 2 sec and try again
            end
        end
        
        % Connect to the dB
        webwrite([URLprefix 'lsss/application/config/unit/DatabaseConf/connected'],...
           struct('value', 'true'), weboptions('MediaType','application/json','Timeout',Inf));
        
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
            firstIndex = 0;
            lastIndex = webread([URLprefix 'lsss/survey/config/unit/DataConf/files'],weboptions('Timeout',Inf));
            
%------------------------
warning('Hack for testing only')            
lastIndex = 200;
firstIndex = 204;
%------------------------

            % Read the files into LSSS
            webwrite([URLprefix 'lsss/survey/config/unit/DataConf/files/selection'], struct('firstIndex', firstIndex,'lastIndex', lastIndex ), weboptions('MediaType','application/json','Timeout',Inf));

            % Wait until the files are read before moving on
            webread([URLprefix 'lsss/data/wait'], weboptions('RequestMethod', 'get','Timeout',Inf));
            
            % Store to local LSSS db
            % Note that 38 needs to be an array in the json object, I use
            % [38 38] to force that. Not very beautiful, but it works 
            intpr = struct('resolution',.1,'quality',1,'frequencies',[38 38]);% Store resolution, quliaty (usually 1) and the frequencies.
            webwrite([URLprefix 'lsss/module/InterpretationModule/database'],intpr , weboptions('RequestMethod', 'post','MediaType','application/json','Timeout',Inf));
        end
        
        % Export from database (either filled from raw and work or copied from server)
        if A{An}
            file=fullfile(ScratchDir,[reportfile{i},'_fromNMDdb.xml']);
        else
            file=fullfile(ScratchDir,[reportfile{i},'_fromNMDraw.xml']);
        end
        websave(file, [URLprefix 'lsss/database/report/20'],weboptions('Timeout',Inf));
        
        % Close LSSS
        try %For some reason this fails, but still closes LSSS...
            webread([URLprefix 'lsss/application/exit'], weboptions('RequestMethod', 'post'))
            wait(30)
        end
   end
end