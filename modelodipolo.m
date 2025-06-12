function modelodipolo(eeg_data, lat)
    eeglab; close;
    EEG = eeg_data;

    % Definir a latência P300
    latency = lat;
    pt300 = round((latency-EEG.xmin)*EEG.srate);

    % Encontrar o dipolo mais adequado do ERP
    erp = mean(EEG.data(:,:,:), 3);
    dipfitdefs;

    % Configuração MNI para 61 canais
    bemPath = fullfile(fileparts(which('eeglab')), 'plugins', 'dipfit', 'standard_BEM');
    EEG = pop_dipfit_settings(EEG, ...
        'hdmfile', fullfile(bemPath, 'standard_vol.mat'), ...
        'coordformat', 'MNI', ...
        'chanfile', fullfile(bemPath, 'elec', 'standard_1005.elc'), ...
        'chansel', 1:61); % Todos os canais EEG

    [ dipole, model, TMPEEG] = dipfit_erpeeg(erp(:,pt300), EEG.chanlocs, 'settings', EEG.dipfit, 'threshold', 100);

    % Plotar
    figure;
    pop_dipplot(TMPEEG, 1, 'normlen', 'on', 'mri', template_models(2).mrifile, 'coordformat', 'MNI');
    title('Localização do Dipolo Ajustado');
end