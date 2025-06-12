function [EEG, dataAvg, source, vol] = eloreta_processamento(EEG)

    % ⚠ Verifica se os dados estão epocados
    if EEG.trials == 1
        error('Os dados devem estar segmentados em épocas!');
    end

    % ⚠ Verifica se os canais possuem coordenadas
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

    % Re-referência no FieldTrip
    cfg = [];
    cfg.channel = 'all';
    cfg.reref = 'yes';
    cfg.refchannel = 'all';
    dataPre = ft_preprocessing(cfg, dataPre);

    % ⚠ Alinha coordenadas com o modelo
    dataPre.elec = ft_convert_units(dataPre.elec, 'mm');

    % Carrega modelo de volume (cabeça)
    vol = load(EEG.dipfit.hdmfile);
    vol.vol = ft_convert_units(vol.vol, 'mm');

    % Prepara a grade de fontes (leadfield)
    cfg = [];
    cfg.elec      = dataPre.elec;
    cfg.headmodel = vol.vol;
    cfg.resolution = 5;  % resolução em mm (mais fino = mais preciso, mais lento)
    cfg.unit      = 'mm';
    cfg.channel   = 'all';
    sourcemodel   = ft_prepare_leadfield(cfg);

    % Calcula a média e covariância dos dados (ERP)
    cfg = [];
    cfg.covariance       = 'yes';
    cfg.covariancewindow = [EEG.xmin 0];  % usa baseline
    cfg.keeptrials       = 'no';  % média por condição
    dataAvg = ft_timelockanalysis(cfg, dataPre);

    % Reconstrução de fonte com eLORETA
    cfg = [];
    cfg.method      = 'eloreta';
    cfg.sourcemodel = sourcemodel;
    cfg.headmodel   = vol.vol;
    source          = ft_sourceanalysis(cfg, dataAvg);
end

