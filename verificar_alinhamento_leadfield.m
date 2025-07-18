function verificar_alinhamento_leadfield(leadfield, vol, elec)
    figure;
    
    % Modelo de cabeça
    ft_plot_headmodel(vol.vol, 'facecolor', 'cortex', 'facealpha', 0.2); hold on;

    % Grade de fontes (do leadfield)
    if isfield(leadfield, 'pos')
        ft_plot_mesh(leadfield.pos, 'vertexcolor', 'b');  % pontos da grade
    elseif isfield(leadfield, 'grid') && isfield(leadfield.grid, 'pos')
        ft_plot_mesh(leadfield.grid.pos, 'vertexcolor', 'b');
    else
        warning('Leadfield não contém campo .pos reconhecível!');
    end

    % Sensores
    ft_plot_sens(elec, 'style', 'r*');  % eletrodos em vermelho

    title('Verificação: Modelo de Cabeça + Leadfield + Sensores');
    camlight; lighting gouraud;
end
