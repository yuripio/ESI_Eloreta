function fontes_mri(EEG, source)
    % project sources on MRI and plot solution
    mri = load('-mat', EEG.dipfit.mrifile);
    mri = ft_volumereslice([], mri.mri);

    cfg              = [];
    cfg.downsample   = 2;
    cfg.parameter    = 'pow';
    source.oridimord = 'pos';
    source.momdimord = 'pos';
    sourceInt  = ft_sourceinterpolate(cfg, source , mri);

    cfg              = [];
    cfg.method       = 'slice';
    cfg.funparameter = 'pow';
    ft_sourceplot(cfg, sourceInt);
end