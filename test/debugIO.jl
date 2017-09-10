#=
The file contains methods which can override file operations to ensure that
the files are closed properly. This needs to be included in the test case with
DEBUG=true. default is false.

This is kept external to the regular library to ensure normal library operations
are not affected.
=#

const DEBUG=false

if DEBUG

import PDFIO.Common: get_tempfilepath,
                     util_open, util_close, utilPrintOpenFiles

using BufferedStreams

import Base: close

function Base.close(stream::BufferedInputStream{IOStream})
  if !isopen(stream)
      return
  end
  util_close(stream.source)
  stream.position = 0
  empty!(stream.buffer)
  return
end

IODebug=[0,Vector{Tuple{AbstractString,IOStream}}()]

function get_tempfilepath()
  global IODebug
  IODebug[1]+=1
  path = joinpath(get_tempdir(), string(IODebug[1]))
  return (path, util_open(path,"w"))
end

function util_open(filename, mode)
  global IODebug
  io=open(filename, mode)
  @printf("Opening file: %s\n",filename)
  push!(IODebug[2], (filename,io))
  return io
end

function util_close(handle::IOStream)
  global IODebug
  idx=1
  for file in IODebug[2]
    if (handle === file[2])
      @printf("Closing file: %s, %d\n", file[1],idx)
      close(handle)
      deleteat!(IODebug[2],idx)
      return
    end
    idx+=1
  end
  error("IO handle not found")
end

function utilPrintOpenFiles()
  global IODebug
  println("The following files are opened currently:")
  println("-----------------------------------------")
  println(IODebug[2])
  println("-----------------------------------------")
  IODebug[2]
end

end

function files_equal(f1, f2)
    io1 = util_open(f1, "r"); io2 = util_open(f2, "r")
    buf1 = read(io1); buf2 = read(io2)
    util_close(io1); util_close(io2)
    return buf1 == buf2
end

function extract_text(io, doc)
    npage = pdDocGetPageCount(doc)
    for i=1:npage
        page = pdDocGetPage(doc, i)
        if pdPageIsEmpty(page) == false
            pdPageGetContentObjects(page)
            pdPageExtractText(io, page)
        end
    end
end

function testfiles(filename)
    name, ext = splitext(filename)
    return (name*".res", joinpath(Pkg.dir("PDFIO"), "test", "files", name*".txt"))
end