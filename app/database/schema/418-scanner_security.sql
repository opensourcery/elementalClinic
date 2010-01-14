UPDATE personnel SET security = security || '0' WHERE length(security) = 6;
