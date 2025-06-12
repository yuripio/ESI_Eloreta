%% CONVERTER DADOS PARA FORMATO EEGLAB
eeglab; close;
eeg_test = struct();
% eeg_test = converte_eeglab('EEG_test', segData);
% eeg_test = EEG_final

%% CALCULAR LATÊNCIA E CRIAR MODELO DIPOLO
lat = latencia_p300_med(eeg_test);
modelodipolo(eeg_test, lat);

%% SOLUÇÕES ELORETA
[EEG, dataAvg, source, vol] = eloreta_processamento(eeg_test);
%fontes_mri(EEG, source);
eloreta_solucao(dataAvg, lat, vol);


%% Inicializar o EEGLAB e carregar os dados
eeglab; close;
EEG = eeg_test; % Carregar seu conjunto de dados EEG

% Visualizar os eletrodos em 2D (Topoplot)
figure;
topoplot([], EEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint');
title('Posicionamento dos Eletrodos');
