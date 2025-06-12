function eloreta_solucao_volumetrico(dataAvg, lat, vol)
    % Prepara uma grade volumétrica (3D) para reconstrução de fonte
    cfg = [];
    cfg.grid.resolution = 5;  % em mm
    cfg.grid.unit       = 'mm';
    cfg.headmodel       = vol.vol;
    cfg.channel         = 'all';
    cfg.elec            = dataAvg.elec;
    sourcemodel         = ft_prepare_sourcemodel(cfg);

    % Leadfield para volume
    cfg = [];
    cfg.elec        = dataAvg.elec;
    cfg.headmodel   = vol.vol;
    cfg.grid        = sourcemodel;
    leadfield       = ft_prepare_leadfield(cfg, dataAvg);

    % Reconstrução eLORETA
    cfg = [];
    cfg.method        = 'eloreta';
    cfg.sourcemodel   = leadfield;
    cfg.headmodel     = vol.vol;
    source            = ft_sourceanalysis(cfg, dataAvg);

    % Mostra coordenadas do pico de ativação
    if isfield(source.avg, 'pow')
        [maxval, maxidx] = max(source.avg.pow);
        peak_coord = source.pos(maxidx, :);
        fprintf('Potência: min=%.4f, max=%.4f\n', min(source.avg.pow), maxval);
        fprintf('Coordenada pico (mm): X=%.1f, Y=%.1f, Z=%.1f\n', peak_coord);
    else
        warning('Nenhuma potência encontrada em source.avg.pow!');
        return;
    end

    % Plot 3D
    cfg = [];
    cfg.parameter    = 'pow';
    cfg.funparameter = 'pow';
    cfg.maskparameter = 'pow';
    cfg.method       = 'ortho';  % opções: 'ortho', 'slice', 'glassbrain'
    cfg.funcolormap  = 'jet';
    cfg.opacitylim   = [0 0.0005];  % ajustável
    ft_sourceplot(cfg, source);
end
