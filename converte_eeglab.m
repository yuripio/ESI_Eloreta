function EEG = converte_eeglab(nome, dados)
    addpath('C:\Users\Bio Lab\Documents\eeglab_current\eeglab2023.1\plugins\dipfit\standard_BESA');
    addpath('C:\Users\Bio Lab\Documents\eeglab_current\eeglab2023.1\plugins\dipfit\standard_BEM\elec');
    EEG = struct();
    EEG.setname = 'EEG Data epochs';
    EEG.filename = nome;
    EEG.filepath = strcat('C:\Users\Bio Lab\Documents\ESI_EEGLAB\DADOS');
    EEG.subject = '';
    EEG.group = '';
    EEG.condition = '';
    EEG.session = [];
    EEG.comments = 'no comments';
    EEG.nbchan = size(dados, 1);                           
    EEG.pnts = size(dados, 2);                             
    EEG.trials = size(dados, 3);                           
    EEG.srate = 1024;                                      
    EEG.xmin = -0.2;                                       
    EEG.xmax = 1.0;                                        
    EEG.times = linspace(EEG.xmin, EEG.xmax, EEG.pnts);     
    EEG.data = dados; 
    EEG.icaact = dados;
    EEG.icawinv = [];
    EEG.icasphere = [];
    EEG.icaweights = [];
    EEG.icachansind = [];
    all_chanlocs = readlocs('standard-10-5-cap385.elp');
    selected_channels = {'AF7', 'AF3', 'Fp1', 'Fp2', 'AF4', 'AF8', 'F7', 'F5', 'F3', 'F1', ...
                     'F2', 'F4', 'F6', 'F8', 'FT7', 'FC5', 'FC3', 'FC1', 'FC2', 'FC4', ...
                     'FC6', 'FT8', 'T3', 'C5', 'C3', 'C1', 'C2', 'C4', 'C6', 'T4', 'TP7', ...
                     'CP5', 'CP3', 'CP1', 'CP2', 'CP4', 'CP6', 'TP8', 'T5', 'P5', 'P3', ...
                     'P1', 'P2', 'P4', 'P6', 'T6', 'Fpz', 'PO7', 'PO3', 'O1', 'O2', ...
                     'PO4', 'PO8', 'Oz', 'Fpz', 'Fz', 'FCz', 'Cz', 'CPz', 'Pz', 'POz'};
    EEG.chanlocs = all_chanlocs(ismember({all_chanlocs.labels}, selected_channels));
    EEG.urchanlocs = EEG.chanlocs;
    EEG.chaninfo = [];
    EEG.ref = 'common';
    EEG.event = [];
    EEG.urevent = [];
    EEG.eventdescription = {};
    EEG.epoch = [];
    EEG.epochdescription = {};
    EEG.reject = [];
    EEG.stats = [];
    EEG.specdata = [];
    EEG.specicaact = [];
    EEG.splinefile = [];
    EEG.icasplinefile = '';
    EEG.dipfit = [];
    EEG.history = '';
    EEG.saved = 'no';
    EEG.etc = [];
    EEG.datfile = nome;
    EEG.run = [];
    EEG.roi = [];
end