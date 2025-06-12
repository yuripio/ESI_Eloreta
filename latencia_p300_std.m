function latency_std = latencia_p300_std(EEG)
    % Defina o intervalo de tempo de interesse (em segundos)
    lat_min = 0.250;  % 250 ms
    lat_max = 0.450;   % 450 ms

    % Encontre o índice do intervalo de latência no EEG
    [~, idx_min] = min(abs(EEG.times - (lat_min * 1000)));  % converte para ms
    [~, idx_max] = min(abs(EEG.times - (lat_max * 1000)));

    % Extraia os dados do EEG nesse intervalo de tempo (250-450 ms)
    data_in_interval = EEG.data(:, idx_min:idx_max, :);  % extrai os dados dos eletrodos nesse intervalo

    % Calcule o desvio padrão da atividade para cada ponto no tempo, considerando todos os canais e trials
    std_data = std(mean(data_in_interval, 3), 0, 2);  % desvio padrão sobre os trials para cada ponto no tempo

    % Encontre o tempo correspondente ao menor desvio padrão (indicando o ponto mais estável)
    [~, min_std_idx] = min(std_data);  % índice do menor desvio padrão

    % Obtenha a latência correspondente ao ponto de menor desvio padrão
    latency_std = EEG.times(idx_min + min_std_idx - 1) / 1000;  % converte para segundos

    % Agora ajuste a latência na sua plotagem de reconstrução de fonte:
    cfg.latency = latency_std;  % Define a latência com base no desvio padrão

end
