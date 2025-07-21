let odir = pwd()
    try
        cd(@__DIR__)
        run(`make`; wait=true)
    finally
        cd(odir)
    end
end
