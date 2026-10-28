function half_violin(xpos, data, side, color)
    [f,xi] = ksdensity(data);
    f = f./max(f) * 0.25;

    if side == "left"
        x = xpos - f;
    else
        x = xpos + f;
    end

    fill([x fliplr(xpos*ones(size(x)))], ...
         [xi fliplr(xi)], ...
         color, 'FaceAlpha',0.25, 'EdgeColor','none');
end