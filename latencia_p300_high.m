function latency_peak = latencia_p300_high(eeg_data)
    EEG = eeg_data;
    % Defina o intervalo de tempo de interesse (em segundos)
    lat_min = 0.25;  % 250 ms
    lat_max = 0.450;   % 450 ms

    % Encontre o índice do intervalo de latência no EEG
    [~, idx_min] = min(abs(EEG.times - (lat_min * 1000)));  % converte para ms
    [~, idx_max] = min(abs(EEG.times - (lat_max * 1000)));

    % Extraia os dados do EEG nesse intervalo de tempo (250-500 ms)
    data_in_interval = EEG.data(:, idx_min:idx_max, :);  % extrai os dados dos eletrodos nesse intervalo

    % Encontre o valor máximo no intervalo de tempo (em todos os canais e trials)
    [max_val, max_idx] = max(mean(data_in_interval, 3), [], 2);  % média sobre trials, pico por canal

    % Encontre o índice do tempo correspondente ao valor máximo
    [max_ch_val, ch_idx] = max(max_val);  % máximo entre os canais
    peak_time_idx = max_idx(ch_idx);  % índice do tempo correspondente ao pico
    peak_time = EEG.times(idx_min + peak_time_idx - 1);  % tempo em ms do pico

    % Converta o tempo de pico para segundos para usar na latência
    latency_peak = peak_time / 1000;  % converte para segundos
end