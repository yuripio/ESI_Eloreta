%% PROCESSAMENTO EEG CORRIGIDO (PRÉ-PROCESSAMENTO + ICA)
% Configuração inicial
addpath('C:\Users\Bio Lab\Documents\eeglab_current\eeglab2023.1\plugins\dipfit\standard_BEM\elec');
eeglab; close;
ft_defaults;

% 1. Carregar dados brutos com todos os canais
arquivo = 'C:\Users\Bio Lab\Documents\ESI_Dados\motorexecution_subject1_run1.gdf';
EEG_raw = pop_biosig(arquivo, 'channels',1:96);

% 2. Rotulagem manual conforme Tabela 2 do dataset
rotulos_completos = {
    'F3','F1','Fz','F2','F4',...
    'FFC5h','FFC3h','FFC1h','FFC2h','FFC4h','FFC6h',...
    'FC5','FC3','FC1','FCz','FC2','FC4','FC6',...
    'FTT7h','FCC5h','FCC3h','FCC1h','FCC2h','FCC4h','FCC6h','FTT8h',...
    'C5','C3','C1','Cz','C2','C4','C6',...
    'TTP7h','CCP5h','CCP3h','CCP1h','CCP2h','CCP4h','CCP6h','TTP8h',...
    'CP5','CP3','CP1','CPz','CP2','CP4','CP6',...
    'CPP5h','CPP3h','CPP1h','CPP2h','CPP4h','CPP6h',...
    'P3','P1','Pz','P2','P4',...
    'PPO1h','PPO2h',...
    'EOG_left','EOG_central','EOG_right',...
    'thumb_near','thumb_far','thumb_index','index_near','index_far',...
    'index_middle','middle_near','middle_far','middle_ring','ring_near',...
    'ring_far','ring_little','little_near','little_far','thumb_palm',...
    'hand_X','hand_Y','hand_Z','elbow_X','elbow_Y','elbow_Z',...
    'shoulder_adduction','shoulder_flexion/extension','shoulder_rotation',...
    'elbow','pro/supination','wrist_flexion/extension'
};

for i = 1:length(rotulos_completos)
    EEG_raw.chanlocs(i).labels = rotulos_completos{i};
end

% 3. Selecionar apenas EEG + EOG (canais 1-64)
EEG = pop_select(EEG_raw, 'channel', 1:64);

% 4. Corrigir geometria dos eletrodos
EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');

% 5. Mapeamento de eventos (Tabela 1)
event_map = {
    '0x600' 'Elbow_Flexion'
    '0x601' 'Elbow_Extension'
    '0x602' 'Supination'
    '0x603' 'Pronation'
    '0x604' 'Hand_Close'
    '0x605' 'Hand_Open'
    '0x606' 'Rest'
};

% Verificação dos códigos originais
fprintf('\n=== Códigos de Evento Originais ===\n');
raw_event_codes = unique([EEG_raw.event.type]);
disp(raw_event_codes);

% Conversão corrigida para hexadecimal (sem padding)
for e = 1:length(EEG.event)
    try
        if isnumeric(EEG.event(e).type)
            event_code = EEG.event(e).type;
        elseif ischar(EEG.event(e).type)
            event_code = str2double(EEG.event(e).type); % converte string numérica
        else
            event_code = NaN;
        end

        if ~isnan(event_code)
            hex_str = sprintf('0x%X', event_code);
        else
            hex_str = '';
        end
        
        % Encontrar correspondência
        match = find(strcmpi(event_map(:,1), hex_str));
        
        if ~isempty(match)
            EEG.event(e).type = event_map{match,2};
        else
            fprintf('Evento não mapeado: Código HEX = %s\n', hex_str);
            EEG.event(e).type = 'Unmapped';
        end
        
    catch ME
        fprintf('Erro no evento %d: %s\n', e, ME.message);
        EEG.event(e).type = 'Invalid';
    end
    fprintf('Evento %d: tipo original = %s | hex = %s\n', e, EEG.event(e).type, hex_str);
end

% Verificação final
fprintf('\n=== Eventos Mapeados ===\n');
disp(unique({EEG.event.type}));
% 6. Pré-processamento robusto
EEG.data = fillmissing(EEG.data, 'linear', 2);
variances = var(EEG.data, [], 2);
bad_chans = find(variances < 1e-6 | any(isnan(EEG.data),2) | any(isinf(EEG.data),2));
if ~isempty(bad_chans)
    fprintf('Removendo %d canais problemáticos: %s\n',...
            length(bad_chans), strjoin({EEG.chanlocs(bad_chans).labels}, ', '));
    EEG = pop_select(EEG, 'nochannel', bad_chans);
end

EEG = pop_eegfiltnew(EEG, 2, 90, [], 0, [], 0);
EEG = pop_eegfiltnew(EEG, 49, 51, [], 1);
EEG = pop_eegfiltnew(EEG, 99, 101, [], 1);

epsilon = 1e-6;
for ch = 1:EEG.nbchan
    chan_data = EEG.data(ch,:);
    EEG.data(ch,:) = (chan_data - mean(chan_data)) / (std(chan_data) + epsilon);
end

% 7. ICA com configurações de estabilidade
ica_cfg = {
    'icatype', 'runica',...
    'extended', 1,...
    'pca', min(60, EEG.nbchan-1),...
    'lrate', 0.0001,...
    'maxsteps', 1000,...
    'stop', 1e-07,...
    'verbose', 'on',...
    'bias', 'on'
};

try
    EEG = pop_runica(EEG, ica_cfg{:});
catch ME
    fprintf('Erro na ICA: %s\nTentando com Picard...\n', ME.message);
    EEG = pop_runica(EEG, 'icatype', 'picard', 'maxiter', 500);
end

% 8. Detecção manual de componentes oculares
eog_labels = {'EOG_left', 'EOG_central', 'EOG_right'};
eog_channels = find(ismember({EEG.chanlocs.labels}, eog_labels));

num_samples = EEG.pnts * EEG.trials;
ica_activations = eeg_getica(EEG);

comps_ocular = [];
for comp = 1:size(ica_activations,1)
    comp_activity = reshape(ica_activations(comp,:,:), [], 1); 
    
    max_corr = 0;
    for eog = 1:length(eog_channels)
        eog_activity = reshape(EEG.data(eog_channels(eog),:,:), [], 1); 
        
        corr_value = corr(comp_activity, eog_activity);
        
        if abs(corr_value) > max_corr
            max_corr = abs(corr_value);
        end
    end
    
    if max_corr > 0.7
        comps_ocular = [comps_ocular comp];
    end
end

if ~isempty(comps_ocular)
    fprintf('Removendo componentes oculares: %s\n', num2str(comps_ocular));
    EEG = pop_subcomp(EEG, comps_ocular);
else
    warning('Nenhum componente ocular detectado! Verificar manualmente.');
    pop_selectcomps(EEG, 1:10);
end

if ~isempty(comps_ocular)
    fprintf('Removendo componentes oculares: %s\n', num2str(comps_ocular));
    EEG = pop_subcomp(EEG, comps_ocular);
else
    warning('Nenhum componente ocular detectado! Verifique manualmente.');
    pop_selectcomps(EEG, 1:20); % Visualizar componentes
end

%Verificação se canais motores ainda estão presentes
% Lista dos canais motores clássicos
canais_motores = {'C3', 'C4', 'CP3', 'CP4', 'C1', 'C2', 'Cz', 'FC3', 'FC4'};

% Verifica quais estão presentes
labels_atuais = {EEG.chanlocs.labels};
canais_presentes = intersect(canais_motores, labels_atuais);
canais_ausentes = setdiff(canais_motores, labels_atuais);

% Exibe resultado
fprintf('\n--- Verificação de canais motores ---\n');
fprintf('Presentes: %s\n', strjoin(canais_presentes, ', '));
fprintf('Ausentes : %s\n', strjoin(canais_ausentes, ', '));

% 9. Segmentação temporal
% Verificar eventos disponíveis
disp('Tipos de eventos disponíveis:');
disp(unique({EEG.event.type}));

% Definir eventos de movimento esperados
eventos_validos = {'Elbow_Flexion', 'Elbow_Extension', 'Supination', 'Pronation',...
                   'Hand_Close', 'Hand_Open'};

% Verificar quais eventos estão presentes
eventos_presentes = intersect(eventos_validos, unique({EEG.event.type}));
if isempty(eventos_presentes)
    error('Nenhum evento válido encontrado! Verifique o mapeamento de eventos.');
else
    fprintf('Eventos disponíveis para segmentação: %s\n', strjoin(eventos_presentes, ', '));
end

% ✅ Definir janela de época (coloquei aqui)
epoch_limites = [-1 3]; % janela de -1s a +3s em relação ao evento

% Segmentar dados
try
    EEG = pop_epoch(EEG, eventos_presentes, epoch_limites,...
                   'verbose', 'yes',...
                   'newname', 'Dados Epocados');
    
    % Verificar épocas criadas
    if EEG.trials == 0
        error('Nenhuma época foi criada! Verifique latências dos eventos.');
    end
    
catch ME
    fprintf('\nErro detalhado na segmentação:\n');
    disp(ME.message);
    
    % Diagnóstico adicional
    fprintf('Número total de eventos: %d\n', length(EEG.event));
    fprintf('Latência mínima: %.2fs\n', min([EEG.event.latency]/EEG.srate));
    fprintf('Latência máxima: %.2fs\n', max([EEG.event.latency]/EEG.srate));
    error('Falha na segmentação. Verifique eventos e latências!');
end

% 10. Verificação final
EEG = pop_rmbase(EEG, [-1000 0]);

figure;
subplot(1,2,1);
topoplot([], EEG.chanlocs, 'style', 'blank', 'plotrad', 0.6);
title('Geometria dos Eletrodos');

subplot(1,2,2);
plot(EEG.times, mean(EEG.data,3));
title('Resposta Média');
xlabel('Tempo (ms)'); 
ylabel('Amplitude (μV)');

disp(['Processamento concluído com sucesso! Épocas: ' num2str(EEG.trials)]);


%% APLICAÇÃO MODELO ELORETA
% Salva EEG original antes de qualquer segmentação
EEG_continuo = EEG;

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

        lat = latencia_motor(EEG_classe);
        modelodipolo(EEG_classe, lat);
        [~, dataAvg, source, vol] = eloreta_processamento(EEG_classe);
        eloreta_solucao(dataAvg, lat, vol, classe);

        fprintf('✓ eLORETA concluído para a classe: %s\n', classe);

    catch ME
        fprintf('Erro ao processar classe %s: %s\n', classe, ME.message);
    end
end