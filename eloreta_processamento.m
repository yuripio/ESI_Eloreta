function [EEG, dataAvg, source, vol] = eloreta_processamento(EEG)
    % Verifica se os dados estão epocados
    if EEG.trials == 1
        error('Os dados devem estar segmentados em épocas!');
    end

    % Verifica se os canais possuem coordenadas
    has_coords = sum(~isnan([EEG.chanlocs.X]));
    if has_coords < EEG.nbchan
        warning('Alguns canais não possuem coordenadas! Corrija com pop_chanedit antes.');
    else
        fprintf('✓ Todos os %d canais possuem coordenadas válidas.\n', has_coords);
    end

    % Inicializa EEGLAB e configurações do dipfit
    eeglab; close;
    bemPath = fullfile(fileparts(which('eeglab')), 'plugins', 'dipfit', 'standard_BEM');

    EEG = pop_dipfit_settings(EEG, ...
        'hdmfile', fullfile(bemPath, 'standard_vol.mat'), ...
        'coordformat', 'MNI', ...
        'chanfile', fullfile(bemPath, 'elec', 'standard_1005.elc'), ...
        'chansel', 1:EEG.nbchan);

    % Converte EEG para estrutura FieldTrip
    dataPre = eeglab2fieldtrip(EEG, 'preprocessing', 'dipfit');

    % Pré-processamento no FieldTrip (re-referência e baseline)
    cfg = [];
    cfg.channel = 'all';
    cfg.reref = 'yes';
    cfg.refchannel = 'all';
    dataPre = ft_preprocessing(cfg, dataPre);

    cfg = [];
    cfg.baseline = [EEG.xmin 0];
    dataPre = ft_preprocessing(cfg, dataPre);

    % Converte unidades para mm
    dataPre.elec = ft_convert_units(dataPre.elec, 'mm');

    % Carrega modelo de volume e converte unidades
    vol = load(EEG.dipfit.hdmfile);
    vol.vol = ft_convert_units(vol.vol, 'mm');

    % Gera grade no espaço MNI com warping não linear
    template_mri = ft_read_mri(fullfile(bemPath, 'standard_mri.mat'));

    cfg = [];
    cfg.warpmni   = 'yes';
    cfg.nonlinear = 'yes';
    cfg.template  = template_mri;
    cfg.grid.resolution = 3;  % mm
    cfg.grid.unit = 'mm';
    cfg.elec      = dataPre.elec;      
    cfg.headmodel = vol.vol;           
    sourcemodel   = ft_prepare_sourcemodel(cfg);


    % Gera leadfield usando grade refinada e volume head model
    cfg = [];
    cfg.elec      = dataPre.elec;
    cfg.headmodel = vol.vol;
    cfg.grid      = sourcemodel;
    cfg.normalize = 'no';
    sourcemodel   = ft_prepare_leadfield(cfg);

    % Calcula média e covariância dos dados (ERP)
    cfg = [];
    cfg.covariance       = 'yes';
    cfg.covariancewindow = [EEG.xmin 0];  % baseline
    cfg.keeptrials       = 'no';
    cfg.removemean       = 'yes';
    dataAvg = ft_timelockanalysis(cfg, dataPre);

    % Reconstrução de fonte com eLORETA
    cfg = [];
    cfg.method      = 'eloreta';
    cfg.tight = 'yes';
    cfg.sourcemodel = sourcemodel;
    cfg.headmodel   = vol.vol;
    source          = ft_sourceanalysis(cfg, dataAvg);

    % Z-score da potência (opcional)
    if isfield(source, 'avg') && isfield(source.avg, 'pow')
        pow = source.avg.pow;
        source.avg.pow_z = (pow - mean(pow)) / std(pow);
    end
end