function EEG = converte_eeglab(nome, segData, lista_canais)
    % Função para converter segData em estrutura EEG com chanlocs corretos
    % Baseado em standard_1005.elc (FieldTrip)

    % Verificação básica
    if size(segData, 1) ~= numel(lista_canais)
        error('❌ Número de canais em segData (%d) não bate com lista_canais (%d).', ...
              size(segData, 1), numel(lista_canais));
    end

    % 1. Carrega coordenadas reais dos canais do arquivo padrão
    ft_defaults;
    elec_full = ft_read_sens('standard_1005.elc');  % coordenadas MNI em mm

    % 2. Filtra apenas os canais da lista
    idx = match_str(elec_full.label, lista_canais);
    elec = elec_full;
    elec.label = elec.label(idx);
    elec.chanpos = elec.chanpos(idx,:);

    % 3. Monta estrutura EEG
    EEG = struct();
    EEG.setname   = nome;
    EEG.filename  = [nome '.set'];
    EEG.filepath  = pwd;
    EEG.nbchan    = size(segData, 1);
    EEG.pnts      = size(segData, 2);
    EEG.trials    = size(segData, 3);
    EEG.srate     = 1024;
    EEG.xmin      = -0.2;
    EEG.xmax      = 1.0;
    EEG.times     = linspace(EEG.xmin, EEG.xmax, EEG.pnts);
    EEG.data      = segData;

    % 4. Preenche EEG.chanlocs com base nas posições do .elc
    for i = 1:numel(lista_canais)
        EEG.chanlocs(i).labels = lista_canais{i};
        EEG.chanlocs(i).X = elec.chanpos(i,1);
        EEG.chanlocs(i).Y = elec.chanpos(i,2);
        EEG.chanlocs(i).Z = elec.chanpos(i,3);
        EEG.chanlocs(i).type = 'EEG';
    end

    EEG.urchanlocs = EEG.chanlocs;  % backup
    EEG.chaninfo = [];
    EEG.ref = 'common';
    EEG.event = [];
    EEG.epoch = [];
    EEG.reject = [];
    EEG.stats = [];
    EEG.etc = [];
    EEG.dipfit = struct();

    fprintf('✅ EEG com %d canais montado com coordenadas do .elc (MNI).\n', EEG.nbchan);
end
