function eloreta_solucao(dataAvg, lat, vol, nome_classe)
    % PREPARA LEADFIELD DA SUPERFÍCIE
    [~, ftPath] = ft_version;
    sourcemodel = ft_read_headshape(fullfile(ftPath, 'template', 'sourcemodel', 'cortex_8196.surf.gii'));
    sourcemodel = ft_convert_units(sourcemodel, 'mm');

    cfg           = [];
    cfg.grid      = sourcemodel;    % malha de superfície
    cfg.headmodel = vol.vol;        % modelo de condução
    cfg.channel   = 'all';
    leadfield     = ft_prepare_leadfield(cfg, dataAvg);

    % USA MNE NA SUPERFÍCIE
    cfg               = [];
    cfg.method        = 'mne';
    cfg.grid          = leadfield;
    cfg.headmodel     = vol.vol;
    cfg.mne.lambda    = 3;
    cfg.mne.scalesourcecov = 'yes';
    source            = ft_sourceanalysis(cfg, dataAvg);

    % OPCIONAL: mostrar valor do pico
    if isfield(source, 'avg') && isfield(source.avg, 'pow')
        [maxval, maxidx] = max(source.avg.pow);
        fprintf('Potência: min=%.4f, max=%.4f\n', min(source.avg.pow), maxval);
        fprintf('Vértice de pico: #%d\n', maxidx);
    else
        warning('Campo source.avg.pow ausente!');
    end

    % PLOTAGEM NA SUPERFÍCIE CORTICAL
    cfg = [];
    cfg.funparameter = 'pow';
    cfg.maskparameter = cfg.funparameter;
    cfg.method = 'surface';
    cfg.opacitylim = [0 0.001];
    cfg.latency = lat;
    cfg.title = ['eLORETA - Classe: ' nome_classe];
    ft_sourceplot(cfg, source);
    colormap jet;
end


