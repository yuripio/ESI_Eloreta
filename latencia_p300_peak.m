function latency_peak = latencia_p300_peak(EEG, canais_interesse)
    % Define o intervalo de interesse para P300 (em segundos)
    lat_min = 0.250;
    lat_max = 0.500;

    % Encontra índices no vetor de tempo
    [~, idx_min] = min(abs(EEG.times - lat_min * 1000));
    [~, idx_max] = min(abs(EEG.times - lat_max * 1000));

    % Se canais não forem especificados, use todos
    if nargin < 2 || isempty(canais_interesse)
        canais_interesse = {EEG.chanlocs.labels};
    end

    % Pega índices dos canais de interesse
    idx_canais = find(ismember({EEG.chanlocs.labels}, canais_interesse));

    % Extrai os dados no intervalo e canais escolhidos
    dados_intervalo = EEG.data(idx_canais, idx_min:idx_max, :);

    % Média sobre trials
    media_canais = mean(dados_intervalo, 3);  % [canal x tempo]

    % Média sobre canais
    sinal_medio = mean(media_canais, 1);  % [1 x tempo]

    % Encontra o pico (valor máximo)
    [~, idx_pico] = max(sinal_medio);

    % Converte índice para tempo real (em segundos)
    latency_peak = EEG.times(idx_min + idx_pico - 1) / 1000;

    % Mostrar resultado
    fprintf('🔍 Latência de pico detectada: %.1f ms\n', latency_peak * 1000);
end
