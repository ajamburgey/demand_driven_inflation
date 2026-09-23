function v = readMPDround(file, grid)
% readMPDround: read one ECB SDMX round csv (dataflow MPD, columns TIME_PERIOD
% like '1995-Q1' and OBS_VALUE) and return the values aligned to a quarterly
% key grid (year*4+quarter).
  T = readtable(file, 'TextType','string');
  v = NaN(numel(grid),1);
  per = T.TIME_PERIOD; val = T.OBS_VALUE;
  for r = 1:numel(per)
    tok = regexp(per(r), '(\d{4})-Q([1-4])', 'tokens', 'once');
    if isempty(tok), continue; end
    k = str2double(tok(1))*4 + str2double(tok(2));
    g = find(grid == k, 1);
    if ~isempty(g) && isnumeric(val(r)), v(g) = val(r); end
  end
end
