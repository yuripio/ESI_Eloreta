%% CONVERTER DADOS PARA FORMATO EEGLAB
%1 - Direita 2 - Esquerda

%% Caminho base e inicialização
baseDir = 'C:\Users\Bio Lab\Documents\ESI_EEGLAB\DADOS';
eeglab; close;
eeg_test_all = [];

% Lista de canais na ordem correta
lista_canais = {'AF7', 'AF3', 'Fp1', 'Fp2', 'AF4', 'AF8', 'F7', 'F5', 'F3', 'F1', ...
                'F2', 'F4', 'F6', 'F8', 'FT7', 'FC5', 'FC3', 'FC1', 'FC2', 'FC4', ...
                'FC6', 'FT8', 'T3', 'C5', 'C3', 'C1', 'C2', 'C4', 'C6', 'T4', 'TP7', ...
                'CP5', 'CP3', 'CP1', 'CP2', 'CP4', 'CP6', 'TP8', 'T5', 'P5', 'P3', ...
                'P1', 'P2', 'P4', 'P6', 'T6', 'Fpz', 'PO7', 'PO3', 'O1', 'O2', ...
                'PO4', 'PO8', 'Oz', 'Fz', 'FCz', 'Cz', 'CPz', 'Pz', 'POz'};
% Carrega todos os voluntários
for i = 1:10
    folderName = fullfile(baseDir, ['V' num2str(i)]);
    filePath = fullfile(folderName, '125_segData_1.mat');
    
    if isfile(filePath)
        load(filePath, 'segData');
        
        % ⚠️ Usa a nova função com base no .elc
        eeg_temp = converte_eeglab(['EEG_V' num2str(i)], segData, lista_canais);
        
        if isempty(eeg_test_all)
            eeg_test_all = eeg_temp;
        else
            eeg_test_all = pop_mergeset(eeg_test_all, eeg_temp);
        end
    else
        warning('Arquivo não encontrado: %s', filePath);
    end
end

eeg_test = eeg_test_all;

%% CALCULAR LATÊNCIA PEAK P300
canais = {'Pz', 'CPz', 'Cz', 'POz'};
lat = latencia_p300_peak(eeg_test, canais);

%% RECONSTRUÇÃO ELORETA
[EEG, dataAvg, source, vol] = eloreta_processamento(eeg_test);
eloreta_solucao(dataAvg, 0.296 , vol);


%%
% Canais para análise visual
canais_erp = {'Cz', 'CPz', 'Pz', 'POz'};
cores = lines(numel(canais_erp));

figure; hold on;
for i = 1:numel(canais_erp)
    idx = find(strcmp({eeg_test.chanlocs.labels}, canais_erp{i}));
    if ~isempty(idx)
        % Média ao longo dos trials
        erp = mean(squeeze(eeg_test.data(idx,:,:)), 2);  % [tempo]
        plot(eeg_test.times, erp, 'DisplayName', canais_erp{i}, 'Color', cores(i,:));
    end
end
xlabel('Tempo (ms)');
ylabel('Amplitude (µV)');
title('ERP - canais centrais');
legend show;
grid on;

%% Visualizar os eletrodos em 2D (Topoplot)
%figure;
%topoplot([], EEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint');
%title('Posicionamento dos Eletrodos');
 