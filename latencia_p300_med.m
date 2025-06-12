function latency_avg = latencia_p300_med(EEG)
    % Defina o intervalo de tempo de interesse (em segundos)
    lat_min = 0.250;  % 250 ms
    lat_max = 0.500;   % 450 ms

    % Encontre o índice do intervalo de latência no EEG
    [~, idx_min] = min(abs(EEG.times - (lat_min * 1000)));  % converte para ms
    [~, idx_max] = min(abs(EEG.times - (lat_max * 1000)));

    % Extraia os dados do EEG nesse intervalo de tempo (250-500 ms)
    data_in_interval = EEG.data(:, idx_min:idx_max, :);  % extrai os dados dos eletrodos nesse intervalo

    % Calcule a média da atividade no intervalo de tempo (250-500 ms) em todos os canais e trials
    avg_data = mean(mean(data_in_interval, 3), 2);  % média sobre o tempo e os trials

    % Calcule a média dos tempos no intervalo, para obter a latência média
    avg_time = mean(EEG.times(idx_min:idx_max));  % tempo médio do intervalo em ms

    % Converta o tempo médio para segundos para usar na latência
    latency_avg = avg_time / 1000;  % converte para segundos

    % Agora ajuste a latência na sua plotagem de reconstrução de fonte:
    cfg.latency = latency_avg;  % Define a latência com base na média da atividade
end
