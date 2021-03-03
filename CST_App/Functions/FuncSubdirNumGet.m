function [SubdirNum] = FuncSubdirNumGet(ParentPath)

    Subdir = dir(ParentPath);
    SubdirNum = sum([Subdir(~ismember({Subdir.name},{'.','..'})).isdir]);
end