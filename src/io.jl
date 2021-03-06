export read, write, existsfile, mkdir 
export filenames, filepaths, dirnames, dirpaths
export readmat, writemat
export writejls, readjls
# using MAT

existsfile(filename::AbstractString) = (s = stat(filename); s.inode!=0)

import Base.read
read(filename::AbstractString) = open(read, filename)

import Base.write
write(data::AbstractString, filename::AbstractString) = write(data, filename, "w")
function write(data::AbstractString, filename::AbstractString, mode)
    io = open(filename, mode)
    finalizer(close, io)
    write(io,data)
    close(io)
end

function filedirnames(path = pwd(); selector = isdir, hidden = false, withpath = false, 
    recursive = false, suffix = "", regex = Nothing)
    # @show path selector hidden withpath
    files = readdir(path)
    r = filter(x->selector(joinpath(path,x)) && (hidden || x[1]!='.'), files)
    # @show r
    r = sort(r)
    r = withpath ? mapvec(r, x->joinpath(path,x)) : r
    f = String
    r = mapvec(r, f)
    if recursive
        f(x) = filedirnames(x; 
            selector = selector, hidden = hidden, withpath = withpath, recursive = true)
        r = @p dirpaths path | mapvec f | flatten | concat r _
    end
    if !isempty(suffix)
        suffix = isa(suffix, AbstractString) ? [suffix] : suffix
        r = @p mapvec suffix (suf->@p filter r x->@p takelast x len(suf) | isequal suf) | flatten
    end
    if regex != Nothing
        r = @p filter r x->@p ismatch regex x
    end
    r
end
dirnames(path = pwd(); kargs...) = filedirnames(path; selector = isdir, kargs...)
dirpaths(path = pwd(); kargs...) = dirnames(path; withpath = true, kargs...)
filenames(path = pwd(); kargs...) = filedirnames(path; selector = x->!isdir(x), kargs...)
filepaths(path = pwd(); kargs...) = filenames(path; withpath = true, kargs...)

function readmat(filename)
    return matread(filename)
end

readmat(filename,variables) = readmat(filename, variables...)

function readmat(filename,variables...)
    r = Any[]
    mat = matopen(filename)
    try
        for v in variables
            r[v] = read(mat, v)
        end
    finally
        close(mat)
    end
end

function writejls(a,filename)
    tempfilename = @p concat filename "." randstring(10) ".tmp"
    open(fd->serialize(fd,a),tempfilename,"w")
    mv(tempfilename, filename, force = true)
    filename
end
readjls(filename) = open(Serialization.deserialize, filename, "r")
