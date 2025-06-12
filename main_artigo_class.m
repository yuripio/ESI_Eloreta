%% MAIN: PRÉ-PROCESSAMENTO DE MÚLTIPLAS EXECUÇÕES COMBINADAS POR ATIVIDADE
addpath('C:\Users\Bio Lab\Documents\eeglab_current\eeglab2023.1\plugins\dipfit\standard_BEM\elec');
eeglab; close;
ft_defaults;

base_dir = 'C:\Users\Bio Lab\Documents\ESI_Dados\';
arquivos = dir(fullfile(base_dir, 'motorexecution_subject6_run*.gdf'));

% Mapeamento de eventos
event_map = {
    '0x600' 'Elbow_Flexion'
    '0x601' 'Elbow_Extension'
    '0x602' 'Supination'
    '0x603' 'Pronation'
    '0x604' 'Hand_Close'
    '0x605' 'Hand_Open'
    '0x606' 'Rest'
};
condicoes = event_map(:,2);

% Inicialização da estrutura por condição
EEG_cond = struct();

for a = 1:length(arquivos)
    %1. Carregamento
    caminho = fullfile(arquivos(a).folder, arquivos(a).name);
    EEG_raw = pop_biosig(caminho, 'channels',1:96);
    
    %2. Rotulagem dos canais
    rotulos = {...
        'F3','F1','Fz','F2','F4', ...
        'FFC5h','FFC3h','FFC1h','FFC2h','FFC4h','FFC6h', ...
        'FC5','FC3','FC1','FCz','FC2','FC4','FC6', ...
        'FTT7h','FCC5h','FCC3h','FCC1h','FCC2h','FCC4h','FCC6h','FTT8h', ...
        'C5','C3','C1','Cz','C2','C4','C6', ...
        'TTP7h','CCP5h','CCP3h','CCP1h','CCP2h','CCP4h','CCP6h','TTP8h', ...
        'CP5','CP3','CP1','CPz','CP2','CP4','CP6', ...
        'CPP5h','CPP3h','CPP1h','CPP2h','CPP4h','CPP6h', ...
        'P3','P1','Pz','P2','P4', ...
        'PPO1h','PPO2h', ...
        'EOG_left','EOG_central','EOG_right', ...
        'thumb_near','thumb_far','thumb_index','index_near','index_far', ...
        'index_middle','middle_near','middle_far','middle_ring','ring_near', ...
        'ring_far','ring_little','little_near','little_far','thumb_palm', ...
        'hand_X','hand_Y','hand_Z','elbow_X','elbow_Y','elbow_Z', ...
        'shoulder_adduction','shoulder_flexion/extension','shoulder_rotation', ...
        'elbow','pro/supination','wrist_flexion/extension'
    };
    for i = 1:length(rotulos)
        EEG_raw.chanlocs(i).labels = rotulos{i};
    end
    
    %3. Seleção dos canais EEG e EOG
    EEG = pop_select(EEG_raw, 'channel', 1:64);
    EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');

    %4. Mapeamento de eventos
    for e = 1:length(EEG.event)
        try
            code = EEG.event(e).type;
            if isnumeric(code), hex = sprintf('0x%X', code);
            elseif ischar(code), hex = sprintf('0x%X', str2double(code));
            else, hex = '';
            end
            idx = find(strcmp(event_map(:,1), hex));
            if ~isempty(idx), EEG.event(e).type = event_map{idx,2};
            else, EEG.event(e).type = 'Unmapped';
            end
        catch
            EEG.event(e).type = 'Invalid';
        end
    end

    %5. Pré-processamento
    EEG.data = fillmissing(EEG.data, 'linear', 2);
    var_ch = var(EEG.data, [], 2);
    ruins = find(var_ch < 1e-6 | any(isnan(EEG.data),2) | any(isinf(EEG.data),2));
    if ~isempty(ruins), EEG = pop_select(EEG, 'nochannel', ruins); end
    
    EEG = pop_eegfiltnew(EEG, 2, 90);
    EEG = pop_eegfiltnew(EEG, 49, 51, [], 1);
    EEG = pop_eegfiltnew(EEG, 99, 101, [], 1);
    
    for ch = 1:EEG.nbchan
        EEG.data(ch,:) = (EEG.data(ch,:) - mean(EEG.data(ch,:))) / (std(EEG.data(ch,:)) + 1e-6);
    end

    %6. Separar por condição e empilhar
    for c = 1:length(condicoes)
        nome = condicoes{c};
        EEG_epoca = pop_epoch(EEG, {nome}, [-1 2], 'epochinfo', 'yes');
        EEG_epoca = pop_rmbase(EEG_epoca, [-1000 0]);

        if ~isempty(EEG_epoca.data)
            if ~isfield(EEG_cond, nome)
                EEG_cond.(nome) = EEG_epoca;
            else
                EEG_cond.(nome).data = cat(3, EEG_cond.(nome).data, EEG_epoca.data);
                EEG_cond.(nome).epoch = [EEG_cond.(nome).epoch EEG_epoca.epoch];
                EEG_cond.(nome).event = [EEG_cond.(nome).event EEG_epoca.event];
                EEG_cond.(nome).urevent = [EEG_cond.(nome).urevent EEG_epoca.urevent];
                EEG_cond.(nome).trials = size(EEG_cond.(nome).data, 3);
            end
        end
    end
end

%7. Unir tudo em um só EEG contínuo
fprintf('\n== Unificando todas as condições em um EEG para ICA ==\n');
EEG_all = EEG_cond.(condicoes{1});
for c = 2:length(condicoes)
    EEG_all = pop_mergeset(EEG_all, EEG_cond.(condicoes{c}));
end

%8. ICA
EEG_all = pop_runica(EEG_all, 'extended', 1);
EEG_all = pop_saveset(EEG_all, 'filename', 'EEG_all_ica.set', 'filepath', base_dir);

%9. Separar novamente por condição final
for c = 1:length(condicoes)
    nome = condicoes{c};
    EEG_final = pop_epoch(EEG_all, {nome}, [-1 2]);
    EEG_final = pop_rmbase(EEG_final, [-1000 0]);
    pop_saveset(EEG_final, 'filename', sprintf('EEG_%s.set', nome), 'filepath', base_dir);
end

fprintf('\n=== FINALIZADO ===\nTodos os dados foram processados e salvos por atividade.\n');

%% APLICAÇÃO MODELO ELORETA
% Combina todas as execuções das condições em um único EEG contínuo
condicoes = fieldnames(EEG_cond);
EEG_final = EEG_cond.(condicoes{1});  % inicializa com a primeira condição

% Define janelas personalizadas para cada classe motora (em milissegundos)
mapa_janelas = struct();
mapa_janelas.Elbow_Flexion = [200 600];
mapa_janelas.Elbow_Extension = [250 650];
mapa_janelas.Supination = [300 700];
mapa_janelas.Pronation = [300 700];
mapa_janelas.Hand_Close = [100 400];
mapa_janelas.Hand_Open = [120 420];

for i = 2:length(condicoes)
    EEG_atual = EEG_cond.(condicoes{i});
    
    % Verifica compatibilidade básica
    if EEG_atual.nbchan ~= EEG_final.nbchan
        error('Número de canais incompatível entre %s e %s', condicoes{1}, condicoes{i});
    end
    if EEG_atual.srate ~= EEG_final.srate
        error('Taxa de amostragem incompatível entre %s e %s', condicoes{1}, condicoes{i});
    end
    
    % Concatena os dados
    EEG_final.data = cat(2, EEG_final.data, EEG_atual.data);
    
    % Corrige latências dos eventos da execução atual
    offset = size(EEG_final.data, 2) - size(EEG_atual.data, 2);
    for e = 1:length(EEG_atual.event)
        EEG_atual.event(e).latency = EEG_atual.event(e).latency + offset;
    end
    
    % Adiciona eventos
    EEG_final.event = [EEG_final.event, EEG_atual.event];
end

% Atualiza metadados
EEG_final.pnts = size(EEG_final.data, 2);
EEG_final.trials = 1;
EEG_final.xmax = EEG_final.xmin + (EEG_final.pnts - 1) / EEG_final.srate;

% Remove campo 'epoch', se existir
if isfield(EEG_final, 'epoch')
    EEG_final = rmfield(EEG_final, 'epoch');
end

disp('Todas as execuções foram combinadas com sucesso em EEG_final');

% Salva EEG original antes de qualquer segmentação
EEG_continuo = EEG_final;

classes_motoras = {'Elbow_Flexion', 'Elbow_Extension', 'Supination', ...
                   'Pronation', 'Hand_Close', 'Hand_Open'};

for i = 1:length(classes_motoras)
    classe = classes_motoras{i};
    fprintf('\n=== Classe: %s ===\n', classe);

    if ~any(strcmp({EEG_continuo.event.type}, classe))
        fprintf('Classe %s não encontrada nos eventos.\n', classe);
        continue;
    end

    try
        EEG_classe = pop_epoch(EEG_continuo, {classe}, [-1 3], 'newname', ['EEG_' classe], 'epochinfo', 'yes');
        EEG_classe = pop_rmbase(EEG_classe, [-1000 0]);

        lat = latencia_motor(EEG_classe,250,450);
        %modelodipolo(EEG_classe, lat);
        [~, dataAvg, source, vol] = eloreta_processamento(EEG_classe);
        eloreta_solucao(dataAvg, lat, vol, classe);

        fprintf('eLORETA concluído para a classe: %s\n', classe);

    catch ME
        fprintf('Erro ao processar classe %s: %s\n', classe, ME.message);
    end
end