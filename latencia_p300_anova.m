function latency_anova = latencia_p300_anova(EEG)
    % Defina o intervalo de tempo de interesse (em segundos)
    lat_min = 0.250;  % 250 ms
    lat_max = 0.450;   % 450 ms

    % Encontre o índice do intervalo de latência no EEG
    [~, idx_min] = min(abs(EEG.times - (lat_min * 1000)));  % converte para ms
    [~, idx_max] = min(abs(EEG.times - (lat_max * 1000)));

    % Extraia os dados do EEG nesse intervalo de tempo (250-450 ms)
    data_in_interval = EEG.data(:, idx_min:idx_max, :);  % extrai os dados dos eletrodos nesse intervalo

    % Inicialize um vetor para armazenar a variância para cada ponto no tempo
    variances = zeros(1, idx_max - idx_min + 1);

    % Calcule a variância para cada ponto de tempo dentro do intervalo
    for t = idx_min:idx_max
        % Extraia os dados do tempo t para todos os canais e trials
        data_at_t = squeeze(data_in_interval(:, t - idx_min + 1, :));
        
        % Calcule a variância entre os trials para cada ponto de tempo
        variances(t - idx_min + 1) = var(mean(data_at_t, 1));  % média dos canais, variância sobre os trials
    end

    % Encontre o tempo correspondente à menor variância (indicando o ponto mais estável)
    [~, min_variance_idx] = min(variances);  % índice da menor variância

    % Obtenha a latência correspondente ao ponto de menor variância
    latency_anova = EEG.times(idx_min + min_variance_idx - 1) / 1000;  % converte para segundos

    % Agora ajuste a latência na sua plotagem de reconstrução de fonte:
    cfg.latency = latency_anova;  % Define a latência com base na ANOVA

end
