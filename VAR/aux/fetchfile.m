function fetchfile(dest, url)
% fetchfile: download url to dest via curl, trying a browser user agent first
% and plain curl second (some hosts accept one and reject the other).
%
% Some hosts (the ECB Data Portal in particular) occasionally respond to a
% valid request with an HTML "server busy"/504 page instead of real data,
% while curl itself still exits 0 with a plausible byte count -- so that
% alone can't be trusted. Each attempt is checked for an HTML/error-page
% signature, and the whole thing is retried a few times with a short pause,
% since these responses are typically transient.
  maxTries  = 3;
  pauseSecs = 5;
  for attempt = 1:maxTries
      ok = tryOnce(dest, url, '-A "Mozilla/5.0"');
      if ~ok, ok = tryOnce(dest, url, ''); end
      if ok, return; end
      if attempt < maxTries, pause(pauseSecs); end
  end
  assert(ok, 'download failed (or kept returning an error page) after %d tries: %s', maxTries, url);
end

function ok = tryOnce(dest, url, uaflag)
  st = system(sprintf('curl -sL %s --max-time 120 -o "%s" "%s"', uaflag, dest, url));
  fi = dir(dest);
  ok = (st == 0) && ~isempty(fi) && fi(1).bytes > 200 && ~looksLikeErrorPage(dest);
end

function bad = looksLikeErrorPage(dest)
% true if the file starts with an HTML/error-page signature rather than
% real data (CSV, xlsx, json): a cheap check that never false-positives on
% legitimate data, since none of it legitimately starts this way.
  fid = fopen(dest, 'rb');
  head = char(fread(fid, 500, 'uint8=>uint8'))';
  fclose(fid);
  bad = ~isempty(regexpi(head, '<!DOCTYPE|<html|<HTML|502 Bad Gateway|503 Service|504 Gateway', 'once'));
end
