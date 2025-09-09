files = dir('*.asv');
for k = 1:length(files)
    delete(files(k).name);
end