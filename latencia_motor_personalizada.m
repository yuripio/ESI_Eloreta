function latency_avg = latencia_motor_personalizada(EEG, t_min, t_max)
    if nargin < 3, t_max = 1000; end
    if nargin < 2, t_min = 0; end

    if EEG.trials == 1
        error('Dados não segmentados! Execute pop_epoch primeiro.');
    end

    idx_min = find(EEG.times >= t_min, 1, 'first');
    idx_max = find(EEG.times <= t_max, 1, 'last');
    time_vector = EEG.times(idx_min:idx_max);

    motor_channels = {'C3', 'C4', 'CP3', 'CP4', 'C1', 'C2', 'Cz', 'FC3', 'FC4'};
    chan_idx = find(ismember({EEG.chanlocs.labels}, motor_channels));

    if isempty(chan_idx)
        error('Nenhum dos canais motores esperados foi encontrado!');
    end

    n_epochs = EEG.trials;
    latencies = zeros(1, n_epochs);

    for i = 1:n_epochs
        dados_epoca = EEG.data(chan_idx, idx_min:idx_max, i);
        energia = mean(dados_epoca.^2, 1);

        % Derivada da energia (mudança de energia no tempo)
        delta_energia = [0, diff(energia)];

        % Suavização opcional
        delta_energia_suave = smoothdata(delta_energia, 'gaussian', 10);

        % Ponto de maior aumento de energia
        [~, peak_idx] = max(delta_energia_suave);

        latencies(i) = time_vector(peak_idx) / 1000; % em segundos
    end

    latency_avg = mean(latencies);
    disp(['Latência média (derivada da energia): ' num2str(latency_avg*1000) ' ms']);
end