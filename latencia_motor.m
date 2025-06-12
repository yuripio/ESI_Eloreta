function latency_avg = latencia_motor(EEG, t_min, t_max)
    % Verificação de entrada
    if nargin < 3, t_max = 1000; end
    if nargin < 2, t_min = 0; end

    if EEG.trials == 1
        error('Dados não segmentados! Execute pop_epoch primeiro.');
    end

    % Índices da janela
    idx_min = find(EEG.times >= t_min, 1, 'first');
    idx_max = find(EEG.times <= t_max, 1, 'last');
    time_vector = EEG.times(idx_min:idx_max);

    % Canais motores
    motor_channels = {'C3', 'C4', 'CP3', 'CP4', 'C1', 'C2', 'Cz', 'FC3', 'FC4'};
    chan_idx = find(ismember({EEG.chanlocs.labels}, motor_channels));

    if isempty(chan_idx)
        error('Nenhum dos canais motores esperados foi encontrado!');
    else
        disp('Canais motores utilizados:');
        disp({EEG.chanlocs(chan_idx).labels});
    end

    % Latência por época
    n_epochs = EEG.trials;
    latencies = zeros(1, n_epochs);
    for i = 1:n_epochs
        epoch_data = mean(EEG.data(chan_idx, idx_min:idx_max, i), 1); % média entre canais
        [~, peak_idx] = max(epoch_data);
        latencies(i) = time_vector(peak_idx)/1000; % em segundos
    end

    latency_avg = mean(latencies);
    disp(['Latência média do movimento: ' num2str(latency_avg*1000) ' ms']);
end
