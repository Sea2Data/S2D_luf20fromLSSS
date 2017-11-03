% This is a wrapper for generating the luf20 files from the LSSS databases 
% from the ces.imr.no file structure
%
% Dependencies: 
% https://github.com/nilsolav/NMDAPIreader
%


%% Init

if isunix
    addpath('/nethome/nilsolav/repos/github/LSSSreader/src/')
    addpath('/nethome/nilsolav/repos/github/NMDAPIreader/')
    addpath('/nethome/nilsolav/repos/nilsolav/MODELS/matlabtools/Enhanced_rdir')
    dd='/data/cruise_data/';
else
    cd D:\repos\Github\S2D_luf20fromLSSS
    dd='\\ces.imr.no\cruise_data\';
end

%% Get survey time series structure
D = NMDAPIreader_readcruiseseries;
save('D','D')

%% Get information and location of the lsss files per cruise series
load('D')
DataStatus = cell(1,8);
DataStatus(1,:) ={'CruiseSeries','Year','CruiseNr','ShipName','DataPath','Problem','lsss','Snap'};
l=1;
for i = 1%:length(D)
    disp([D(i).name])
    for j=1:length(D(i).sampletime)
        ds = fullfile(dd,D(i).sampletime(j).sampletime);
        disp(['   ',D(i).sampletime(j).sampletime])
        for k=1:length(D(i).sampletime(j).Cruise)
            DataStatus{l,1} = D(i).name;
            DataStatus{l,2} = D(i).sampletime(j).sampletime;
            DataStatus{l,3} = D(i).sampletime(j).Cruise(k).cruisenr;
            DataStatus{l,4} = D(i).sampletime(j).Cruise(k).shipName;
            if ~isempty(D(i).sampletime(j).Cruise(k).cruise)
                if isfield(D(i).sampletime(j).Cruise(k).cruise.datapath,'Text')
                    DataStatus{l,5} = D(i).sampletime(j).Cruise(k).cruise.datapath.Text;
                end
                DataStatus{l,6} = D(i).sampletime(j).Cruise(k).cruise.datapath.Comment;
                if isfield(D(i).sampletime(j).Cruise(k).cruise.datapath,'lsssfile')
                    DataStatus{l,7} = D(i).sampletime(j).Cruise(k).cruise.datapath.rawfiles;
                end
                if isfield(D(i).sampletime(j).Cruise(k).cruise.datapath,'snapfiles')
                    DataStatus{l,8} = D(i).sampletime(j).Cruise(k).cruise.datapath.snapfiles;
                end
            end
            l=l+1;
        end
    end
end

%% Save summary data
fid=fopen([fullfile(dd_out,'DataOverview.csv')],'w');
for i=1:size(DataStatus,1)
    for j=1:size(DataStatus,2)
        if i>1&&ismember(j,[7 8])
            st='%i;';
            str = (DataStatus{i,j});
        else
            st = '%s;';
            str=DataStatus{i,j};
        end
        fprintf(fid,st,str);
    end
    fprintf(fid,'\n');
end
fclose(fid);


%% Crunch data
for i = 1:length(D)
    disp([D(i).name])
    for j=1:length(D(i).sampletime)
        ds = fullfile(dd,D(i).sampletime(j).sampletime);
%        disp(['   ',D(i).sampletime(j).sampletime])
        for k=1:length(D(i).sampletime(j).Cruise)
            if isfield(D(i).sampletime(j).Cruise(k).cruise.datapath,'lsssfile')
                if (D(i).sampletime(j).Cruise(k).cruise.datapath.lsssfile)>0
                    d=dir(fullfile(D(i).sampletime(j).Cruise(k).cruise.datapath.Text,'ACOUSTIC_DATA','LSSS','LSSS_FILES','*.lsss'));
                    if length(d)==2
                        in=2;
                    else
                        in=1;
                    end
                    [~,name,~]=fileparts(d(in).name);
                    zipfile = fullfile('.',name);
                    lsssfile= fullfile(d.folder,d.name);
                    luf20_LSSS_writereports(lsssfile,zipfile);
                else
                    disp('No LSSS file in std location.')
                end
            end
        end
    end
end





